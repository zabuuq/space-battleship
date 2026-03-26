extends "res://addons/gut/test.gd"

## Tests for fleet destruction detection and game-end state transitions.
## Issues: #51 Detect full fleet destruction, #52 Win and loss state handling,
##         #55 Add victory condition tests.

const GameState = preload("res://src/shared/GameState.gd")
const ServerGameLogic = preload("res://src/shared/ServerGameLogic.gd")

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


func _make_ship(id: int, health: int, is_destroyed: bool) -> Dictionary:
	return {
		"id": id,
		"type": "cruiser",
		"position": Vector2i(id * 5, 3),
		"facing": Vector2i(1, 0),
		"length": 3,
		"health": health,
		"is_destroyed": is_destroyed
	}


func _make_state_with_ships(ships: Array) -> GameState:
	var state := GameState.new()
	state.set_phase("combat")
	for ship in ships:
		state.add_ship(ship)
	return state


# ---------------------------------------------------------------------------
# #51 – Detect full fleet destruction
# ---------------------------------------------------------------------------


func test_fleet_not_destroyed_when_ships_remain():
	var state := _make_state_with_ships(
		[
			_make_ship(1, 3, false),
			_make_ship(2, 0, true),
		]
	)
	assert_false(state.is_fleet_destroyed(), "Fleet should not be destroyed while at least one ship survives")


func test_fleet_destroyed_when_all_ships_at_zero_health():
	var state := _make_state_with_ships(
		[
			_make_ship(1, 0, true),
			_make_ship(2, 0, true),
		]
	)
	assert_true(state.is_fleet_destroyed(), "Fleet should be destroyed when every ship has zero health")


func test_single_ship_fleet_destroyed_on_last_hit():
	var state := GameState.new()
	state.set_phase("combat")
	var ship := _make_ship(1, 1, false)
	state.add_ship(ship)
	# Simulate the final hit by applying damage directly.
	state.update_ship_health(1, 1)
	assert_true(state.is_fleet_destroyed(), "Single-ship fleet should be destroyed after its last hit")


func test_empty_fleet_is_not_considered_destroyed():
	var state := GameState.new()
	assert_false(state.is_fleet_destroyed(), "An empty fleet must not report as destroyed")


# ---------------------------------------------------------------------------
# #52 – Win and loss state handling
# ---------------------------------------------------------------------------


func test_game_phase_transitions_to_game_over():
	var logic := _make_logic_with_one_hit_ship()
	var result := logic.process_action(0, {"action": "missile", "ship_id": 1, "params": {"x": 10, "y": 5}})
	assert_eq(result["result"], ServerGameLogic.RESULT_GAME_OVER, "Phase should transition to game_over")
	assert_eq(logic.game_state.turn_phase, "game_over", "turn_phase must be game_over after fleet destruction")


func test_winner_recorded_correctly():
	var logic := _make_logic_with_one_hit_ship()
	logic.process_action(0, {"action": "missile", "ship_id": 1, "params": {"x": 10, "y": 5}})
	assert_eq(logic.game_state.winner, 0, "Winner should be the attacking player (index 0)")


func test_loser_recorded_correctly():
	var logic := _make_logic_with_one_hit_ship()
	logic.process_action(0, {"action": "missile", "ship_id": 1, "params": {"x": 10, "y": 5}})
	# With two players (0 and 1), the loser is 1 - winner.
	var loser := 1 - logic.game_state.winner
	assert_eq(loser, 1, "Loser should be the defending player (index 1)")


func test_no_actions_accepted_after_game_over():
	var logic := _make_logic_with_one_hit_ship()
	# Destroy the fleet → game_over.
	logic.process_action(0, {"action": "missile", "ship_id": 1, "params": {"x": 10, "y": 5}})
	assert_eq(logic.game_state.turn_phase, "game_over", "Precondition: phase is game_over")
	# Any further action must be rejected.
	var result := logic.process_action(0, {"action": "missile", "ship_id": 1, "params": {"x": 5, "y": 5}})
	assert_eq(result["result"], ServerGameLogic.RESULT_INVALID, "Actions after game_over must be rejected")


# ---------------------------------------------------------------------------
# #52 – Serialization round-trip includes winner
# ---------------------------------------------------------------------------


func test_winner_survives_serialization_round_trip():
	var state := GameState.new()
	state.set_game_over(1)
	var restored := GameState.new()
	restored.from_dict(state.to_dict())
	assert_eq(restored.winner, 1, "winner must survive to_dict / from_dict round-trip")
	assert_eq(restored.turn_phase, "game_over", "turn_phase must survive round-trip")


# ---------------------------------------------------------------------------
# Helper – builds a ServerGameLogic with one ship at health 1
# ---------------------------------------------------------------------------


func _make_logic_with_one_hit_ship() -> ServerGameLogic:
	var state := GameState.new()
	state.set_phase("combat")
	state.add_ship(
		{
			"id": 1,
			"type": "cruiser",
			"position": Vector2i(10, 5),
			"facing": Vector2i(1, 0),
			"length": 3,
			"health": 1,
			"is_destroyed": false
		}
	)
	var logic := ServerGameLogic.new()
	logic.start_match(state.to_dict())
	return logic
