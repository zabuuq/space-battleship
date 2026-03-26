'use strict';

/**
 * SQLite database initialisation for the relay server.
 * Issue #42 – relay server room state persistence.
 *
 * The database file lives at server/relay.db (per project spec).
 * All server-side state – lobbies, sessions and match metadata – is stored here
 * so that AI tooling (mcp-sqlite) can query it directly.
 */

const path = require('path');
const Database = require('better-sqlite3');

const DB_PATH = path.join(__dirname, 'relay.db');

const db = new Database(DB_PATH);

// Enable WAL mode for better concurrent-read performance.
db.pragma('journal_mode = WAL');

db.exec(`
  CREATE TABLE IF NOT EXISTS lobbies (
    code        TEXT PRIMARY KEY,
    host_id     TEXT NOT NULL,
    state       TEXT NOT NULL DEFAULT 'waiting',
    created_at  INTEGER NOT NULL DEFAULT (unixepoch())
  );

  CREATE TABLE IF NOT EXISTS sessions (
    session_id    TEXT PRIMARY KEY,
    lobby_code    TEXT NOT NULL,
    player_index  INTEGER NOT NULL,
    player_name   TEXT NOT NULL,
    connected     INTEGER NOT NULL DEFAULT 1,
    joined_at     INTEGER NOT NULL DEFAULT (unixepoch()),
    FOREIGN KEY (lobby_code) REFERENCES lobbies (code)
  );

  CREATE TABLE IF NOT EXISTS matches (
    lobby_code    TEXT PRIMARY KEY,
    game_state    TEXT,
    started_at    INTEGER NOT NULL DEFAULT (unixepoch()),
    ended_at      INTEGER,
    FOREIGN KEY (lobby_code) REFERENCES lobbies (code)
  );
`);

module.exports = db;
