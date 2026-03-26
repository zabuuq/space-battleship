extends Control

## EndGame
## Post-match results screen. Shows Victory or Defeat based on the outcome
## stored in NetworkManager.last_match_result.
## "Play Again" returns to the Lobby to start a new match.
## "Main Menu" disconnects from the server and returns to MainMenu.
## Issues: #53 Create end-game results screen, #54 Add restart or return-to-menu flow.


func _ready() -> void:
	var result: Dictionary = NetworkManager.last_match_result
	if result.is_empty():
		# Arrived here without a recorded result (e.g. dev shortcut button).
		if has_node("%ResultLabel"):
			(%ResultLabel as Label).text = "Game Over"
		return
	var headline := "Victory!" if result.get("won", false) else "Defeat"
	if has_node("%ResultLabel"):
		(%ResultLabel as Label).text = headline


func _on_play_again_button_pressed() -> void:
	NetworkManager.last_match_result = {}
	get_tree().change_scene_to_file("res://src/client/scenes/Lobby.tscn")


func _on_main_menu_button_pressed() -> void:
	NetworkManager.last_match_result = {}
	NetworkManager.disconnect_from_server()
	get_tree().change_scene_to_file("res://src/client/scenes/MainMenu.tscn")
