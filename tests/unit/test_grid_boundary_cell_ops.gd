extends "res://addons/gut/test.gd"

## Tests for BattlefieldGrid cell access and index conversion at boundaries.
## Part of Issue #10: Add grid boundary validation tests.

const BattlefieldGrid = preload("res://src/shared/BattlefieldGrid.gd")

var _grid: RefCounted


func before_each():
	_grid = BattlefieldGrid.new()


# ---------------------------------------------------------------------------
# get_cell_data
# ---------------------------------------------------------------------------


func test_get_cell_data_returns_null_for_negative_x():
	assert_null(_grid.get_cell_data(Vector2i(-1, 0)), "get_cell_data must return null for x=-1")


func test_get_cell_data_returns_null_for_negative_y():
	assert_null(_grid.get_cell_data(Vector2i(0, -1)), "get_cell_data must return null for y=-1")


func test_get_cell_data_returns_null_for_x_at_width():
	assert_null(_grid.get_cell_data(Vector2i(120, 0)), "get_cell_data must return null for x=120")


func test_get_cell_data_returns_null_for_y_at_height():
	assert_null(_grid.get_cell_data(Vector2i(0, 12)), "get_cell_data must return null for y=12")


func test_get_cell_data_valid_at_last_column():
	var data = _grid.get_cell_data(Vector2i(119, 6))
	assert_not_null(data, "get_cell_data must return data at last column (x=119)")


func test_get_cell_data_valid_at_last_row():
	var data = _grid.get_cell_data(Vector2i(60, 11))
	assert_not_null(data, "get_cell_data must return data at last row (y=11)")


# ---------------------------------------------------------------------------
# set_cell_state
# ---------------------------------------------------------------------------


func test_set_cell_state_fails_at_x_boundary():
	assert_false(_grid.set_cell_state(Vector2i(120, 0), "hit"), "set_cell_state must fail for x=120")


func test_set_cell_state_fails_at_y_boundary():
	assert_false(_grid.set_cell_state(Vector2i(0, 12), "hit"), "set_cell_state must fail for y=12")


func test_set_cell_state_fails_for_negative_coords():
	assert_false(_grid.set_cell_state(Vector2i(-1, -1), "hit"), "set_cell_state must fail for negative coords")


func test_set_cell_state_succeeds_at_last_valid_cell():
	assert_true(_grid.set_cell_state(Vector2i(119, 11), "miss"), "set_cell_state must succeed at (119,11)")
	assert_eq(_grid.get_cell_data(Vector2i(119, 11))["state"], "miss", "State must be updated at (119,11)")


# ---------------------------------------------------------------------------
# set_cell_occupant
# ---------------------------------------------------------------------------


func test_set_cell_occupant_fails_at_x_boundary():
	assert_false(_grid.set_cell_occupant(Vector2i(120, 0), "ship_1"), "set_cell_occupant must fail for x=120")


func test_set_cell_occupant_fails_at_y_boundary():
	assert_false(_grid.set_cell_occupant(Vector2i(0, 12), "ship_1"), "set_cell_occupant must fail for y=12")


func test_set_cell_occupant_fails_for_negative_coords():
	assert_false(_grid.set_cell_occupant(Vector2i(-5, -5), "ship_1"), "set_cell_occupant must fail for negative coords")


func test_set_cell_occupant_succeeds_at_origin():
	assert_true(_grid.set_cell_occupant(Vector2i(0, 0), "ship_a"), "set_cell_occupant must succeed at origin")
	assert_eq(_grid.get_cell_data(Vector2i(0, 0))["occupied_by"], "ship_a", "Occupant must be stored at origin")


# ---------------------------------------------------------------------------
# Index conversion at boundaries
# ---------------------------------------------------------------------------


func test_pos_to_index_at_origin():
	assert_eq(_grid.pos_to_index(Vector2i(0, 0)), 0, "Origin maps to index 0")


func test_pos_to_index_at_last_cell():
	assert_eq(_grid.pos_to_index(Vector2i(119, 11)), 1439, "Last cell maps to index 1439")


func test_index_to_pos_at_zero():
	assert_eq(_grid.index_to_pos(0), Vector2i(0, 0), "Index 0 maps to (0,0)")


func test_index_to_pos_at_last():
	assert_eq(_grid.index_to_pos(1439), Vector2i(119, 11), "Index 1439 maps to (119,11)")


func test_pos_to_index_round_trip_for_edge_cells():
	var edge_positions = [
		Vector2i(0, 0),
		Vector2i(119, 0),
		Vector2i(0, 11),
		Vector2i(119, 11),
		Vector2i(60, 0),
		Vector2i(0, 6),
	]
	for pos in edge_positions:
		var idx = _grid.pos_to_index(pos)
		assert_eq(_grid.index_to_pos(idx), pos, "Round-trip for %s must return original position" % str(pos))
