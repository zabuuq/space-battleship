extends "res://addons/gut/test.gd"

const BattlefieldGridUI = preload("res://src/client/scripts/BattlefieldGridUI.gd")

var _grid_ui: Control


func before_each():
	_grid_ui = BattlefieldGridUI.new()
	# Set size manually since it's not in a tree
	_grid_ui.size = Vector2(120 * 16, 12 * 16)


func after_each():
	_grid_ui.free()


func test_screen_to_grid():
	# Top-left of cell (0,0)
	assert_eq(_grid_ui.screen_to_grid(Vector2(0, 0)), Vector2i(0, 0), "0,0 should be grid 0,0")
	# Middle of cell (0,0)
	assert_eq(_grid_ui.screen_to_grid(Vector2(8, 8)), Vector2i(0, 0), "8,8 should be grid 0,0")
	# Edge of cell (0,0)
	assert_eq(_grid_ui.screen_to_grid(Vector2(15.9, 15.9)), Vector2i(0, 0), "15.9,15.9 should be grid 0,0")

	# Cell (1,1)
	assert_eq(_grid_ui.screen_to_grid(Vector2(16, 16)), Vector2i(1, 1), "16,16 should be grid 1,1")

	# Out of bounds (negative)
	assert_eq(_grid_ui.screen_to_grid(Vector2(-1, 0)), Vector2i(-1, -1), "-1,0 should be out of bounds")

	# Out of bounds (too large)
	assert_eq(_grid_ui.screen_to_grid(Vector2(120 * 16, 0)), Vector2i(-1, -1), "Width boundary should be out of bounds")
	assert_eq(_grid_ui.screen_to_grid(Vector2(0, 12 * 16)), Vector2i(-1, -1), "Height boundary should be out of bounds")


func test_grid_to_screen():
	assert_eq(_grid_ui.grid_to_screen(Vector2i(0, 0)), Vector2(0, 0), "Grid 0,0 should be screen 0,0")
	assert_eq(_grid_ui.grid_to_screen(Vector2i(1, 1)), Vector2(16, 16), "Grid 1,1 should be screen 16,16")


func test_get_cell_center():
	assert_eq(_grid_ui.get_cell_center(Vector2i(0, 0)), Vector2(8, 8), "Grid 0,0 center should be 8,8")
