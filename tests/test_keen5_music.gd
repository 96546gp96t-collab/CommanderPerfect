extends "res://tests/test_case.gd"
## Checks where Keen 5's songs and screen sounds play ([Keen5View] on the
## Galaxy game with [GalaxyAudio], milestone E8) with the player's files:
## every map its own song from its start (the world map, the levels, the
## demos, the high scores), silence once a map's play ends (Omni
## CK_PlayLoop's StopMusic: the boxes between the maps), the level-exit
## sound, the fuse message waiting for that sound to end (Omni
## SD_WaitSoundDone), the help's song (map 19) and the map's again after
## it, the story's (17), the end's (14), the exploding galaxy's sounds and
## the game-over song (18), Shift+S and Shift+M. Which song plays is the
## player's [method GalaxySoundPlayer.song] (also while it is still being
## rendered; nothing is heard in a headless run). The screen must be in a
## running scene tree, so the suite runs in the first frame; the shared
## settings go to a folder of their own. Skipped without the files.

const VIEW_SCENE := "res://src/keen5/keen5_view.tscn"
const TEST_DIRECTORY := "user://test_keen5_music"
const FRAME_SECONDS := 1.0 / 35.0
const QUEUE_FRAMES := 400
const DEATH_FRAMES := 300
const NO_SONG := GalaxySoundPlayer.NO_SONG
## Songs (Omni CK_LevelMusic): the world map Robo Red Rock, level 1
## Wednesday at the Beach, level 4 Spiro Grip Me Tighter, the high scores
## Skating O'er the Ice; the screens: the story, the end, game over, help.
const MAP_SONG := 11
const LEVEL_1_SONG := 5
const LEVEL_4_SONG := 10
const HIGH_SCORE_SONG := 2
const STORY_SONG := 1
const ENDING_SONG := 12
const GAME_OVER_SONG := 0
const HELP_SONG := 8
const LEVEL_EXIT := 13
const GALAXY_EXPLODE_PRE := 54
const GALAXY_EXPLODE := 53
## The fuse message's four steps (two screens, each 30 tics and a key).
const FUSE_STEPS := 4
const TIC_SLACK := 2
const TILE := 256
## A score that makes the table (the defaults are 10,000).
const HIGH_SCORE := 20000

var _view: Keen5View
var _tree: SceneTree


func _init() -> void:
	if Keen5Files.locate() == null:
		skip("no Keen 5 files in game_data/keen5")
		return
	_tree = Engine.get_main_loop() as SceneTree
	if _tree == null or not _tree.root.is_inside_tree():
		skip("needs a running scene tree (the screen loads its files when it is ready)")


func run_all() -> void:
	if not skip_reason.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(TEST_DIRECTORY)
	KeyBindings.reset()
	super.run_all()
	_free_view()
	_remove_recursive(ProjectSettings.globalize_path(TEST_DIRECTORY))


func test_the_audio_is_keen_5s() -> void:
	_create_view()
	var audio := _view.audio()
	assert_equal(audio.library.cache.directory, "user://keen5/cache", "Keen 5's cache")
	assert_equal(audio.names, Keen5Sounds.NUMBERS, "Keen 5's sound names")
	assert_equal(audio.library.songs.size(), Keen5Sounds.SONG_COUNT, "14 songs")
	assert_equal(_view._galaxy_settings.path, "user://keen5/settings.cfg", "its own settings")


func test_every_map_plays_its_song_and_the_boxes_are_silent() -> void:
	_create_view()
	_view._new_game()
	assert_equal(_view.audio().song(), NO_SONG, "the map's box is silent")
	_run_queue()
	assert_equal(_view.audio().song(), MAP_SONG, "the world map's song")
	_view.progress().map_position = _entrance(1) * TILE
	_view._show_level(Keen5Episode.WORLD_MAP)
	_press_jump()
	assert_true(_view.shows_message(), "One moment")
	assert_equal(_view.audio().song(), NO_SONG, "the map's play is over: silence")
	_run_queue()
	assert_equal(_view.map_number(), 1, "level 1")
	assert_equal(_view.audio().song(), LEVEL_1_SONG, "level 1's song")
	_view.session().world.complete(&"")
	_frames(2)
	assert_equal(_view.audio().song(), NO_SONG, "the level is over: silence")
	assert_equal(_view.audio().current_sound(), LEVEL_EXIT, "the exit sound")
	_run_queue()
	assert_equal(_view.audio().song(), MAP_SONG, "the map's song again")


func test_a_death_stops_the_music_and_try_again_starts_it() -> void:
	_create_view()
	_view._new_game()
	_run_queue()
	_view._show_level(1)
	assert_equal(_view.audio().song(), LEVEL_1_SONG, "level 1's song")
	_view.session().keen.kill()
	for frame in DEATH_FRAMES:
		_frames(1)
		if _view._choice >= 0:
			break
	assert_equal(_view.audio().song(), NO_SONG, "the box after a death is silent")
	_press_key(KEY_ENTER)
	_run_queue()
	assert_equal(_view.audio().song(), LEVEL_1_SONG, "Try Again: the song from its start")


func test_the_fuse_message_waits_for_the_exit_sound() -> void:
	_create_view()
	_view.audio().set_mode(GalaxySoundPlayer.Mode.ADLIB)
	_view._new_game()
	_run_queue()
	_view._show_level(4)
	assert_equal(_view.audio().song(), LEVEL_4_SONG, "level 4's song")
	_view.session().world.complete(Keen5LevelEnd.FUSE_ENDING)
	_frames_until_message()
	assert_equal(_view.audio().current_sound(), LEVEL_EXIT, "the exit sound")
	var library := _view.audio().library
	var exit_tics := ceili(library.duration(GalaxySoundLibrary.Kind.ADLIB, LEVEL_EXIT) * 70.0)
	var wait := _view.queue().current()
	assert_equal(_view.queue().steps.size(), FUSE_STEPS + 1, "a wait, then the two screens")
	assert_true(wait.image == null, "the game stands still")
	assert_true(
		wait.tics <= exit_tics and wait.tics >= exit_tics - TIC_SLACK,
		"as long as the exit sound (%d tics, %d)" % [exit_tics, wait.tics]
	)
	_press_key()
	assert_equal(_view.queue().steps.size(), FUSE_STEPS + 1, "a key does not cut it short")
	_frames(ceili(wait.tics / float(GalaxyClock.NORMAL_TICS)))
	assert_equal(_view.queue().steps.size(), FUSE_STEPS, "then the message")
	assert_true(_view.queue().current().image != null, "its first screen")


func test_the_fuse_message_comes_at_once_with_the_sound_off() -> void:
	_create_view()
	_view.audio().set_mode(GalaxySoundPlayer.Mode.OFF)
	_view._new_game()
	_run_queue()
	_view._show_level(4)
	_view.session().world.complete(Keen5LevelEnd.FUSE_ENDING)
	_frames_until_message()
	assert_equal(_view.queue().steps.size(), FUSE_STEPS, "no sound to wait for")


func test_the_help_plays_its_song_and_the_maps_after_it() -> void:
	_create_view()
	_view._new_game()
	_run_queue()
	_press_key(KEY_F1)
	assert_equal(_view.front(), GalaxyFrontScreen.Front.HELP, "the help")
	assert_equal(_view.audio().song(), HELP_SONG, "A Shikadi Aire (map 19)")
	_press_key(KEY_ESCAPE)
	assert_equal(_view.audio().song(), MAP_SONG, "the map's song again, from its start")


func test_the_title_loop_songs() -> void:
	_create_view()
	assert_equal(_view.audio().song(), NO_SONG, "the intro is silent")
	_view._next_title_step()
	_run_queue()
	assert_equal(_view.front(), GalaxyFrontScreen.Front.DEMO, "demo 0")
	assert_equal(_view.audio().song(), LEVEL_1_SONG, "a demo plays its map's song")
	_view._end_demo()
	assert_equal(_view.front(), GalaxyFrontScreen.Front.STORY, "the story")
	assert_equal(_view.audio().song(), STORY_SONG, "Having Tea With Little Ampton (map 17)")
	_view._story_tics = _view._story.total_tics()
	_frames(1)
	assert_true(_view.front() != GalaxyFrontScreen.Front.STORY, "the story is over")
	_run_queue()
	assert_equal(_view.front(), GalaxyFrontScreen.Front.DEMO, "demo 1")
	var demo_song := _view.rules.song_for_map(_view.map_number())
	assert_equal(_view.audio().song(), demo_song, "demo 1 plays its map's song")
	_view._end_demo()
	assert_equal(_view.audio().song(), NO_SONG, "the demo's play is over")
	_run_queue()
	assert_equal(_view.audio().song(), HIGH_SCORE_SONG, "the high scores: map 15's song")


func test_the_end_and_the_name_entry() -> void:
	_create_view()
	_view._new_game()
	_run_queue()
	_view._cheat_end()
	assert_equal(_view.front(), GalaxyFrontScreen.Front.ENDING, "the end pages")
	assert_equal(_view.audio().song(), ENDING_SONG, "the Fanfare (map 14)")
	_view.inventory().score = HIGH_SCORE
	_view._game_ended()
	assert_equal(_view.audio().song(), NO_SONG, "the end's song stops")
	_run_queue()
	assert_equal(_view.front(), GalaxyFrontScreen.Front.NAME_ENTRY, "the name is typed in")
	assert_equal(_view.audio().song(), NO_SONG, "in silence (the map is only loaded)")


func test_game_over_sounds_and_its_song() -> void:
	_create_view()
	_view.audio().set_mode(GalaxySoundPlayer.Mode.ADLIB)
	_view._new_game()
	_run_queue()
	_view._show_level(1)
	_view.inventory().lives = 0
	_view.session().keen.kill()
	for frame in DEATH_FRAMES:
		_frames(1)
		if _view.front() == GalaxyFrontScreen.Front.SCENE:
			break
	var scene := _view._scene as Keen5GalaxyExplosion
	assert_true(scene != null, "the galaxy explodes")
	assert_equal(_view.audio().song(), NO_SONG, "in silence")
	_view.audio().sound_finished()
	for frame in DEATH_FRAMES:
		_frames(1)
		if scene.stage == Keen5GalaxyExplosion.Stage.FLASH:
			break
	assert_equal(_view.audio().current_sound(), GALAXY_EXPLODE_PRE, "the flashing's sound")
	for frame in DEATH_FRAMES:
		_frames(1)
		if scene.stage == Keen5GalaxyExplosion.Stage.STARS:
			break
	assert_equal(_view.audio().current_sound(), GALAXY_EXPLODE, "the stars' sound")
	_press_key(KEY_SPACE)
	assert_equal(scene.stage, Keen5GalaxyExplosion.Stage.GAME_OVER, "GAME OVER")
	assert_equal(_view.audio().song(), GAME_OVER_SONG, "This Is Where I Came In! (map 18)")
	_press_key(KEY_SPACE)
	assert_equal(_view.audio().song(), NO_SONG, "stopped after it")


func test_shift_s_and_shift_m() -> void:
	_create_view()
	_view._new_game()
	_run_queue()
	_view.audio().set_mode(GalaxySoundPlayer.Mode.ADLIB)
	_view.audio().set_music(true)
	_shift_key(KEY_S)
	assert_equal(_view.audio().mode, GalaxySoundPlayer.Mode.PC, "Shift+S: the PC speaker")
	assert_equal(_view._message, "Sound: PC speaker", "said")
	assert_equal(_view._user_settings.sound_device, "pc", "stored")
	assert_true(FileAccess.file_exists(_view._user_settings.path), "saved")
	_shift_key(KEY_M)
	assert_true(not _view.audio().music_on, "Shift+M: music off")
	assert_equal(_view._message, "Music off", "said")
	_shift_key(KEY_M)
	assert_true(_view.audio().music_on, "and on")


func _create_view() -> void:
	_free_view()
	_release_all()
	var scene := load(VIEW_SCENE) as PackedScene
	_view = scene.instantiate() as Keen5View
	_tree.root.add_child(_view)
	_view._user_settings.path = TEST_DIRECTORY.path_join("settings.cfg")
	_view._settings.aspect = DisplaySettings.Aspect.ORIGINAL
	_view._apply_display_settings()
	# Never the player's own table.
	var path := TEST_DIRECTORY.path_join("high_scores.json")
	_view._high_scores = GalaxyHighScores.load_from(
		path, GalaxyHighScoreBoard.defaults(_view._data, _view.rules)
	)


func _free_view() -> void:
	if _view != null:
		_view.get_parent().remove_child(_view)
		_view.free()
		_view = null


## The first cell of level [param level]'s entrance on the world map.
func _entrance(level: int) -> Vector2i:
	var map := _view._data.maps.load_map(Keen5Episode.WORLD_MAP)
	for y in map.height:
		for x in map.width:
			if map.tile(GalaxyMap.Layer.INFO, x, y) == GalaxyMapKeen.ENTRY_BASE + level:
				return Vector2i(x, y)
	return Vector2i.ZERO


func _run_queue() -> void:
	for frame in QUEUE_FRAMES:
		if not _view.shows_message():
			return
		_frames(1)


func _frames_until_message() -> void:
	for frame in QUEUE_FRAMES:
		if _view.shows_message():
			return
		_frames(1)


func _frames(count: int) -> void:
	for frame in count:
		_view._process(FRAME_SECONDS)


func _press_jump() -> void:
	Input.action_press("jump")
	for frame in 4:
		_frames(1)
		if _view.shows_message():
			break
	Input.action_release("jump")


func _press_key(key := KEY_SPACE) -> void:
	_send(key, false)


func _shift_key(key: Key) -> void:
	_send(key, true)


func _send(key: Key, shift: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.shift_pressed = shift
	event.pressed = true
	_view._unhandled_input(event)
	var release := event.duplicate() as InputEventKey
	release.pressed = false
	_view._unhandled_input(release)


func _release_all() -> void:
	for action in KeyBindings.all_actions():
		Input.action_release(action)


static func _remove_recursive(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for file in directory.get_files():
		directory.remove(file)
	for sub in directory.get_directories():
		_remove_recursive(path.path_join(sub))
	DirAccess.remove_absolute(path)
