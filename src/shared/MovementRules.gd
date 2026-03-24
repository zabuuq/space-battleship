extends RefCounted

## MovementRules
## Canonical movement rules for ship navigation: facing constants, turn geometry,
## forward movement, and collision validation.
## All public methods are static and require no instantiation.
## Issue #17 – Implement ship facing direction model.
## Issue #18 – Implement forward movement rules.
## Issue #19 – Implement turning cost rules.
## Issue #20 – Prevent collision during movement.

const GameState = preload("res://src/shared/GameState.gd")
const ShipDefs = preload("res://src/shared/ShipDefs.gd")
const PlacementValidator = preload("res://src/shared/PlacementValidator.gd")

# ---------------------------------------------------------------------------
# Facing direction constants (grid space — Y increases downward)
# ---------------------------------------------------------------------------

const DIR_EAST := Vector2i(1, 0)
const DIR_WEST := Vector2i(-1, 0)
const DIR_NORTH := Vector2i(0, -1)
const DIR_SOUTH := Vector2i(0, 1)

## All valid cardinal facing directions.
const CARDINALS: Array = [DIR_EAST, DIR_WEST, DIR_NORTH, DIR_SOUTH]

# ---------------------------------------------------------------------------
# Turn identifiers
# ---------------------------------------------------------------------------

const TURN_LEFT := "left"
const TURN_RIGHT := "right"

# ---------------------------------------------------------------------------
# Pure geometric helpers
# ---------------------------------------------------------------------------


## Returns the new facing direction after a 90-degree turn.
## TURN_RIGHT rotates clockwise (in screen coords where Y increases downward).
## TURN_LEFT rotates counterclockwise.
static func apply_turn(facing: Vector2i, direction: String) -> Vector2i:
	if direction == TURN_RIGHT:
		return Vector2i(-facing.y, facing.x)
	return Vector2i(facing.y, -facing.x)


## Returns the grid position after moving forward by steps cells.
static func forward_position(pos: Vector2i, facing: Vector2i, steps: int) -> Vector2i:
	return pos + facing * steps


# ---------------------------------------------------------------------------
# Forward movement
# ---------------------------------------------------------------------------


## Returns the number of forward cells this ship type may move per action.
## All types move 1 cell by default.
static func move_steps_for(_ship_type: String) -> int:
	return 1


## Returns true if moving the ship forward by the given number of steps is legal:
## the destination must be in bounds and free of other ships.
static func can_move_forward(game_state: GameState, ship_id: int, steps: int) -> bool:
	var ship := _find_ship(game_state, ship_id)
	if ship.is_empty():
		return false
	var new_pos := forward_position(ship["position"], ship["facing"], steps)
	return _can_occupy(game_state, ship_id, new_pos, ship["facing"], ship["length"])


## Moves the ship forward by steps cells. Does not validate; call can_move_forward first.
static func move_forward(game_state: GameState, ship_id: int, steps: int) -> void:
	var ship := _find_ship(game_state, ship_id)
	if ship.is_empty():
		return
	var new_pos := forward_position(ship["position"], ship["facing"], steps)
	_update_grid(game_state.grid, ship, new_pos, ship["facing"])
	ship["position"] = new_pos


# ---------------------------------------------------------------------------
# Turning (costs one movement action)
# ---------------------------------------------------------------------------


## Returns true if rotating the ship is legal: the rotated body must be in bounds
## and not overlap any other ship. Turning consumes the ship's movement action.
static func can_turn(game_state: GameState, ship_id: int, direction: String) -> bool:
	var ship := _find_ship(game_state, ship_id)
	if ship.is_empty():
		return false
	var new_facing := apply_turn(ship["facing"], direction)
	return _can_occupy(game_state, ship_id, ship["position"], new_facing, ship["length"])


## Rotates the ship 90 degrees. Does not validate; call can_turn first.
static func turn_ship(game_state: GameState, ship_id: int, direction: String) -> void:
	var ship := _find_ship(game_state, ship_id)
	if ship.is_empty():
		return
	var new_facing := apply_turn(ship["facing"], direction)
	_update_grid(game_state.grid, ship, ship["position"], new_facing)
	ship["facing"] = new_facing


# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------


static func _find_ship(game_state: GameState, ship_id: int) -> Dictionary:
	for ship: Dictionary in game_state.ships:
		if ship["id"] == ship_id:
			return ship
	return {}


## Clears the ship's current grid cells and writes new ones.
## Must be called BEFORE updating ship["position"] or ship["facing"].
static func _update_grid(grid: RefCounted, ship: Dictionary, new_pos: Vector2i, new_facing: Vector2i) -> void:
	for cell in PlacementValidator.get_ship_cells(ship["position"], ship["facing"], ship["length"]):
		grid.set_cell_occupant(cell, null)
	for cell in PlacementValidator.get_ship_cells(new_pos, new_facing, ship["length"]):
		grid.set_cell_occupant(cell, ship["id"])


## Returns true if the target position and facing are within bounds and every
## cell is either empty or already occupied by ship_id (partial overlap is
## allowed when moving — the ship's own tail cells count as free).
static func _can_occupy(game_state: GameState, ship_id: int, pos: Vector2i, facing: Vector2i, length: int) -> bool:
	if not PlacementValidator.is_in_bounds(pos, facing, length):
		return false
	for cell in PlacementValidator.get_ship_cells(pos, facing, length):
		var data: Variant = game_state.grid.get_cell_data(cell)
		if data == null:
			return false
		var occupant: Variant = data.get("occupied_by")
		if occupant != null and occupant != ship_id:
			return false
	return true
