extends "res://addons/gut/test.gd"

const FogOfWarState = preload("res://src/shared/FogOfWarState.gd")
const MissileRules = preload("res://src/shared/MissileRules.gd")


func test_initial_state_empty():
	var fog = FogOfWarState.new()
	assert_eq(fog.get_visible_cells().size(), 0, "No cells visible initially")


func test_apply_probe_result_marks_revealed():
	var fog = FogOfWarState.new()
	var positions = [Vector2i(5, 3), Vector2i(6, 3)]
	fog.apply_probe_result(positions)
	assert_true(fog.is_cell_observed(Vector2i(5, 3)), "Cell should be observed after probe")
	assert_eq(fog.get_cell_state(Vector2i(5, 3)), FogOfWarState.CELL_REVEALED)


func test_apply_probe_does_not_overwrite_hit():
	var fog = FogOfWarState.new()
	fog.apply_missile_result(Vector2i(5, 3), MissileRules.RESULT_HIT)
	fog.apply_probe_result([Vector2i(5, 3)])
	assert_eq(fog.get_cell_state(Vector2i(5, 3)), FogOfWarState.CELL_HIT, "Hit should not be overwritten by probe")


func test_apply_missile_hit():
	var fog = FogOfWarState.new()
	fog.apply_missile_result(Vector2i(10, 5), MissileRules.RESULT_HIT)
	assert_eq(fog.get_cell_state(Vector2i(10, 5)), FogOfWarState.CELL_HIT)


func test_apply_missile_miss():
	var fog = FogOfWarState.new()
	fog.apply_missile_result(Vector2i(20, 8), MissileRules.RESULT_MISS)
	assert_eq(fog.get_cell_state(Vector2i(20, 8)), FogOfWarState.CELL_MISS)


func test_unobserved_cell_returns_empty():
	var fog = FogOfWarState.new()
	assert_false(fog.is_cell_observed(Vector2i(0, 0)))
	assert_eq(fog.get_cell_state(Vector2i(0, 0)), "")


func test_serialization_roundtrip():
	var fog = FogOfWarState.new()
	fog.apply_probe_result([Vector2i(3, 2)])
	fog.apply_missile_result(Vector2i(7, 4), MissileRules.RESULT_HIT)
	fog.apply_missile_result(Vector2i(15, 1), MissileRules.RESULT_MISS)

	var data = fog.to_dict()
	var fog2 = FogOfWarState.new()
	fog2.from_dict(data)

	assert_eq(fog2.get_cell_state(Vector2i(3, 2)), FogOfWarState.CELL_REVEALED)
	assert_eq(fog2.get_cell_state(Vector2i(7, 4)), FogOfWarState.CELL_HIT)
	assert_eq(fog2.get_cell_state(Vector2i(15, 1)), FogOfWarState.CELL_MISS)
	assert_false(fog2.is_cell_observed(Vector2i(0, 0)))


func test_get_visible_cells_returns_copy():
	var fog = FogOfWarState.new()
	fog.apply_probe_result([Vector2i(1, 1)])
	var cells = fog.get_visible_cells()
	cells[Vector2i(99, 99)] = "revealed"
	assert_false(fog.is_cell_observed(Vector2i(99, 99)), "Modifying copy should not affect internal state")
