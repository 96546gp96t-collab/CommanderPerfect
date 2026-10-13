extends RefCounted
## Base class for test suites. Every method whose name starts with "test_" is
## run by tests/run_tests.gd.

var failures: PackedStringArray = []
var skip_reason := ""
var _current_test := ""


func run_all() -> void:
	for method in get_method_list():
		var method_name: String = method.name
		if method_name.begins_with("test_"):
			_current_test = method_name
			call(method_name)


func assert_equal(actual: Variant, expected: Variant, description := "") -> void:
	if actual != expected:
		_fail("%s: expected %s, got %s" % [description, str(expected), str(actual)])


func assert_true(condition: bool, description: String) -> void:
	if not condition:
		_fail(description)


## Marks the whole suite as skipped, for example when game data is missing.
func skip(reason: String) -> void:
	skip_reason = reason


func _fail(message: String) -> void:
	failures.append("%s: %s" % [_current_test, message])
