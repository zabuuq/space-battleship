extends "res://addons/gut/test.gd"

const GameState = preload("res://src/shared/GameState.gd")


func test_initialization():
	var state = GameState.new()
	assert_not_null(state.grid, "Grid should be initialized")
	assert_eq(state.ships.size(), 0, "Should have no ships initially")
	assert_eq(state.current_turn, 0, "Initial turn should be 0")
	assert_eq(state.turn_phase, "placement", "Initial phase should be placement")


func test_add_ship():
	var state = GameState.new()
	var ship = {
		"id": 1,
		"type": "Carrier",
		"position": Vector2i(0, 0),
		"facing": Vector2i(1, 0),
		"length": 5,
		"health": 5,
		"is_destroyed": false
	}
	state.add_ship(ship)
	assert_eq(state.ships.size(), 1, "Should have 1 ship")
	assert_eq(state.ships[0]["id"], 1, "Ship ID should match")


func test_update_ship_health():
	var state = GameState.new()
	var ship = {
		"id": 1,
		"type": "Carrier",
		"position": Vector2i(0, 0),
		"facing": Vector2i(1, 0),
		"length": 5,
		"health": 5,
		"is_destroyed": false
	}
	state.add_ship(ship)
	state.update_ship_health(1, 2)
	assert_eq(state.ships[0]["health"], 3, "Ship health should be updated")
	state.update_ship_health(1, 3)
	assert_eq(state.ships[0]["health"], 0, "Ship health should be 0")
	assert_true(state.ships[0]["is_destroyed"], "Ship should be destroyed")


func test_record_probe():
	var state = GameState.new()
	var pos = Vector2i(5, 5)
	state.record_probe(0, pos, "hit")
	assert_eq(state.probe_history.size(), 1, "Probe history should have 1 entry")
	assert_eq(state.probe_history[0]["position"], pos, "Probe position should match")
	assert_eq(state.probe_history[0]["result"], "hit", "Probe result should match")


func test_record_missile():
	var state = GameState.new()
	var pos = Vector2i(10, 2)
	state.record_missile(1, pos, "miss")
	assert_eq(state.missile_history.size(), 1, "Missile history should have 1 entry")
	assert_eq(state.missile_history[0]["position"], pos, "Missile position should match")
	assert_eq(state.missile_history[0]["result"], "miss", "Missile result should match")


func test_add_ship_grid_sync():
	var state = GameState.new()
	var ship = {
		"id": 1,
		"type": "Carrier",
		"position": Vector2i(0, 0),
		"facing": Vector2i(1, 0),
		"length": 3,
		"health": 3,
		"is_destroyed": false
	}
	state.add_ship(ship)

	assert_eq(state.grid.get_cell_data(Vector2i(0, 0))["occupied_by"], 1, "Cell (0,0) should be occupied by ship 1")
	assert_eq(state.grid.get_cell_data(Vector2i(1, 0))["occupied_by"], 1, "Cell (1,0) should be occupied by ship 1")
	assert_eq(state.grid.get_cell_data(Vector2i(2, 0))["occupied_by"], 1, "Cell (2,0) should be occupied by ship 1")
	assert_null(state.grid.get_cell_data(Vector2i(3, 0))["occupied_by"], "Cell (3,0) should be null")


func test_record_missile_grid_sync():
	var state = GameState.new()
	var pos = Vector2i(5, 5)
	state.record_missile(0, pos, "hit")
	assert_eq(state.grid.get_cell_data(pos)["state"], "hit", "Grid cell state should be updated to hit")

	state.record_missile(1, Vector2i(6, 6), "miss")
	assert_eq(state.grid.get_cell_data(Vector2i(6, 6))["state"], "miss", "Grid cell state should be updated to miss")


func test_serialization():
	var state = GameState.new()
	var ship = {
		"id": 1,
		"type": "Carrier",
		"position": Vector2i(0, 0),
		"facing": Vector2i(1, 0),
		"length": 3,
		"health": 3,
		"is_destroyed": false
	}
	state.add_ship(ship)
	state.record_missile(0, Vector2i(5, 5), "miss")
	state.next_turn()
	state.set_phase("combat")

	var data = state.to_dict()
	assert_eq(data["ships"].size(), 1, "Serialized ships size")
	assert_eq(data["current_turn"], 1, "Serialized current turn")
	assert_eq(data["turn_phase"], "combat", "Serialized turn phase")

	var new_state = GameState.new()
	new_state.from_dict(data)
	assert_eq(new_state.ships.size(), 1, "Deserialized ships size")
	assert_eq(new_state.current_turn, 1, "Deserialized current turn")
	assert_eq(new_state.turn_phase, "combat", "Deserialized turn phase")
	assert_eq(new_state.grid.get_cell_data(Vector2i(0, 0))["occupied_by"], 1, "Grid sync after deserialization")
	assert_eq(
		new_state.grid.get_cell_data(Vector2i(5, 5))["state"], "miss", "Grid missile state sync after deserialization"
	)


func test_next_turn():
	var state = GameState.new()
	assert_eq(state.current_turn, 0, "Initial turn should be 0")
	state.next_turn()
	assert_eq(state.current_turn, 1, "Turn should be 1")
	state.next_turn()
	assert_eq(state.current_turn, 0, "Turn should be 0 again")


func test_set_phase():
	var state = GameState.new()
	state.set_phase("combat")
	assert_eq(state.turn_phase, "combat", "Phase should be combat")
