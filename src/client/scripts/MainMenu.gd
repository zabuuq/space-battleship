extends Control

## MainMenu
## Entry point for the game. Navigates to Lobby on Play.


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://src/client/scenes/Lobby.tscn")
