extends RefCounted

## ProbeRules
## Core scanning logic for the probe subsystem.
## All public methods are static and require no instantiation.
## Issue #23 – Implement 3×3 probe targeting.
## Issue #24 – Reveal ship presence from probe results.
## Issue #25 – Handle probe scans at map edges.
## Issue #26 – Implement Support double-probe ability.
## Issue #27 – Implement Stealth probe masking.

const GameState = preload("res://src/shared/GameState.gd")
const ShipDefs = preload("res://src/shared/ShipDefs.gd")

# ---------------------------------------------------------------------------
# Probe targeting
# ---------------------------------------------------------------------------


## Returns all in-bounds cells covered by a 3×3 probe centred on `center`.
## Out-of-bounds positions are silently clipped.
static func get_probe_cells(center: Vector2i) -> Array[Vector2i]:
	const GRID_W := 120
	const GRID_H := 12
	var cells: Array[Vector2i] = []
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var pos := Vector2i(center.x + dx, center.y + dy)
			if pos.x >= 0 and pos.x < GRID_W and pos.y >= 0 and pos.y < GRID_H:
				cells.append(pos)
	return cells


## Returns the number of probe actions this ship type may fire per turn.
## The Support's ABILITY_DOUBLE_PROBE grants 2 probes; all others get 1.
static func probe_count_for(ship_type: String) -> int:
	var defn: Dictionary = ShipDefs.DEFINITIONS.get(ship_type, {})
	if defn.get("ability") == ShipDefs.ABILITY_DOUBLE_PROBE:
		return 2
	return 1


# ---------------------------------------------------------------------------
# Probe execution
# ---------------------------------------------------------------------------


## Fires a probe centred on `center` for `player_index`.
## Marks occupied, non-masked cells as "revealed" and records the probe in history.
## Returns an array of Vector2i positions where ships were detected.
static func fire_probe(game_state: GameState, player_index: int, center: Vector2i) -> Array[Vector2i]:
	var detected: Array[Vector2i] = []
	for cell in get_probe_cells(center):
		var data: Variant = game_state.grid.get_cell_data(cell)
		if data == null:
			continue
		var occupant: Variant = data.get("occupied_by")
		if occupant != null and not _is_probe_masked(game_state, int(occupant)):
			game_state.grid.set_cell_state(cell, "revealed")
			detected.append(cell)
	game_state.record_probe(player_index, center, detected)
	return detected


# ---------------------------------------------------------------------------
# Stealth probe masking
# ---------------------------------------------------------------------------


## Activates the probe mask for the given Stealth ship for one round.
## Returns false if the ship does not exist, is not a Stealth type,
## already has the mask active, or the ability is on cooldown.
static func activate_probe_mask(game_state: GameState, ship_id: int) -> bool:
	var ship := _find_ship(game_state, ship_id)
	if ship.is_empty():
		return false
	if ship.get("type") != ShipDefs.TYPE_STEALTH:
		return false
	if ship.get("probe_mask_active", false):
		return false
	if ship.get("probe_mask_cooldown", 0) > 0:
		return false
	ship["probe_mask_active"] = true
	return true


## Advances the probe mask state for a ship at the end of a round.
## If the mask was active it expires and a one-round cooldown begins.
## If a cooldown is running it is decremented by one.
static func tick_probe_mask(ship: Dictionary) -> void:
	if ship.get("probe_mask_active", false):
		ship["probe_mask_active"] = false
		ship["probe_mask_cooldown"] = 1
	elif ship.get("probe_mask_cooldown", 0) > 0:
		ship["probe_mask_cooldown"] -= 1


## Returns true if the ship's probe mask ability is currently available.
static func can_activate_probe_mask(ship: Dictionary) -> bool:
	return (
		ship.get("type") == ShipDefs.TYPE_STEALTH
		and not ship.get("probe_mask_active", false)
		and ship.get("probe_mask_cooldown", 0) == 0
	)


# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------


static func _find_ship(game_state: GameState, ship_id: int) -> Dictionary:
	for ship: Dictionary in game_state.ships:
		if ship["id"] == ship_id:
			return ship
	return {}


static func _is_probe_masked(game_state: GameState, ship_id: int) -> bool:
	var ship := _find_ship(game_state, ship_id)
	return ship.get("probe_mask_active", false)
