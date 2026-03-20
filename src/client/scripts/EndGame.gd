extends Control

## EndGame
## Placeholder for post-match results. Navigates back to MainMenu on Play Again.


func _on_play_again_button_pressed() -> void:
	get_tree().change_scene_to_file("res://src/client/scenes/MainMenu.tscn")
