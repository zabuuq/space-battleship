extends Control

## BattlefieldGridUI
## Renders the 120x12 grid and handles screen-to-grid translation.

signal cell_selected(grid_pos: Vector2i)

const GRID_WIDTH = 120
const GRID_HEIGHT = 12
const CELL_SIZE = 16

## The color of the grid lines.
@export var grid_color: Color = Color(0.3, 0.3, 0.3, 1.0)
## The color of the background.
@export var bg_color: Color = Color(0.05, 0.05, 0.1, 1.0)
## The color of the selection highlight.
@export var selection_color: Color = Color(1.0, 1.0, 0.0, 0.3)

var selected_cell: Vector2i = Vector2i(-1, -1)


func _ready() -> void:
	custom_minimum_size = Vector2(GRID_WIDTH * CELL_SIZE, GRID_HEIGHT * CELL_SIZE)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var grid_pos = screen_to_grid(event.position)
			if grid_pos != Vector2i(-1, -1):
				select_cell(grid_pos)


func _draw() -> void:
	# Draw background
	draw_rect(Rect2(Vector2.ZERO, size), bg_color)

	# Draw selection highlight
	if selected_cell != Vector2i(-1, -1):
		var rect = Rect2(grid_to_screen(selected_cell), Vector2(CELL_SIZE, CELL_SIZE))
		draw_rect(rect, selection_color)

	# Draw vertical lines
	for x in range(GRID_WIDTH + 1):
		var start = Vector2(x * CELL_SIZE, 0)
		var end = Vector2(x * CELL_SIZE, GRID_HEIGHT * CELL_SIZE)
		draw_line(start, end, grid_color)

	# Draw horizontal lines
	for y in range(GRID_HEIGHT + 1):
		var start = Vector2(0, y * CELL_SIZE)
		var end = Vector2(GRID_WIDTH * CELL_SIZE, y * CELL_SIZE)
		draw_line(start, end, grid_color)


## Translates a local screen position to grid coordinates.
## Returns a Vector2i in grid space, or Vector2i(-1, -1) if out of bounds.
func screen_to_grid(local_pos: Vector2) -> Vector2i:
	if local_pos.x < 0 or local_pos.y < 0:
		return Vector2i(-1, -1)

	var grid_x = int(local_pos.x / CELL_SIZE)
	var grid_y = int(local_pos.y / CELL_SIZE)

	if grid_x >= GRID_WIDTH or grid_y >= GRID_HEIGHT:
		return Vector2i(-1, -1)

	return Vector2i(grid_x, grid_y)


## Updates the selection and emits the signal.
func select_cell(grid_pos: Vector2i) -> void:
	if grid_pos != selected_cell:
		selected_cell = grid_pos
		queue_redraw()
		cell_selected.emit(grid_pos)


## Translates a grid coordinate back to its top-left local screen position.
func grid_to_screen(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * CELL_SIZE, grid_pos.y * CELL_SIZE)


## Returns the center screen position of a grid cell.
func get_cell_center(grid_pos: Vector2i) -> Vector2:
	return grid_to_screen(grid_pos) + Vector2(CELL_SIZE / 2.0, CELL_SIZE / 2.0)
