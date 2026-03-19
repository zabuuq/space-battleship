extends RefCounted

## BattlefieldGrid
## Handles raw grid data storage, coordinate validation, and bounds checking.

const WIDTH := 120
const HEIGHT := 12

# A dictionary to store cell data, keyed by Vector2i.
# Using a dictionary allows for sparse storage if needed,
# though for 1440 cells a nested array would also work.
# Key: Vector2i, Value: Dictionary (cell metadata)
var _cells: Dictionary = {}


func _init() -> void:
	_initialize_grid()


## Resets the grid to an empty state.
func _initialize_grid() -> void:
	_cells.clear()
	for y in range(HEIGHT):
		for x in range(WIDTH):
			var pos := Vector2i(x, y)
			_cells[pos] = {
				"occupied_by": null,  # Reference to a ship ID or object
				"state": "hidden",  # hidden, revealed, hit, miss
			}


## Checks if a coordinate is within the 120x12 boundaries.
func is_in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < WIDTH and pos.y >= 0 and pos.y < HEIGHT


## Returns the data for a specific cell.
## Returns null if out of bounds.
func get_cell_data(pos: Vector2i) -> Variant:
	if not is_in_bounds(pos):
		return null
	return _cells.get(pos)


## Updates the state of a specific cell.
## Returns true if successful, false if out of bounds.
func set_cell_state(pos: Vector2i, state: String) -> bool:
	if not is_in_bounds(pos):
		return false
	_cells[pos]["state"] = state
	return true


## Marks a cell as occupied by a specific ship ID.
## Returns true if successful, false if out of bounds.
func set_cell_occupant(pos: Vector2i, ship_id: Variant) -> bool:
	if not is_in_bounds(pos):
		return false
	_cells[pos]["occupied_by"] = ship_id
	return true


## Utility to convert a 1D index to a 2D Vector2i.
func index_to_pos(index: int) -> Vector2i:
	return Vector2i(index % WIDTH, index / WIDTH)


## Utility to convert a 2D Vector2i to a 1D index.
func pos_to_index(pos: Vector2i) -> int:
	return pos.y * WIDTH + pos.x
