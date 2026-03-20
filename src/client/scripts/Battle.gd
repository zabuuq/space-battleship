extends Control

## Battle
## Placeholder for the battle phase. Navigates to EndGame on End Battle.


func _on_end_battle_button_pressed() -> void:
	get_tree().change_scene_to_file("res://src/client/scenes/EndGame.tscn")
