class_name GameEventLog
extends RefCounted

## GameEventLog
## Records structured game events with type, player, turn, and optional data.
## Provides queries by turn or player and supports serialisation for network transport.
## Issue: #73 Add structured game event logging.

const EVENT_MOVE = "move"
const EVENT_TURN_SHIP = "turn_ship"
const EVENT_PROBE = "probe"
const EVENT_MISSILE = "missile"
const EVENT_PROBE_MASK = "probe_mask"
const EVENT_END_TURN = "end_turn"
const EVENT_GAME_OVER = "game_over"

var _events: Array = []


## Appends a new event. data is an optional dictionary of event-specific fields.
func log_event(event_type: String, player_index: int, turn_number: int, data: Dictionary = {}) -> void:
	(
		_events
		. append(
			{
				"type": event_type,
				"player_index": player_index,
				"turn": turn_number,
				"data": data.duplicate(),
			}
		)
	)


## Returns a shallow copy of all recorded events.
func get_events() -> Array:
	return _events.duplicate()


## Returns events recorded for a specific turn number.
func get_events_for_turn(turn_number: int) -> Array:
	var result: Array = []
	for event in _events:
		if event.get("turn", -1) == turn_number:
			result.append(event.duplicate())
	return result


## Returns events recorded for a specific player index.
func get_events_for_player(player_index: int) -> Array:
	var result: Array = []
	for event in _events:
		if event.get("player_index", -1) == player_index:
			result.append(event.duplicate())
	return result


## Returns the most recent event, or an empty dictionary if the log is empty.
func get_last_event() -> Dictionary:
	if _events.is_empty():
		return {}
	return _events.back().duplicate()


## Returns the total number of recorded events.
func event_count() -> int:
	return _events.size()


## Serialises the log to an array for network transport.
func to_dict() -> Array:
	return _events.duplicate(true)


## Restores the log from an array produced by to_dict().
func from_dict(data: Array) -> void:
	_events = data.duplicate(true)
