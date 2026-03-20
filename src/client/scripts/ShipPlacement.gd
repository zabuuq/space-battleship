extends Control

## ShipPlacement
## Placeholder for the ship placement phase. Navigates to Battle on Ready.


func _on_ready_button_pressed() -> void:
	get_tree().change_scene_to_file("res://src/client/scenes/Battle.tscn")


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://src/client/scenes/Lobby.tscn")
