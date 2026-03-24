extends "res://addons/gut/test.gd"

## Tests for ProbeRules — Stealth probe masking.
## Issue #27 – Implement Stealth probe masking.
## Issue #28 – Add probe system tests.

const GameState = preload("res://src/shared/GameState.gd")
const ShipDefs = preload("res://src/shared/ShipDefs.gd")
const ProbeRules = preload("res://src/shared/ProbeRules.gd")

var _state: RefCounted
var _defs: RefCounted


func before_each() -> void:
	_state = GameState.new()
	_defs = ShipDefs.new()


# ---------------------------------------------------------------------------
# Stealth probe masking (#27)
# ---------------------------------------------------------------------------


func test_stealth_mask_hides_ship_from_probe():
	var stealth = _defs.create_ship_dict(0, ShipDefs.TYPE_STEALTH, Vector2i(5, 5), Vector2i(1, 0))
	_state.add_ship(stealth)
	ProbeRules.activate_probe_mask(_state, 0)
	var detected := ProbeRules.fire_probe(_state, 1, Vector2i(5, 5))
	assert_false(detected.has(Vector2i(5, 5)), "Masked Stealth ship must not be detected")
	assert_eq(_state.grid.get_cell_data(Vector2i(5, 5))["state"], "hidden", "Masked cell must stay hidden")


func test_unmasked_stealth_ship_is_detected():
	var stealth = _defs.create_ship_dict(0, ShipDefs.TYPE_STEALTH, Vector2i(5, 5), Vector2i(1, 0))
	_state.add_ship(stealth)
	var detected := ProbeRules.fire_probe(_state, 1, Vector2i(5, 5))
	assert_true(detected.has(Vector2i(5, 5)), "Unmasked Stealth ship must be detected by probe")


func test_stealth_mask_expires_after_tick():
	var stealth = _defs.create_ship_dict(0, ShipDefs.TYPE_STEALTH, Vector2i(5, 5), Vector2i(1, 0))
	_state.add_ship(stealth)
	ProbeRules.activate_probe_mask(_state, 0)
	ProbeRules.tick_probe_mask(_state.ships[0])
	assert_false(_state.ships[0].get("probe_mask_active", false), "Mask must expire after one tick")


func test_stealth_mask_cooldown_set_after_expiry():
	var stealth = _defs.create_ship_dict(0, ShipDefs.TYPE_STEALTH, Vector2i(5, 5), Vector2i(1, 0))
	_state.add_ship(stealth)
	ProbeRules.activate_probe_mask(_state, 0)
	ProbeRules.tick_probe_mask(_state.ships[0])
	assert_eq(_state.ships[0].get("probe_mask_cooldown", 0), 1, "One-round cooldown must begin after mask expires")


func test_stealth_mask_cannot_reactivate_during_cooldown():
	var stealth = _defs.create_ship_dict(0, ShipDefs.TYPE_STEALTH, Vector2i(5, 5), Vector2i(1, 0))
	_state.add_ship(stealth)
	ProbeRules.activate_probe_mask(_state, 0)
	ProbeRules.tick_probe_mask(_state.ships[0])
	var result := ProbeRules.activate_probe_mask(_state, 0)
	assert_false(result, "Mask cannot be reactivated during cooldown")


func test_stealth_mask_available_after_cooldown_expires():
	var stealth = _defs.create_ship_dict(0, ShipDefs.TYPE_STEALTH, Vector2i(5, 5), Vector2i(1, 0))
	_state.add_ship(stealth)
	ProbeRules.activate_probe_mask(_state, 0)
	ProbeRules.tick_probe_mask(_state.ships[0])
	ProbeRules.tick_probe_mask(_state.ships[0])
	var result := ProbeRules.activate_probe_mask(_state, 0)
	assert_true(result, "Mask must be available after cooldown expires")


func test_activate_mask_on_non_stealth_fails():
	var cruiser = _defs.create_ship_dict(0, ShipDefs.TYPE_CRUISER, Vector2i(5, 5), Vector2i(1, 0))
	_state.add_ship(cruiser)
	var result := ProbeRules.activate_probe_mask(_state, 0)
	assert_false(result, "Probe mask cannot be activated on non-Stealth ships")


func test_activate_mask_on_unknown_id_fails():
	var result := ProbeRules.activate_probe_mask(_state, 99)
	assert_false(result, "Probe mask activation must fail for unknown ship ID")


func test_can_activate_probe_mask_true_for_fresh_stealth():
	var stealth = _defs.create_ship_dict(0, ShipDefs.TYPE_STEALTH, Vector2i(5, 5), Vector2i(1, 0))
	_state.add_ship(stealth)
	assert_true(ProbeRules.can_activate_probe_mask(_state.ships[0]))


func test_can_activate_probe_mask_false_when_active():
	var stealth = _defs.create_ship_dict(0, ShipDefs.TYPE_STEALTH, Vector2i(5, 5), Vector2i(1, 0))
	_state.add_ship(stealth)
	ProbeRules.activate_probe_mask(_state, 0)
	assert_false(ProbeRules.can_activate_probe_mask(_state.ships[0]))


func test_can_activate_probe_mask_false_on_cooldown():
	var stealth = _defs.create_ship_dict(0, ShipDefs.TYPE_STEALTH, Vector2i(5, 5), Vector2i(1, 0))
	_state.add_ship(stealth)
	ProbeRules.activate_probe_mask(_state, 0)
	ProbeRules.tick_probe_mask(_state.ships[0])
	assert_false(ProbeRules.can_activate_probe_mask(_state.ships[0]))
