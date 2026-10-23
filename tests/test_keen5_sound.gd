extends "res://tests/test_case.gd"
## Checks Keen 5's sounds and songs ([Keen5Sounds], milestone E8): the
## table (64 numbers, each once, Omnispeak's and Commander Genius's
## numbers, not Keen 4's), every sound name the Galaxy and Keen 5 code
## plays resolves to a number (a scan of the sources), the song of each map
## (Omni CK_LevelMusic) and of the screens, the rules that carry them and
## the cache in Keen 5's own user folder; with the player's files (skipped
## without them; nothing of them is in the repository): 206 chunks, the 14
## songs at 192-205, every sound and song decodes, one priority for both
## versions of a sound, each song's length.

const Sound := preload("res://tests/galaxy_sound_fixtures.gd")
const SOUND_COUNT := 64
const SONG_COUNT := 14
const CHUNK_COUNT := 206
const FIRST_SONG := 192
## One round of each song in ticks and its commands (the user's v1.4).
const SONG_ROUND_TICKS: PackedInt32Array = [
	13666, 31592, 18385, 45910, 22798, 31152, 34301, 28059, 27319, 35261, 32765, 35448, 11067, 34690
]
const SONG_COMMANDS: PackedInt32Array = [
	1105, 1600, 1466, 4277, 1610, 3314, 3925, 4115, 1413, 2980, 3080, 2819, 2320, 2152
]
## The song of maps 0-19 (Omni CK_LevelMusic; research.md §9).
const MAP_SONGS: PackedInt32Array = [
	11, 5, 7, 9, 10, 9, 10, 9, 10, 9, 10, 3, 13, 4, 12, 2, 6, 1, 0, 8
]
## Sound numbers by Omni's names (EPISODE.CK5) and, where Omni says
## UNKNOWN, Commander Genius's (CAudioGalaxy.cpp).
const OMNI_NUMBERS: Dictionary[StringName, int] = {
	&"keen_walk_1": 0,
	&"keen_jump": 2,
	&"mine_explode": 5,
	&"got_drop": 10,
	&"enter_level": 12,
	&"level_exit": 13,
	&"need_keycard": 14,
	&"open_security_door": 18,
	&"got_gem": 19,
	&"keen_die": 23,
	&"status_down": 34,
	&"status_up": 35,
	&"teleport": 41,
	&"fuse_break": 52,
	&"galaxy_explode": 53,
	&"galaxy_explode_pre": 54,
	&"got_keycard": 55,
	&"keen_land_on_fuse": 57,
	&"open_gem_door": 60,
	&"elevator_door": 63,
}
## Names whose Keen 5 number is not Keen 4's (the table is Keen 5's own).
const NOT_KEEN_4: Array[StringName] = [&"open_gem_door", &"paddle_keen", &"mine_explode"]
## Where the code Keen 5 runs lives.
const SOURCE_FOLDERS: PackedStringArray = ["res://src/galaxy", "res://src/keen5"]
## A sound asked for by its name: played by the world, the screen or a
## scene, given to a shot or a flight, sent by Paddle War (E9).
const SOUND_CALL := '(?:play_sound|_bounce|hit_sound\\s*:?=|play|emit)\\s*\\(?\\s*&"([a-z0-9_]+)"'
## At least this many names are found (a broken scan finds none).
const LEAST_NAMES := 40
const LEVEL_EXIT := 13

var _data: GalaxyData


func _init() -> void:
	var files := Keen5Files.locate()
	if files != null:
		_data = Keen5Episode.load_data(files)


func test_the_table_has_every_number_once() -> void:
	assert_equal(Keen5Sounds.SOUND_COUNT, SOUND_COUNT, "64 sounds")
	assert_equal(Keen5Sounds.SONG_COUNT, SONG_COUNT, "14 songs")
	var numbers := Keen5Sounds.NUMBERS.values()
	numbers.sort()
	var expected: Array = range(SOUND_COUNT)
	assert_equal(numbers, expected, "every sound number once")
	for sound_name in OMNI_NUMBERS:
		assert_equal(
			Keen5Sounds.NUMBERS.get(sound_name, -1), OMNI_NUMBERS[sound_name], String(sound_name)
		)
	for sound_name in NOT_KEEN_4:
		assert_true(
			Keen5Sounds.NUMBERS[sound_name] != Keen4Sounds.NUMBERS[sound_name],
			"%s is Keen 5's own number" % sound_name
		)


func test_every_sound_the_code_plays_has_a_number() -> void:
	var found := _sound_names_in_sources()
	assert_true(found.size() >= LEAST_NAMES, "the scan finds the names (%d)" % found.size())
	for sound_name in found:
		assert_true(
			Keen5Sounds.NUMBERS.has(sound_name),
			"%s (%s) has a Keen 5 number" % [sound_name, found[sound_name]]
		)
	var items: Array[StringName] = Keen5Keen.ITEM_SOUNDS_KEEN_5
	for sound_name in items:
		assert_true(Keen5Sounds.NUMBERS.has(sound_name), "item sound %s" % sound_name)
	assert_equal(Keen5Sounds.NUMBERS[items[Keen5Inventory.KEYCARD_ITEM]], 55, "the keycard's")


func test_the_song_of_each_map_and_screen() -> void:
	for map in MAP_SONGS.size():
		assert_equal(Keen5Sounds.song_for_map(map), MAP_SONGS[map], "map %d" % map)
	assert_equal(Keen5Sounds.song_for_map(20), Keen5Sounds.NO_SONG, "no map 20")
	assert_equal(Keen5Sounds.song_for_map(-1), Keen5Sounds.NO_SONG, "no map -1")
	var rules := Keen5Episode.game_rules()
	assert_equal(rules.song_for_map(rules.story_song), 1, "the story: Having Tea (map 17)")
	assert_equal(rules.song_for_map(rules.ending_song), 12, "the end: the Fanfare (map 14)")
	assert_equal(rules.song_for_map(rules.game_over_song), 0, "game over: song 0 (map 18)")
	assert_equal(rules.song_for_map(rules.help_song), 8, "the help: A Shikadi Aire (map 19)")
	assert_equal(rules.song_for_map(Keen5Episode.HIGH_SCORE_MAP), 2, "the high scores: song 2")
	assert_equal(rules.sound_count, SOUND_COUNT, "the rules' sound count")
	assert_equal(rules.song_count, SONG_COUNT, "the rules' song count")
	assert_equal(rules.sound_names, Keen5Sounds.NUMBERS, "the rules' names")


func test_the_cache_and_settings_are_keen_5s_own() -> void:
	var rules := Keen5Episode.game_rules()
	assert_equal(rules.sound_cache_folder(), "user://keen5/cache", "the cache")
	assert_equal(rules.settings_path(), "user://keen5/settings.cfg", "the settings")
	assert_true(not rules.sound_cache_folder().contains("keen4"), "never Keen 4's folder")


func test_the_chunks_of_sounds_and_songs() -> void:
	if _data == null:
		return
	assert_equal(_data.audio.chunk_count(), CHUNK_COUNT, "206 chunks")
	assert_equal(GalaxyAudio.first_song(_data.audio, SONG_COUNT), FIRST_SONG, "the songs from 192")
	for index in SOUND_COUNT:
		assert_true(_data.audio.is_empty(SOUND_COUNT * 2 + index), "no digitised sound %d" % index)


func test_every_sound_decodes_with_one_priority() -> void:
	if _data == null:
		return
	for index in SOUND_COUNT:
		var pc := GalaxyPcSound.parse(_data.audio.chunk(index))
		var adlib := GalaxyAdlibSound.parse(_data.audio.chunk(SOUND_COUNT + index))
		assert_true(pc != null and adlib != null, "sound %d decodes" % index)
		if pc == null or adlib == null:
			continue
		assert_true(pc.duration() > 0.0 and adlib.duration() > 0.0, "sound %d lasts" % index)
		assert_equal(adlib.instrument.size(), Sound.INSTRUMENT_SIZE, "a 16-byte instrument")
		assert_equal(adlib.priority, pc.priority, "sound %d: one priority for both" % index)


func test_every_song_decodes_with_its_length() -> void:
	if _data == null:
		return
	for index in SONG_COUNT:
		var song := GalaxyMusic.parse(_data.audio.chunk(FIRST_SONG + index))
		assert_true(song != null, "song %d" % index)
		if song == null:
			continue
		assert_equal(song.command_count(), SONG_COMMANDS[index], "song %d: its commands" % index)
		assert_equal(song.loop_ticks(), SONG_ROUND_TICKS[index], "song %d: one round" % index)


func test_the_library_reads_keen_5s_sounds_into_its_cache() -> void:
	if _data == null:
		return
	var audio := GalaxyAudio.new()
	var settings := UserSettings.new()
	audio.load_sounds(
		_data, Keen5Episode.game_rules(), settings, PackedInt32Array([Keen5Episode.WORLD_MAP])
	)
	assert_equal(audio.library.cache.directory, "user://keen5/cache", "Keen 5's cache")
	assert_equal(audio.library.sound_count(), SOUND_COUNT, "64 sounds")
	assert_equal(audio.library.songs.size(), SONG_COUNT, "14 songs")
	assert_equal(audio.names[&"level_exit"], LEVEL_EXIT, "Keen 5's names")
	assert_equal(audio.song_for_map(Keen5Episode.WORLD_MAP), 11, "the map: Robo Red Rock")
	audio.library.stop()
	audio.free()


## Every sound name in the code Keen 5 runs, with the file it is in.
func _sound_names_in_sources() -> Dictionary[StringName, String]:
	var pattern := RegEx.create_from_string(SOUND_CALL)
	var found: Dictionary[StringName, String] = {}
	for path in _scripts():
		var text := FileAccess.get_file_as_string(path)
		for match in pattern.search_all(text):
			found[StringName(match.get_string(1))] = path.get_file()
	return found


func _scripts() -> PackedStringArray:
	var paths := PackedStringArray()
	var folders := Array(SOURCE_FOLDERS)
	while not folders.is_empty():
		var folder: String = folders.pop_back()
		for sub in DirAccess.get_directories_at(folder):
			folders.append(folder.path_join(sub))
		for file in DirAccess.get_files_at(folder):
			if file.ends_with(".gd"):
				paths.append(folder.path_join(file))
	return paths
