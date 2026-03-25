extends RefCounted

## MissileRules
## Core missile-combat logic.
## All public methods are static and require no instantiation.
## Issue #29 – Implement missile targeting.
## Issue #30 – Implement hit and miss resolution.
## Issue #31 – Track ship damage state.
## Issue #32 – Implement Battleship double-missile ability.
## Issue #33 – Implement ship destruction logic.

const GameState = preload("res://src/shared/GameState.gd")
const ShipDefs = preload("res://src/shared/ShipDefs.gd")

## Returned by fire_missile when the cell is occupied.
const RESULT_HIT := "hit"
## Returned by fire_missile when the cell is empty.
const RESULT_MISS := "miss"
## Returned by fire_missile when the target is out of bounds.
const RESULT_INVALID := ""

# ---------------------------------------------------------------------------
# Missile count (#32)
# ---------------------------------------------------------------------------


## Returns the number of missiles this ship type fires per action.
## The Battleship's ABILITY_DOUBLE_MISSILE grants 2; all others get 1.
static func missile_count_for(ship_type: String) -> int:
	var defn: Dictionary = ShipDefs.DEFINITIONS.get(ship_type, {})
	if defn.get("ability") == ShipDefs.ABILITY_DOUBLE_MISSILE:
		return 2
	return 1


# ---------------------------------------------------------------------------
# Target validation (#29)
# ---------------------------------------------------------------------------


## Returns true if `target` is a valid in-bounds grid cell.
static func is_valid_target(target: Vector2i) -> bool:
	return target.x >= 0 and target.x < 120 and target.y >= 0 and target.y < 12


# ---------------------------------------------------------------------------
# Missile execution (#29, #30, #31, #33)
# ---------------------------------------------------------------------------


## Fires a missile at `target` for `player_index`.
## Returns RESULT_HIT if the cell is occupied, RESULT_MISS if empty,
## or RESULT_INVALID if the target is out of bounds.
## On a hit: applies 1 damage to the occupying ship (marking it destroyed when
## health reaches 0) and marks the cell "hit". On a miss: marks the cell "miss".
## The result is always recorded in game_state.missile_history.
static func fire_missile(game_state: GameState, player_index: int, target: Vector2i) -> String:
	if not is_valid_target(target):
		return RESULT_INVALID
	var data: Variant = game_state.grid.get_cell_data(target)
	if data == null:
		return RESULT_INVALID
	var occupant: Variant = data.get("occupied_by")
	var result: String
	if occupant != null:
		result = RESULT_HIT
		game_state.update_ship_health(int(occupant), 1)
	else:
		result = RESULT_MISS
	game_state.record_missile(player_index, target, result)
	return result
