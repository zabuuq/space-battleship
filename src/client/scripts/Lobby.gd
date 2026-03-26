extends Control

## Lobby
## Handles lobby creation and joining using codes supplied by the relay server.
## Issue #40 – Create lobby code match flow.
##
## Expected scene nodes (add in Godot editor):
##   %PlayerNameInput   – LineEdit for the player's display name
##   %LobbyCodeInput    – LineEdit to enter a lobby code when joining
##   %LobbyCodeLabel    – Label to display the generated lobby code
##   %StatusLabel       – Label for connection / waiting messages
##   %CreateButton      – Button to create a new lobby
##   %JoinButton        – Button to join an existing lobby
##   %BackButton        – Button to return to the main menu

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var _player_name := ""
var _player_index := -1

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------


func _ready() -> void:
	NetworkManager.connected_to_server.connect(_on_connected)
	NetworkManager.disconnected_from_server.connect(_on_disconnected)
	NetworkManager.message_received.connect(_on_message_received)
	NetworkManager.connect_to_server()


func _exit_tree() -> void:
	NetworkManager.message_received.disconnect(_on_message_received)


# ---------------------------------------------------------------------------
# Button handlers
# ---------------------------------------------------------------------------


func _on_create_button_pressed() -> void:
	_player_name = _get_player_name()
	if _player_name.is_empty():
		_set_status("Enter a player name first.")
		return
	_set_status("Connecting…")
	NetworkManager.send_create_lobby(_player_name)


func _on_join_button_pressed() -> void:
	_player_name = _get_player_name()
	if _player_name.is_empty():
		_set_status("Enter a player name first.")
		return
	var code := _get_lobby_code_input()
	if code.is_empty():
		_set_status("Enter a lobby code.")
		return
	_set_status("Joining lobby %s…" % code)
	NetworkManager.send_join_lobby(code, _player_name)


func _on_back_button_pressed() -> void:
	NetworkManager.disconnect_from_server()
	get_tree().change_scene_to_file("res://src/client/scenes/MainMenu.tscn")


# ---------------------------------------------------------------------------
# NetworkManager signal handlers
# ---------------------------------------------------------------------------


func _on_connected() -> void:
	_set_status("Connected. Create or join a lobby.")


func _on_disconnected() -> void:
	_set_status("Disconnected from server.")


func _on_message_received(msg: Dictionary) -> void:
	match msg.get("type", ""):
		"lobby_created":
			_player_index = msg.get("player_index", 0)
			var code: String = msg.get("lobby_code", "")
			_show_lobby_code(code)
			_set_status("Lobby created. Waiting for opponent…")
		"lobby_joined":
			_player_index = msg.get("player_index", 1)
			_set_status("Joined lobby. Waiting for game to start…")
		"player_joined":
			_set_status("Opponent connected! Starting…")
			_start_game()
		"error":
			_set_status("Error: %s" % msg.get("error", "unknown"))


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


func _get_player_name() -> String:
	if has_node("%PlayerNameInput"):
		return (%PlayerNameInput as LineEdit).text.strip_edges()
	return "Player"


func _get_lobby_code_input() -> String:
	if has_node("%LobbyCodeInput"):
		return (%LobbyCodeInput as LineEdit).text.strip_edges().to_upper()
	return ""


func _show_lobby_code(code: String) -> void:
	if has_node("%LobbyCodeLabel"):
		(%LobbyCodeLabel as Label).text = "Lobby code: %s" % code


func _set_status(text: String) -> void:
	if has_node("%StatusLabel"):
		(%StatusLabel as Label).text = text


func _start_game() -> void:
	get_tree().change_scene_to_file("res://src/client/scenes/ShipPlacement.tscn")
