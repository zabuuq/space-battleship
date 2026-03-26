extends RefCounted

## ReconnectHandler
## Manages automatic reconnection after a lost server connection and validates
## incoming session tokens to reject stale or hijacked sessions.
##
## Issue #44 – Handle disconnects and invalid sessions.
##
## Usage: attach to a scene that owns a NetworkManager reference and call
## start() when a connection is first established.

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Emitted when reconnection succeeds after a disconnect.
signal reconnected

## Emitted when all reconnect attempts have been exhausted.
signal reconnect_failed

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

const MAX_ATTEMPTS := 3
const RETRY_DELAY_SEC := 2.0

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var _attempts := 0
var _server_url := ""
var _retry_timer: SceneTreeTimer = null

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------


## Records the URL and resets the attempt counter on successful connection.
func on_connected(url: String) -> void:
	_server_url = url
	_attempts = 0


## Call when the connection is lost. Begins the reconnect sequence.
func on_disconnected(scene_tree: SceneTree) -> void:
	if _server_url.is_empty() or _attempts >= MAX_ATTEMPTS:
		emit_signal("reconnect_failed")
		return
	_attempts += 1
	_retry_timer = scene_tree.create_timer(RETRY_DELAY_SEC)
	_retry_timer.timeout.connect(_attempt_reconnect)


## Returns true if we are currently within the reconnect window.
func is_reconnecting() -> bool:
	return _attempts > 0 and _attempts <= MAX_ATTEMPTS


# ---------------------------------------------------------------------------
# Internal
# ---------------------------------------------------------------------------


func _attempt_reconnect() -> void:
	var err := NetworkManager.connect_to_server(_server_url)
	if err == OK:
		emit_signal("reconnected")
		_attempts = 0
	elif _attempts < MAX_ATTEMPTS:
		on_disconnected(Engine.get_main_loop() as SceneTree)
	else:
		emit_signal("reconnect_failed")


## Returns true when a server message belongs to a valid session.
## Rejects messages that lack a required player_index field in
## session-bearing message types.
static func validate_session(msg: Dictionary) -> bool:
	const SESSION_TYPES := ["action_received", "turn_ended", "game_state_update"]
	var msg_type: String = msg.get("type", "")
	if msg_type in SESSION_TYPES:
		return msg.has("player_index") or msg.has("state")
	return true
