extends "res://addons/gut/test.gd"

## Tests for MovementRules — collision prevention, Destroyer double-move,
## turning cost rules, and invalid-ID safety.
## Issue #22 – Add movement and collision tests (part 2 of 2).

const GameState = preload("res://src/shared/GameState.gd")
const ShipDefs = preload("res://src/shared/ShipDefs.gd")
const MovementRules = preload("res://src/shared/MovementRules.gd")

var _state: RefCounted
var _defs: RefCounted


func before_each() -> void:
	_state = GameState.new()
	_defs = ShipDefs.new()


# ---------------------------------------------------------------------------
# Collision prevention — forward movement
# ---------------------------------------------------------------------------


func test_cannot_move_into_other_ship():
	# Cruiser at (5,5) East len 3: cells (5,6,7). One step → (6,7,8). Blocker at (8,5).
	var cruiser = _defs.create_ship_dict(0, ShipDefs.TYPE_CRUISER, Vector2i(5, 5), MovementRules.DIR_EAST)
	var stealth = _defs.create_ship_dict(1, ShipDefs.TYPE_STEALTH, Vector2i(8, 5), MovementRules.DIR_EAST)
	_state.add_ship(cruiser)
	_state.add_ship(stealth)
	assert_false(MovementRules.can_move_forward(_state, 0, 1), "Must not move into occupied cell")


# ---------------------------------------------------------------------------
# Destroyer double-move
# ---------------------------------------------------------------------------


func test_destroyer_can_move_two_cells():
	var d = _defs.create_ship_dict(0, ShipDefs.TYPE_DESTROYER, Vector2i(5, 5), MovementRules.DIR_EAST)
	_state.add_ship(d)
	var steps := MovementRules.move_steps_for(ShipDefs.TYPE_DESTROYER)
	assert_true(MovementRules.can_move_forward(_state, 0, steps))


func test_destroyer_advances_two_cells():
	var d = _defs.create_ship_dict(0, ShipDefs.TYPE_DESTROYER, Vector2i(5, 5), MovementRules.DIR_EAST)
	_state.add_ship(d)
	MovementRules.move_forward(_state, 0, MovementRules.move_steps_for(ShipDefs.TYPE_DESTROYER))
	assert_eq(_state.ships[0]["position"], Vector2i(7, 5), "Destroyer must advance 2 cells")


func test_destroyer_blocked_at_second_cell():
	# Bow lands at (7,5)+(length 3)=(10,5) after 2 steps; blocker at (9,5)
	var d = _defs.create_ship_dict(0, ShipDefs.TYPE_DESTROYER, Vector2i(5, 5), MovementRules.DIR_EAST)
	var blocker = _defs.create_ship_dict(1, ShipDefs.TYPE_CRUISER, Vector2i(9, 5), MovementRules.DIR_EAST)
	_state.add_ship(d)
	_state.add_ship(blocker)
	assert_false(MovementRules.can_move_forward(_state, 0, 2), "Destroyer blocked by ship at 2-step destination")


# ---------------------------------------------------------------------------
# can_turn / turn_ship
# ---------------------------------------------------------------------------


func test_can_turn_right_open_space():
	var ship = _defs.create_ship_dict(0, ShipDefs.TYPE_CRUISER, Vector2i(5, 5), MovementRules.DIR_EAST)
	_state.add_ship(ship)
	assert_true(MovementRules.can_turn(_state, 0, MovementRules.TURN_RIGHT))


func test_turn_right_updates_facing():
	var ship = _defs.create_ship_dict(0, ShipDefs.TYPE_CRUISER, Vector2i(5, 5), MovementRules.DIR_EAST)
	_state.add_ship(ship)
	MovementRules.turn_ship(_state, 0, MovementRules.TURN_RIGHT)
	assert_eq(_state.ships[0]["facing"], MovementRules.DIR_SOUTH)


func test_turn_updates_grid_cells():
	# Cruiser at (5,5) East: (5,5),(6,5),(7,5) → turn right → (5,5),(5,6),(5,7)
	var ship = _defs.create_ship_dict(0, ShipDefs.TYPE_CRUISER, Vector2i(5, 5), MovementRules.DIR_EAST)
	_state.add_ship(ship)
	MovementRules.turn_ship(_state, 0, MovementRules.TURN_RIGHT)
	assert_null(_state.grid.get_cell_data(Vector2i(6, 5))["occupied_by"], "Old horizontal cells cleared")
	assert_eq(_state.grid.get_cell_data(Vector2i(5, 6))["occupied_by"], 0)
	assert_eq(_state.grid.get_cell_data(Vector2i(5, 7))["occupied_by"], 0)


func test_cannot_turn_past_top_edge():
	# Battleship (len 4) at (5,0) East; left turn → North → tail at y=-3 OOB
	var ship = _defs.create_ship_dict(0, ShipDefs.TYPE_BATTLESHIP, Vector2i(5, 0), MovementRules.DIR_EAST)
	_state.add_ship(ship)
	assert_false(MovementRules.can_turn(_state, 0, MovementRules.TURN_LEFT))


func test_cannot_turn_into_other_ship():
	# Cruiser at (5,5) East; blocker at (5,6) — right turn body would overlap
	var cruiser = _defs.create_ship_dict(0, ShipDefs.TYPE_CRUISER, Vector2i(5, 5), MovementRules.DIR_EAST)
	var blocker = _defs.create_ship_dict(1, ShipDefs.TYPE_STEALTH, Vector2i(5, 6), MovementRules.DIR_EAST)
	_state.add_ship(cruiser)
	_state.add_ship(blocker)
	assert_false(MovementRules.can_turn(_state, 0, MovementRules.TURN_RIGHT))


func test_turn_left_updates_facing():
	var ship = _defs.create_ship_dict(0, ShipDefs.TYPE_CRUISER, Vector2i(5, 5), MovementRules.DIR_EAST)
	_state.add_ship(ship)
	MovementRules.turn_ship(_state, 0, MovementRules.TURN_LEFT)
	assert_eq(_state.ships[0]["facing"], MovementRules.DIR_NORTH)


# ---------------------------------------------------------------------------
# Safety — unknown ship ID
# ---------------------------------------------------------------------------


func test_can_move_forward_unknown_id():
	assert_false(MovementRules.can_move_forward(_state, 99, 1))


func test_can_turn_unknown_id():
	assert_false(MovementRules.can_turn(_state, 99, MovementRules.TURN_RIGHT))
