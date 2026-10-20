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
	preload("res://tests/test_keen_actions.gd"),
	preload("res://tests/test_level_session.gd"),
	preload("res://tests/test_enemies.gd"),
	preload("res://tests/test_world_map.gd"),
	preload("res://tests/test_ending.gd"),
	preload("res://tests/test_sounds.gd"),
	preload("res://tests/test_saving.gd"),
	preload("res://tests/test_menus.gd"),
	preload("res://tests/test_graphics.gd"),
	preload("res://tests/test_two_players.gd"),
	preload("res://tests/test_split_screen.gd"),
	preload("res://tests/test_online_session.gd"),
	preload("res://tests/test_online_sync.gd"),
	preload("res://tests/test_online_menus.gd"),
	preload("res://tests/test_launcher.gd"),
	preload("res://tests/test_backdrops.gd"),
	preload("res://tests/test_ship.gd"),
	preload("res://tests/test_keen1_data.gd"),
	preload("res://tests/test_keen1_extras.gd"),
	preload("res://tests/test_keen1_ship.gd"),
	preload("res://tests/test_keen2_files.gd"),
	preload("res://tests/test_keen2_renamed_keen1.gd"),
	preload("res://tests/test_keen2_data.gd"),
	preload("res://tests/test_keen2_level.gd"),
	preload("res://tests/test_keen2_stand_in.gd"),
	preload("res://tests/test_keen2_enemies.gd"),
	preload("res://tests/test_keen2_riding.gd"),
	preload("res://tests/test_keen2_shot_wall.gd"),
	preload("res://tests/test_keen2_switches.gd"),
	preload("res://tests/test_keen2_tantalus.gd"),
	preload("res://tests/test_keen2_ending.gd"),
	preload("res://tests/test_keen2_menus.gd"),
	preload("res://tests/test_keen2_extras.gd"),
	preload("res://tests/test_keen2_coop.gd"),
	preload("res://tests/test_keen2_online.gd"),
	preload("res://tests/test_keen2_original.gd"),
	preload("res://tests/test_keen3_files.gd"),
	preload("res://tests/test_keen3_data.gd"),
	preload("res://tests/test_keen3_level.gd"),
	preload("res://tests/test_keen3_keen.gd"),
	preload("res://tests/test_keen3_play.gd"),
	preload("res://tests/test_keen3_enemies.gd"),
	preload("res://tests/test_keen3_enemy_rules.gd"),
	preload("res://tests/test_keen3_enemy_census.gd"),
	preload("res://tests/test_keen3_objects.gd"),
	preload("res://tests/test_keen3_riding.gd"),
	preload("res://tests/test_keen3_lift_jump.gd"),
	preload("res://tests/test_keen3_shot_wall.gd"),
	preload("res://tests/test_keen3_map.gd"),
	preload("res://tests/test_keen3_messie.gd"),
	preload("res://tests/test_keen3_status.gd"),
	preload("res://tests/test_keen3_map_data.gd"),
	preload("res://tests/test_keen3_machine.gd"),
	preload("res://tests/test_keen3_machine_data.gd"),
	preload("res://tests/test_keen3_scenes.gd"),
	preload("res://tests/test_keen3_ending.gd"),
	preload("res://tests/test_keen3_sounds.gd"),
	preload("res://tests/test_keen3_menus.gd"),
	preload("res://tests/test_keen3_menus_data.gd"),
	preload("res://tests/test_keen3_extras.gd"),
	preload("res://tests/test_keen3_coop.gd"),
	preload("res://tests/test_keen3_online.gd"),
	preload("res://tests/test_keen3_original.gd"),
	preload("res://tests/test_masked_tiles.gd"),
	preload("res://tests/test_galaxy_data.gd"),
	preload("res://tests/test_galaxy_files.gd"),
	preload("res://tests/test_keen4_data.gd"),
	preload("res://tests/test_galaxy_level.gd"),
	preload("res://tests/test_keen4_level.gd"),
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
