extends Control

## Battle
## Drives the combat phase: sends player actions to the relay server and
## applies confirmed updates broadcast by the server.
## Issues: #43 Synchronise turn actions over the network,
##         #46 Build tabbed battlefield interface,
##         #53 Create end-game results screen.
##
## Expected scene nodes:
##   %TurnLabel            – Label showing current turn number
##   %StatusLabel          – Label showing turn info / messages
##   %EndTurnButton        – Button to end the player's turn
##   %BattleTabContainer   – TabContainer with fleet and enemy tabs
##   %PlayerGrid           – BattlefieldGridUI for the player's fleet
##   %EnemyGrid            – BattlefieldGridUI for the enemy fog-of-war
##   %ShipActionContainer  – HBoxContainer populated with per-ship panels
##   %ActionHintLabel      – Label guiding the player on next input

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var _my_player_index := 0
var _game_state: GameState = GameState.new()
var _is_my_turn := false

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------


func _ready() -> void:
	NetworkManager.message_received.connect(_on_message_received)
	NetworkManager.disconnected_from_server.connect(_on_disconnected)


func _exit_tree() -> void:
	if NetworkManager.message_received.is_connected(_on_message_received):
		NetworkManager.message_received.disconnect(_on_message_received)
	if NetworkManager.disconnected_from_server.is_connected(_on_disconnected):
		NetworkManager.disconnected_from_server.disconnect(_on_disconnected)


# ---------------------------------------------------------------------------
# Public API – called by UI action controls
# ---------------------------------------------------------------------------


## Sends a move_forward action for the given ship.
func submit_move_forward(ship_id: int, steps: int) -> void:
	if not _is_my_turn:
		return
	NetworkManager.send_perform_action(ship_id, "move_forward", {"steps": steps})


## Sends a turn action for the given ship.
func submit_turn(ship_id: int, direction: String) -> void:
	if not _is_my_turn:
		return
	NetworkManager.send_perform_action(ship_id, "turn", {"direction": direction})


## Sends a probe action for the given ship.
func submit_probe(ship_id: int, center_x: int, center_y: int) -> void:
	if not _is_my_turn:
		return
	NetworkManager.send_perform_action(ship_id, "probe", {"x": center_x, "y": center_y})


## Sends a missile action for the given ship.
func submit_missile(ship_id: int, target_x: int, target_y: int) -> void:
	if not _is_my_turn:
		return
	NetworkManager.send_perform_action(ship_id, "missile", {"x": target_x, "y": target_y})


## Ends the current player's turn and sends the latest state snapshot.
func submit_end_turn() -> void:
	if not _is_my_turn:
		return
	_is_my_turn = false
	NetworkManager.send_end_turn(_game_state.to_dict())
	_set_status("Waiting for opponent…")


# ---------------------------------------------------------------------------
# NetworkManager signal handlers
# ---------------------------------------------------------------------------


func _on_message_received(msg: Dictionary) -> void:
	match msg.get("type", ""):
		"game_state_update":
			_apply_game_state(msg.get("state", {}))
		"action_received":
			_on_action_received(msg)
		"turn_ended":
			_on_turn_ended(msg)
		"player_disconnected":
			_on_opponent_disconnected()
		"game_over":
			_on_game_over(msg)


func _on_disconnected() -> void:
	_set_status("Lost connection to server.")


# ---------------------------------------------------------------------------
# State application
# ---------------------------------------------------------------------------


func _apply_game_state(state: Dictionary) -> void:
	_game_state.from_dict(state)
	_is_my_turn = _game_state.current_turn == _my_player_index
	_set_status("Your turn." if _is_my_turn else "Opponent's turn.")


func _on_action_received(msg: Dictionary) -> void:
	# The server has validated the opponent's action; apply it locally.
	var action: String = msg.get("action", "")
	var params: Dictionary = msg.get("params", {})
	var ship_id: int = msg.get("ship_id", -1)
	_set_status("Opponent used %s on ship %d" % [action, ship_id])
	_apply_opponent_action(action, ship_id, params)


func _apply_opponent_action(action: String, ship_id: int, params: Dictionary) -> void:
	match action:
		"move_forward":
			MovementRules.move_forward(_game_state, ship_id, params.get("steps", 1))
		"turn":
			var dir: String = params.get("direction", "left")
			var facing: Vector2i = MovementRules.TURN_LEFT if dir == "left" else MovementRules.TURN_RIGHT
			MovementRules.turn_ship(_game_state, ship_id, facing)
		"probe":
			ProbeRules.fire_probe(_game_state, 1 - _my_player_index, Vector2i(params.get("x", 0), params.get("y", 0)))
		"missile":
			MissileRules.fire_missile(
				_game_state, 1 - _my_player_index, Vector2i(params.get("x", 0), params.get("y", 0))
			)


func _on_turn_ended(_msg: Dictionary) -> void:
	_is_my_turn = true
	_set_status("Your turn.")


func _on_opponent_disconnected() -> void:
	_set_status("Opponent disconnected. You win!")
	NetworkManager.last_match_result = {"won": true, "winner": _my_player_index}
	get_tree().change_scene_to_file("res://src/client/scenes/EndGame.tscn")


func _on_game_over(msg: Dictionary) -> void:
	var winner: int = msg.get("winner", -1)
	var won := winner == _my_player_index
	NetworkManager.last_match_result = {"won": won, "winner": winner}
	if won:
		_set_status("You win!")
	else:
		_set_status("You lose.")
	get_tree().change_scene_to_file("res://src/client/scenes/EndGame.tscn")


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


func _set_status(text: String) -> void:
	if has_node("%StatusLabel"):
		(%StatusLabel as Label).text = text


## Triggered by the End Turn button in the status bar.
func _on_end_turn_button_pressed() -> void:
	submit_end_turn()
	if has_node("%EndTurnButton"):
		(%EndTurnButton as Button).disabled = true


## Called when the player switches between the fleet and enemy tabs.
func _on_tab_changed(_tab_index: int) -> void:
	pass
