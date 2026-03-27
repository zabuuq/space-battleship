extends "res://addons/gut/test.gd"

const GameEventLog = preload("res://src/shared/GameEventLog.gd")


func test_initial_log_empty():
	var log = GameEventLog.new()
	assert_eq(log.event_count(), 0)
	assert_true(log.get_events().is_empty())
	assert_true(log.get_last_event().is_empty())


func test_log_single_event():
	var log = GameEventLog.new()
	log.log_event(GameEventLog.EVENT_MOVE, 0, 1, {"ship_id": 2, "steps": 1})
	assert_eq(log.event_count(), 1)
	var event = log.get_last_event()
	assert_eq(event["type"], GameEventLog.EVENT_MOVE)
	assert_eq(event["player_index"], 0)
	assert_eq(event["turn"], 1)
	assert_eq(event["data"]["ship_id"], 2)


func test_log_multiple_events():
	var log = GameEventLog.new()
	log.log_event(GameEventLog.EVENT_PROBE, 0, 1)
	log.log_event(GameEventLog.EVENT_MISSILE, 0, 1)
	log.log_event(GameEventLog.EVENT_END_TURN, 0, 1)
	assert_eq(log.event_count(), 3)


func test_get_events_for_turn():
	var log = GameEventLog.new()
	log.log_event(GameEventLog.EVENT_MOVE, 0, 1)
	log.log_event(GameEventLog.EVENT_PROBE, 1, 2)
	log.log_event(GameEventLog.EVENT_MISSILE, 0, 3)
	var turn2 = log.get_events_for_turn(2)
	assert_eq(turn2.size(), 1)
	assert_eq(turn2[0]["type"], GameEventLog.EVENT_PROBE)


func test_get_events_for_player():
	var log = GameEventLog.new()
	log.log_event(GameEventLog.EVENT_MOVE, 0, 1)
	log.log_event(GameEventLog.EVENT_PROBE, 1, 1)
	log.log_event(GameEventLog.EVENT_MISSILE, 0, 1)
	var p0 = log.get_events_for_player(0)
	assert_eq(p0.size(), 2)
	var p1 = log.get_events_for_player(1)
	assert_eq(p1.size(), 1)


func test_get_last_event_no_mutation():
	var log = GameEventLog.new()
	log.log_event(GameEventLog.EVENT_GAME_OVER, 0, 5, {"winner": 0})
	var event = log.get_last_event()
	event["type"] = "tampered"
	assert_eq(log.get_last_event()["type"], GameEventLog.EVENT_GAME_OVER, "Mutating returned copy must not affect log")


func test_serialization_roundtrip():
	var log = GameEventLog.new()
	log.log_event(GameEventLog.EVENT_PROBE, 0, 1, {"x": 10, "y": 5})
	log.log_event(GameEventLog.EVENT_MISSILE, 1, 2, {"x": 20, "y": 3})

	var data = log.to_dict()
	var log2 = GameEventLog.new()
	log2.from_dict(data)

	assert_eq(log2.event_count(), 2)
	assert_eq(log2.get_events_for_turn(1)[0]["data"]["x"], 10)
	assert_eq(log2.get_events_for_player(1)[0]["type"], GameEventLog.EVENT_MISSILE)
