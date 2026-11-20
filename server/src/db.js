import pg from "pg";

// A pool keeps a few connections open and reuses them,
// instead of opening a new connection for every request (slow).
export const pool = new pg.Pool({
  connectionString: process.env.DATABASE_URL,
});
