-- One row per accepted event (FAL-406). No IP, no name, no persistent ID: session_id
-- is a random ID the game makes at launch and keeps only in memory.
CREATE TABLE events (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  received_at  TEXT    NOT NULL,  -- UTC, 2026-10-29T06:30:00Z
  session_id   TEXT    NOT NULL,
  seq          INTEGER,           -- the event's order within its session, when the game sends it
  event        TEXT    NOT NULL,
  view_id      TEXT,
  seed         INTEGER,
  fields       TEXT    NOT NULL,  -- JSON object: the event's other allowlisted fields
  game_version TEXT    NOT NULL,
  arms         TEXT               -- JSON object, experiment name to arm, or NULL
);

-- The outlier report (FAL-407): rates per question type and per seed
CREATE INDEX events_event_view_seed ON events (event, view_id, seed);
-- Drop-off: each session's events in order
CREATE INDEX events_session ON events (session_id, seq, id);
-- Errors grouped by game version
CREATE INDEX events_event_version ON events (event, game_version);
-- Weekly windows and the 12-month retention job
CREATE INDEX events_received_at ON events (received_at);
