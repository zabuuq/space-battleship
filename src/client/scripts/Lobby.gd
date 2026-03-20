extends Control

## Lobby
## Placeholder for player matchmaking. Navigates to ShipPlacement on Start.


func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://src/client/scenes/ShipPlacement.tscn")


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://src/client/scenes/MainMenu.tscn")
