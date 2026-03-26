extends RefCounted

## ServerGameLogic
## Authoritative server-side game logic processor.
## Validates and applies player actions using ActionValidator and the
## appropriate Rules class, then returns a result suitable for broadcast.
## Issue #69 – Implement authoritative server game logic.

const ActionValidator = preload("res://src/shared/ActionValidator.gd")
const MovementRules = preload("res://src/shared/MovementRules.gd")
const ProbeRules = preload("res://src/shared/ProbeRules.gd")
const MissileRules = preload("res://src/shared/MissileRules.gd")
const GameState = preload("res://src/shared/GameState.gd")
const TurnManager = preload("res://src/shared/TurnManager.gd")

# ---------------------------------------------------------------------------
# Result constants
# ---------------------------------------------------------------------------

const RESULT_OK := "ok"
const RESULT_INVALID := "invalid"
const RESULT_GAME_OVER := "game_over"

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var game_state: GameState = GameState.new()
var turn_manager: TurnManager = TurnManager.new()

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------


## Initialises a new match from a serialised game-state dictionary.
func start_match(state_dict: Dictionary) -> void:
	game_state.from_dict(state_dict)
	turn_manager.begin_turn(game_state)


# ---------------------------------------------------------------------------
# Action processing
# ---------------------------------------------------------------------------


## Processes a single action submitted by player_index.
## action_dict must contain: "action" (String), "ship_id" (int), "params" (Dictionary).
##
## Returns a result dictionary:
##   {"result": RESULT_OK, "state": {...}, "game_over": false} on success
##   {"result": RESULT_INVALID, "error": "...", "game_over": false} on invalid action
##   {"result": RESULT_GAME_OVER, "state": {...}, "winner": player_index} when last ship destroyed
func process_action(player_index: int, action_dict: Dictionary) -> Dictionary:
	var action: String = action_dict.get("action", "")
	var ship_id: int = action_dict.get("ship_id", -1)
	var params: Dictionary = action_dict.get("params", {})

	var validation := _validate(player_index, action, ship_id, params)
	if not validation["valid"]:
		return {"result": RESULT_INVALID, "error": validation["error"], "game_over": false}

	var record_result := turn_manager.record_action(game_state, player_index, ship_id)
	if record_result != TurnManager.RESULT_OK:
		return {"result": RESULT_INVALID, "error": record_result, "game_over": false}

	_apply(player_index, action, ship_id, params)

	if _is_fleet_destroyed(1 - player_index):
		game_state.set_phase("game_over")
		return {"result": RESULT_GAME_OVER, "state": game_state.to_dict(), "winner": player_index, "game_over": true}

	return {"result": RESULT_OK, "state": game_state.to_dict(), "game_over": false}


## Ends the current player's turn.
## Returns the updated state dict for broadcast.
func process_end_turn() -> Dictionary:
	turn_manager.end_turn(game_state)
	turn_manager.begin_turn(game_state)
	return {"result": RESULT_OK, "state": game_state.to_dict(), "game_over": false}


# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------


func _validate(player_index: int, action: String, ship_id: int, params: Dictionary) -> Dictionary:
	match action:
		"move_forward":
			return ActionValidator.validate_move_forward(
				game_state, turn_manager, player_index, ship_id, params.get("steps", 1)
			)
		"turn":
			return ActionValidator.validate_turn(
				game_state, turn_manager, player_index, ship_id, params.get("direction", "")
			)
		"probe":
			return ActionValidator.validate_probe(
				game_state, turn_manager, player_index, ship_id, Vector2i(params.get("x", 0), params.get("y", 0))
			)
		"missile":
			return ActionValidator.validate_missile(
				game_state, turn_manager, player_index, ship_id, Vector2i(params.get("x", 0), params.get("y", 0))
			)
		_:
			return {"valid": false, "error": "unknown_action"}


func _apply(player_index: int, action: String, ship_id: int, params: Dictionary) -> void:
	match action:
		"move_forward":
			MovementRules.move_forward(game_state, ship_id, params.get("steps", 1))
		"turn":
			MovementRules.turn_ship(game_state, ship_id, params.get("direction", ""))
		"probe":
			ProbeRules.fire_probe(game_state, player_index, Vector2i(params.get("x", 0), params.get("y", 0)))
		"missile":
			MissileRules.fire_missile(game_state, player_index, Vector2i(params.get("x", 0), params.get("y", 0)))


## Returns true when every ship in game_state has is_destroyed = true.
## In a two-player match the caller passes the defender's player_index so
## the name is intentional; this implementation assumes the game_state
## represents the targeted fleet only (server maintains one state per player).
func _is_fleet_destroyed(_player_index: int) -> bool:
	if game_state.ships.is_empty():
		return false
	for ship: Dictionary in game_state.ships:
		if not ship.get("is_destroyed", false):
			return false
	return true
