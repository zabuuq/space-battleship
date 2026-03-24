extends "res://addons/gut/test.gd"

## Tests for MovementRules — facing direction model, turn geometry,
## forward_position, move_steps_for, and basic forward movement.
## Issue #22 – Add movement and collision tests (part 1 of 2).

const GameState = preload("res://src/shared/GameState.gd")
const ShipDefs = preload("res://src/shared/ShipDefs.gd")
const MovementRules = preload("res://src/shared/MovementRules.gd")

var _state: RefCounted
var _defs: RefCounted


func before_each() -> void:
	_state = GameState.new()
	_defs = ShipDefs.new()


# ---------------------------------------------------------------------------
# apply_turn
# ---------------------------------------------------------------------------


func test_turn_right_east_gives_south():
	assert_eq(MovementRules.apply_turn(MovementRules.DIR_EAST, MovementRules.TURN_RIGHT), MovementRules.DIR_SOUTH)


func test_turn_right_south_gives_west():
	assert_eq(MovementRules.apply_turn(MovementRules.DIR_SOUTH, MovementRules.TURN_RIGHT), MovementRules.DIR_WEST)


func test_turn_right_west_gives_north():
	assert_eq(MovementRules.apply_turn(MovementRules.DIR_WEST, MovementRules.TURN_RIGHT), MovementRules.DIR_NORTH)


func test_turn_right_north_gives_east():
	assert_eq(MovementRules.apply_turn(MovementRules.DIR_NORTH, MovementRules.TURN_RIGHT), MovementRules.DIR_EAST)


func test_turn_left_east_gives_north():
	assert_eq(MovementRules.apply_turn(MovementRules.DIR_EAST, MovementRules.TURN_LEFT), MovementRules.DIR_NORTH)


func test_turn_left_north_gives_west():
	assert_eq(MovementRules.apply_turn(MovementRules.DIR_NORTH, MovementRules.TURN_LEFT), MovementRules.DIR_WEST)


func test_four_right_turns_restore_facing():
	var facing := MovementRules.DIR_EAST
	for _i in range(4):
		facing = MovementRules.apply_turn(facing, MovementRules.TURN_RIGHT)
	assert_eq(facing, MovementRules.DIR_EAST, "Four right turns must restore original facing")


# ---------------------------------------------------------------------------
# forward_position
# ---------------------------------------------------------------------------


func test_forward_east_one_step():
	assert_eq(MovementRules.forward_position(Vector2i(5, 3), MovementRules.DIR_EAST, 1), Vector2i(6, 3))


func test_forward_south_two_steps():
	assert_eq(MovementRules.forward_position(Vector2i(5, 3), MovementRules.DIR_SOUTH, 2), Vector2i(5, 5))


func test_forward_west_three_steps():
	assert_eq(MovementRules.forward_position(Vector2i(10, 0), MovementRules.DIR_WEST, 3), Vector2i(7, 0))


# ---------------------------------------------------------------------------
# move_steps_for
# ---------------------------------------------------------------------------


func test_support_moves_one_step():
	assert_eq(MovementRules.move_steps_for(ShipDefs.TYPE_SUPPORT), 1)


func test_battleship_moves_one_step():
	assert_eq(MovementRules.move_steps_for(ShipDefs.TYPE_BATTLESHIP), 1)


func test_cruiser_moves_one_step():
	assert_eq(MovementRules.move_steps_for(ShipDefs.TYPE_CRUISER), 1)


func test_destroyer_moves_two_steps():
	assert_eq(MovementRules.move_steps_for(ShipDefs.TYPE_DESTROYER), 2, "Destroyer must move 2 cells")


func test_stealth_moves_one_step():
	assert_eq(MovementRules.move_steps_for(ShipDefs.TYPE_STEALTH), 1)


# ---------------------------------------------------------------------------
# can_move_forward / move_forward — legal forward movement
# ---------------------------------------------------------------------------


func test_can_move_forward_open_space():
	var ship = _defs.create_ship_dict(0, ShipDefs.TYPE_CRUISER, Vector2i(5, 5), MovementRules.DIR_EAST)
	_state.add_ship(ship)
	assert_true(MovementRules.can_move_forward(_state, 0, 1))


func test_move_forward_updates_position():
	var ship = _defs.create_ship_dict(0, ShipDefs.TYPE_CRUISER, Vector2i(5, 5), MovementRules.DIR_EAST)
	_state.add_ship(ship)
	MovementRules.move_forward(_state, 0, 1)
	assert_eq(_state.ships[0]["position"], Vector2i(6, 5))


func test_move_forward_vacates_tail_cell():
	var ship = _defs.create_ship_dict(0, ShipDefs.TYPE_CRUISER, Vector2i(5, 5), MovementRules.DIR_EAST)
	_state.add_ship(ship)
	MovementRules.move_forward(_state, 0, 1)
	assert_null(_state.grid.get_cell_data(Vector2i(5, 5))["occupied_by"], "Old tail must be cleared")


func test_cannot_move_forward_past_right_edge():
	var ship = _defs.create_ship_dict(0, ShipDefs.TYPE_CRUISER, Vector2i(118, 5), MovementRules.DIR_EAST)
	_state.add_ship(ship)
	assert_false(MovementRules.can_move_forward(_state, 0, 1))
