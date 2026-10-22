extends "res://tests/test_case.gd"
## Checks Keen 4's sounds and songs in the player's real files (skipped
## without them; nothing of them is in the repository): 52 PC speaker and
## 52 AdLib sounds and 6 songs decode, the two versions of a sound share
## its priority, every AdLib instrument is valid, each song's length, the
## song of each map (Omni `EPISODE.CK4`), the sound names, and that a
## sound and the shortest song render to plausible audio.

const Sound := preload("res://tests/galaxy_sound_fixtures.gd")
const SOUND_COUNT := 52
const SONG_COUNT := 6
const FIRST_SONG_V1_0 := 156
## One round of each song in ticks: the delays without the last, + 1
## (all six end on a delay of 0); from the user's v1.0.
const SONG_ROUND_TICKS: PackedInt32Array = [11689, 29942, 9058, 25385, 18355, 7188]
const SONG_COMMANDS: PackedInt32Array = [933, 2476, 685, 3605, 1800, 570]
## The song of maps 0-19 (Omni CK_LevelMusic; research.md §10).
const MAP_SONGS: PackedInt32Array = [0, 4, 3, 3, 2, 2, 4, 3, 1, 1, 1, 2, 2, 2, 2, 2, 2, 1, 3, -1]
## Sound numbers by Omni's names (EPISODE.CK4).
const OMNI_NUMBERS: Dictionary[StringName, int] = {
	&"keen_walk_1": 0,
	&"keen_jump": 2,
	&"keen_land": 3,
	&"keen_shoot": 4,
	&"keen_pogo": 7,
	&"got_gem": 19,
	&"keen_die": 23,
	&"council_saved": 31,
	&"status_down": 34,
	&"dopefish_burp": 42,
	&"paddle_keen_scores": 51,
}
const JUMP := 2
const SHORTEST_SONG := 5
## Rendering may take at most this many seconds per second of music.
const SONG_RENDER_SECONDS_LIMIT := 3.0

var _data: GalaxyData


func _init() -> void:
	var files := Keen4Files.locate()
	if files == null:
		skip("no Keen 4 files in game_data/keen4")
		return
	_data = Keen4Episode.load_data(files)


func _first_song() -> int:
	return Keen4Sounds.first_song(_data.audio)


func test_the_chunks_of_sounds_and_songs() -> void:
	if _data == null:
		return
	assert_equal(Keen4Sounds.SOUND_COUNT, SOUND_COUNT, "52 sounds")
	assert_equal(Keen4Sounds.SONG_COUNT, SONG_COUNT, "6 songs")
	if _data.executable.version == "1.0":
		assert_equal(_first_song(), FIRST_SONG_V1_0, "the songs from chunk 156 in 1.0")
	for index in SONG_COUNT:
		assert_true(not _data.audio.is_empty(_first_song() + index), "song %d is there" % index)


func test_every_pc_sound_decodes() -> void:
	if _data == null:
		return
	for index in SOUND_COUNT:
		var chunk := _data.audio.chunk(index)
		var sound := GalaxyPcSound.parse(chunk)
		assert_true(sound != null, "PC sound %d" % index)
		if sound == null:
			continue
		assert_equal(sound.steps.size(), chunk.decode_u32(0), "PC sound %d: every step" % index)
		assert_true(sound.duration() > 0.0, "PC sound %d lasts" % index)
		var multiples := true
		for divisor in sound.divisors():
			multiples = multiples and divisor % Sound.PC_DIVISOR_STEP == 0
		assert_true(multiples, "PC sound %d: divisors are bytes × 60" % index)


func test_every_adlib_sound_decodes() -> void:
	if _data == null:
		return
	for index in SOUND_COUNT:
		var chunk := _data.audio.chunk(SOUND_COUNT + index)
		var sound := GalaxyAdlibSound.parse(chunk)
		assert_true(sound != null, "AdLib sound %d" % index)
		if sound == null:
			continue
		assert_equal(sound.notes.size(), chunk.decode_u32(0), "AdLib sound %d: every note" % index)
		assert_equal(sound.instrument.size(), Sound.INSTRUMENT_SIZE, "a 16-byte instrument")
		assert_true(
			sound.instrument[Sound.M_SUS] | sound.instrument[Sound.C_SUS] != 0,
			"AdLib sound %d has a valid instrument (Omni: 'Bad instrument')" % index
		)
		var pc := GalaxyPcSound.parse(_data.audio.chunk(index))
		if pc != null:
			assert_equal(sound.priority, pc.priority, "sound %d: one priority for both" % index)


func test_every_song_decodes_with_its_length() -> void:
	if _data == null:
		return
	for index in SONG_COUNT:
		var chunk := _data.audio.chunk(_first_song() + index)
		var song := GalaxyMusic.parse(chunk)
		assert_true(song != null, "song %d" % index)
		if song == null:
			continue
		assert_equal(song.command_count(), SONG_COMMANDS[index], "song %d: its commands" % index)
		assert_equal(song.loop_ticks(), SONG_ROUND_TICKS[index], "song %d: one round" % index)
		var seconds := SONG_ROUND_TICKS[index] / GalaxyMusic.TICKS_PER_SECOND
		assert_true(
			absf(song.duration() - seconds) < 0.01, "song %d lasts %.2f s" % [index, seconds]
		)


func test_the_song_of_each_place() -> void:
	for map in MAP_SONGS.size():
		assert_equal(Keen4Sounds.song_for_map(map), MAP_SONGS[map], "map %d" % map)
	assert_equal(Keen4Sounds.song_for_map(20), Keen4Sounds.NO_SONG, "no map 20")
	assert_equal(Keen4Sounds.song_for_map(-1), Keen4Sounds.NO_SONG, "no map -1")
	assert_equal(Keen4Sounds.COUNCIL_SONG, 5, "the council's messages (Omni ck4_specialMusic)")
	assert_equal(Keen4Sounds.ENDING_MAP, 7, "the end plays map 7's song")
	assert_equal(Keen4Sounds.STORY_MAP, 12, "the story map 12's")


func test_the_sound_names() -> void:
	var numbers := Keen4Sounds.NUMBERS.values()
	numbers.sort()
	var expected: Array = range(SOUND_COUNT)
	assert_equal(numbers, expected, "every sound number once")
	for sound_name in OMNI_NUMBERS:
		assert_equal(
			Keen4Sounds.NUMBERS.get(sound_name, -1), OMNI_NUMBERS[sound_name], String(sound_name)
		)


func test_a_sound_renders_in_both_kinds() -> void:
	if _data == null:
		return
	var pc := GalaxyPcSound.parse(_data.audio.chunk(JUMP))
	var pc_samples := Sound.stream_samples(pc.render())
	assert_true(Sound.peak(pc_samples) > 0.05, "the PC jump sounds")
	var expected := ceili(pc.duration() * SpeakerSynth.MIX_RATE)
	assert_true(
		absi(pc_samples.size() - expected) < SpeakerSynth.MIX_RATE / 100,
		"for its steps (%d samples, got %d)" % [expected, pc_samples.size()]
	)
	var adlib := GalaxyAdlibSound.parse(_data.audio.chunk(SOUND_COUNT + JUMP))
	var samples := adlib.render_samples()
	var loudest := Sound.peak(samples)
	assert_true(
		loudest > 0.05 and loudest < 1.0, "the AdLib jump sounds, unclipped (%.3f)" % loudest
	)
	var notes := roundi(adlib.duration() * GalaxyOpl.CHIP_RATE)
	assert_true(
		(
			samples.size() >= notes - GalaxyOpl.CHIP_RATE / 100
			and samples.size() <= notes + GalaxyOpl.CHIP_RATE + 1024
		),
		"its notes plus at most a second of release"
	)


func test_the_shortest_song_renders() -> void:
	if _data == null:
		return
	var song := GalaxyMusic.parse(_data.audio.chunk(_first_song() + SHORTEST_SONG))
	var started := Time.get_ticks_msec()
	var result := song.render()
	var seconds := (Time.get_ticks_msec() - started) / 1000.0
	var samples: PackedFloat32Array = result.get("samples", PackedFloat32Array())
	var loop_begin: int = result.get("loop_begin", -1)
	var loop_end: int = result.get("loop_end", -1)
	var round_samples := song.duration() * GalaxyOpl.CHIP_RATE
	assert_true(absf(loop_end - loop_begin - round_samples) <= 2.0, "the loop is one round")
	assert_true(loop_end <= samples.size(), "inside the audio")
	var loudest := Sound.peak(samples)
	assert_true(loudest > 0.05, "it sounds (%.3f)" % loudest)
	assert_true(loudest < 1.0, "never clipped (%.3f)" % loudest)
	var quiet_seconds := 0
	var second := GalaxyOpl.CHIP_RATE
	for start in range(0, loop_end - second, second):
		if Sound.rms(samples, start, second) < 0.003:
			quiet_seconds += 1
	assert_true(quiet_seconds <= 1, "music all through (%d silent seconds)" % quiet_seconds)
	var music_seconds := samples.size() / float(GalaxyOpl.CHIP_RATE)
	assert_true(
		seconds < music_seconds * SONG_RENDER_SECONDS_LIMIT,
		"rendered in %.1f s for %.1f s of music" % [seconds, music_seconds]
	)
