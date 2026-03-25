extends "res://addons/gut/test.gd"

## Tests for MissileRules — hit/miss resolution, damage, and ship destruction.
## Issue #30 – Implement hit and miss resolution.
## Issue #31 – Track ship damage state.
## Issue #33 – Implement ship destruction logic.
## Issue #34 – Add missile combat tests.

const GameState = preload("res://src/shared/GameState.gd")
const ShipDefs = preload("res://src/shared/ShipDefs.gd")
const MissileRules = preload("res://src/shared/MissileRules.gd")

var _state: RefCounted
var _defs: RefCounted


func before_each() -> void:
	_state = GameState.new()
	_defs = ShipDefs.new()


# ---------------------------------------------------------------------------
# Hit and miss resolution (#30)
# ---------------------------------------------------------------------------


func test_missile_hits_occupied_cell():
	var ship = _defs.create_ship_dict(0, ShipDefs.TYPE_CRUISER, Vector2i(5, 5), Vector2i(1, 0))
	_state.add_ship(ship)
	var result := MissileRules.fire_missile(_state, 0, Vector2i(5, 5))
	assert_eq(result, MissileRules.RESULT_HIT)


func test_missile_misses_empty_cell():
	var result := MissileRules.fire_missile(_state, 0, Vector2i(5, 5))
	assert_eq(result, MissileRules.RESULT_MISS)


func test_missile_marks_cell_as_hit():
	var ship = _defs.create_ship_dict(0, ShipDefs.TYPE_CRUISER, Vector2i(5, 5), Vector2i(1, 0))
	_state.add_ship(ship)
	MissileRules.fire_missile(_state, 0, Vector2i(5, 5))
	assert_eq(_state.grid.get_cell_data(Vector2i(5, 5))["state"], "hit")


func test_missile_marks_cell_as_miss():
	MissileRules.fire_missile(_state, 0, Vector2i(5, 5))
	assert_eq(_state.grid.get_cell_data(Vector2i(5, 5))["state"], "miss")


func test_out_of_bounds_target_is_rejected():
	var result := MissileRules.fire_missile(_state, 0, Vector2i(-1, 0))
	assert_eq(result, MissileRules.RESULT_INVALID)


func test_missile_recorded_in_history():
	MissileRules.fire_missile(_state, 0, Vector2i(5, 5))
	assert_eq(_state.missile_history.size(), 1)
	assert_eq(_state.missile_history[0]["position"], Vector2i(5, 5))


# ---------------------------------------------------------------------------
# Ship damage state (#31)
# ---------------------------------------------------------------------------


func test_missile_deals_one_damage_to_ship():
	var ship = _defs.create_ship_dict(0, ShipDefs.TYPE_CRUISER, Vector2i(5, 5), Vector2i(1, 0))
	_state.add_ship(ship)
	MissileRules.fire_missile(_state, 0, Vector2i(5, 5))
	assert_eq(_state.ships[0]["health"], 2)


func test_missile_does_not_destroy_ship_with_remaining_health():
	var ship = _defs.create_ship_dict(0, ShipDefs.TYPE_CRUISER, Vector2i(5, 5), Vector2i(1, 0))
	_state.add_ship(ship)
	MissileRules.fire_missile(_state, 0, Vector2i(5, 5))
	assert_false(_state.ships[0]["is_destroyed"])


# ---------------------------------------------------------------------------
# Ship destruction logic (#33)
# ---------------------------------------------------------------------------


func test_missile_destroys_ship_when_health_reaches_zero():
	var ship = _defs.create_ship_dict(0, ShipDefs.TYPE_CRUISER, Vector2i(5, 5), Vector2i(1, 0))
	_state.add_ship(ship)
	MissileRules.fire_missile(_state, 0, Vector2i(5, 5))
	MissileRules.fire_missile(_state, 0, Vector2i(6, 5))
	MissileRules.fire_missile(_state, 0, Vector2i(7, 5))
	assert_true(_state.ships[0]["is_destroyed"])


func test_missile_health_never_drops_below_zero():
	var ship = _defs.create_ship_dict(0, ShipDefs.TYPE_CRUISER, Vector2i(5, 5), Vector2i(1, 0))
	_state.add_ship(ship)
	for x in range(5):
		MissileRules.fire_missile(_state, 0, Vector2i(5 + x, 5))
	assert_eq(_state.ships[0]["health"], 0)
