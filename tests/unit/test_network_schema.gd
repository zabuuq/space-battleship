extends "res://addons/gut/test.gd"

## Tests for NetworkMessage schema validation and message builders.
## Issue #67 – Create network message schema.

const NetworkMessage = preload("res://src/shared/NetworkMessage.gd")


func test_create_lobby_has_required_fields():
	var msg = NetworkMessage.build_create_lobby("Alice")
	assert_true(NetworkMessage.validate(msg), "create_lobby message should be valid")
	assert_eq(msg["type"], NetworkMessage.MSG_CREATE_LOBBY, "type field should match")
	assert_eq(msg["player_name"], "Alice", "player_name should be set")


func test_join_lobby_has_required_fields():
	var msg = NetworkMessage.build_join_lobby("ABC123", "Bob")
	assert_true(NetworkMessage.validate(msg), "join_lobby message should be valid")
	assert_eq(msg["type"], NetworkMessage.MSG_JOIN_LOBBY, "type field should match")
	assert_eq(msg["lobby_code"], "ABC123", "lobby_code should be set")
	assert_eq(msg["player_name"], "Bob", "player_name should be set")


func test_place_ship_has_required_fields():
	var pos = {"x": 5, "y": 3}
	var facing = {"x": 1, "y": 0}
	var msg = NetworkMessage.build_place_ship(1, pos, facing)
	assert_true(NetworkMessage.validate(msg), "place_ship message should be valid")
	assert_eq(msg["type"], NetworkMessage.MSG_PLACE_SHIP, "type field should match")
	assert_eq(msg["ship_id"], 1, "ship_id should be set")
	assert_eq(msg["position"], pos, "position should be set")
	assert_eq(msg["facing"], facing, "facing should be set")


func test_perform_action_has_required_fields():
	var params = {"target": {"x": 10, "y": 5}}
	var msg = NetworkMessage.build_perform_action(2, "missile", params)
	assert_true(NetworkMessage.validate(msg), "perform_action message should be valid")
	assert_eq(msg["type"], NetworkMessage.MSG_PERFORM_ACTION, "type field should match")
	assert_eq(msg["ship_id"], 2, "ship_id should be set")
	assert_eq(msg["action"], "missile", "action should be set")
	assert_eq(msg["params"], params, "params should be set")


func test_end_turn_has_required_fields():
	var msg = NetworkMessage.build_end_turn()
	assert_true(NetworkMessage.validate(msg), "end_turn message should be valid")
	assert_eq(msg["type"], NetworkMessage.MSG_END_TURN, "type field should match")


func test_game_state_update_has_required_fields():
	var state = {"current_turn": 0, "turn_phase": "combat", "ships": []}
	var msg = NetworkMessage.build_game_state_update(state)
	assert_true(NetworkMessage.validate(msg), "game_state_update message should be valid")
	assert_eq(msg["type"], NetworkMessage.MSG_GAME_STATE_UPDATE, "type field should match")
	assert_eq(msg["state"], state, "state should be set")


func test_message_missing_type_field_is_invalid():
	var msg = {"player_name": "Alice"}
	assert_false(NetworkMessage.validate(msg), "Message without type field should be invalid")


func test_unknown_message_type_is_invalid():
	var msg = {"type": "launch_rocket", "target": "moon"}
	assert_false(NetworkMessage.validate(msg), "Unknown message type should be invalid")
