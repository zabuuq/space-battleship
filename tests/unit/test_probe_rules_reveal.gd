extends "res://addons/gut/test.gd"

## Tests for ProbeRules — ship-presence reveal and Support double-probe.
## Issue #24 – Reveal ship presence from probe results.
## Issue #26 – Implement Support double-probe ability.
## Issue #28 – Add probe system tests.

const GameState = preload("res://src/shared/GameState.gd")
const ShipDefs = preload("res://src/shared/ShipDefs.gd")
const ProbeRules = preload("res://src/shared/ProbeRules.gd")

var _state: RefCounted
var _defs: RefCounted


func before_each() -> void:
	_state = GameState.new()
	_defs = ShipDefs.new()


# ---------------------------------------------------------------------------
# Ship-presence reveal (#24)
# ---------------------------------------------------------------------------


func test_fire_probe_reveals_occupied_cells():
	var ship = _defs.create_ship_dict(0, ShipDefs.TYPE_CRUISER, Vector2i(5, 5), Vector2i(1, 0))
	_state.add_ship(ship)
	ProbeRules.fire_probe(_state, 0, Vector2i(5, 5))
	assert_eq(_state.grid.get_cell_data(Vector2i(5, 5))["state"], "revealed")


func test_fire_probe_does_not_reveal_empty_cells():
	ProbeRules.fire_probe(_state, 0, Vector2i(5, 5))
	assert_eq(_state.grid.get_cell_data(Vector2i(5, 5))["state"], "hidden")


func test_fire_probe_returns_detected_positions():
	var ship = _defs.create_ship_dict(0, ShipDefs.TYPE_CRUISER, Vector2i(5, 5), Vector2i(1, 0))
	_state.add_ship(ship)
	var detected := ProbeRules.fire_probe(_state, 0, Vector2i(5, 5))
	assert_true(detected.has(Vector2i(5, 5)), "Occupied cell must be in detected list")


func test_fire_probe_recorded_in_history():
	ProbeRules.fire_probe(_state, 0, Vector2i(10, 6))
	assert_eq(_state.probe_history.size(), 1, "Probe must be recorded in history")
	assert_eq(_state.probe_history[0]["position"], Vector2i(10, 6))


func test_fire_probe_does_not_reveal_cells_outside_3x3():
	var ship = _defs.create_ship_dict(0, ShipDefs.TYPE_CRUISER, Vector2i(10, 5), Vector2i(1, 0))
	_state.add_ship(ship)
	ProbeRules.fire_probe(_state, 0, Vector2i(5, 5))
	assert_eq(_state.grid.get_cell_data(Vector2i(10, 5))["state"], "hidden")


# ---------------------------------------------------------------------------
# Support double-probe (#26)
# ---------------------------------------------------------------------------


func test_support_probe_count_is_two():
	assert_eq(ProbeRules.probe_count_for(ShipDefs.TYPE_SUPPORT), 2)


func test_battleship_probe_count_is_one():
	assert_eq(ProbeRules.probe_count_for(ShipDefs.TYPE_BATTLESHIP), 1)


func test_cruiser_probe_count_is_one():
	assert_eq(ProbeRules.probe_count_for(ShipDefs.TYPE_CRUISER), 1)


func test_destroyer_probe_count_is_one():
	assert_eq(ProbeRules.probe_count_for(ShipDefs.TYPE_DESTROYER), 1)


func test_stealth_probe_count_is_one():
	assert_eq(ProbeRules.probe_count_for(ShipDefs.TYPE_STEALTH), 1)
