extends SceneTree
## Runs all test suites and exits with code 1 if any test fails. The
## suites of [constant TREE_SUITES] need a running scene tree (a screen that
## loads its files when it is ready) and run in the first frame.
##
## Usage:  godot --headless --path . --script res://tests/run_tests.gd
##         [-- --only=test_language,test_menus]   (only those suites)

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
	preload("res://tests/test_level_walls.gd"),
	preload("res://tests/test_level_walls_data.gd"),
	preload("res://tests/test_level_walls_fixes.gd"),
	preload("res://tests/test_level_walls_fixes_data.gd"),
	preload("res://tests/test_level_walls_fixes2.gd"),
	preload("res://tests/test_level_walls_fixes2_data.gd"),
	preload("res://tests/test_ship.gd"),
	preload("res://tests/test_keen1_data.gd"),
	preload("res://tests/test_keen1_extras.gd"),
	preload("res://tests/test_keen1_ship.gd"),
	preload("res://tests/test_keen1_ship_sky.gd"),
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
	preload("res://tests/test_keen4_backgrounds.gd"),
	preload("res://tests/test_galaxy_actions.gd"),
	preload("res://tests/test_galaxy_keen.gd"),
	preload("res://tests/test_galaxy_items.gd"),
	preload("res://tests/test_keen4_play.gd"),
	preload("res://tests/test_galaxy_creatures.gd"),
	preload("res://tests/test_keen4_creatures.gd"),
	preload("res://tests/test_keen4_creatures_more.gd"),
	preload("res://tests/test_keen4_creatures_play.gd"),
	preload("res://tests/test_keen4_platforms.gd"),
	preload("res://tests/test_keen4_people.gd"),
	preload("res://tests/test_keen4_water.gd"),
	preload("res://tests/test_keen4_d6_play.gd"),
	preload("res://tests/test_keen4_map.gd"),
	preload("res://tests/test_keen4_map_more.gd"),
	preload("res://tests/test_keen4_map_play.gd"),
	preload("res://tests/test_galaxy_front.gd"),
	preload("res://tests/test_keen4_front_play.gd"),
	preload("res://tests/test_keen4_demo_sync.gd"),
	preload("res://tests/test_galaxy_sound_opl.gd"),
	preload("res://tests/test_galaxy_sound_envelope.gd"),
	preload("res://tests/test_galaxy_sound_formats.gd"),
	preload("res://tests/test_galaxy_sound_music.gd"),
	preload("res://tests/test_galaxy_sound_player.gd"),
	preload("res://tests/test_galaxy_sound_world.gd"),
	preload("res://tests/test_keen4_sound.gd"),
	preload("res://tests/test_galaxy_menus.gd"),
	preload("res://tests/test_keen4_save.gd"),
	preload("res://tests/test_keen4_save_play.gd"),
	preload("res://tests/test_galaxy_paddle_war.gd"),
	preload("res://tests/test_galaxy_paddle_points.gd"),
	preload("res://tests/test_galaxy_paddle_menus.gd"),
	preload("res://tests/test_keen4_d11_quiet.gd"),
	preload("res://tests/test_keen4_coop_keys.gd"),
	preload("res://tests/test_galaxy_coop.gd"),
	preload("res://tests/test_galaxy_coop_creatures.gd"),
	preload("res://tests/test_keen4_coop_session.gd"),
	preload("res://tests/test_keen4_coop_levels.gd"),
	preload("res://tests/test_keen4_online_bytes.gd"),
	preload("res://tests/test_keen4_online.gd"),
	preload("res://tests/test_keen4_online_snapshot.gd"),
	preload("res://tests/test_keen4_d13_seen.gd"),
	preload("res://tests/test_keen4_v14.gd"),
	preload("res://tests/test_keen4_framed_pages.gd"),
	preload("res://tests/test_galaxy_split_look.gd"),
	preload("res://tests/test_galaxy_split_small_areas.gd"),
	preload("res://tests/test_galaxy_sky_pockets.gd"),
	preload("res://tests/test_galaxy_wide_waking.gd"),
	preload("res://tests/test_keen5_files.gd"),
	preload("res://tests/test_keen5_data.gd"),
	preload("res://tests/test_galaxy_game_session.gd"),
	preload("res://tests/test_keen5_keen.gd"),
	preload("res://tests/test_keen5_level.gd"),
	preload("res://tests/test_galaxy_creature_seams.gd"),
	preload("res://tests/test_keen5_creatures.gd"),
	preload("res://tests/test_keen5_creatures_more.gd"),
	preload("res://tests/test_keen5_creatures_play.gd"),
	preload("res://tests/test_keen5_platforms.gd"),
	preload("res://tests/test_keen5_fuses.gd"),
	preload("res://tests/test_keen5_mechanics_play.gd"),
	preload("res://tests/test_galaxy_game_map.gd"),
	preload("res://tests/test_keen5_map.gd"),
	preload("res://tests/test_keen5_map_play.gd"),
	preload("res://tests/test_keen5_status.gd"),
	preload("res://tests/test_keen5_galaxy_explosion.gd"),
	preload("res://tests/test_keen5_demo_sync.gd"),
	preload("res://tests/test_keen5_sound.gd"),
	preload("res://tests/test_galaxy_game_audio.gd"),
	preload("res://tests/test_galaxy_game_saved.gd"),
	preload("res://tests/test_keen5_save_play.gd"),
	preload("res://tests/test_keen5_online.gd"),
	preload("res://tests/test_keen5_coop.gd"),
]
const TREE_SUITES: Array[Script] = [
	preload("res://tests/test_keen4_d11_screen.gd"),
	preload("res://tests/test_keen4_d11_xbrz.gd"),
	preload("res://tests/test_keen4_coop_screen.gd"),
	preload("res://tests/test_keen4_online_play.gd"),
	preload("res://tests/test_keen4_d13_2_fixes.gd"),
	preload("res://tests/test_keen4_wide_waking_screen.gd"),
	preload("res://tests/test_galaxy_game_screen.gd"),
	preload("res://tests/test_galaxy_game_flow.gd"),
	preload("res://tests/test_keen5_view.gd"),
	preload("res://tests/test_galaxy_game_front.gd"),
	preload("res://tests/test_keen5_front.gd"),
	preload("res://tests/test_keen5_music.gd"),
	preload("res://tests/test_keen5_menus.gd"),
	preload("res://tests/test_keen5_backgrounds.gd"),
	preload("res://tests/test_keen5_picture_fixes.gd"),
	preload("res://tests/test_keen5_original_mode.gd"),
	preload("res://tests/test_keen5_coop_screen.gd"),
	preload("res://tests/test_keen5_online_play.gd"),
	preload("res://tests/test_realistic_look.gd"),
	preload("res://tests/test_player_controllers.gd"),
	preload("res://tests/test_button_bindings.gd"),
	preload("res://tests/test_language.gd"),
	preload("res://tests/test_alien_signs.gd"),
]

## Command line option that names the only suites to run.
const ONLY_OPTION := "--only="

var _failure_count := 0
var _tree_suites_run := false


func _initialize() -> void:
	_run(SUITES)
	if TREE_SUITES.is_empty():
		_finish()


func _process(_delta: float) -> bool:
	if _tree_suites_run:
		return false
	_tree_suites_run = true
	_run(TREE_SUITES)
	_finish()
	return false


func _run(suites: Array[Script]) -> void:
	var only := _only()
	for suite_script in suites:
		if (
			not only.is_empty()
			and not only.has(suite_script.resource_path.get_file().get_basename())
		):
			continue
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
			_failure_count += suite.failures.size()


## The suites named with [constant ONLY_OPTION]; empty: all of them.
static func _only() -> PackedStringArray:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with(ONLY_OPTION):
			return argument.trim_prefix(ONLY_OPTION).split(",", false)
	return PackedStringArray()


func _finish() -> void:
	print("%d failure(s)" % _failure_count)
	quit(1 if _failure_count > 0 else 0)
