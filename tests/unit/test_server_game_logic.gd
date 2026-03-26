extends "res://addons/gut/test.gd"

## Tests for ServerGameLogic authoritative action processing.
## Issue #69 – Implement authoritative server game logic.

const ServerGameLogic = preload("res://src/shared/ServerGameLogic.gd")
const GameState = preload("res://src/shared/GameState.gd")

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


func _make_combat_state() -> GameState:
	var state := GameState.new()
	state.set_phase("combat")
	var ship := {
		"id": 1,
		"type": "cruiser",
		"position": Vector2i(10, 5),
		"facing": Vector2i(1, 0),
		"length": 3,
		"health": 1,
		"is_destroyed": false
	}
	state.add_ship(ship)
	return state


func _make_logic_in_combat() -> ServerGameLogic:
	var state := _make_combat_state()
	var logic := ServerGameLogic.new()
	logic.start_match(state.to_dict())
	return logic


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------


func test_valid_action_is_applied_and_broadcast():
	var logic := _make_logic_in_combat()
	var result := logic.process_action(0, {"action": "missile", "ship_id": 1, "params": {"x": 50, "y": 3}})
	assert_eq(result["result"], ServerGameLogic.RESULT_OK, "Valid missile action should succeed")
	assert_true(result.has("state"), "Result should include updated state")


func test_invalid_action_is_rejected_with_error():
	var logic := _make_logic_in_combat()
	# Target out of bounds
	var result := logic.process_action(0, {"action": "missile", "ship_id": 1, "params": {"x": 9999, "y": 9999}})
	assert_eq(result["result"], ServerGameLogic.RESULT_INVALID, "Out-of-bounds target should be rejected")
	assert_true(result.has("error"), "Result should include error field")
	assert_false(result.has("state"), "State should not be included in error result")


func test_out_of_turn_action_is_rejected():
	var logic := _make_logic_in_combat()
	# Player 1 acts when it is player 0's turn (current_turn = 0)
	var result := logic.process_action(1, {"action": "missile", "ship_id": 1, "params": {"x": 5, "y": 5}})
	assert_eq(result["result"], ServerGameLogic.RESULT_INVALID, "Out-of-turn action should be rejected")
	assert_eq(result["error"], "wrong_turn", "Error code should indicate wrong turn")


func test_action_applied_to_correct_player_state():
	var logic := _make_logic_in_combat()
	# Move the ship forward and verify position changed
	var initial_pos: Vector2i = logic.game_state.ships[0]["position"]
	var result := logic.process_action(0, {"action": "move_forward", "ship_id": 1, "params": {"steps": 1}})
	assert_eq(result["result"], ServerGameLogic.RESULT_OK, "Move should succeed")
	var new_pos: Vector2i = logic.game_state.ships[0]["position"]
	assert_ne(new_pos, initial_pos, "Ship position should have changed")


func test_broadcast_includes_updated_game_state():
	var logic := _make_logic_in_combat()
	var result := logic.process_action(0, {"action": "missile", "ship_id": 1, "params": {"x": 5, "y": 5}})
	assert_eq(result["result"], ServerGameLogic.RESULT_OK, "Action should succeed")
	var state_dict: Dictionary = result.get("state", {})
	assert_false(state_dict.is_empty(), "Broadcast result must contain non-empty state")
	assert_true(state_dict.has("current_turn"), "State must include current_turn")


func test_fleet_destruction_triggers_game_over_broadcast():
	var logic := _make_logic_in_combat()
	# Ship has health=1; one missile hit destroys it → fleet destroyed → game over
	var result := logic.process_action(0, {"action": "missile", "ship_id": 1, "params": {"x": 10, "y": 5}})
	assert_eq(result["result"], ServerGameLogic.RESULT_GAME_OVER, "Destroying last ship should trigger game-over")
	assert_true(result.get("game_over", false), "game_over flag should be true")
	assert_eq(result.get("winner", -1), 0, "Winner should be player 0")
