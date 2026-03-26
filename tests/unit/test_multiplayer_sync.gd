extends "res://addons/gut/test.gd"

## Tests verifying both client states stay in sync after each action.
## Issue #71 – Add multiplayer sync consistency tests.

const GameState = preload("res://src/shared/GameState.gd")
const ServerGameLogic = preload("res://src/shared/ServerGameLogic.gd")
const MissileRules = preload("res://src/shared/MissileRules.gd")
const MovementRules = preload("res://src/shared/MovementRules.gd")
const ProbeRules = preload("res://src/shared/ProbeRules.gd")
const TurnManager = preload("res://src/shared/TurnManager.gd")

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


func _make_combat_state_with_ship(ship_id: int, pos: Vector2i) -> GameState:
	var state := GameState.new()
	state.set_phase("combat")
	state.add_ship(
		{
			"id": ship_id,
			"type": "cruiser",
			"position": pos,
			"facing": Vector2i(1, 0),
			"length": 3,
			"health": 3,
			"is_destroyed": false
		}
	)
	return state


## Returns a deep copy of a GameState by serialising and deserialising.
func _clone_state(src: GameState) -> GameState:
	var dst := GameState.new()
	dst.from_dict(src.to_dict())
	return dst


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------


func test_game_state_matches_after_missile_action():
	# Server fires a missile; both clients apply the state update.
	var logic := ServerGameLogic.new()
	logic.start_match(_make_combat_state_with_ship(1, Vector2i(30, 5)).to_dict())

	var result := logic.process_action(0, {"action": "missile", "ship_id": 1, "params": {"x": 5, "y": 5}})
	assert_eq(result["result"], ServerGameLogic.RESULT_OK, "Missile action should succeed")

	var client_a := GameState.new()
	client_a.from_dict(result["state"])

	var client_b := GameState.new()
	client_b.from_dict(result["state"])

	assert_eq(
		client_a.to_dict(),
		client_b.to_dict(),
		"Both clients must have identical state after applying the same broadcast"
	)


func test_game_state_matches_after_move_action():
	var logic := ServerGameLogic.new()
	logic.start_match(_make_combat_state_with_ship(1, Vector2i(10, 5)).to_dict())

	var result := logic.process_action(0, {"action": "move_forward", "ship_id": 1, "params": {"steps": 1}})
	assert_eq(result["result"], ServerGameLogic.RESULT_OK, "Move action should succeed")

	var client_a := GameState.new()
	client_a.from_dict(result["state"])

	var client_b := GameState.new()
	client_b.from_dict(result["state"])

	assert_eq(
		client_a.ships[0]["position"],
		client_b.ships[0]["position"],
		"Both clients must agree on ship position after move"
	)


func test_game_state_matches_after_probe_action():
	var logic := ServerGameLogic.new()
	logic.start_match(_make_combat_state_with_ship(1, Vector2i(20, 5)).to_dict())

	var result := logic.process_action(0, {"action": "probe", "ship_id": 1, "params": {"x": 20, "y": 5}})
	assert_eq(result["result"], ServerGameLogic.RESULT_OK, "Probe action should succeed")

	var client_a := GameState.new()
	client_a.from_dict(result["state"])

	var client_b := GameState.new()
	client_b.from_dict(result["state"])

	assert_eq(
		client_a.probe_history.size(),
		client_b.probe_history.size(),
		"Both clients must have the same probe history size"
	)


func test_turn_counter_matches_across_clients():
	var logic := ServerGameLogic.new()
	logic.start_match(_make_combat_state_with_ship(1, Vector2i(40, 5)).to_dict())

	var end_turn_result := logic.process_end_turn()
	assert_eq(end_turn_result["result"], ServerGameLogic.RESULT_OK, "End turn should succeed")

	var client_a := GameState.new()
	client_a.from_dict(end_turn_result["state"])

	var client_b := GameState.new()
	client_b.from_dict(end_turn_result["state"])

	assert_eq(client_a.current_turn, client_b.current_turn, "Turn counters must match on both clients")
	assert_eq(client_a.current_turn, 1, "Turn should advance to 1 after end_turn")


func test_diverged_state_is_detected():
	# Simulate two client states diverging: client_b applies an extra action
	# that was not broadcast. Verifies that to_dict() comparison catches it.
	var authoritative := _make_combat_state_with_ship(1, Vector2i(50, 5))
	authoritative.set_phase("combat")

	var client_a := _clone_state(authoritative)

	var client_b := _clone_state(authoritative)
	var turn_mgr := TurnManager.new()
	turn_mgr.begin_turn(client_b)
	turn_mgr.record_action(client_b, 0, 1)
	MissileRules.fire_missile(client_b, 0, Vector2i(50, 5))

	assert_ne(client_a.to_dict(), client_b.to_dict(), "Diverged client state must differ from authoritative state")
