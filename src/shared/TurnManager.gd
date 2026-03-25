extends RefCounted

## TurnManager
## Manages turn sequencing for two-player matches.
## Tracks whose turn it is, advances turns, and coordinates end-of-turn effects.
## Issue #35 – Implement turn manager.

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
# Turn lifecycle (#35)
# ---------------------------------------------------------------------------


## Prepares the manager for the start of a new turn.
## Must be called once at the beginning of each player's turn.
func begin_turn(_game_state: Object) -> void:
	pass


## Ends the active player's turn and passes control to the opponent.
## Call begin_turn after this to start the next player's turn.
func end_turn(game_state: Object) -> void:
	game_state.next_turn()
