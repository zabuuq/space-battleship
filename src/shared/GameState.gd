extends RefCounted

## GameState
## The high-level container representing the full match state.
## Coordinates between ship data, turn state, and the battlefield grid.
## Issues: #51 Detect full fleet destruction, #52 Win and loss state handling.

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

# Victory state – set when turn_phase transitions to "game_over"
var winner: int = -1  # player index of the winner, or -1 if game is still in progress

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


## Transitions the game to game_over and records the winner.
## Issue #52 – Implement win and loss state handling.
func set_game_over(winning_player: int) -> void:
	turn_phase = "game_over"
	winner = winning_player


## Returns true when every ship in this state's fleet has been destroyed.
## Issue #51 – Detect full fleet destruction.
func is_fleet_destroyed() -> bool:
	if ships.is_empty():
		return false
	for ship: Dictionary in ships:
		if not ship.get("is_destroyed", false):
			return false
	return true


## Serializes the game state to a dictionary.
func to_dict() -> Dictionary:
	return {
		"ships": ships,
		"current_turn": current_turn,
		"turn_phase": turn_phase,
		"winner": winner,
		"probe_history": probe_history,
		"missile_history": missile_history
	}


## Deserializes the game state from a dictionary.
func from_dict(data: Dictionary) -> void:
	ships.assign(data.get("ships", []))
	current_turn = data.get("current_turn", 0)
	turn_phase = data.get("turn_phase", "placement")
	winner = data.get("winner", -1)
	probe_history.assign(data.get("probe_history", []))
	missile_history.assign(data.get("missile_history", []))

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

	for probe in probe_history:
		var detected: Variant = probe.get("result", [])
		for pos in detected:
			grid.set_cell_state(pos, "revealed")

	for missile in missile_history:
		grid.set_cell_state(missile["position"], missile["result"])
