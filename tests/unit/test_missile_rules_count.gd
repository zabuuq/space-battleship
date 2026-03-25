extends "res://addons/gut/test.gd"

## Tests for MissileRules — missile counts and target validation.
## Issue #29 – Implement missile targeting.
## Issue #32 – Implement Battleship double-missile ability.
## Issue #34 – Add missile combat tests.

const ShipDefs = preload("res://src/shared/ShipDefs.gd")
const MissileRules = preload("res://src/shared/MissileRules.gd")

# ---------------------------------------------------------------------------
# Battleship double-missile ability (#32)
# ---------------------------------------------------------------------------


func test_battleship_missile_count_is_two():
	assert_eq(MissileRules.missile_count_for(ShipDefs.TYPE_BATTLESHIP), 2)


func test_support_missile_count_is_one():
	assert_eq(MissileRules.missile_count_for(ShipDefs.TYPE_SUPPORT), 1)


func test_cruiser_missile_count_is_one():
	assert_eq(MissileRules.missile_count_for(ShipDefs.TYPE_CRUISER), 1)


func test_destroyer_missile_count_is_one():
	assert_eq(MissileRules.missile_count_for(ShipDefs.TYPE_DESTROYER), 1)


func test_stealth_missile_count_is_one():
	assert_eq(MissileRules.missile_count_for(ShipDefs.TYPE_STEALTH), 1)


# ---------------------------------------------------------------------------
# Target validation (#29)
# ---------------------------------------------------------------------------


func test_is_valid_target_interior_returns_true():
	assert_true(MissileRules.is_valid_target(Vector2i(60, 6)))


func test_is_valid_target_negative_x_returns_false():
	assert_false(MissileRules.is_valid_target(Vector2i(-1, 6)))


func test_is_valid_target_x_out_of_range_returns_false():
	assert_false(MissileRules.is_valid_target(Vector2i(120, 6)))


func test_is_valid_target_negative_y_returns_false():
	assert_false(MissileRules.is_valid_target(Vector2i(60, -1)))


func test_is_valid_target_y_out_of_range_returns_false():
	assert_false(MissileRules.is_valid_target(Vector2i(60, 12)))
