extends "res://tests/test_case.gd"
## Tests for playing Galaxy sounds with a hand-made AUDIO file
## (tests/galaxy_sound_fixtures.gd): the GalaxySoundLibrary renders in the
## background and keeps the AdLib renderings in a cache (a second start
## only loads them, a changed chunk renders again), the GalaxySoundPlayer
## follows the original's priority rule, the sound mode and music setting,
## the settings are stored, and Keen4Audio picks the song of each place and
## cycles the sound mode.

const Sound := preload("res://tests/galaxy_sound_fixtures.gd")
const CACHE_DIRECTORY := "user://test_galaxy_sound_player_cache"
const SETTINGS_PATH := "user://test_galaxy_sound_settings.cfg"
const SOUND_COUNT := 4
const SONG_COUNT := 1
const FIRST_SONG := 2 * SOUND_COUNT
## PC and AdLib priorities of the four sounds; sound 3 is two steps long.
const PC_PRIORITIES: PackedInt32Array = [50, 20, 50, 10]
const ADLIB_PRIORITIES: PackedInt32Array = [60, 20, 60, 10]
const LONG_STEPS := 280
const NAMES: Dictionary[StringName, int] = {&"big": 0, &"small": 1, &"same": 2, &"short": 3}
const SHORT_WAIT_MS := 40

var _player: GalaxySoundPlayer
var _library: GalaxySoundLibrary


func _init() -> void:
	_remove(CACHE_DIRECTORY)
	_library = _new_library(_chunks())
	_library.start()
	_library.wait()


func _chunks(changed_sound := -1) -> Array[PackedByteArray]:
	var chunks: Array[PackedByteArray] = []
	for index in SOUND_COUNT:
		var steps := LONG_STEPS if index < 3 else 2
		var bytes := PackedByteArray()
		bytes.resize(steps)
		bytes.fill(20 + index)
		chunks.append(Sound.pc_sound(PC_PRIORITIES[index], bytes))
	for index in SOUND_COUNT:
		var steps := LONG_STEPS if index < 3 else 2
		var notes := PackedByteArray()
		notes.resize(steps)
		notes.fill(100 + index + (1 if index == changed_sound else 0))
		chunks.append(Sound.adlib_sound(ADLIB_PRIORITIES[index], Sound.sine_instrument(), 4, notes))
	var commands: Array[PackedInt32Array] = []
	for write in Sound.sine_writes(0):
		commands.append(PackedInt32Array([write[0], write[1], 0]))
	for write in Sound.key_on_writes(0, Sound.A440_F_NUMBER, Sound.A440_BLOCK):
		commands.append(PackedInt32Array([write[0], write[1], 100]))
	chunks.append(Sound.song(commands))
	return chunks


func _new_library(chunks: Array[PackedByteArray]) -> GalaxySoundLibrary:
	return GalaxySoundLibrary.create(
		Sound.audio_file(chunks),
		SOUND_COUNT,
		FIRST_SONG,
		SONG_COUNT,
		GalaxySoundCache.new(CACHE_DIRECTORY)
	)


## A player on a library that is not started: its sounds are read (so
## the priorities and lengths count) but none is rendered, so nothing is
## handed to an AudioStreamPlayer, which cannot play in a headless test
## run (it is outside the scene tree's frames).
func _new_player(player := GalaxySoundPlayer.new()) -> GalaxySoundPlayer:
	player.use_library(_new_library(_chunks()), NAMES)
	return player


func test_the_library_reads_every_sound() -> void:
	assert_equal(_library.sound_count(), SOUND_COUNT, "four sounds")
	for index in SOUND_COUNT:
		assert_equal(
			_library.priority(GalaxySoundLibrary.Kind.PC, index),
			PC_PRIORITIES[index],
			"PC priority %d" % index
		)
		assert_equal(
			_library.priority(GalaxySoundLibrary.Kind.ADLIB, index),
			ADLIB_PRIORITIES[index],
			"AdLib priority %d" % index
		)
	var expected := LONG_STEPS / GalaxyAdlibSound.STEPS_PER_SECOND
	assert_true(
		absf(_library.duration(GalaxySoundLibrary.Kind.ADLIB, 0) - expected) < 0.02,
		"a sound counts as playing for its notes"
	)


func test_everything_is_rendered_into_streams() -> void:
	assert_true(_library.is_ready(), "all the work is done")
	assert_equal(_library.rendered_count, SOUND_COUNT + SONG_COUNT, "AdLib sounds and the song")
	assert_equal(_library.loaded_count, 0, "nothing was cached yet")
	for index in SOUND_COUNT:
		var pc := _library.stream(GalaxySoundLibrary.Kind.PC, index)
		var adlib := _library.stream(GalaxySoundLibrary.Kind.ADLIB, index)
		assert_true(pc != null and adlib != null, "sound %d in both kinds" % index)
		if pc != null and adlib != null:
			assert_equal(pc.mix_rate, SpeakerSynth.MIX_RATE, "PC at the synth's rate")
			assert_equal(adlib.mix_rate, GalaxyOpl.CHIP_RATE, "AdLib at the chip's rate")
			assert_true(Sound.peak(Sound.stream_samples(adlib)) > 0.01, "AdLib %d sounds" % index)
	var song := _library.stream(GalaxySoundLibrary.Kind.SONG, 0)
	assert_true(song != null, "the song")
	if song != null:
		assert_equal(song.loop_mode, AudioStreamWAV.LOOP_FORWARD, "a song loops")
		assert_true(song.loop_end > song.loop_begin, "over one round")
	assert_true(_library.stream(GalaxySoundLibrary.Kind.SONG, 1) == null, "no second song")


func test_a_second_start_loads_from_the_cache() -> void:
	var files := DirAccess.get_files_at(CACHE_DIRECTORY)
	assert_equal(files.size(), SOUND_COUNT + SONG_COUNT, "one file a rendering (%s)" % [files])
	var again := _new_library(_chunks())
	again.start()
	again.wait()
	assert_equal(again.rendered_count, 0, "nothing rendered again")
	assert_equal(again.loaded_count, SOUND_COUNT + SONG_COUNT, "all loaded")
	for kind in [GalaxySoundLibrary.Kind.ADLIB, GalaxySoundLibrary.Kind.SONG]:
		var stream := again.stream(kind, 0)
		var first := _library.stream(kind, 0)
		assert_true(stream != null and first != null, "kind %d ready" % kind)
		if stream != null and first != null:
			assert_equal(stream.data, first.data, "the same audio from the cache (kind %d)" % kind)
			assert_equal(stream.loop_begin, first.loop_begin, "the same loop")
			assert_equal(stream.loop_end, first.loop_end, "the same loop end")
			assert_equal(stream.loop_mode, first.loop_mode, "the same loop mode")


func test_a_changed_chunk_renders_again() -> void:
	var changed := _new_library(_chunks(2))
	changed.start()
	changed.wait()
	assert_equal(changed.rendered_count, 1, "only the changed sound")
	assert_equal(changed.loaded_count, SOUND_COUNT + SONG_COUNT - 1, "the rest from the cache")


func test_a_sound_needs_at_least_the_playing_priority() -> void:
	var player := _new_player()
	player.play(&"big")
	assert_equal(player.current_sound(), 0, "the first sound plays")
	assert_equal(player.current_priority(), ADLIB_PRIORITIES[0], "with the AdLib priority")
	player.play(&"small")
	assert_equal(player.current_sound(), 0, "a lower priority does not interrupt")
	player.play(&"same")
	assert_equal(player.current_sound(), 2, "the same priority does")
	player.sound_finished()
	assert_equal(player.current_sound(), -1, "finished")
	assert_equal(player.current_priority(), 0, "priority 0 afterwards")
	player.play(&"small")
	assert_equal(player.current_sound(), 1, "then any sound plays")
	player.play(&"big")
	assert_equal(player.current_sound(), 0, "and a higher one interrupts")
	player.play(&"small", true)
	assert_equal(player.current_sound(), 1, "interrupting stops what plays")
	player.play(&"no such sound")
	assert_equal(player.current_sound(), 1, "an unknown name is silent")
	player.free()


func test_a_sound_is_over_after_its_notes() -> void:
	var player := _new_player()
	player.play(&"short")
	assert_equal(player.current_sound(), 3, "the short sound")
	OS.delay_msec(SHORT_WAIT_MS)
	assert_equal(player.current_sound(), -1, "over after its step")
	player.play(&"small")
	assert_equal(player.current_sound(), 1, "so a lower priority plays")
	player.free()


func test_the_sound_mode() -> void:
	var player := _new_player()
	assert_equal(player.mode, GalaxySoundPlayer.Mode.ADLIB, "AdLib by default")
	player.set_mode(GalaxySoundPlayer.Mode.PC)
	player.play(&"big")
	assert_equal(player.current_priority(), PC_PRIORITIES[0], "the PC sound's priority")
	player.set_mode(GalaxySoundPlayer.Mode.OFF)
	assert_equal(player.current_sound(), -1, "a new mode stops the sound")
	player.play(&"big")
	assert_equal(player.current_sound(), -1, "sound off plays nothing")
	assert_equal(GalaxySoundPlayer.mode_named("pc"), GalaxySoundPlayer.Mode.PC, "pc")
	assert_equal(GalaxySoundPlayer.mode_named("off"), GalaxySoundPlayer.Mode.OFF, "off")
	assert_equal(GalaxySoundPlayer.mode_named("?"), GalaxySoundPlayer.Mode.ADLIB, "unknown")
	assert_equal(GalaxySoundPlayer.mode_name(GalaxySoundPlayer.Mode.PC), "pc", "the name")
	player.free()


func test_music_on_and_off() -> void:
	var player := _new_player()
	player.start_song(0)
	assert_equal(player.song(), 0, "the song")
	player.set_music(false)
	assert_true(not player.music_on, "music off")
	assert_equal(player.song(), 0, "remembers the song")
	assert_true(not player.is_music_playing(), "silent")
	player.set_music(true)
	assert_equal(player.song(), 0, "the same song when the music is on again")
	player.stop_music()
	assert_equal(player.song(), GalaxySoundPlayer.NO_SONG, "stopped")
	assert_true(not player.is_music_playing(), "silent")
	player.free()


func test_the_settings_are_stored() -> void:
	var defaults := UserSettings.new()
	assert_equal(defaults.sound_device, "adlib", "AdLib by default")
	assert_true(defaults.music_enabled, "with music")
	var settings := UserSettings.load_from(SETTINGS_PATH)
	assert_equal(settings.sound_device, "adlib", "no file: AdLib")
	settings.sound_device = "pc"
	settings.music_enabled = false
	assert_true(settings.save(), "saved")
	var loaded := UserSettings.load_from(SETTINGS_PATH)
	assert_equal(loaded.sound_device, "pc", "the device")
	assert_true(not loaded.music_enabled, "music off")
	assert_true(loaded.sound_enabled, "the Keen 1-3 setting untouched")
	DirAccess.remove_absolute(SETTINGS_PATH)


func test_keen4_audio_cycles_the_mode_and_music() -> void:
	var audio := Keen4Audio.new()
	var settings := UserSettings.new()
	settings.path = SETTINGS_PATH
	audio.apply_settings(settings)
	assert_equal(audio.mode, GalaxySoundPlayer.Mode.ADLIB, "AdLib")
	audio.next_mode(settings)
	assert_equal(audio.mode, GalaxySoundPlayer.Mode.PC, "then the PC speaker")
	assert_equal(settings.sound_device, "pc", "stored")
	audio.next_mode(settings)
	assert_equal(audio.mode, GalaxySoundPlayer.Mode.OFF, "then off")
	audio.next_mode(settings)
	assert_equal(audio.mode, GalaxySoundPlayer.Mode.ADLIB, "then AdLib again")
	assert_equal(settings.sound_device, "adlib", "stored")
	audio.toggle_music(settings)
	assert_true(not audio.music_on and not settings.music_enabled, "music off")
	audio.toggle_music(settings)
	assert_true(audio.music_on and settings.music_enabled, "music on")
	audio.free()


func test_keen4_audio_picks_the_song_of_each_place() -> void:
	var audio := Keen4Audio.new()
	for map in 20:
		audio.play_map_song(map)
		assert_equal(audio.song(), Keen4Sounds.song_for_map(map), "map %d" % map)
	audio.play_council_song()
	assert_equal(audio.song(), 5, "the council's song")
	audio.play_ending_song()
	assert_equal(audio.song(), 3, "the end: map 7's song")
	audio.play_story_song()
	assert_equal(audio.song(), 2, "the story: map 12's song")
	audio.play_map_song(19)
	assert_equal(audio.song(), GalaxySoundPlayer.NO_SONG, "the high-score map: none")
	audio.free()


func test_zz_clean_up() -> void:
	_remove(CACHE_DIRECTORY)
	assert_true(not DirAccess.dir_exists_absolute(CACHE_DIRECTORY), "the test cache is gone")


func _remove(folder: String) -> void:
	if not DirAccess.dir_exists_absolute(folder):
		return
	for file_name in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(file_name))
	DirAccess.remove_absolute(folder)
