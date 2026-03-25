extends RefCounted

## ActionValidator
## Centralised pre-execution validation for all player actions.
## Returns a result dictionary {"valid": bool, "error": String} without
## mutating game state. Call the corresponding Rules method only when valid.
## Issue #72 – Implement centralised action validation system.

const MovementRules = preload("res://src/shared/MovementRules.gd")
const MissileRules = preload("res://src/shared/MissileRules.gd")
const PlacementValidator = preload("res://src/shared/PlacementValidator.gd")

# ---------------------------------------------------------------------------
# Error constants
# ---------------------------------------------------------------------------

const ERROR_NONE := ""
const ERROR_WRONG_TURN := "wrong_turn"
const ERROR_ACTION_LIMIT := "action_limit_reached"
const ERROR_OUT_OF_BOUNDS := "out_of_bounds"
const ERROR_COLLISION := "collision"
const ERROR_GAME_OVER := "game_over"
const ERROR_NOT_COMBAT := "not_combat_phase"

# ---------------------------------------------------------------------------
# Movement validation
# ---------------------------------------------------------------------------


## Validates a forward-movement action for ship_id.
## steps must be 1, or 2 for the Destroyer's double-move ability.
## Returns {"valid": true, "error": ""} or {"valid": false, "error": <code>}.
static func validate_move_forward(
	game_state: Object, turn_manager: Object, player_index: int, ship_id: int, steps: int
) -> Dictionary:
	var err := _check_prerequisites(game_state, turn_manager, player_index, ship_id)
	if err != ERROR_NONE:
		return _fail(err)
	var ship := _find_ship(game_state, ship_id)
	if ship.is_empty():
		return _fail(ERROR_OUT_OF_BOUNDS)
	var new_pos := MovementRules.forward_position(ship["position"], ship["facing"], steps)
	if not PlacementValidator.is_in_bounds(new_pos, ship["facing"], ship["length"]):
		return _fail(ERROR_OUT_OF_BOUNDS)
	for cell in PlacementValidator.get_ship_cells(new_pos, ship["facing"], ship["length"]):
		var data: Variant = game_state.grid.get_cell_data(cell)
		if data == null:
			return _fail(ERROR_OUT_OF_BOUNDS)
		var occupant: Variant = data.get("occupied_by")
		if occupant != null and occupant != ship_id:
			return _fail(ERROR_COLLISION)
	return _ok()


## Validates a turn (rotation) action for ship_id.
## direction must be MovementRules.TURN_LEFT or TURN_RIGHT.
static func validate_turn(
	game_state: Object, turn_manager: Object, player_index: int, ship_id: int, direction: String
) -> Dictionary:
	var err := _check_prerequisites(game_state, turn_manager, player_index, ship_id)
	if err != ERROR_NONE:
		return _fail(err)
	if not MovementRules.can_turn(game_state, ship_id, direction):
		return _fail(ERROR_OUT_OF_BOUNDS)
	return _ok()


# ---------------------------------------------------------------------------
# Probe validation
# ---------------------------------------------------------------------------


## Validates a probe action centred on center for ship_id.
static func validate_probe(
	game_state: Object, turn_manager: Object, player_index: int, ship_id: int, center: Vector2i
) -> Dictionary:
	var err := _check_prerequisites(game_state, turn_manager, player_index, ship_id)
	if err != ERROR_NONE:
		return _fail(err)
	if not game_state.grid.is_in_bounds(center):
		return _fail(ERROR_OUT_OF_BOUNDS)
	return _ok()


# ---------------------------------------------------------------------------
# Missile validation
# ---------------------------------------------------------------------------


## Validates a missile-launch action targeting target for ship_id.
static func validate_missile(
	game_state: Object, turn_manager: Object, player_index: int, ship_id: int, target: Vector2i
) -> Dictionary:
	var err := _check_prerequisites(game_state, turn_manager, player_index, ship_id)
	if err != ERROR_NONE:
		return _fail(err)
	if not MissileRules.is_valid_target(target):
		return _fail(ERROR_OUT_OF_BOUNDS)
	return _ok()


# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------


## Checks phase, turn ownership, and action budget in one call.
## Returns ERROR_NONE when all prerequisites pass.
static func _check_prerequisites(game_state: Object, turn_manager: Object, player_index: int, ship_id: int) -> String:
	if game_state.turn_phase == "game_over":
		return ERROR_GAME_OVER
	if game_state.turn_phase != "combat":
		return ERROR_NOT_COMBAT
	if game_state.current_turn != player_index:
		return ERROR_WRONG_TURN
	if not turn_manager.can_ship_act(ship_id):
		return ERROR_ACTION_LIMIT
	return ERROR_NONE


static func _find_ship(game_state: Object, ship_id: int) -> Dictionary:
	for ship: Dictionary in game_state.ships:
		if ship["id"] == ship_id:
			return ship
	return {}


static func _ok() -> Dictionary:
	return {"valid": true, "error": ERROR_NONE}


static func _fail(error: String) -> Dictionary:
	return {"valid": false, "error": error}
