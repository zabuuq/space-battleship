extends "res://addons/gut/test.gd"

## Tests for TurnManager — turn sequencing, per-ship action budgets, end-turn flow.
## Issue #35 – Implement turn manager.
## Issue #36 – Track per-ship actions each turn.
## Issue #37 – Prevent illegal extra actions.
## Issue #38 – Implement end-turn flow.
## Issue #39 – Add turn system tests.

const GameState = preload("res://src/shared/GameState.gd")
const ShipDefs = preload("res://src/shared/ShipDefs.gd")
const TurnManager = preload("res://src/shared/TurnManager.gd")

var _state: RefCounted
var _defs: RefCounted
var _tm: RefCounted


func before_each() -> void:
	_state = GameState.new()
	_state.set_phase("combat")
	_defs = ShipDefs.new()
	_tm = TurnManager.new()
	_tm.begin_turn(_state)


# ---------------------------------------------------------------------------
# Turn sequencing (#35)
# ---------------------------------------------------------------------------


func test_initial_turn_is_player_zero():
	assert_eq(_state.current_turn, 0)


func test_begin_turn_clears_action_budgets():
	var ship = _defs.create_ship_dict(0, ShipDefs.TYPE_CRUISER, Vector2i(0, 0), Vector2i(1, 0))
	_state.add_ship(ship)
	_tm.record_action(_state, 0, 0)
	_tm.begin_turn(_state)
	assert_true(_tm.can_ship_act(0))


# ---------------------------------------------------------------------------
# Per-ship action tracking (#36)
# ---------------------------------------------------------------------------


func test_ship_can_act_before_using_action():
	assert_true(_tm.can_ship_act(1))


func test_ship_cannot_act_after_using_action():
	var ship = _defs.create_ship_dict(1, ShipDefs.TYPE_CRUISER, Vector2i(0, 0), Vector2i(1, 0))
	_state.add_ship(ship)
	_tm.record_action(_state, 0, 1)
	assert_false(_tm.can_ship_act(1))


func test_record_action_returns_ok_on_first_use():
	var ship = _defs.create_ship_dict(2, ShipDefs.TYPE_CRUISER, Vector2i(0, 0), Vector2i(1, 0))
	_state.add_ship(ship)
	var result: String = _tm.record_action(_state, 0, 2)
	assert_eq(result, TurnManager.RESULT_OK)


# ---------------------------------------------------------------------------
# Prevent illegal extra actions (#37)
# ---------------------------------------------------------------------------


func test_second_action_by_same_ship_is_rejected():
	var ship = _defs.create_ship_dict(3, ShipDefs.TYPE_CRUISER, Vector2i(0, 0), Vector2i(1, 0))
	_state.add_ship(ship)
	_tm.record_action(_state, 0, 3)
	var result: String = _tm.record_action(_state, 0, 3)
	assert_eq(result, TurnManager.RESULT_ALREADY_ACTED)


func test_action_on_wrong_turn_is_rejected():
	var result: String = _tm.record_action(_state, 1, 0)
	assert_eq(result, TurnManager.RESULT_WRONG_TURN)


func test_action_in_game_over_phase_is_rejected():
	_state.set_phase("game_over")
	var result: String = _tm.record_action(_state, 0, 0)
	assert_eq(result, TurnManager.RESULT_GAME_OVER)


func test_action_in_placement_phase_is_rejected():
	_state.set_phase("placement")
	var result: String = _tm.record_action(_state, 0, 0)
	assert_eq(result, TurnManager.RESULT_NOT_COMBAT)


# ---------------------------------------------------------------------------
# End-turn flow (#38)
# ---------------------------------------------------------------------------


func test_end_turn_advances_to_next_player():
	_tm.end_turn(_state)
	assert_eq(_state.current_turn, 1)


func test_end_turn_resets_action_budgets():
	var ship = _defs.create_ship_dict(4, ShipDefs.TYPE_CRUISER, Vector2i(0, 0), Vector2i(1, 0))
	_state.add_ship(ship)
	_tm.record_action(_state, 0, 4)
	_tm.end_turn(_state)
	assert_true(_tm.can_ship_act(4))


func test_end_turn_ticks_stealth_probe_mask():
	var stealth = _defs.create_ship_dict(5, ShipDefs.TYPE_STEALTH, Vector2i(0, 0), Vector2i(1, 0))
	stealth["probe_mask_active"] = true
	_state.add_ship(stealth)
	_tm.end_turn(_state)
	assert_false(_state.ships[0].get("probe_mask_active", false))


func test_end_turn_applies_cooldown_after_mask_expires():
	var stealth = _defs.create_ship_dict(6, ShipDefs.TYPE_STEALTH, Vector2i(0, 0), Vector2i(1, 0))
	stealth["probe_mask_active"] = true
	_state.add_ship(stealth)
	_tm.end_turn(_state)
	assert_eq(_state.ships[0].get("probe_mask_cooldown", 0), 1)


func test_double_end_turn_returns_to_player_zero():
	_tm.end_turn(_state)
	_tm.end_turn(_state)
	assert_eq(_state.current_turn, 0)
