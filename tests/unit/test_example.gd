extends "res://addons/gut/test.gd"


func test_assert_true():
	assert_true(true, "Should pass")


func test_assert_false():
	assert_false(false, "Should pass")
