extends "res://addons/gut/test.gd"

## Tests for BattlefieldGrid.is_in_bounds — corners, edges, and extreme values.
## Part of Issue #10: Add grid boundary validation tests.

const BattlefieldGrid = preload("res://src/shared/BattlefieldGrid.gd")

var _grid: RefCounted


func before_each():
	_grid = BattlefieldGrid.new()


# ---------------------------------------------------------------------------
# Corners
# ---------------------------------------------------------------------------


func test_top_left_corner_in_bounds():
	assert_true(_grid.is_in_bounds(Vector2i(0, 0)), "Top-left corner (0,0) must be in bounds")


func test_top_right_corner_in_bounds():
	assert_true(_grid.is_in_bounds(Vector2i(119, 0)), "Top-right corner (119,0) must be in bounds")


func test_bottom_left_corner_in_bounds():
	assert_true(_grid.is_in_bounds(Vector2i(0, 11)), "Bottom-left corner (0,11) must be in bounds")


func test_bottom_right_corner_in_bounds():
	assert_true(_grid.is_in_bounds(Vector2i(119, 11)), "Bottom-right corner (119,11) must be in bounds")


# ---------------------------------------------------------------------------
# Just outside each edge
# ---------------------------------------------------------------------------


func test_one_past_right_edge_out_of_bounds():
	assert_false(_grid.is_in_bounds(Vector2i(120, 0)), "x=120 must be out of bounds")


func test_one_past_bottom_edge_out_of_bounds():
	assert_false(_grid.is_in_bounds(Vector2i(0, 12)), "y=12 must be out of bounds")


func test_one_before_left_edge_out_of_bounds():
	assert_false(_grid.is_in_bounds(Vector2i(-1, 0)), "x=-1 must be out of bounds")


func test_one_before_top_edge_out_of_bounds():
	assert_false(_grid.is_in_bounds(Vector2i(0, -1)), "y=-1 must be out of bounds")


# ---------------------------------------------------------------------------
# Large and combined out-of-bounds values
# ---------------------------------------------------------------------------


func test_large_positive_x_out_of_bounds():
	assert_false(_grid.is_in_bounds(Vector2i(9999, 0)), "Large x must be out of bounds")


func test_large_positive_y_out_of_bounds():
	assert_false(_grid.is_in_bounds(Vector2i(0, 9999)), "Large y must be out of bounds")


func test_large_negative_x_out_of_bounds():
	assert_false(_grid.is_in_bounds(Vector2i(-9999, 0)), "Large negative x must be out of bounds")


func test_large_negative_y_out_of_bounds():
	assert_false(_grid.is_in_bounds(Vector2i(0, -9999)), "Large negative y must be out of bounds")


func test_both_axes_negative_out_of_bounds():
	assert_false(_grid.is_in_bounds(Vector2i(-1, -1)), "(-1,-1) must be out of bounds")


func test_both_axes_over_limit_out_of_bounds():
	assert_false(_grid.is_in_bounds(Vector2i(120, 12)), "(120,12) must be out of bounds")
