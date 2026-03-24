extends "res://addons/gut/test.gd"

## Tests for ProbeRules — 3×3 scan geometry and edge clipping.
## Issue #23 – Implement 3×3 probe targeting.
## Issue #25 – Handle probe scans at map edges.
## Issue #28 – Add probe system tests.

const ProbeRules = preload("res://src/shared/ProbeRules.gd")

# ---------------------------------------------------------------------------
# 3×3 scan geometry (#23)
# ---------------------------------------------------------------------------


func test_probe_returns_nine_cells_in_open_area():
	var cells := ProbeRules.get_probe_cells(Vector2i(5, 5))
	assert_eq(cells.size(), 9, "Interior probe covers exactly 9 cells")


func test_probe_cells_are_all_in_bounds():
	var cells := ProbeRules.get_probe_cells(Vector2i(5, 5))
	for cell in cells:
		assert_true(cell.x >= 0 and cell.x < 120 and cell.y >= 0 and cell.y < 12, "All probe cells must be in bounds")


func test_probe_includes_center_cell():
	var center := Vector2i(10, 6)
	var cells := ProbeRules.get_probe_cells(center)
	assert_true(cells.has(center), "Probe must include the centre cell")


# ---------------------------------------------------------------------------
# Edge clipping (#25)
# ---------------------------------------------------------------------------


func test_probe_at_top_left_corner():
	var cells := ProbeRules.get_probe_cells(Vector2i(0, 0))
	assert_eq(cells.size(), 4, "Top-left corner probe covers 4 in-bounds cells")
	for cell in cells:
		assert_true(cell.x >= 0 and cell.y >= 0, "No out-of-bounds cells")


func test_probe_at_top_right_corner():
	var cells := ProbeRules.get_probe_cells(Vector2i(119, 0))
	assert_eq(cells.size(), 4, "Top-right corner probe covers 4 in-bounds cells")
	for cell in cells:
		assert_true(cell.x <= 119 and cell.y >= 0, "No out-of-bounds cells")


func test_probe_at_bottom_left_corner():
	var cells := ProbeRules.get_probe_cells(Vector2i(0, 11))
	assert_eq(cells.size(), 4, "Bottom-left corner probe covers 4 in-bounds cells")
	for cell in cells:
		assert_true(cell.x >= 0 and cell.y <= 11, "No out-of-bounds cells")


func test_probe_at_bottom_right_corner():
	var cells := ProbeRules.get_probe_cells(Vector2i(119, 11))
	assert_eq(cells.size(), 4, "Bottom-right corner probe covers 4 in-bounds cells")
	for cell in cells:
		assert_true(cell.x <= 119 and cell.y <= 11, "No out-of-bounds cells")


func test_probe_clipped_by_left_edge():
	var cells := ProbeRules.get_probe_cells(Vector2i(0, 5))
	assert_eq(cells.size(), 6, "Left-edge probe covers 6 in-bounds cells")
	for cell in cells:
		assert_true(cell.x >= 0, "No negative x")


func test_probe_clipped_by_right_edge():
	var cells := ProbeRules.get_probe_cells(Vector2i(119, 5))
	assert_eq(cells.size(), 6, "Right-edge probe covers 6 in-bounds cells")
	for cell in cells:
		assert_true(cell.x <= 119, "No x > 119")


func test_probe_clipped_by_top_edge():
	var cells := ProbeRules.get_probe_cells(Vector2i(5, 0))
	assert_eq(cells.size(), 6, "Top-edge probe covers 6 in-bounds cells")
	for cell in cells:
		assert_true(cell.y >= 0, "No negative y")


func test_probe_clipped_by_bottom_edge():
	var cells := ProbeRules.get_probe_cells(Vector2i(5, 11))
	assert_eq(cells.size(), 6, "Bottom-edge probe covers 6 in-bounds cells")
	for cell in cells:
		assert_true(cell.y <= 11, "No y > 11")
