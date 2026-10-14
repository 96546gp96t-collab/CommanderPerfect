extends SceneTree
## Runs all test suites and exits with code 1 if any test fails.
##
## Usage:  godot --headless --path . --script res://tests/run_tests.gd

const SUITES: Array[Script] = [
	preload("res://tests/test_decompressors.gd"),
	preload("res://tests/test_ega_decoding.gd"),
	preload("res://tests/test_level_rendering.gd"),
	preload("res://tests/test_tile_properties.gd"),
	preload("res://tests/test_keen_movement.gd"),
	preload("res://tests/test_keen1_data.gd"),
]


func _initialize() -> void:
	var failure_count := 0
	for suite_script in SUITES:
		var suite = suite_script.new()  # Untyped: the members come from test_case.gd.
		suite.run_all()
		var suite_name := suite_script.resource_path.get_file().get_basename()
		if not suite.skip_reason.is_empty():
			print("SKIP  %s (%s)" % [suite_name, suite.skip_reason])
		elif suite.failures.is_empty():
			print("PASS  %s" % suite_name)
		else:
			print("FAIL  %s" % suite_name)
			for failure in suite.failures:
				print("      " + failure)
			failure_count += suite.failures.size()

	print("%d failure(s)" % failure_count)
	quit(1 if failure_count > 0 else 0)
