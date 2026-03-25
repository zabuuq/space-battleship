extends RefCounted

## TurnManager
## Manages turn sequencing for two-player matches.
## Tracks whose turn it is, advances turns, and coordinates end-of-turn effects.
## Issue #35 – Implement turn manager.
## Issue #36 – Track per-ship actions each turn.
## Issue #37 – Prevent illegal extra actions.
## Issue #38 – Implement end-turn flow.

const ProbeRules = preload("res://src/shared/ProbeRules.gd")

# ---------------------------------------------------------------------------
# Action type constants
# ---------------------------------------------------------------------------

const ACTION_MOVE := "move"
const ACTION_PROBE := "probe"
const ACTION_MISSILE := "missile"
const ACTION_PROBE_MASK := "probe_mask"

# ---------------------------------------------------------------------------
# Result constants
# ---------------------------------------------------------------------------

const RESULT_OK := "ok"
const RESULT_ALREADY_ACTED := "already_acted"
const RESULT_WRONG_TURN := "wrong_turn"
const RESULT_GAME_OVER := "game_over"
const RESULT_NOT_COMBAT := "not_combat"

# ---------------------------------------------------------------------------
# Action tracking (#36)
# ---------------------------------------------------------------------------

## Tracks which ships have consumed their one action this turn.
## Key: ship_id (int) → true when the ship has acted.
var _actions_used: Dictionary = {}

# ---------------------------------------------------------------------------
# Turn lifecycle (#35)
# ---------------------------------------------------------------------------


## Resets per-ship action budgets for the start of a new turn.
## Must be called once at the beginning of each player's turn.
func begin_turn(_game_state: Object) -> void:
	_actions_used.clear()


## Returns true if the given ship has not yet used its action this turn.
func can_ship_act(ship_id: int) -> bool:
	return not _actions_used.get(ship_id, false)


## Records that ship_id has spent its action this turn.
## Validates turn ownership and action budget before recording.
## Returns RESULT_OK on success, or an error constant on failure.
func record_action(game_state: Object, player_index: int, ship_id: int) -> String:
	if game_state.turn_phase == "game_over":
		return RESULT_GAME_OVER
	if game_state.turn_phase != "combat":
		return RESULT_NOT_COMBAT
	if game_state.current_turn != player_index:
		return RESULT_WRONG_TURN
	if _actions_used.get(ship_id, false):
		return RESULT_ALREADY_ACTED
	_actions_used[ship_id] = true
	return RESULT_OK


## Ends the active player's turn and passes control to the opponent.
## Ticks all probe-mask cooldowns before advancing the turn counter.
## Call begin_turn after this to start the next player's turn.
func end_turn(game_state: Object) -> void:
	for ship in game_state.ships:
		ProbeRules.tick_probe_mask(ship)
	game_state.next_turn()
	_actions_used.clear()
