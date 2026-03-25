extends RefCounted

## NetworkMessage
## Defines and validates the JSON message schema used between client and server.
## All messages must include a "type" field matching one of the MSG_* constants.
## Issue #67 – Create network message schema.

# ---------------------------------------------------------------------------
# Message type constants
# ---------------------------------------------------------------------------

const MSG_CREATE_LOBBY := "create_lobby"
const MSG_JOIN_LOBBY := "join_lobby"
const MSG_PLACE_SHIP := "place_ship"
const MSG_PERFORM_ACTION := "perform_action"
const MSG_END_TURN := "end_turn"
const MSG_GAME_STATE_UPDATE := "game_state_update"
const MSG_ERROR := "error"
const MSG_LOBBY_CREATED := "lobby_created"
const MSG_LOBBY_JOINED := "lobby_joined"
const MSG_PLAYER_DISCONNECTED := "player_disconnected"

# ---------------------------------------------------------------------------
# Required fields per message type
# ---------------------------------------------------------------------------

const _REQUIRED_FIELDS := {
	MSG_CREATE_LOBBY: ["type", "player_name"],
	MSG_JOIN_LOBBY: ["type", "lobby_code", "player_name"],
	MSG_PLACE_SHIP: ["type", "ship_id", "position", "facing"],
	MSG_PERFORM_ACTION: ["type", "ship_id", "action", "params"],
	MSG_END_TURN: ["type"],
	MSG_GAME_STATE_UPDATE: ["type", "state"],
}

# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------


## Returns true if msg contains a valid "type" and all required fields.
static func validate(msg: Dictionary) -> bool:
	if not msg.has("type"):
		return false
	var msg_type: String = msg["type"]
	if not _REQUIRED_FIELDS.has(msg_type):
		return false
	for field: String in _REQUIRED_FIELDS[msg_type]:
		if not msg.has(field):
			return false
	return true


# ---------------------------------------------------------------------------
# Message builders
# ---------------------------------------------------------------------------


## Builds a create_lobby message.
static func build_create_lobby(player_name: String) -> Dictionary:
	return {"type": MSG_CREATE_LOBBY, "player_name": player_name}


## Builds a join_lobby message.
static func build_join_lobby(lobby_code: String, player_name: String) -> Dictionary:
	return {"type": MSG_JOIN_LOBBY, "lobby_code": lobby_code, "player_name": player_name}


## Builds a place_ship message. position and facing are {"x": int, "y": int} dicts.
static func build_place_ship(ship_id: int, position: Dictionary, facing: Dictionary) -> Dictionary:
	return {"type": MSG_PLACE_SHIP, "ship_id": ship_id, "position": position, "facing": facing}


## Builds a perform_action message. params is an action-specific dictionary.
static func build_perform_action(ship_id: int, action: String, params: Dictionary) -> Dictionary:
	return {"type": MSG_PERFORM_ACTION, "ship_id": ship_id, "action": action, "params": params}


## Builds an end_turn message.
static func build_end_turn() -> Dictionary:
	return {"type": MSG_END_TURN}


## Builds a game_state_update message wrapping a serialized state dictionary.
static func build_game_state_update(state: Dictionary) -> Dictionary:
	return {"type": MSG_GAME_STATE_UPDATE, "state": state}
