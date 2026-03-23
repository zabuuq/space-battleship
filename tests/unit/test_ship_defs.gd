extends "res://addons/gut/test.gd"

## Tests for ShipDefs — ship type definitions and placement metadata (Issue #11).

const ShipDefs = preload("res://src/shared/ShipDefs.gd")

var _defs: RefCounted


func before_each():
	_defs = ShipDefs.new()


# ---------------------------------------------------------------------------
# Fleet composition
# ---------------------------------------------------------------------------


func test_fleet_has_five_ship_types():
	assert_eq(ShipDefs.FLEET_COMPOSITION.size(), 5, "Fleet must contain exactly 5 ship types")


func test_fleet_contains_all_required_types():
	assert_true(ShipDefs.FLEET_COMPOSITION.has(ShipDefs.TYPE_SUPPORT), "Fleet must include Support")
	assert_true(ShipDefs.FLEET_COMPOSITION.has(ShipDefs.TYPE_BATTLESHIP), "Fleet must include Battleship")
	assert_true(ShipDefs.FLEET_COMPOSITION.has(ShipDefs.TYPE_CRUISER), "Fleet must include Cruiser")
	assert_true(ShipDefs.FLEET_COMPOSITION.has(ShipDefs.TYPE_DESTROYER), "Fleet must include Destroyer")
	assert_true(ShipDefs.FLEET_COMPOSITION.has(ShipDefs.TYPE_STEALTH), "Fleet must include Stealth")


# ---------------------------------------------------------------------------
# is_valid_type
# ---------------------------------------------------------------------------


func test_valid_types_return_true():
	assert_true(_defs.is_valid_type(ShipDefs.TYPE_SUPPORT))
	assert_true(_defs.is_valid_type(ShipDefs.TYPE_BATTLESHIP))
	assert_true(_defs.is_valid_type(ShipDefs.TYPE_CRUISER))
	assert_true(_defs.is_valid_type(ShipDefs.TYPE_DESTROYER))
	assert_true(_defs.is_valid_type(ShipDefs.TYPE_STEALTH))


func test_unknown_type_returns_false():
	assert_false(_defs.is_valid_type("carrier"), "Unknown type must return false")
	assert_false(_defs.is_valid_type(""), "Empty string must return false")


# ---------------------------------------------------------------------------
# get_definition — per-type properties
# ---------------------------------------------------------------------------


func test_support_definition():
	var d = _defs.get_definition(ShipDefs.TYPE_SUPPORT)
	assert_eq(d["length"], 5, "Support length must be 5")
	assert_eq(d["health"], 5, "Support health must be 5")
	assert_eq(d["ability"], ShipDefs.ABILITY_DOUBLE_PROBE, "Support ability must be double_probe")


func test_battleship_definition():
	var d = _defs.get_definition(ShipDefs.TYPE_BATTLESHIP)
	assert_eq(d["length"], 4, "Battleship length must be 4")
	assert_eq(d["health"], 4, "Battleship health must be 4")
	assert_eq(d["ability"], ShipDefs.ABILITY_DOUBLE_MISSILE, "Battleship ability must be double_missile")


func test_cruiser_definition():
	var d = _defs.get_definition(ShipDefs.TYPE_CRUISER)
	assert_eq(d["length"], 3, "Cruiser length must be 3")
	assert_eq(d["health"], 3, "Cruiser health must be 3")
	assert_eq(d["ability"], ShipDefs.ABILITY_NONE, "Cruiser must have no ability")


func test_destroyer_definition():
	var d = _defs.get_definition(ShipDefs.TYPE_DESTROYER)
	assert_eq(d["length"], 3, "Destroyer length must be 3")
	assert_eq(d["health"], 3, "Destroyer health must be 3")
	assert_eq(d["ability"], ShipDefs.ABILITY_DOUBLE_MOVE, "Destroyer ability must be double_move")


func test_stealth_definition():
	var d = _defs.get_definition(ShipDefs.TYPE_STEALTH)
	assert_eq(d["length"], 3, "Stealth length must be 3")
	assert_eq(d["health"], 3, "Stealth health must be 3")
	assert_eq(d["ability"], ShipDefs.ABILITY_PROBE_MASK, "Stealth ability must be probe_mask")


func test_unknown_type_returns_empty_dict():
	var d = _defs.get_definition("unknown")
	assert_true(d.is_empty(), "Unknown type must return empty dictionary")


# ---------------------------------------------------------------------------
# create_ship_dict
# ---------------------------------------------------------------------------


func test_create_ship_dict_valid():
	var ship = _defs.create_ship_dict(1, ShipDefs.TYPE_CRUISER, Vector2i(5, 3), Vector2i(1, 0))
	assert_eq(ship["id"], 1)
	assert_eq(ship["type"], ShipDefs.TYPE_CRUISER)
	assert_eq(ship["position"], Vector2i(5, 3))
	assert_eq(ship["facing"], Vector2i(1, 0))
	assert_eq(ship["length"], 3)
	assert_eq(ship["health"], 3)
	assert_false(ship["is_destroyed"], "Newly created ship must not be destroyed")


func test_create_ship_dict_invalid_type_returns_empty():
	var ship = _defs.create_ship_dict(99, "ghost_ship", Vector2i(0, 0), Vector2i(1, 0))
	assert_true(ship.is_empty(), "Invalid type must produce empty dictionary")
