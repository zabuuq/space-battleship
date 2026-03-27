extends Control

## Battle
## Drives the combat phase: sends player actions to the relay server and
## applies confirmed updates broadcast by the server.
## Issues: #43 Synchronise turn actions over the network,
##         #46 Build tabbed battlefield interface,
##         #47 Render player battlefield state,
##         #48 Render enemy fog-of-war battlefield,
##         #49 Add ship action selection panel,
##         #50 Add turn and status indicators,
##         #53 Create end-game results screen.
##
## Expected scene nodes:
##   %TurnLabel            – Label showing current turn number
##   %StatusLabel          – Label showing turn info / messages
##   %EndTurnButton        – Button to end the player's turn (enabled only on player's turn)
##   %BattleTabContainer   – TabContainer (index 1 = Enemy tab)
##   %PlayerGrid           – BattlefieldGridUI for the player's fleet
##   %EnemyGrid            – BattlefieldGridUI for enemy fog-of-war
##   %ShipActionContainer  – HBoxContainer populated with per-ship panels
##   %ActionHintLabel      – Label guiding the player on next input

## One colour per fleet slot — matched by ship id modulo palette size.
const SHIP_COLORS: Array[Color] = [
	Color(0.2, 0.6, 1.0, 0.7),
	Color(1.0, 0.5, 0.1, 0.7),
	Color(0.2, 0.8, 0.3, 0.7),
	Color(0.9, 0.2, 0.2, 0.7),
	Color(0.7, 0.3, 0.9, 0.7),
]

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var _my_player_index := 0
var _game_state: GameState = GameState.new()
var _is_my_turn := false
var _pending_action: Dictionary = {}  # {ship_id, action} while awaiting grid click

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------


func _ready() -> void:
	NetworkManager.message_received.connect(_on_message_received)
	NetworkManager.disconnected_from_server.connect(_on_disconnected)
	if has_node("%EnemyGrid"):
		var eg := %EnemyGrid as Control
		eg.cell_selected.connect(_on_enemy_grid_cell_selected)
		eg.cell_hovered.connect(
			func(pos: Vector2i) -> void:
				if _pending_action.is_empty():
					return
				var cells: Array[Vector2i] = (
					ProbeRules.get_probe_cells(pos) if _pending_action.get("action") == "probe" else [pos]
				)
				eg.set_action_preview(cells)
		)


func _exit_tree() -> void:
	if NetworkManager.message_received.is_connected(_on_message_received):
		NetworkManager.message_received.disconnect(_on_message_received)
	if NetworkManager.disconnected_from_server.is_connected(_on_disconnected):
		NetworkManager.disconnected_from_server.disconnect(_on_disconnected)


# ---------------------------------------------------------------------------
# Action submission
# ---------------------------------------------------------------------------


## Ends the current player's turn and sends the latest state snapshot.
func submit_end_turn() -> void:
	if not _is_my_turn:
		return
	_is_my_turn = false
	_pending_action = {}
	NetworkManager.send_end_turn(_game_state.to_dict())
	_set_status("Waiting for opponent…")


## Sends a validated action to the server. Only called when it is the player's turn.
func _send_ship_action(ship_id: int, action: String, params: Dictionary) -> void:
	if not _is_my_turn:
		return
	NetworkManager.send_perform_action(ship_id, action, params)


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
	if has_node("%EndTurnButton"):
		(%EndTurnButton as Button).disabled = not _is_my_turn
	_refresh_player_grid()
	_refresh_enemy_grid()
	_build_action_panel()


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
	_pending_action = {}
	_set_status("Your turn.")
	if has_node("%EndTurnButton"):
		(%EndTurnButton as Button).disabled = false
	_build_action_panel()


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
# Grid rendering
# ---------------------------------------------------------------------------


func _set_status(text: String) -> void:
	if has_node("%StatusLabel"):
		(%StatusLabel as Label).text = text
	if has_node("%TurnLabel"):
		(%TurnLabel as Label).text = "Your turn" if _is_my_turn else "Opp's turn"


## Redraws the player's fleet grid from the current game state.
## Ships are shown in palette colours; enemy hits and misses are marked.
func _refresh_player_grid() -> void:
	if not has_node("%PlayerGrid"):
		return
	var grid_ui := %PlayerGrid as Control
	var ship_cells: Dictionary = {}
	for ship in _game_state.ships:
		var color: Color = (
			Color(0.35, 0.35, 0.35, 0.7)
			if ship.get("is_destroyed", false)
			else SHIP_COLORS[ship["id"] % SHIP_COLORS.size()]
		)
		for i in range(ship.get("length", 0)):
			var cell: Vector2i = ship["position"] + ship["facing"] * i
			ship_cells[cell] = color
	grid_ui.set_placed_ship_cells(ship_cells)
	var state_cells: Dictionary = {}
	for missile in _game_state.missile_history:
		if missile.get("player", -1) != _my_player_index:
			state_cells[missile["position"]] = missile["result"]
	grid_ui.set_state_cells(state_cells)


## Redraws the enemy fog-of-war grid from missile and probe history.
## Only cells hit, missed, or revealed by the local player's actions are shown.
func _refresh_enemy_grid() -> void:
	if not has_node("%EnemyGrid"):
		return
	var grid_ui := %EnemyGrid as Control
	var state_cells: Dictionary = {}
	for missile in _game_state.missile_history:
		if missile.get("player", -1) == _my_player_index:
			state_cells[missile["position"]] = missile["result"]
	for probe in _game_state.probe_history:
		if probe.get("player", -1) == _my_player_index:
			for pos in probe.get("result", []):
				if pos not in state_cells:
					state_cells[pos] = "revealed"
	grid_ui.set_state_cells(state_cells)


# ---------------------------------------------------------------------------
# Action panel
# ---------------------------------------------------------------------------


## Rebuilds the ship action panel for the current turn. Clears buttons when
## it is not the player's turn so the panel does not show stale controls.
func _build_action_panel() -> void:
	if not has_node("%ShipActionContainer"):
		return
	var container := %ShipActionContainer as HBoxContainer
	for child in container.get_children():
		child.queue_free()
	if not _is_my_turn:
		return
	for ship in _game_state.ships:
		if ship.get("is_destroyed", false):
			continue
		var sid: int = ship["id"]
		var stype: String = ship.get("type", "")
		var card := VBoxContainer.new()
		var name_lbl := Label.new()
		name_lbl.text = "%s (HP:%d)" % [stype.capitalize(), ship.get("health", 0)]
		card.add_child(name_lbl)
		for pair in [
			["Fwd", "move_forward"],
			["Left", "turn_left"],
			["Right", "turn_right"],
			["Probe", "probe"],
			["Missile", "missile"]
		]:
			var btn := Button.new()
			btn.text = pair[0]
			btn.pressed.connect(_on_ship_action_selected.bind(sid, pair[1]))
			card.add_child(btn)
		container.add_child(card)


## Handles a ship action button press. Immediate actions are sent to the server;
## targeting actions (probe, missile) wait for a grid click.
func _on_ship_action_selected(ship_id: int, action: String) -> void:
	if not _is_my_turn:
		return
	if action in ["probe", "missile"]:
		_pending_action = {"ship_id": ship_id, "action": action}
		if has_node("%BattleTabContainer"):
			(%BattleTabContainer as TabContainer).current_tab = 1
		if has_node("%ActionHintLabel"):
			(%ActionHintLabel as Label).text = "Click the enemy grid to target your %s." % action
		return
	_pending_action = {}
	if action == "move_forward":
		_send_ship_action(ship_id, "move_forward", {"steps": 1})
	elif action in ["turn_left", "turn_right"]:
		var dir := "left" if action == "turn_left" else "right"
		_send_ship_action(ship_id, "turn", {"direction": dir})


## Called when the player clicks the enemy grid. Confirms a pending targeting action.
func _on_enemy_grid_cell_selected(pos: Vector2i) -> void:
	if _pending_action.is_empty():
		return
	var ship_id: int = _pending_action.get("ship_id", -1)
	var action: String = _pending_action.get("action", "")
	_pending_action = {}
	_send_ship_action(ship_id, action, {"x": pos.x, "y": pos.y})
	if has_node("%EnemyGrid"):
		(%EnemyGrid as Control).set_action_preview([])
	if has_node("%ActionHintLabel"):
		(%ActionHintLabel as Label).text = "Action sent."


# ---------------------------------------------------------------------------
# Toolbar handlers
# ---------------------------------------------------------------------------


## Triggered by the End Turn button in the status bar.
func _on_end_turn_button_pressed() -> void:
	submit_end_turn()
	if has_node("%EndTurnButton"):
		(%EndTurnButton as Button).disabled = true


## Called when the player switches between the fleet and enemy tabs.
func _on_tab_changed(_tab_index: int) -> void:
	pass
