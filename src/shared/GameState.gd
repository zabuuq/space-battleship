extends RefCounted

## GameState
## The high-level container representing the full match state.
## Coordinates between ship data, turn state, and the battlefield grid.

const BattlefieldGrid = preload("res://src/shared/BattlefieldGrid.gd")

# Ship data structure:
# {
#     "id": int,
#     "type": String,
#     "position": Vector2i,
#     "facing": Vector2i,
#     "length": int,
#     "health": int,
#     "is_destroyed": bool
# }
var ships: Array[Dictionary] = []

# Battlefield grid instance
var grid: BattlefieldGrid

# Turn state
var current_turn: int = 0  # 0 or 1 for player indices
var turn_phase: String = "placement"  # placement, combat, game_over

# History of actions
var probe_history: Array[Dictionary] = []
var missile_history: Array[Dictionary] = []


func _init() -> void:
	grid = BattlefieldGrid.new()


## Adds a ship to the game state and marks it in the grid.
func add_ship(ship_data: Dictionary) -> void:
	ships.append(ship_data)
	var pos: Vector2i = ship_data.get("position", Vector2i.ZERO)
	var facing: Vector2i = ship_data.get("facing", Vector2i.ZERO)
	var length: int = ship_data.get("length", 0)
	var ship_id: int = ship_data.get("id", -1)

	for i in range(length):
		var cell_pos = pos + facing * i
		grid.set_cell_occupant(cell_pos, ship_id)


## Updates a ship's health and checks for destruction.
func update_ship_health(ship_id: int, damage: int) -> void:
	for ship in ships:
		if ship["id"] == ship_id:
			ship["health"] = max(0, ship["health"] - damage)
			if ship["health"] == 0:
				ship["is_destroyed"] = true
			break


## Records a probe result in the history.
func record_probe(player_index: int, position: Vector2i, result: Variant) -> void:
	probe_history.append({"player": player_index, "position": position, "result": result, "turn": current_turn})


## Records a missile result in the history and updates the grid.
func record_missile(player_index: int, position: Vector2i, result: String) -> void:
	missile_history.append({"player": player_index, "position": position, "result": result, "turn": current_turn})
	grid.set_cell_state(position, result)


## Switches to the next turn.
func next_turn() -> void:
	current_turn = 1 - current_turn


## Sets the current phase of the game.
func set_phase(phase: String) -> void:
	turn_phase = phase


## Serializes the game state to a dictionary.
func to_dict() -> Dictionary:
	return {
		"ships": ships,
		"current_turn": current_turn,
		"turn_phase": turn_phase,
		"probe_history": probe_history,
		"missile_history": missile_history
	}


## Deserializes the game state from a dictionary.
func from_dict(data: Dictionary) -> void:
	ships = data.get("ships", [])
	current_turn = data.get("current_turn", 0)
	turn_phase = data.get("turn_phase", "placement")
	probe_history = data.get("probe_history", [])
	missile_history = data.get("missile_history", [])

	# Rebuild grid state from ships and history
	grid._initialize_grid()
	for ship in ships:
		var pos: Vector2i = ship.get("position", Vector2i.ZERO)
		var facing: Vector2i = ship.get("facing", Vector2i.ZERO)
		var length: int = ship.get("length", 0)
		var ship_id: int = ship.get("id", -1)
		for i in range(length):
			var cell_pos = pos + facing * i
			grid.set_cell_occupant(cell_pos, ship_id)

	for missile in missile_history:
		grid.set_cell_state(missile["position"], missile["result"])
