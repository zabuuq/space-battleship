'use strict';

/**
 * Message handler for the relay server.
 * Dispatches incoming client messages to the appropriate handler function.
 *
 * Issues covered:
 *   #40 – lobby code match flow
 *   #41 – WebSocket connection layer
 *   #42 – relay server room state
 *   #43 – synchronise turn actions over the network
 *   #44 – handle disconnects and invalid sessions
 */

const crypto = require('crypto');

// ---------------------------------------------------------------------------
// In-memory map: ws socket → session info { sessionId, lobbyCode, playerIndex }
// ---------------------------------------------------------------------------
const socketToSession = new Map();

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** Sends a JSON message to a single WebSocket client. */
function send(ws, msg) {
  if (ws.readyState === ws.OPEN) {
    ws.send(JSON.stringify(msg));
  }
}

/** Broadcasts a message to all clients in the same lobby except the sender. */
function broadcast(wss, senderWs, lobbyCode, msg) {
  wss.clients.forEach((client) => {
    if (client === senderWs) return;
    const session = socketToSession.get(client);
    if (session && session.lobbyCode === lobbyCode) {
      send(client, msg);
    }
  });
}

/** Broadcasts a message to ALL clients in a lobby including the sender. */
function broadcastAll(wss, lobbyCode, msg) {
  wss.clients.forEach((client) => {
    const session = socketToSession.get(client);
    if (session && session.lobbyCode === lobbyCode) {
      send(client, msg);
    }
  });
}

/** Generates a unique 6-character alphanumeric lobby code. */
function generateLobbyCode() {
  return crypto.randomBytes(3).toString('hex').toUpperCase();
}

// ---------------------------------------------------------------------------
// Handlers
// ---------------------------------------------------------------------------

function handleCreateLobby(wss, ws, msg, db) {
  const playerName = (msg.player_name || '').trim();
  if (!playerName) {
    send(ws, { type: 'error', error: 'invalid_player_name' });
    return;
  }

  // Generate a unique lobby code (retry on collision).
  let code;
  let attempts = 0;
  do {
    code = generateLobbyCode();
    attempts += 1;
    if (attempts > 10) {
      send(ws, { type: 'error', error: 'lobby_creation_failed' });
      return;
    }
  } while (db.prepare('SELECT 1 FROM lobbies WHERE code = ?').get(code));

  const sessionId = crypto.randomUUID();

  db.prepare("INSERT INTO lobbies (code, host_id, state) VALUES (?, ?, 'waiting')").run(
    code,
    sessionId,
  );
  db.prepare(
    'INSERT INTO sessions (session_id, lobby_code, player_index, player_name) VALUES (?, ?, 0, ?)',
  ).run(sessionId, code, playerName);

  socketToSession.set(ws, { sessionId, lobbyCode: code, playerIndex: 0 });

  send(ws, { type: 'lobby_created', lobby_code: code, player_index: 0 });
  console.log(`[relay] Lobby created: ${code} by ${playerName}`);
}

function handleJoinLobby(wss, ws, msg, db) {
  const lobbyCode = (msg.lobby_code || '').toUpperCase().trim();
  const playerName = (msg.player_name || '').trim();

  if (!lobbyCode || !playerName) {
    send(ws, { type: 'error', error: 'invalid_fields' });
    return;
  }

  const lobby = db.prepare("SELECT * FROM lobbies WHERE code = ? AND state = 'waiting'").get(lobbyCode);
  if (!lobby) {
    send(ws, { type: 'error', error: 'lobby_not_found' });
    return;
  }

  const existingCount = db
    .prepare('SELECT COUNT(*) AS cnt FROM sessions WHERE lobby_code = ? AND connected = 1')
    .get(lobbyCode).cnt;
  if (existingCount >= 2) {
    send(ws, { type: 'error', error: 'lobby_full' });
    return;
  }

  const sessionId = crypto.randomUUID();
  db.prepare(
    'INSERT INTO sessions (session_id, lobby_code, player_index, player_name) VALUES (?, ?, 1, ?)',
  ).run(sessionId, lobbyCode, playerName);

  socketToSession.set(ws, { sessionId, lobbyCode, playerIndex: 1 });

  // Mark lobby as active now that both players are in.
  db.prepare("UPDATE lobbies SET state = 'active' WHERE code = ?").run(lobbyCode);
  db.prepare('INSERT OR IGNORE INTO matches (lobby_code, game_state) VALUES (?, NULL)').run(
    lobbyCode,
  );

  send(ws, { type: 'lobby_joined', lobby_code: lobbyCode, player_index: 1 });

  // Notify host that the opponent joined.
  broadcast(wss, ws, lobbyCode, {
    type: 'player_joined',
    player_name: playerName,
    player_index: 1,
  });

  console.log(`[relay] ${playerName} joined lobby ${lobbyCode}`);
}

function handlePerformAction(wss, ws, msg, db) {
  const session = socketToSession.get(ws);
  if (!session) {
    send(ws, { type: 'error', error: 'not_in_lobby' });
    return;
  }

  const matchRow = db
    .prepare('SELECT game_state FROM matches WHERE lobby_code = ?')
    .get(session.lobbyCode);
  if (!matchRow) {
    send(ws, { type: 'error', error: 'match_not_found' });
    return;
  }

  // Broadcast action to the other player so they can apply it locally.
  broadcast(wss, ws, session.lobbyCode, {
    type: 'action_received',
    player_index: session.playerIndex,
    ship_id: msg.ship_id,
    action: msg.action,
    params: msg.params,
  });
}

function handleEndTurn(wss, ws, msg, db) {
  const session = socketToSession.get(ws);
  if (!session) {
    send(ws, { type: 'error', error: 'not_in_lobby' });
    return;
  }

  // Broadcast end-turn notification to the other player.
  broadcast(wss, ws, session.lobbyCode, {
    type: 'turn_ended',
    player_index: session.playerIndex,
  });

  // Persist updated game state if provided.
  if (msg.state) {
    db.prepare('UPDATE matches SET game_state = ? WHERE lobby_code = ?').run(
      JSON.stringify(msg.state),
      session.lobbyCode,
    );
  }
}

function handleGameStateUpdate(wss, ws, msg, db) {
  const session = socketToSession.get(ws);
  if (!session) {
    send(ws, { type: 'error', error: 'not_in_lobby' });
    return;
  }

  if (msg.state) {
    db.prepare('UPDATE matches SET game_state = ? WHERE lobby_code = ?').run(
      JSON.stringify(msg.state),
      session.lobbyCode,
    );
  }

  broadcastAll(wss, session.lobbyCode, { type: 'game_state_update', state: msg.state });
}

// ---------------------------------------------------------------------------
// Disconnect handler (called from index.js on ws 'close' event)
// ---------------------------------------------------------------------------

function handleDisconnect(wss, ws, db) {
  const session = socketToSession.get(ws);
  if (!session) return;

  db.prepare('UPDATE sessions SET connected = 0 WHERE session_id = ?').run(session.sessionId);

  broadcast(wss, ws, session.lobbyCode, {
    type: 'player_disconnected',
    player_index: session.playerIndex,
  });

  // Mark lobby as abandoned if no connected players remain.
  const remaining = db
    .prepare('SELECT COUNT(*) AS cnt FROM sessions WHERE lobby_code = ? AND connected = 1')
    .get(session.lobbyCode).cnt;
  if (remaining === 0) {
    db.prepare("UPDATE lobbies SET state = 'abandoned' WHERE code = ?").run(session.lobbyCode);
  }

  socketToSession.delete(ws);
  console.log(`[relay] Player ${session.playerIndex} disconnected from lobby ${session.lobbyCode}`);
}

// ---------------------------------------------------------------------------
// Main dispatcher
// ---------------------------------------------------------------------------

function handleMessage(wss, ws, msg, db) {
  switch (msg.type) {
    case 'create_lobby':
      handleCreateLobby(wss, ws, msg, db);
      break;
    case 'join_lobby':
      handleJoinLobby(wss, ws, msg, db);
      break;
    case 'perform_action':
      handlePerformAction(wss, ws, msg, db);
      break;
    case 'end_turn':
      handleEndTurn(wss, ws, msg, db);
      break;
    case 'game_state_update':
      handleGameStateUpdate(wss, ws, msg, db);
      break;
    default:
      send(ws, { type: 'error', error: 'unknown_message_type' });
  }
}

module.exports = { handleMessage, handleDisconnect, socketToSession, send, broadcastAll };
