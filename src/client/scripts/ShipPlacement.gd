extends Control

## ShipPlacement
## Manages the ship placement phase: guides the player through placing each
## ship in the fleet onto the battlefield grid, then transitions to Battle.
## Issue #12 – Implement ship placement UI.
## Issue #13 – Add ship rotation during placement.
## Issue #14 – Prevent overlapping ship placement.

const ShipDefs = preload("res://src/shared/ShipDefs.gd")
const GameState = preload("res://src/shared/GameState.gd")
const PlacementValidator = preload("res://src/shared/PlacementValidator.gd")

## One colour per fleet slot — matched by ship index.
const SHIP_COLORS: Array[Color] = [
	Color(0.2, 0.6, 1.0, 0.7),
	Color(1.0, 0.5, 0.1, 0.7),
	Color(0.2, 0.8, 0.3, 0.7),
	Color(0.9, 0.2, 0.2, 0.7),
	Color(0.7, 0.3, 0.9, 0.7),
]

var _ship_defs := ShipDefs.new()
var _game_state := GameState.new()
var _current_index: int = 0
var _orientation: Vector2i = Vector2i(1, 0)  # horizontal by default

@onready var _grid_ui: Control = %BattlefieldGridUI
@onready var _status_label: Label = %StatusLabel
@onready var _ship_list_container: VBoxContainer = %ShipListContainer
@onready var _ready_button: Button = %ReadyButton
@onready var _rotate_button: Button = %RotateButton


func _ready() -> void:
	_grid_ui.cell_selected.connect(_on_cell_selected)
	_grid_ui.cell_hovered.connect(_on_cell_hovered)
	_ready_button.disabled = true
	_rebuild_ship_list()
	_update_status()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			_toggle_rotation()


func _on_cell_hovered(pos: Vector2i) -> void:
	if _current_index >= ShipDefs.FLEET_COMPOSITION.size():
		return
	var length := _current_ship_length()
	var cells := PlacementValidator.get_ship_cells(pos, _orientation, length)
	var valid := PlacementValidator.is_not_overlapping(_game_state.grid, pos, _orientation, length)
	_grid_ui.set_preview_cells(cells, valid)


func _on_cell_selected(pos: Vector2i) -> void:
	if _current_index >= ShipDefs.FLEET_COMPOSITION.size():
		return
	var length := _current_ship_length()
	if not PlacementValidator.is_not_overlapping(_game_state.grid, pos, _orientation, length):
		return
	var type := ShipDefs.FLEET_COMPOSITION[_current_index]
	var ship := _ship_defs.create_ship_dict(_current_index, type, pos, _orientation)
	_game_state.add_ship(ship)
	_current_index += 1
	_rebuild_ship_list()
	_update_status()
	_refresh_grid_overlay()
	if _current_index >= ShipDefs.FLEET_COMPOSITION.size():
		_ready_button.disabled = false
		_grid_ui.set_preview_cells([])


func _current_ship_length() -> int:
	if _current_index >= ShipDefs.FLEET_COMPOSITION.size():
		return 0
	return ShipDefs.DEFINITIONS[ShipDefs.FLEET_COMPOSITION[_current_index]]["length"]


func _refresh_grid_overlay() -> void:
	var cells: Dictionary = {}
	for ship in _game_state.ships:
		var color: Color = SHIP_COLORS[ship["id"] % SHIP_COLORS.size()]
		for cell in PlacementValidator.get_ship_cells(ship["position"], ship["facing"], ship["length"]):
			cells[cell] = color
	_grid_ui.set_placed_ship_cells(cells)


func _rebuild_ship_list() -> void:
	for child in _ship_list_container.get_children():
		child.queue_free()
	for i in range(ShipDefs.FLEET_COMPOSITION.size()):
		var type: String = ShipDefs.FLEET_COMPOSITION[i]
		var length: int = ShipDefs.DEFINITIONS[type]["length"]
		var prefix: String
		if i < _current_index:
			prefix = "[placed] "
		elif i == _current_index:
			prefix = "[next]   "
		else:
			prefix = "         "
		var lbl := Label.new()
		lbl.text = "%s%s  (len %d)" % [prefix, type.capitalize(), length]
		_ship_list_container.add_child(lbl)


func _update_status() -> void:
	if _current_index >= ShipDefs.FLEET_COMPOSITION.size():
		_status_label.text = "All ships placed.\nPress Ready!"
		return
	var type: String = ShipDefs.FLEET_COMPOSITION[_current_index]
	var length: int = ShipDefs.DEFINITIONS[type]["length"]
	var dir: String = "Horizontal" if _orientation == Vector2i(1, 0) else "Vertical"
	_status_label.text = "Place: %s\nLength: %d\nDir: %s\nClick grid to place" % [type.capitalize(), length, dir]


func _toggle_rotation() -> void:
	if _current_index >= ShipDefs.FLEET_COMPOSITION.size():
		return
	_orientation = Vector2i(0, 1) if _orientation == Vector2i(1, 0) else Vector2i(1, 0)
	_update_status()
	# Refresh preview at the current hover cell if available
	_grid_ui.set_preview_cells([])


func _on_rotate_button_pressed() -> void:
	_toggle_rotation()


func _on_ready_button_pressed() -> void:
	get_tree().change_scene_to_file("res://src/client/scenes/Battle.tscn")


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://src/client/scenes/Lobby.tscn")
