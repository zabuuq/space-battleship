'use strict';

/**
 * Space Battleship – relay server entry point.
 * Issue #41 – WebSocket connection layer.
 *
 * Accepts WebSocket connections from Godot clients, parses JSON messages,
 * and dispatches them to registered handlers.  Room state, lobby flow,
 * action processing and disconnect handling are built on top of this layer
 * in subsequent issues.
 */

const { WebSocketServer } = require('ws');
const db = require('./db');
const { handleMessage } = require('./messageHandler');

const PORT = process.env.PORT ? parseInt(process.env.PORT, 10) : 9090;

const wss = new WebSocketServer({ port: PORT });

console.log(`[relay] WebSocket server listening on port ${PORT}`);

wss.on('connection', (ws) => {
  console.log('[relay] Client connected');

  ws.on('message', (raw) => {
    let msg;
    try {
      msg = JSON.parse(raw.toString());
    } catch {
      send(ws, { type: 'error', error: 'invalid_json' });
      return;
    }

    if (typeof msg !== 'object' || msg === null || typeof msg.type !== 'string') {
      send(ws, { type: 'error', error: 'missing_type' });
      return;
    }

    handleMessage(wss, ws, msg, db);
  });

  ws.on('close', () => {
    console.log('[relay] Client disconnected');
    const { handleDisconnect } = require('./messageHandler');
    handleDisconnect(wss, ws, db);
  });

  ws.on('error', (err) => {
    console.error('[relay] WebSocket error:', err.message);
  });
});

/** Safely serialises and sends a message to a single client. */
function send(ws, msg) {
  if (ws.readyState === ws.OPEN) {
    ws.send(JSON.stringify(msg));
  }
}

module.exports = { wss, send };
