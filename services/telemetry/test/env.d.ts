declare namespace Cloudflare {
	interface GlobalProps {
		mainModule: typeof import("../src/index");
	}
	interface Env {
		DB: D1Database;
		ALLOWED_ORIGIN: string;
		RATE_LIMIT_PER_MINUTE: string;
		TEST_MIGRATIONS: import("cloudflare:test").D1Migration[];
	}
}
