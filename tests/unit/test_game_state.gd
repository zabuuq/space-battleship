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


func test_serialization_with_multiple_ships():
	var state = GameState.new()
	for i in range(3):
		var ship = {
			"id": i,
			"type": "Cruiser",
			"position": Vector2i(i * 5, 0),
			"facing": Vector2i(1, 0),
			"length": 3,
			"health": 3,
			"is_destroyed": false
		}
		state.add_ship(ship)
	var data = state.to_dict()
	var new_state = GameState.new()
	new_state.from_dict(data)
	assert_eq(new_state.ships.size(), 3, "All three ships should be deserialized")
	for i in range(3):
		assert_eq(new_state.ships[i]["id"], i, "Ship id should match after round-trip")
		assert_eq(new_state.ships[i]["position"], Vector2i(i * 5, 0), "Ship position should match")
		assert_eq(new_state.ships[i]["health"], 3, "Ship health should match")


func test_serialization_preserves_grid_state():
	var state = GameState.new()
	var ship = {
		"id": 1,
		"type": "Cruiser",
		"position": Vector2i(10, 5),
		"facing": Vector2i(1, 0),
		"length": 3,
		"health": 3,
		"is_destroyed": false
	}
	state.add_ship(ship)
	state.record_missile(0, Vector2i(5, 5), "miss")
	state.record_missile(0, Vector2i(10, 5), "hit")
	var data = state.to_dict()
	var new_state = GameState.new()
	new_state.from_dict(data)
	assert_eq(
		new_state.grid.get_cell_data(Vector2i(5, 5))["state"], "miss", "Miss cell state should survive deserialization"
	)
	assert_eq(
		new_state.grid.get_cell_data(Vector2i(10, 5))["state"], "hit", "Hit cell state should survive deserialization"
	)


func test_serialization_preserves_turn_and_phase():
	var state = GameState.new()
	state.set_phase("combat")
	state.next_turn()
	var data = state.to_dict()
	var new_state = GameState.new()
	new_state.from_dict(data)
	assert_eq(new_state.current_turn, 1, "Turn counter should be restored")
	assert_eq(new_state.turn_phase, "combat", "Turn phase should be restored")


func test_serialization_preserves_missile_history():
	var state = GameState.new()
	state.record_missile(0, Vector2i(3, 3), "hit")
	state.record_missile(1, Vector2i(7, 2), "miss")
	var data = state.to_dict()
	var new_state = GameState.new()
	new_state.from_dict(data)
	assert_eq(new_state.missile_history.size(), 2, "Missile history size should be preserved")
	assert_eq(new_state.missile_history[0]["position"], Vector2i(3, 3), "First missile position")
	assert_eq(new_state.missile_history[0]["result"], "hit", "First missile result")
	assert_eq(new_state.missile_history[1]["result"], "miss", "Second missile result")


func test_serialization_preserves_probe_history():
	var state = GameState.new()
	var detected: Array[Vector2i] = [Vector2i(5, 5)]
	state.record_probe(0, Vector2i(5, 5), detected)
	state.record_probe(1, Vector2i(10, 3), [])
	var data = state.to_dict()
	var new_state = GameState.new()
	new_state.from_dict(data)
	assert_eq(new_state.probe_history.size(), 2, "Probe history size should be preserved")
	assert_eq(new_state.probe_history[0]["position"], Vector2i(5, 5), "First probe center")
	assert_eq(new_state.probe_history[0]["player"], 0, "First probe player")


func test_from_dict_with_empty_state():
	var new_state = GameState.new()
	new_state.from_dict({})
	assert_eq(new_state.ships.size(), 0, "Empty dict should produce zero ships")
	assert_eq(new_state.current_turn, 0, "Empty dict should default turn to 0")
	assert_eq(new_state.turn_phase, "placement", "Empty dict should default phase to placement")
	assert_not_null(new_state.grid, "Grid should still be initialized")
