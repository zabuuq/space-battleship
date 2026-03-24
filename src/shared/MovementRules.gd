extends RefCounted

## MovementRules
## Canonical movement rules for ship navigation: facing constants, turn geometry,
## forward movement, and collision validation.
## All public methods are static and require no instantiation.
## Issue #17 – Implement ship facing direction model.

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
