extends "res://addons/gut/test.gd"

## Tests for multiplayer networking message schemas and turn synchronisation.
## Issue #45 – Add multiplayer networking tests.

const NetworkMessage = preload("res://src/shared/NetworkMessage.gd")
const GameState = preload("res://src/shared/GameState.gd")

# ---------------------------------------------------------------------------
# Message schema tests
# ---------------------------------------------------------------------------


func test_create_lobby_message_schema():
	var msg := NetworkMessage.build_create_lobby("Alice")
	assert_true(NetworkMessage.validate(msg), "create_lobby message should be valid")
	assert_eq(msg["type"], NetworkMessage.MSG_CREATE_LOBBY)
	assert_true(msg.has("player_name"), "player_name field must be present")


func test_join_lobby_message_schema():
	var msg := NetworkMessage.build_join_lobby("ABCD12", "Bob")
	assert_true(NetworkMessage.validate(msg), "join_lobby message should be valid")
	assert_eq(msg["type"], NetworkMessage.MSG_JOIN_LOBBY)
	assert_true(msg.has("lobby_code"), "lobby_code field must be present")
	assert_true(msg.has("player_name"), "player_name field must be present")


func test_place_ship_message_schema():
	var pos := {"x": 0, "y": 0}
	var facing := {"x": 1, "y": 0}
	var msg := NetworkMessage.build_place_ship(3, pos, facing)
	assert_true(NetworkMessage.validate(msg), "place_ship message should be valid")
	assert_eq(msg["type"], NetworkMessage.MSG_PLACE_SHIP)
	assert_true(msg.has("ship_id"), "ship_id field must be present")
	assert_true(msg.has("position"), "position field must be present")
	assert_true(msg.has("facing"), "facing field must be present")


func test_perform_action_message_schema():
	var params := {"steps": 1}
	var msg := NetworkMessage.build_perform_action(1, "move_forward", params)
	assert_true(NetworkMessage.validate(msg), "perform_action message should be valid")
	assert_eq(msg["type"], NetworkMessage.MSG_PERFORM_ACTION)
	assert_true(msg.has("ship_id"), "ship_id field must be present")
	assert_true(msg.has("action"), "action field must be present")
	assert_true(msg.has("params"), "params field must be present")


func test_end_turn_message_schema():
	var msg := NetworkMessage.build_end_turn()
	assert_true(NetworkMessage.validate(msg), "end_turn message should be valid")
	assert_eq(msg["type"], NetworkMessage.MSG_END_TURN)


func test_game_state_update_message_schema():
	var state := {"current_turn": 1, "turn_phase": "combat"}
	var msg := NetworkMessage.build_game_state_update(state)
	assert_true(NetworkMessage.validate(msg), "game_state_update message should be valid")
	assert_eq(msg["type"], NetworkMessage.MSG_GAME_STATE_UPDATE)
	assert_true(msg.has("state"), "state field must be present")


func test_invalid_message_type_is_rejected():
	var bad_msg := {"type": "nuke_everything"}
	assert_false(NetworkMessage.validate(bad_msg), "Unknown message type must be rejected")


func test_turn_sync_after_end_turn():
	# Simulate two client states starting in sync, then advancing via a
	# serialised game_state_update message (as the server would broadcast).
	var state_p0 := GameState.new()
	state_p0.set_phase("combat")
	state_p0.next_turn()  # advance to turn 1

	var broadcast := NetworkMessage.build_game_state_update(state_p0.to_dict())
	assert_true(NetworkMessage.validate(broadcast), "Broadcast message should be valid")

	var state_p1 := GameState.new()
	state_p1.from_dict(broadcast["state"])

	assert_eq(state_p1.current_turn, 1, "After applying broadcast, client turn counter should be 1")
	assert_eq(state_p1.turn_phase, "combat", "After applying broadcast, phase should be combat")
