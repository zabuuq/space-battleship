extends "res://addons/gut/test.gd"

const BattlefieldGrid = preload("res://src/shared/BattlefieldGrid.gd")

var _grid: RefCounted


func before_each():
	_grid = BattlefieldGrid.new()


func test_grid_dimensions():
	assert_eq(_grid.WIDTH, 120, "Width should be 120")
	assert_eq(_grid.HEIGHT, 12, "Height should be 12")


func test_bounds_checking():
	assert_true(_grid.is_in_bounds(Vector2i(0, 0)), "0,0 should be in bounds")
	assert_true(_grid.is_in_bounds(Vector2i(119, 11)), "119,11 should be in bounds")
	assert_false(_grid.is_in_bounds(Vector2i(-1, 0)), "-1,0 should be out of bounds")
	assert_false(_grid.is_in_bounds(Vector2i(120, 0)), "120,0 should be out of bounds")
	assert_false(_grid.is_in_bounds(Vector2i(0, -1)), "0,-1 should be out of bounds")
	assert_false(_grid.is_in_bounds(Vector2i(0, 12)), "0,12 should be out of bounds")


func test_cell_data_initialization():
	var data = _grid.get_cell_data(Vector2i(5, 5))
	assert_not_null(data, "Should return data for valid cell")
	assert_eq(data["state"], "hidden", "Default state should be hidden")
	assert_null(data["occupied_by"], "Default occupant should be null")


func test_set_get_cell_state():
	var pos = Vector2i(10, 2)
	assert_true(_grid.set_cell_state(pos, "hit"), "Should succeed for in-bounds")
	assert_eq(_grid.get_cell_data(pos)["state"], "hit", "Should retrieve updated state")
	assert_false(_grid.set_cell_state(Vector2i(200, 200), "hit"), "Should fail for out-of-bounds")


func test_index_conversion():
	var pos = Vector2i(1, 1)
	var expected_index = 121  # (1 * 120) + 1
	assert_eq(_grid.pos_to_index(pos), expected_index, "Pos to index conversion")
	assert_eq(_grid.index_to_pos(expected_index), pos, "Index to pos conversion")
