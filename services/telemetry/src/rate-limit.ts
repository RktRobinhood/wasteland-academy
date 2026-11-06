// A fixed one-minute window per session ID, held in the Worker instance's memory.
// Each instance counts on its own, so this stops a runaway client, not a determined
// one. It is keyed by the game's random session ID because the collector never reads
// the IP.
const WINDOW_MS = 60_000;
const MAX_KEYS = 10_000;

export class RateLimiter {
	private windows = new Map<string, { start: number; count: number }>();

	allow(key: string, perMinute: number, now: number): boolean {
		const window = this.windows.get(key);
		if (!window || now - window.start >= WINDOW_MS) {
			if (this.windows.size >= MAX_KEYS) this.prune(now);
			this.windows.set(key, { start: now, count: 1 });
			return true;
		}
		window.count += 1;
		return window.count <= perMinute;
	}

	private prune(now: number): void {
		for (const [key, window] of this.windows) if (now - window.start >= WINDOW_MS) this.windows.delete(key);
		if (this.windows.size >= MAX_KEYS) this.windows.clear();
	}
}
