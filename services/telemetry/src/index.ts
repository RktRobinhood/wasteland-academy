// The telemetry collector (FAL-406): takes event batches from the Godot game at
// POST /v1/events and stores the allowlisted fields in D1.
//
// Privacy rules from the FAL-379 plan: this Worker never reads the IP, any
// forwarding header or Cloudflare's per-request location data, and it logs nothing.
import { checkEvent, schema, type Row } from "./schema";
import { RateLimiter } from "./rate-limit";

export interface Env {
	DB: D1Database;
	ALLOWED_ORIGIN: string;
	RATE_LIMIT_PER_MINUTE: string;
}

const limiter = new RateLimiter();

function json(body: unknown, status: number, headers: HeadersInit = {}): Response {
	return new Response(JSON.stringify(body), {
		status,
		headers: { "Content-Type": "application/json", ...headers },
	});
}

function cors(origin: string): Record<string, string> {
	return { "Access-Control-Allow-Origin": origin, Vary: "Origin" };
}

// The body as text, or null when it is over `limit` bytes. Stops reading at the
// limit, whatever Content-Length says.
async function readCapped(request: Request, limit: number): Promise<string | null> {
	const declared = Number(request.headers.get("Content-Length"));
	if (declared > limit) return null;
	if (!request.body) return "";
	const reader = request.body.getReader();
	const chunks: Uint8Array[] = [];
	let size = 0;
	for (;;) {
		const { done, value } = await reader.read();
		if (done) break;
		size += value.byteLength;
		if (size > limit) {
			await reader.cancel();
			return null;
		}
		chunks.push(value);
	}
	const bytes = new Uint8Array(size);
	let at = 0;
	for (const chunk of chunks) {
		bytes.set(chunk, at);
		at += chunk.byteLength;
	}
	return new TextDecoder().decode(bytes);
}

// UTC to the second: 2026-10-29T06:30:00Z
export function timestamp(date: Date): string {
	return date.toISOString().slice(0, 19) + "Z";
}

async function receive(request: Request, env: Env, headers: Record<string, string>): Promise<Response> {
	const text = await readCapped(request, schema.limits.max_bytes);
	if (text === null) return json({ error: "body over 32 KB" }, 413, headers);

	let body: unknown;
	try {
		body = JSON.parse(text);
	} catch {
		return json({ error: "body is not JSON" }, 400, headers);
	}
	if (typeof body !== "object" || body === null || Array.isArray(body)) return json({ error: "body is not an object" }, 400, headers);
	const { schema: version, events } = body as Record<string, unknown>;
	if (version !== schema.version) return json({ error: `schema must be ${schema.version}` }, 400, headers);
	if (!Array.isArray(events) || events.length === 0) return json({ error: "events must be a non-empty array" }, 400, headers);
	if (events.length > schema.limits.max_events) return json({ error: `over ${schema.limits.max_events} events` }, 413, headers);

	// A batch comes from one session, and the rate limit counts per session
	const sessions = new Set(events.map((e) => (typeof e === "object" && e !== null ? (e as Record<string, unknown>).session_id : undefined)));
	const [session] = sessions;
	if (sessions.size !== 1 || typeof session !== "string") return json({ error: "a batch needs one session_id" }, 400, headers);
	const perMinute = Number(env.RATE_LIMIT_PER_MINUTE) || 30;
	if (!limiter.allow(session, perMinute, Date.now())) return json({ error: "too many requests" }, 429, { ...headers, "Retry-After": "60" });

	const rows: Row[] = [];
	const rejected: { index: number; reason: string }[] = [];
	events.forEach((event, index) => {
		const checked = checkEvent(event);
		if (checked.ok) rows.push(checked.row);
		else rejected.push({ index, reason: checked.reason });
	});
	if (rows.length === 0) return json({ accepted: 0, rejected }, 400, headers);

	const receivedAt = timestamp(new Date());
	const insert = env.DB.prepare(
		"INSERT INTO events (received_at, session_id, seq, event, view_id, seed, fields, game_version, arms) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
	);
	try {
		await env.DB.batch(
			rows.map((r) => insert.bind(receivedAt, r.session_id, r.seq, r.event, r.view_id, r.seed, r.fields, r.game_version, r.arms)),
		);
	} catch {
		return json({ error: "storage unavailable" }, 503, { ...headers, "Retry-After": "60" });
	}
	return json({ accepted: rows.length, rejected }, 202, headers);
}

// Deletes raw events received more than 12 months before `now`. Returns how many.
export async function deleteOldEvents(db: D1Database, now: Date): Promise<number> {
	const cutoff = new Date(now);
	cutoff.setUTCMonth(cutoff.getUTCMonth() - 12);
	const result = await db.prepare("DELETE FROM events WHERE received_at < ?").bind(timestamp(cutoff)).run();
	return result.meta.changes;
}

export default {
	async fetch(request, env): Promise<Response> {
		const url = new URL(request.url);
		if (url.pathname !== "/v1/events") return new Response("Not found", { status: 404 });

		// Only the game's own site. Builds outside a browser send this Origin header too.
		const origin = request.headers.get("Origin");
		if (origin !== env.ALLOWED_ORIGIN) return new Response("Forbidden", { status: 403 });
		const headers = cors(origin);

		if (request.method === "OPTIONS") {
			return new Response(null, {
				status: 204,
				headers: {
					...headers,
					"Access-Control-Allow-Methods": "POST",
					"Access-Control-Allow-Headers": "Content-Type",
					"Access-Control-Max-Age": "86400",
				},
			});
		}
		if (request.method !== "POST") return new Response("Method not allowed", { status: 405, headers: { ...headers, Allow: "POST, OPTIONS" } });
		return receive(request, env, headers);
	},

	async scheduled(controller, env): Promise<void> {
		await deleteOldEvents(env.DB, new Date(controller.scheduledTime));
	},
} satisfies ExportedHandler<Env>;
