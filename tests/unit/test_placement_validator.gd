extends "res://addons/gut/test.gd"

## Tests for PlacementValidator — bounds checking, overlap prevention,
## cell enumeration, and combined can_place logic.
## Issue #16 – Add ship placement validation tests.

const BattlefieldGrid = preload("res://src/shared/BattlefieldGrid.gd")
const PlacementValidator = preload("res://src/shared/PlacementValidator.gd")

var _grid: RefCounted


func before_each() -> void:
	_grid = BattlefieldGrid.new()


# ---------------------------------------------------------------------------
# get_ship_cells
# ---------------------------------------------------------------------------


func test_get_ship_cells_horizontal_length_3():
	var cells := PlacementValidator.get_ship_cells(Vector2i(2, 1), Vector2i(1, 0), 3)
	assert_eq(cells.size(), 3, "Should return 3 cells")
	assert_eq(cells[0], Vector2i(2, 1))
	assert_eq(cells[1], Vector2i(3, 1))
	assert_eq(cells[2], Vector2i(4, 1))


func test_get_ship_cells_vertical_length_4():
	var cells := PlacementValidator.get_ship_cells(Vector2i(5, 0), Vector2i(0, 1), 4)
	assert_eq(cells.size(), 4, "Should return 4 cells")
	assert_eq(cells[0], Vector2i(5, 0))
	assert_eq(cells[1], Vector2i(5, 1))
	assert_eq(cells[2], Vector2i(5, 2))
	assert_eq(cells[3], Vector2i(5, 3))


func test_get_ship_cells_length_1():
	var cells := PlacementValidator.get_ship_cells(Vector2i(10, 5), Vector2i(1, 0), 1)
	assert_eq(cells.size(), 1)
	assert_eq(cells[0], Vector2i(10, 5))


# ---------------------------------------------------------------------------
# is_in_bounds
# ---------------------------------------------------------------------------


func test_in_bounds_horizontal_fits():
	assert_true(
		PlacementValidator.is_in_bounds(Vector2i(0, 0), Vector2i(1, 0), 5), "Length-5 ship at (0,0) horizontal must fit"
	)


func test_in_bounds_horizontal_at_right_edge():
	# Last cell would be at x = 115 + 4 = 119, still in bounds
	assert_true(
		PlacementValidator.is_in_bounds(Vector2i(115, 0), Vector2i(1, 0), 5), "Length-5 ship at x=115 must just fit"
	)


func test_out_of_bounds_horizontal_overflow():
	# Last cell at x = 116 + 4 = 120, out of bounds
	assert_false(
		PlacementValidator.is_in_bounds(Vector2i(116, 0), Vector2i(1, 0), 5),
		"Length-5 ship at x=116 must overflow right edge"
	)


func test_in_bounds_vertical_fits():
	assert_true(
		PlacementValidator.is_in_bounds(Vector2i(0, 0), Vector2i(0, 1), 5),
		"Length-5 ship at (0,0) vertical must fit (grid height 12)"
	)


func test_in_bounds_vertical_at_bottom_edge():
	# Last cell at y = 7 + 4 = 11, still in bounds
	assert_true(
		PlacementValidator.is_in_bounds(Vector2i(0, 7), Vector2i(0, 1), 5),
		"Length-5 ship at y=7 vertical must just fit"
	)


func test_out_of_bounds_vertical_overflow():
	# Last cell at y = 8 + 4 = 12, out of bounds
	assert_false(
		PlacementValidator.is_in_bounds(Vector2i(0, 8), Vector2i(0, 1), 5),
		"Length-5 ship at y=8 vertical must overflow bottom edge"
	)


func test_out_of_bounds_negative_origin():
	assert_false(
		PlacementValidator.is_in_bounds(Vector2i(-1, 0), Vector2i(1, 0), 3), "Negative origin must be out of bounds"
	)


# ---------------------------------------------------------------------------
# is_not_overlapping
# ---------------------------------------------------------------------------


func test_not_overlapping_empty_grid():
	assert_true(
		PlacementValidator.is_not_overlapping(_grid, Vector2i(0, 0), Vector2i(1, 0), 4),
		"Empty grid must allow any placement"
	)


func test_overlapping_after_ship_placed():
	# Occupy cells (0,0), (1,0), (2,0) with ship id 0
	_grid.set_cell_occupant(Vector2i(0, 0), 0)
	_grid.set_cell_occupant(Vector2i(1, 0), 0)
	_grid.set_cell_occupant(Vector2i(2, 0), 0)
	assert_false(
		PlacementValidator.is_not_overlapping(_grid, Vector2i(1, 0), Vector2i(1, 0), 3),
		"Placement overlapping existing ship must fail"
	)


func test_not_overlapping_adjacent_ship():
	_grid.set_cell_occupant(Vector2i(0, 0), 0)
	_grid.set_cell_occupant(Vector2i(1, 0), 0)
	_grid.set_cell_occupant(Vector2i(2, 0), 0)
	# New ship starts at x=3, no overlap
	assert_true(
		PlacementValidator.is_not_overlapping(_grid, Vector2i(3, 0), Vector2i(1, 0), 3),
		"Ship placed directly adjacent must not count as overlapping"
	)


func test_overlapping_partial_overlap():
	_grid.set_cell_occupant(Vector2i(5, 5), 1)
	# New ship: cells (4,5), (5,5), (6,5) — cell (5,5) is taken
	assert_false(
		PlacementValidator.is_not_overlapping(_grid, Vector2i(4, 5), Vector2i(1, 0), 3),
		"Partial overlap must still be rejected"
	)


# ---------------------------------------------------------------------------
# can_place (combines both checks)
# ---------------------------------------------------------------------------


func test_can_place_valid():
	assert_true(
		PlacementValidator.can_place(_grid, Vector2i(10, 3), Vector2i(1, 0), 4),
		"Valid position on empty grid must be placeable"
	)


func test_cannot_place_overlapping():
	_grid.set_cell_occupant(Vector2i(10, 3), 0)
	assert_false(
		PlacementValidator.can_place(_grid, Vector2i(10, 3), Vector2i(1, 0), 4),
		"Overlapping ship must prevent placement"
	)


func test_cannot_place_out_of_bounds():
	# Length-5 ship at x=117 would end at x=121 — out of bounds
	assert_false(
		PlacementValidator.can_place(_grid, Vector2i(117, 0), Vector2i(1, 0), 5),
		"Out-of-bounds placement must be rejected"
	)


func test_cannot_place_both_invalid():
	_grid.set_cell_occupant(Vector2i(118, 0), 0)
	# Also overflows the grid (x=118+4=122)
	assert_false(
		PlacementValidator.can_place(_grid, Vector2i(118, 0), Vector2i(1, 0), 5),
		"Placement that is both overlapping and out-of-bounds must be rejected"
	)
