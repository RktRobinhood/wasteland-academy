import { createScheduledController } from "cloudflare:test";
import { env, exports } from "cloudflare:workers";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import worker, { timestamp } from "../src/index";
import schemaJson from "../schema.json";
import indexSource from "../src/index.ts?raw";
import schemaSource from "../src/schema.ts?raw";
import rateLimitSource from "../src/rate-limit.ts?raw";
import wranglerToml from "../wrangler.toml?raw";

const ORIGIN = "https://rktrobinhood.github.io";
const URL_ = "https://telemetry.example/v1/events";

let sessionCounter = 0;
// A fresh session per test, so the rate limit from one test can't touch another
function newSession(): string {
	sessionCounter += 1;
	return sessionCounter.toString(16).padStart(32, "0");
}

let session = "";
beforeEach(async () => {
	session = newSession();
	await env.DB.exec("DELETE FROM events");
});
afterEach(() => vi.restoreAllMocks());

function base(event: string) {
	return { event, session_id: session, game_version: "0.4.1" };
}

const shown = () => ({ ...base("question_shown"), view_id: "fn-quadratic-features/vertex-from-general/equation/complete-square/value", seed: 3, cell: "fn-quadratic-features/vertex-from-general", mode: "practice" });
const checked = () => ({ ...base("answer_checked"), view_id: "fn-quadratic-features/vertex-from-general/equation/complete-square/value", seed: 3, correct: false, attempt: 1, seconds: 41.5, format_errors: 0, misconception: "sign-of-h", solution_opened: true });

function post(body: unknown, headers: Record<string, string> = {}): Promise<Response> {
	return exports.default.fetch(URL_, {
		method: "POST",
		headers: { Origin: ORIGIN, "Content-Type": "application/json", ...headers },
		body: typeof body === "string" ? body : JSON.stringify(body),
	});
}

async function rows(): Promise<Record<string, unknown>[]> {
	const { results } = await env.DB.prepare("SELECT * FROM events ORDER BY id").all();
	return results;
}

describe("a valid batch", () => {
	it("is stored, one row per event, with view id and seed in their own columns", async () => {
		const res = await post({ schema: 1, events: [{ ...base("session_start"), seq: 0, platform: "web", language: "en", screen_band: "small", arms: { "hint-wording": "new" } }, { ...shown(), seq: 1 }, { ...checked(), seq: 2 }] });
		expect(res.status).toBe(202);
		expect(await res.json()).toEqual({ accepted: 3, rejected: [] });
		expect(res.headers.get("Access-Control-Allow-Origin")).toBe(ORIGIN);

		const stored = await rows();
		expect(stored).toHaveLength(3);
		expect(stored[0]).toMatchObject({ session_id: session, seq: 0, event: "session_start", view_id: null, seed: null, game_version: "0.4.1", arms: '{"hint-wording":"new"}' });
		expect(JSON.parse(stored[0].fields as string)).toEqual({ platform: "web", language: "en", screen_band: "small" });
		expect(stored[2]).toMatchObject({ event: "answer_checked", view_id: "fn-quadratic-features/vertex-from-general/equation/complete-square/value", seed: 3, arms: null });
		expect(JSON.parse(stored[2].fields as string)).toEqual({ correct: false, attempt: 1, seconds: 41.5, format_errors: 0, misconception: "sign-of-h", solution_opened: true });
		expect(stored[0].received_at).toMatch(/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ$/);
	});

	it("is accepted as text/plain, as navigator.sendBeacon sends it", async () => {
		const res = await post({ schema: 1, events: [shown()] }, { "Content-Type": "text/plain;charset=UTF-8" });
		expect(res.status).toBe(202);
		expect(await rows()).toHaveLength(1);
	});

	it("answers the CORS preflight for the game's site", async () => {
		const res = await exports.default.fetch(URL_, { method: "OPTIONS", headers: { Origin: ORIGIN, "Access-Control-Request-Method": "POST" } });
		expect(res.status).toBe(204);
		expect(res.headers.get("Access-Control-Allow-Origin")).toBe(ORIGIN);
		expect(res.headers.get("Access-Control-Allow-Methods")).toBe("POST");
	});

	it("takes every event type in schema.json", async () => {
		const events = [
			{ ...base("session_start"), platform: "desktop" },
			shown(),
			checked(),
			{ ...base("question_left"), view_id: "a/b", seed: 9, seconds: 600 },
			{ ...base("generator_error"), view_id: "a/b", seed: 9, message: "no root" },
			{ ...base("client_error"), message: "Invalid call", script: "res://ui/practice.gd", line: 120 },
			{ ...base("session_end"), minutes: 12.5, answered: 30 },
		];
		expect(events.map((e) => e.event).sort()).toEqual(Object.keys(schemaJson.events).sort());
		const res = await post({ schema: 1, events });
		expect(await res.json()).toEqual({ accepted: 7, rejected: [] });
	});
});

describe("fields", () => {
	it("drops fields that aren't on the allowlist", async () => {
		const res = await post({ schema: 1, events: [{ ...checked(), typed_answer: "x = 3/0", name: "Ada", email: "a@b.c", class_code: "11B" }] });
		expect(res.status).toBe(202);
		const [row] = await rows();
		const text = JSON.stringify(row);
		for (const leaked of ["typed_answer", "3/0", "Ada", "a@b.c", "11B", "class_code"]) expect(text).not.toContain(leaked);
		expect(Object.keys(JSON.parse(row.fields as string)).sort()).toEqual(["attempt", "correct", "format_errors", "misconception", "seconds", "solution_opened"]);
	});

	it("drops an optional field with a bad value and keeps the event", async () => {
		await post({ schema: 1, events: [{ ...checked(), seconds: 9999, mode: "practice", misconception: "Has Spaces" }] });
		const [row] = await rows();
		const fields = JSON.parse(row.fields as string);
		expect(fields).not.toHaveProperty("seconds");
		expect(fields).not.toHaveProperty("misconception");
		expect(fields).not.toHaveProperty("mode"); // a question_shown field, not an answer_checked one
		expect(fields.correct).toBe(false);
	});

	it("rejects an event missing a required field or with a bad one", async () => {
		const { view_id: _, ...noView } = shown();
		const res = await post({ schema: 1, events: [noView, { ...shown(), seed: -1 }, { ...shown(), session_id: session, game_version: "0.4.1 <script>" }, shown()] });
		expect(res.status).toBe(202);
		expect(await res.json()).toEqual({
			accepted: 1,
			rejected: [
				{ index: 0, reason: "missing view_id" },
				{ index: 1, reason: "invalid seed" },
				{ index: 2, reason: "invalid game_version" },
			],
		});
	});

	it("removes numbers from error messages", async () => {
		await post({ schema: 1, events: [{ ...base("client_error"), message: "Index 12 out of bounds (size 3)", line: 40 }] });
		const [row] = await rows();
		expect(JSON.parse(row.fields as string)).toEqual({ message: "Index # out of bounds (size #)", line: 40 });
	});
});

describe("rejects", () => {
	it("an unknown event name", async () => {
		const res = await post({ schema: 1, events: [{ ...base("mouse_moved"), x: 1 }, { ...base("__proto__") }] });
		expect(res.status).toBe(400);
		expect(await res.json()).toEqual({ accepted: 0, rejected: [{ index: 0, reason: "unknown event" }, { index: 1, reason: "unknown event" }] });
		expect(await rows()).toHaveLength(0);
	});

	it("an unknown event but keeps the known ones in the same batch", async () => {
		const res = await post({ schema: 1, events: [shown(), { ...base("mouse_moved") }] });
		expect(res.status).toBe(202);
		expect(await res.json()).toEqual({ accepted: 1, rejected: [{ index: 1, reason: "unknown event" }] });
	});

	it("more than 50 events with 413", async () => {
		const res = await post({ schema: 1, events: Array.from({ length: 51 }, () => ({ ...base("session_end") })) });
		expect(res.status).toBe(413);
		expect(await rows()).toHaveLength(0);
	});

	it("50 events is fine", async () => {
		const res = await post({ schema: 1, events: Array.from({ length: 50 }, () => ({ ...base("session_end") })) });
		expect(res.status).toBe(202);
		expect(await rows()).toHaveLength(50);
	});

	it("a body over 32 KB with 413, even when it doesn't say its length", async () => {
		const big = JSON.stringify({ schema: 1, events: [{ ...base("client_error"), message: "x".repeat(33_000) }] });
		expect((await post(big)).status).toBe(413);

		// A streamed body has no Content-Length, so the collector has to count
		const stream = new ReadableStream({
			start(controller) {
				controller.enqueue(new TextEncoder().encode(big));
				controller.close();
			},
		});
		const res = await exports.default.fetch(URL_, { method: "POST", headers: { Origin: ORIGIN }, body: stream, duplex: "half" } as RequestInit);
		expect(res.status).toBe(413);
		expect(await rows()).toHaveLength(0);
	});

	it("a request from another origin, or none, with 403 and no CORS headers", async () => {
		for (const origin of ["https://evil.example", "http://rktrobinhood.github.io", "https://rktrobinhood.github.io.evil.example", "null"]) {
			const res = await post({ schema: 1, events: [shown()] }, { Origin: origin });
			expect(res.status, origin).toBe(403);
			expect(res.headers.get("Access-Control-Allow-Origin")).toBeNull();
		}
		const preflight = await exports.default.fetch(URL_, { method: "OPTIONS", headers: { Origin: "https://evil.example" } });
		expect(preflight.status).toBe(403);
		const noOrigin = await exports.default.fetch(URL_, { method: "POST", body: JSON.stringify({ schema: 1, events: [shown()] }) });
		expect(noOrigin.status).toBe(403);
		expect(await rows()).toHaveLength(0);
	});

	it("a wrong schema version, bad JSON, or a batch mixing sessions with 400", async () => {
		expect((await post({ schema: 2, events: [shown()] })).status).toBe(400);
		expect((await post("{not json")).status).toBe(400);
		expect((await post({ schema: 1, events: [] })).status).toBe(400);
		expect((await post({ schema: 1, events: [shown(), { ...shown(), session_id: newSession() }] })).status).toBe(400);
		expect(await rows()).toHaveLength(0);
	});

	it("other paths and methods", async () => {
		expect((await exports.default.fetch("https://telemetry.example/", { headers: { Origin: ORIGIN } })).status).toBe(404);
		expect((await exports.default.fetch(URL_, { headers: { Origin: ORIGIN } })).status).toBe(405);
	});
});

describe("rate limit", () => {
	it("allows 30 requests a minute per session, then answers 429", async () => {
		for (let i = 0; i < 30; i++) expect((await post({ schema: 1, events: [shown()] })).status).toBe(202);
		const res = await post({ schema: 1, events: [shown()] });
		expect(res.status).toBe(429);
		expect(res.headers.get("Retry-After")).toBe("60");

		// Another session isn't held back
		session = newSession();
		expect((await post({ schema: 1, events: [shown()] })).status).toBe(202);
	});
});

describe("privacy", () => {
	it("stores no IP, even when the request carries one in every usual header", async () => {
		const ip = "203.0.113.77";
		const res = await post(
			{ schema: 1, events: [shown(), { ...checked(), ip }] },
			{ "CF-Connecting-IP": ip, "X-Forwarded-For": ip, "X-Real-IP": ip, "True-Client-IP": ip },
		);
		expect(res.status).toBe(202);
		const stored = await rows();
		expect(stored).toHaveLength(2);
		expect(JSON.stringify(stored)).not.toContain(ip);
		expect(JSON.stringify(stored)).not.toContain("203.0.113");

		const { results: columns } = await env.DB.prepare("SELECT name FROM pragma_table_info('events')").all<{ name: string }>();
		expect(columns.map((c) => c.name).sort()).toEqual(["arms", "event", "fields", "game_version", "id", "received_at", "seed", "seq", "session_id", "view_id"]);
	});

	it("never reads the IP headers or request.cf, and logs nothing", async () => {
		for (const source of [indexSource, schemaSource, rateLimitSource]) {
			expect(source).not.toMatch(/connecting-ip|x-forwarded|real-ip|true-client|\.cf\b/i);
			expect(source).not.toMatch(/console\./);
		}
		expect(wranglerToml).toMatch(/\[observability\]\s*\nenabled = false/);
	});

	it("writes nothing to the console while handling a batch", async () => {
		const spies = (["log", "info", "warn", "error", "debug"] as const).map((m) => vi.spyOn(console, m));
		await post({ schema: 1, events: [checked(), { ...base("mouse_moved") }] });
		await post("{not json");
		for (const spy of spies) expect(spy).not.toHaveBeenCalled();
	});
});

describe("retention", () => {
	it("the scheduled job deletes raw events older than 12 months and keeps the rest", async () => {
		const now = new Date("2026-10-29T03:15:00Z");
		const insert = env.DB.prepare("INSERT INTO events (received_at, session_id, event, fields, game_version) VALUES (?, ?, 'session_end', '{}', '0.4.1')");
		await env.DB.batch([
			insert.bind("2025-01-01T00:00:00Z", "old"),
			insert.bind("2025-10-29T03:14:59Z", "just-over-a-year"),
			insert.bind("2025-10-29T03:15:00Z", "exactly-a-year"),
			insert.bind("2026-06-01T00:00:00Z", "recent"),
			insert.bind(timestamp(now), "today"),
		]);

		await worker.scheduled(createScheduledController({ scheduledTime: now.getTime(), cron: "15 3 * * *" }), env);

		expect((await rows()).map((r) => r.session_id)).toEqual(["exactly-a-year", "recent", "today"]);
	});
});
