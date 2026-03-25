extends "res://addons/gut/test.gd"

## Tests for ActionValidator — movement, probe, missile validation, and action limits.
## Issue #72 – Implement centralised action validation system.
## Issue #39 – Add turn system tests.

const GameState = preload("res://src/shared/GameState.gd")
const ShipDefs = preload("res://src/shared/ShipDefs.gd")
const TurnManager = preload("res://src/shared/TurnManager.gd")
const ActionValidator = preload("res://src/shared/ActionValidator.gd")
const MovementRules = preload("res://src/shared/MovementRules.gd")

var _state: RefCounted
var _defs: RefCounted
var _tm: RefCounted


func before_each() -> void:
	_state = GameState.new()
	_state.set_phase("combat")
	_defs = ShipDefs.new()
	_tm = TurnManager.new()
	_tm.begin_turn(_state)


## Places a ship and returns the ship dictionary.
func _place_ship(id: int, type: String, pos: Vector2i, facing: Vector2i) -> Dictionary:
	var ship = _defs.create_ship_dict(id, type, pos, facing)
	_state.add_ship(ship)
	return ship


# ---------------------------------------------------------------------------
# Movement validation
# ---------------------------------------------------------------------------


func test_valid_movement_is_accepted():
	_place_ship(0, ShipDefs.TYPE_CRUISER, Vector2i(5, 5), MovementRules.DIR_EAST)
	var result := ActionValidator.validate_move_forward(_state, _tm, 0, 0, 1)
	assert_true(result["valid"])


func test_movement_out_of_bounds_is_rejected():
	# Ship at x=117 facing east, length 3 → moving 1 east puts tail at x=120 (out of bounds)
	_place_ship(0, ShipDefs.TYPE_CRUISER, Vector2i(117, 5), MovementRules.DIR_EAST)
	var result := ActionValidator.validate_move_forward(_state, _tm, 0, 0, 1)
	assert_false(result["valid"])
	assert_eq(result["error"], ActionValidator.ERROR_OUT_OF_BOUNDS)


func test_movement_to_occupied_cell_is_rejected():
	# Ship 0 at (5,5)→(7,5); Ship 1 at (8,5)→(10,5) blocks ship 0 moving east
	_place_ship(0, ShipDefs.TYPE_CRUISER, Vector2i(5, 5), MovementRules.DIR_EAST)
	_place_ship(1, ShipDefs.TYPE_CRUISER, Vector2i(8, 5), MovementRules.DIR_EAST)
	var result := ActionValidator.validate_move_forward(_state, _tm, 0, 0, 1)
	assert_false(result["valid"])
	assert_eq(result["error"], ActionValidator.ERROR_COLLISION)


# ---------------------------------------------------------------------------
# Probe validation
# ---------------------------------------------------------------------------


func test_valid_probe_is_accepted():
	_place_ship(0, ShipDefs.TYPE_SUPPORT, Vector2i(0, 0), MovementRules.DIR_EAST)
	var result := ActionValidator.validate_probe(_state, _tm, 0, 0, Vector2i(10, 5))
	assert_true(result["valid"])


func test_probe_out_of_bounds_is_rejected():
	_place_ship(0, ShipDefs.TYPE_SUPPORT, Vector2i(0, 0), MovementRules.DIR_EAST)
	var result := ActionValidator.validate_probe(_state, _tm, 0, 0, Vector2i(-1, 5))
	assert_false(result["valid"])
	assert_eq(result["error"], ActionValidator.ERROR_OUT_OF_BOUNDS)


# ---------------------------------------------------------------------------
# Missile validation
# ---------------------------------------------------------------------------


func test_valid_missile_is_accepted():
	_place_ship(0, ShipDefs.TYPE_BATTLESHIP, Vector2i(0, 0), MovementRules.DIR_EAST)
	var result := ActionValidator.validate_missile(_state, _tm, 0, 0, Vector2i(50, 5))
	assert_true(result["valid"])


func test_missile_out_of_bounds_is_rejected():
	_place_ship(0, ShipDefs.TYPE_BATTLESHIP, Vector2i(0, 0), MovementRules.DIR_EAST)
	var result := ActionValidator.validate_missile(_state, _tm, 0, 0, Vector2i(200, 5))
	assert_false(result["valid"])
	assert_eq(result["error"], ActionValidator.ERROR_OUT_OF_BOUNDS)


# ---------------------------------------------------------------------------
# Action limits and turn order
# ---------------------------------------------------------------------------


func test_action_rejected_when_limit_reached():
	_place_ship(0, ShipDefs.TYPE_CRUISER, Vector2i(5, 5), MovementRules.DIR_EAST)
	_tm.record_action(_state, 0, 0)
	var result := ActionValidator.validate_move_forward(_state, _tm, 0, 0, 1)
	assert_false(result["valid"])
	assert_eq(result["error"], ActionValidator.ERROR_ACTION_LIMIT)


func test_action_rejected_on_wrong_turn():
	_place_ship(0, ShipDefs.TYPE_CRUISER, Vector2i(5, 5), MovementRules.DIR_EAST)
	# Player 1 tries to act but it is player 0's turn
	var result := ActionValidator.validate_move_forward(_state, _tm, 1, 0, 1)
	assert_false(result["valid"])
	assert_eq(result["error"], ActionValidator.ERROR_WRONG_TURN)


func test_probe_rejected_on_wrong_turn():
	_place_ship(0, ShipDefs.TYPE_SUPPORT, Vector2i(0, 0), MovementRules.DIR_EAST)
	var result := ActionValidator.validate_probe(_state, _tm, 1, 0, Vector2i(10, 5))
	assert_false(result["valid"])
	assert_eq(result["error"], ActionValidator.ERROR_WRONG_TURN)


func test_missile_rejected_on_wrong_turn():
	_place_ship(0, ShipDefs.TYPE_BATTLESHIP, Vector2i(0, 0), MovementRules.DIR_EAST)
	var result := ActionValidator.validate_missile(_state, _tm, 1, 0, Vector2i(50, 5))
	assert_false(result["valid"])
	assert_eq(result["error"], ActionValidator.ERROR_WRONG_TURN)
