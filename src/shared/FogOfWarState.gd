class_name FogOfWarState
extends RefCounted

## FogOfWarState
## Tracks what a player can see on the opponent's grid.
## Cells are recorded when revealed by probes or resolved by missiles.
## Issue: #74 Implement fog-of-war data model.

const CELL_REVEALED = "revealed"
const CELL_HIT = "hit"
const CELL_MISS = "miss"

var _visible_cells: Dictionary = {}  # Vector2i -> String (state constant)


## Marks cells as revealed from a successful probe. Already-recorded hit/miss cells
## are not overwritten so that combat results take priority.
func apply_probe_result(positions: Array) -> void:
	for pos in positions:
		if pos not in _visible_cells:
			_visible_cells[pos] = CELL_REVEALED


## Records a missile result at the given position using MissileRules result constants.
func apply_missile_result(pos: Vector2i, result: String) -> void:
	if result == MissileRules.RESULT_HIT:
		_visible_cells[pos] = CELL_HIT
	elif result == MissileRules.RESULT_MISS:
		_visible_cells[pos] = CELL_MISS


## Returns true if the cell has been observed (revealed, hit, or missed).
func is_cell_observed(pos: Vector2i) -> bool:
	return pos in _visible_cells


## Returns the observed state string for a cell, or an empty string if not observed.
func get_cell_state(pos: Vector2i) -> String:
	return _visible_cells.get(pos, "")


## Returns a copy of all observed cells mapped to their state strings.
func get_visible_cells() -> Dictionary:
	return _visible_cells.duplicate()


## Serialises the fog state to a dictionary for network transport.
## Keys are "x,y" strings; values are state strings.
func to_dict() -> Dictionary:
	var result: Dictionary = {}
	for pos: Vector2i in _visible_cells:
		result["%d,%d" % [pos.x, pos.y]] = _visible_cells[pos]
	return result


## Deserialises the fog state from a dictionary produced by to_dict().
func from_dict(data: Dictionary) -> void:
	_visible_cells.clear()
	for key: String in data:
		var parts: PackedStringArray = key.split(",")
		if parts.size() == 2:
			var pos := Vector2i(int(parts[0]), int(parts[1]))
			_visible_cells[pos] = data[key]
