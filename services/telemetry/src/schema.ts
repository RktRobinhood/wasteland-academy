// Checks events against schema.json, the allowlist the game shares (FAL-405).
import schemaJson from "../schema.json";

type FieldSpec =
	| { type: "string"; required?: boolean; max?: number; pattern?: string; strip_digits?: boolean }
	| { type: "int" | "number"; required?: boolean; min?: number; max?: number }
	| { type: "bool"; required?: boolean }
	| { type: "enum"; required?: boolean; values: string[] }
	| { type: "arms"; required?: boolean; max_entries: number; key_pattern: string; value_pattern: string };

type Fields = Record<string, FieldSpec>;

interface Schema {
	version: number;
	limits: { max_events: number; max_bytes: number };
	envelope: Fields;
	events: Record<string, Fields>;
}

export const schema = schemaJson as unknown as Schema;

// The fields that get their own column; every other event field goes in `fields`
const COLUMNS = new Set(["event", "session_id", "game_version", "seq", "arms", "view_id", "seed"]);

export interface Row {
	session_id: string;
	seq: number | null;
	event: string;
	view_id: string | null;
	seed: number | null;
	fields: string;
	game_version: string;
	arms: string | null;
}

export type Checked = { ok: true; row: Row } | { ok: false; reason: string };

const patterns = new Map<string, RegExp>();
function matches(pattern: string, value: string): boolean {
	let re = patterns.get(pattern);
	if (!re) {
		re = new RegExp(pattern);
		patterns.set(pattern, re);
	}
	return re.test(value);
}

const INVALID = Symbol("invalid");

// The clean value, or INVALID
function clean(spec: FieldSpec, value: unknown): unknown {
	switch (spec.type) {
		case "string": {
			if (typeof value !== "string") return INVALID;
			const text = spec.strip_digits ? value.replace(/[0-9]+/g, "#") : value;
			if (spec.max !== undefined && text.length > spec.max) return INVALID;
			if (spec.pattern !== undefined && !matches(spec.pattern, text)) return INVALID;
			return text;
		}
		case "int":
		case "number": {
			if (typeof value !== "number" || !Number.isFinite(value)) return INVALID;
			if (spec.type === "int" && !Number.isSafeInteger(value)) return INVALID;
			if (spec.min !== undefined && value < spec.min) return INVALID;
			if (spec.max !== undefined && value > spec.max) return INVALID;
			return value;
		}
		case "bool":
			return typeof value === "boolean" ? value : INVALID;
		case "enum":
			return typeof value === "string" && spec.values.includes(value) ? value : INVALID;
		case "arms": {
			if (typeof value !== "object" || value === null || Array.isArray(value)) return INVALID;
			const entries = Object.entries(value);
			if (entries.length > spec.max_entries) return INVALID;
			for (const [k, v] of entries) {
				if (!matches(spec.key_pattern, k) || typeof v !== "string" || !matches(spec.value_pattern, v)) return INVALID;
			}
			return entries.length ? Object.fromEntries(entries) : INVALID;
		}
	}
}

// Rejects an unknown event name or a missing or invalid required field. Drops
// unknown fields and invalid optional ones.
export function checkEvent(input: unknown): Checked {
	if (typeof input !== "object" || input === null || Array.isArray(input)) return { ok: false, reason: "not an object" };
	const raw = input as Record<string, unknown>;
	const name = raw.event;
	if (typeof name !== "string" || !Object.hasOwn(schema.events, name)) return { ok: false, reason: "unknown event" };

	const allowed: Fields = { ...schema.envelope, ...schema.events[name] };
	const kept: Record<string, unknown> = {};
	for (const [field, spec] of Object.entries(allowed)) {
		const present = Object.hasOwn(raw, field) && raw[field] !== null;
		const value = present ? clean(spec, raw[field]) : INVALID;
		if (value === INVALID) {
			if (spec.required) return { ok: false, reason: present ? `invalid ${field}` : `missing ${field}` };
			continue;
		}
		kept[field] = value;
	}

	const rest: Record<string, unknown> = {};
	for (const [field, value] of Object.entries(kept)) if (!COLUMNS.has(field)) rest[field] = value;
	return {
		ok: true,
		row: {
			session_id: kept.session_id as string,
			seq: (kept.seq as number | undefined) ?? null,
			event: name,
			view_id: (kept.view_id as string | undefined) ?? null,
			seed: (kept.seed as number | undefined) ?? null,
			fields: JSON.stringify(rest),
			game_version: kept.game_version as string,
			arms: kept.arms === undefined ? null : JSON.stringify(kept.arms),
		},
	};
}
