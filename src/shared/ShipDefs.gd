extends RefCounted

## ShipDefs
## Canonical definitions for all ship types, their sizes, health, and placement metadata.
## Used by fleet construction, placement validation, and ability dispatch.
## Issue #11 – Define ship types and placement metadata.

# ---------------------------------------------------------------------------
# Ship type identifiers
# ---------------------------------------------------------------------------

const TYPE_SUPPORT := "support"
const TYPE_BATTLESHIP := "battleship"
const TYPE_CRUISER := "cruiser"
const TYPE_DESTROYER := "destroyer"
const TYPE_STEALTH := "stealth"

# ---------------------------------------------------------------------------
# Ability identifiers
# ---------------------------------------------------------------------------

const ABILITY_NONE := "none"
const ABILITY_DOUBLE_PROBE := "double_probe"
const ABILITY_DOUBLE_MISSILE := "double_missile"
const ABILITY_DOUBLE_MOVE := "double_move"
const ABILITY_PROBE_MASK := "probe_mask"

# ---------------------------------------------------------------------------
# Definitions
#
# Each entry:
#   "length"  – number of cells the ship occupies when placed.
#   "health"  – hit points (equals length for all ship types).
#   "ability" – special action available once per turn.
# ---------------------------------------------------------------------------

const DEFINITIONS := {
	TYPE_SUPPORT: {"length": 5, "health": 5, "ability": ABILITY_DOUBLE_PROBE},
	TYPE_BATTLESHIP: {"length": 4, "health": 4, "ability": ABILITY_DOUBLE_MISSILE},
	TYPE_CRUISER: {"length": 3, "health": 3, "ability": ABILITY_NONE},
	TYPE_DESTROYER: {"length": 3, "health": 3, "ability": ABILITY_DOUBLE_MOVE},
	TYPE_STEALTH: {"length": 3, "health": 3, "ability": ABILITY_PROBE_MASK},
}

# ---------------------------------------------------------------------------
# Fleet composition
#
# Required set: exactly one ship of each type per player.
# Order matches the standard placement sequence.
# ---------------------------------------------------------------------------

const FLEET_COMPOSITION := [
	TYPE_SUPPORT,
	TYPE_BATTLESHIP,
	TYPE_CRUISER,
	TYPE_DESTROYER,
	TYPE_STEALTH,
]

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


## Returns true if the given string is a recognised ship type.
func is_valid_type(type: String) -> bool:
	return DEFINITIONS.has(type)


## Returns the definition dictionary for a ship type.
## Returns an empty dictionary for unknown types.
func get_definition(type: String) -> Dictionary:
	return DEFINITIONS.get(type, {})


## Builds a ship instance dictionary ready for use in GameState.
## Facing must be a unit Vector2i (e.g. Vector2i(1, 0) for east).
## Returns an empty dictionary if the type is invalid.
func create_ship_dict(id: int, type: String, position: Vector2i, facing: Vector2i) -> Dictionary:
	if not is_valid_type(type):
		return {}
	var defn := get_definition(type)
	return {
		"id": id,
		"type": type,
		"position": position,
		"facing": facing,
		"length": defn["length"],
		"health": defn["health"],
		"is_destroyed": false,
	}
