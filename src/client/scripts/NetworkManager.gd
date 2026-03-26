extends Node

## NetworkManager – WebSocket client singleton.
## Connects to the relay server, serialises outgoing messages as JSON, and
## emits signals when messages arrive from the server.
##
## Issues: #41 WebSocket connection layer, #43 Turn action sync,
##         #44 Disconnect handling.
##
## Register as autoload "NetworkManager" in project.godot.

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Emitted once the WebSocket handshake completes.
signal connected_to_server

## Emitted when the connection to the server is lost.
signal disconnected_from_server

## Emitted for every valid message received from the server.
signal message_received(msg: Dictionary)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

const DEFAULT_URL := "ws://localhost:9090"

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var _peer: WebSocketPeer = WebSocketPeer.new()
var _connected := false
var _url := DEFAULT_URL

# ---------------------------------------------------------------------------
# Connection management
# ---------------------------------------------------------------------------


## Initiates a WebSocket connection to the relay server.
func connect_to_server(url: String = DEFAULT_URL) -> Error:
	_url = url
	var err := _peer.connect_to_url(url)
	if err != OK:
		push_error("[NetworkManager] Failed to initiate connection: %s" % error_string(err))
	return err


## Closes the WebSocket connection gracefully.
func disconnect_from_server() -> void:
	_peer.close()
	_connected = false


# ---------------------------------------------------------------------------
# Send helpers
# ---------------------------------------------------------------------------


## Sends a raw dictionary as JSON. Returns OK or an error code.
func send_message(msg: Dictionary) -> Error:
	if not _connected:
		push_warning("[NetworkManager] send_message called while not connected")
		return ERR_UNAVAILABLE
	var json := JSON.stringify(msg)
	return _peer.send_text(json)


func send_create_lobby(player_name: String) -> Error:
	return send_message({"type": "create_lobby", "player_name": player_name})


func send_join_lobby(lobby_code: String, player_name: String) -> Error:
	return send_message({"type": "join_lobby", "lobby_code": lobby_code, "player_name": player_name})


func send_perform_action(ship_id: int, action: String, params: Dictionary) -> Error:
	return send_message({"type": "perform_action", "ship_id": ship_id, "action": action, "params": params})


func send_end_turn(state: Dictionary = {}) -> Error:
	var msg := {"type": "end_turn"}
	if not state.is_empty():
		msg["state"] = state
	return send_message(msg)


func send_game_state_update(state: Dictionary) -> Error:
	return send_message({"type": "game_state_update", "state": state})


# ---------------------------------------------------------------------------
# Poll loop – must be called every frame
# ---------------------------------------------------------------------------


func _process(_delta: float) -> void:
	_peer.poll()
	var state := _peer.get_ready_state()
	match state:
		WebSocketPeer.STATE_OPEN:
			if not _connected:
				_connected = true
				emit_signal("connected_to_server")
			_drain_packets()
		WebSocketPeer.STATE_CLOSING:
			pass
		WebSocketPeer.STATE_CLOSED:
			if _connected:
				_connected = false
				emit_signal("disconnected_from_server")


func _drain_packets() -> void:
	while _peer.get_available_packet_count() > 0:
		var raw := _peer.get_packet()
		var text := raw.get_string_from_utf8()
		var parsed := JSON.parse_string(text)
		if parsed is Dictionary:
			emit_signal("message_received", parsed)
		else:
			push_warning("[NetworkManager] Received non-dict payload: %s" % text)
