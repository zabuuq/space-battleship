extends RefCounted

## PlacementValidator
## Shared validation logic for ship placement.
## All methods are static so the class can be used without instantiation.
## Issue #14 – Prevent overlapping ship placement.
## Issue #15 – Prevent out-of-bounds ship placement.

const BattlefieldGrid = preload("res://src/shared/BattlefieldGrid.gd")


## Returns the list of grid cells that a ship occupies given its origin,
## facing direction, and length.
static func get_ship_cells(pos: Vector2i, facing: Vector2i, length: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for i in range(length):
		cells.append(pos + facing * i)
	return cells


## Returns true if every cell the ship would occupy lies within the grid.
static func is_in_bounds(pos: Vector2i, facing: Vector2i, length: int) -> bool:
	for i in range(length):
		var cell := pos + facing * i
		if cell.x < 0 or cell.x >= BattlefieldGrid.WIDTH:
			return false
		if cell.y < 0 or cell.y >= BattlefieldGrid.HEIGHT:
			return false
	return true


## Returns true if none of the cells the ship would occupy are already taken.
static func is_not_overlapping(grid: BattlefieldGrid, pos: Vector2i, facing: Vector2i, length: int) -> bool:
	for i in range(length):
		var cell := pos + facing * i
		var data: Variant = grid.get_cell_data(cell)
		if data != null and data.get("occupied_by") != null:
			return false
	return true


## Returns true when the placement is both within bounds and non-overlapping.
static func can_place(grid: BattlefieldGrid, pos: Vector2i, facing: Vector2i, length: int) -> bool:
	return is_in_bounds(pos, facing, length) and is_not_overlapping(grid, pos, facing, length)
