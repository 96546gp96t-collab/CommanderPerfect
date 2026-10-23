extends "res://tests/test_case.gd"
## Tests for the Galaxy game's sound (milestone E8) with a hand-made AUDIO
## file (tests/galaxy_sound_fixtures.gd) and rules of an episode of its
## own: [GalaxyAudio] takes the episode's sound names, sound and song
## counts and the song of every map from the rules and renders into the
## episode's own cache folder; how long the playing sound still lasts (the
## original's SD_WaitSoundDone); Shift+S and Shift+M's cycles;
## [GalaxySettings] in the episode's folder.

const Sound := preload("res://tests/galaxy_sound_fixtures.gd")
const USER_FOLDER := "user://test_galaxy_game_audio"
const SOUND_COUNT := 2
const SONG_COUNT := 2
const LONG_STEPS := 280
const SHORT_STEPS := 2
const PRIORITY := 50
const NAMES: Dictionary[StringName, int] = {&"long": 0, &"short": 1}
## Maps 0 and 1 play songs 1 and 0, map 2 none.
const MAP_SONGS: PackedInt32Array = [1, 0, -1]
const TIC_SLACK := 2

var _data: GalaxyData
var _rules: GalaxyGameRules


func _init() -> void:
	_remove(USER_FOLDER)
	_data = GalaxyData.new()
	_data.audio = Sound.audio_file(_chunks())
	_rules = GalaxyGameRules.new()
	_rules.user_folder = USER_FOLDER
	_rules.sound_count = SOUND_COUNT
	_rules.song_count = SONG_COUNT
	_rules.sound_names = NAMES
	_rules.map_songs = MAP_SONGS


func _chunks() -> Array[PackedByteArray]:
	var chunks: Array[PackedByteArray] = []
	var lengths: PackedInt32Array = [LONG_STEPS, SHORT_STEPS]
	for steps in lengths:
		var bytes := PackedByteArray()
		bytes.resize(steps)
		bytes.fill(20)
		chunks.append(Sound.pc_sound(PRIORITY, bytes))
	for steps in lengths:
		var notes := PackedByteArray()
		notes.resize(steps)
		notes.fill(100)
		chunks.append(Sound.adlib_sound(PRIORITY, Sound.sine_instrument(), 4, notes))
	# The (empty) digitised sounds, then the songs, as in the real files.
	for index in SOUND_COUNT:
		chunks.append(PackedByteArray())
	for song in SONG_COUNT:
		var commands: Array[PackedInt32Array] = []
		for write in Sound.sine_writes(0):
			commands.append(PackedInt32Array([write[0], write[1], 0]))
		for write in Sound.key_on_writes(0, Sound.A440_F_NUMBER + song, Sound.A440_BLOCK):
			commands.append(PackedInt32Array([write[0], write[1], 100]))
		chunks.append(Sound.song(commands))
	return chunks


## The audio of the fixture episode with [param settings]; its rendering
## runs in the background but is never handed to a player (nothing polls
## it: an AudioStreamPlayer cannot play outside the scene tree).
func _audio(settings := UserSettings.new()) -> GalaxyAudio:
	var audio := GalaxyAudio.new()
	audio.load_sounds(_data, _rules, settings, PackedInt32Array([0]))
	return audio


static func _done(audio: GalaxyAudio) -> void:
	audio.library.stop()
	audio.free()


func test_the_audio_takes_the_episodes_tables() -> void:
	var audio := _audio()
	audio.library.wait()
	assert_equal(audio.library.sound_count(), SOUND_COUNT, "the rules' sound count")
	assert_equal(audio.library.songs.size(), SONG_COUNT, "the rules' song count")
	assert_equal(GalaxyAudio.first_song(_data.audio, SONG_COUNT), 3 * SOUND_COUNT, "the last two")
	assert_equal(audio.names, NAMES, "the rules' names")
	assert_equal(audio.library.cache.directory, USER_FOLDER.path_join("cache"), "its own cache")
	assert_true(
		not DirAccess.get_files_at(USER_FOLDER.path_join("cache")).is_empty(),
		"the renderings are kept there"
	)
	_done(audio)


func test_the_song_of_each_map() -> void:
	var audio := _audio()
	audio.play_map_song(0)
	assert_equal(audio.song(), 1, "map 0: song 1")
	audio.play_map_song(1)
	assert_equal(audio.song(), 0, "map 1: song 0")
	audio.play_map_song(2)
	assert_equal(audio.song(), GalaxySoundPlayer.NO_SONG, "map 2 has none: the music stops")
	audio.play_map_song(0)
	audio.play_map_song(MAP_SONGS.size())
	assert_equal(audio.song(), GalaxySoundPlayer.NO_SONG, "no such map: none")
	assert_equal(_rules.song_for_map(1), 0, "the rules agree")
	_done(audio)


func test_how_long_the_sound_still_plays() -> void:
	var audio := _audio()
	audio.set_mode(GalaxySoundPlayer.Mode.ADLIB)
	assert_equal(audio.remaining_tics(), 0, "nothing plays")
	audio.play(&"long")
	var expected := ceili(audio.library.duration(GalaxySoundLibrary.Kind.ADLIB, 0) * 70.0)
	var left := audio.remaining_tics()
	assert_true(
		left <= expected and left >= expected - TIC_SLACK,
		"the long sound's %d tics (%d)" % [expected, left]
	)
	audio.stop_sound()
	assert_equal(audio.remaining_tics(), 0, "stopped")
	audio.set_mode(GalaxySoundPlayer.Mode.OFF)
	audio.play(&"long")
	assert_equal(audio.remaining_tics(), 0, "sound off: nothing to wait for")
	_done(audio)


func test_shift_s_and_shift_m() -> void:
	var settings := UserSettings.new()
	var audio := _audio(settings)
	assert_equal(audio.mode, GalaxySoundPlayer.Mode.ADLIB, "AdLib by default")
	var titles := PackedStringArray()
	for step in 3:
		titles.append(audio.next_mode(settings))
	assert_equal(
		titles,
		PackedStringArray(["Sound: PC speaker", "Sound off", "Sound: AdLib"]),
		"AdLib, PC speaker, off, AdLib"
	)
	assert_equal(settings.sound_device, "adlib", "stored in the settings")
	assert_equal(audio.toggle_music(settings), "Music off", "music off")
	assert_true(not settings.music_enabled, "stored")
	assert_equal(audio.toggle_music(settings), "Music on", "and on again")
	settings.sound_device = "pc"
	audio.apply_settings(settings)
	assert_equal(audio.mode, GalaxySoundPlayer.Mode.PC, "the settings applied")
	_done(audio)


func test_the_episodes_own_settings() -> void:
	var path := _rules.settings_path()
	assert_equal(path, USER_FOLDER.path_join("settings.cfg"), "in its own folder")
	var settings := GalaxySettings.load_from(path)
	assert_true(settings.score_box and not settings.quiet_adlib, "the defaults")
	settings.quiet_adlib = true
	settings.score_box = false
	assert_true(settings.save(), "saved")
	var again := GalaxySettings.load_from(path)
	assert_true(again.quiet_adlib and not again.score_box, "read back")


func test_zz_clean_up() -> void:
	_remove(USER_FOLDER)


static func _remove(folder: String) -> void:
	var path := ProjectSettings.globalize_path(folder)
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for sub in directory.get_directories():
		_remove(folder.path_join(sub))
	for file in directory.get_files():
		directory.remove(file)
	DirAccess.remove_absolute(path)
