extends RefCounted

## TurnManager
## Manages turn sequencing for two-player matches.
## Tracks whose turn it is, advances turns, and coordinates end-of-turn effects.
## Issue #35 – Implement turn manager.
## Issue #36 – Track per-ship actions each turn.

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


## Ends the active player's turn and passes control to the opponent.
## Call begin_turn after this to start the next player's turn.
func end_turn(game_state: Object) -> void:
	game_state.next_turn()
