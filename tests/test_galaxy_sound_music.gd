extends "res://tests/test_case.gd"
## Tests for the Galaxy songs (GalaxyMusic) and the cache of rendered
## audio (GalaxySoundCache) with hand-made data: the commands of a song,
## its delays at about 560 ticks a second, one round as the original plays
## it (the last delay is never waited for; Omni `id_sd.c`,
## SD_AL_MusicService), the loop, the waveforms enabled as after the
## original's reset, stopping a render; and cache files by the hash of the
## chunk.

const Sound := preload("res://tests/galaxy_sound_fixtures.gd")
const CACHE_DIRECTORY := "user://test_galaxy_sound_music_cache"
## 870 in block 4 is 660 Hz.
const HIGH_F_NUMBER := 870
const HALF_SECOND_TICKS := 280
const SHORT_TICKS := 140
const LAST_DELAY := 33
const PITCH_TOLERANCE := 0.01
const SILENT_DB := -40.0


## A song: 440 Hz for 280 ticks, a pause of 280 ticks, 660 Hz for 140
## ticks, then the key off as the last command (its delay never counts).
func _song_commands(waveform := 0) -> Array[PackedInt32Array]:
	var commands: Array[PackedInt32Array] = []
	for write in Sound.sine_writes(0):
		commands.append(PackedInt32Array([write[0], write[1], 0]))
	if waveform != 0:
		commands.append(PackedInt32Array([Sound.WAVEFORM + Sound.CARRIERS[0], waveform, 0]))
	var key_on := Sound.KEY_ON | (Sound.A440_BLOCK << 2)
	var key_off := Sound.A440_BLOCK << 2
	commands.append(PackedInt32Array([Sound.FREQUENCY_LOW, Sound.A440_F_NUMBER & 0xFF, 0]))
	commands.append(
		PackedInt32Array([Sound.KEY_BLOCK, key_on | (Sound.A440_F_NUMBER >> 8), HALF_SECOND_TICKS])
	)
	commands.append(PackedInt32Array([Sound.KEY_BLOCK, key_off, HALF_SECOND_TICKS]))
	commands.append(PackedInt32Array([Sound.FREQUENCY_LOW, HIGH_F_NUMBER & 0xFF, 0]))
	commands.append(PackedInt32Array([Sound.KEY_BLOCK, key_on | (HIGH_F_NUMBER >> 8), SHORT_TICKS]))
	commands.append(PackedInt32Array([Sound.KEY_BLOCK, key_off | (HIGH_F_NUMBER >> 8), LAST_DELAY]))
	return commands


func _sample_of(seconds: float) -> int:
	return Sound.samples_for(seconds)


func _seconds_of(ticks: int) -> float:
	return ticks / GalaxyMusic.TICKS_PER_SECOND


func test_the_tick_rate() -> void:
	assert_true(
		absf(GalaxyMusic.TICKS_PER_SECOND - Sound.SONG_RATE) < 1.5,
		"about 560 ticks a second (%.3f)" % GalaxyMusic.TICKS_PER_SECOND
	)
	assert_true(
		absf(GalaxyMusic.TICKS_PER_SECOND / 4.0 - GalaxyAdlibSound.STEPS_PER_SECOND) < 0.01,
		"the sounds step at a quarter of it"
	)


func test_a_song_is_read() -> void:
	var commands := _song_commands()
	var song := GalaxyMusic.parse(Sound.song(commands))
	assert_true(song != null, "parsed")
	if song == null:
		return
	assert_equal(song.command_count(), commands.size(), "four bytes a command")
	var total := 2 * HALF_SECOND_TICKS + SHORT_TICKS + LAST_DELAY
	assert_equal(song.delay_sum(), total, "every delay")
	assert_equal(song.loop_ticks(), total - LAST_DELAY + 1, "a round: not the last delay, +1 tick")
	assert_true(absf(song.duration() - _seconds_of(song.loop_ticks())) < 1e-6, "a round in seconds")
	assert_true(GalaxyMusic.parse(PackedByteArray([1])) == null, "too short")


func test_an_empty_song_renders_nothing() -> void:
	var song := GalaxyMusic.parse(Sound.song([]))
	assert_true(song != null, "an empty song is read")
	if song == null:
		return
	assert_equal(song.command_count(), 0, "no commands")
	assert_equal(song.loop_ticks(), 0, "no round")
	assert_true(song.render().is_empty(), "nothing to render")


func test_the_delays_time_the_notes() -> void:
	var song := GalaxyMusic.parse(Sound.song(_song_commands()))
	var result := song.render()
	var samples: PackedFloat32Array = result.get("samples", PackedFloat32Array())
	var rate := Sound.rate()
	var full := Sound.rms(samples, _sample_of(0.1), _sample_of(0.2))
	assert_true(full > 0.05, "the first note sounds from the start (%.3f)" % full)
	var first := Sound.zero_crossing_frequency(samples, rate, _sample_of(0.02), _sample_of(0.45))
	assert_true(absf(first - Sound.A440) < PITCH_TOLERANCE * Sound.A440, "440 Hz (%.1f)" % first)
	var off := _seconds_of(HALF_SECOND_TICKS)
	var pause := Sound.rms(samples, _sample_of(off + 0.03), _sample_of(off - 0.06))
	assert_true(
		Sound.decibels(pause / full) < SILENT_DB, "silent after 280 ticks (key off; %.4f)" % pause
	)
	var just_before := Sound.rms(samples, _sample_of(off - 0.01), _sample_of(0.005))
	assert_true(just_before > 0.5 * full, "and not before")
	var high_start := _seconds_of(2 * HALF_SECOND_TICKS)
	var high := Sound.zero_crossing_frequency(
		samples, rate, _sample_of(high_start + 0.02), _sample_of(_seconds_of(SHORT_TICKS) - 0.04)
	)
	var expected := Sound.opl_frequency(HIGH_F_NUMBER, Sound.A440_BLOCK)
	assert_true(absf(high - expected) < PITCH_TOLERANCE * expected, "then 660 Hz (%.1f)" % high)
	var before_high := Sound.rms(samples, _sample_of(high_start - 0.02), _sample_of(0.015))
	assert_true(Sound.decibels(before_high / full) < SILENT_DB, "not earlier")


func test_the_next_round_follows_one_tick_after_the_last_command() -> void:
	var song := GalaxyMusic.parse(Sound.song(_song_commands()))
	var samples: PackedFloat32Array = song.render().get("samples", PackedFloat32Array())
	var round_start := _seconds_of(song.loop_ticks())
	var last := _seconds_of(song.loop_ticks() - 1)
	var full := Sound.rms(samples, _sample_of(0.1), _sample_of(0.2))
	var gap := Sound.rms(samples, _sample_of(last + 0.0005), _sample_of(round_start - last - 0.001))
	assert_true(Sound.decibels(gap / full) < -6.0, "the last command keys off")
	var again := Sound.zero_crossing_frequency(
		samples, Sound.rate(), _sample_of(round_start + 0.02), _sample_of(0.4)
	)
	assert_true(
		absf(again - Sound.A440) < PITCH_TOLERANCE * Sound.A440,
		"the song starts again (%.1f Hz at %.3f s)" % [again, round_start]
	)
	for seconds: float in [0.1, 0.3, 1.1]:
		var level := Sound.rms(samples, _sample_of(seconds), Sound.window())
		var later := Sound.rms(samples, _sample_of(seconds + round_start), Sound.window())
		assert_true(
			absf(Sound.decibels(later / level)) < 1.0,
			"a round later the same at %.1f s (%.3f, %.3f)" % [seconds, level, later]
		)


func test_the_loop_is_one_round() -> void:
	var song := GalaxyMusic.parse(Sound.song(_song_commands()))
	var result := song.render()
	var samples: PackedFloat32Array = result.get("samples", PackedFloat32Array())
	var loop_begin: int = result.get("loop_begin", -1)
	var loop_end: int = result.get("loop_end", -1)
	assert_true(
		loop_begin >= 0 and loop_begin < loop_end, "a loop (%d-%d)" % [loop_begin, loop_end]
	)
	assert_true(loop_end <= samples.size(), "inside the samples")
	var expected := song.loop_ticks() * Sound.rate() / GalaxyMusic.TICKS_PER_SECOND
	assert_true(
		absf(loop_end - loop_begin - expected) <= 2.0,
		"one round long (%.1f samples, got %d)" % [expected, loop_end - loop_begin]
	)
	var window := Sound.window()
	var at_begin := Sound.rms(samples, loop_begin - window, window)
	var at_end := Sound.rms(samples, loop_end - window, window)
	assert_true(
		absf(at_begin - at_end) < 0.05 * maxf(Sound.rms(samples, 0, samples.size()), 1e-6),
		"the seam is seamless: the same before both loop points (%.4f, %.4f)" % [at_begin, at_end]
	)


func test_song_waveforms_are_enabled_as_after_the_reset() -> void:
	var song := GalaxyMusic.parse(Sound.song(_song_commands(1)))
	var samples: PackedFloat32Array = song.render().get("samples", PackedFloat32Array())
	var window := samples.slice(_sample_of(0.05), _sample_of(0.4))
	var lowest := 0.0
	for sample in window:
		lowest = minf(lowest, sample)
	assert_true(Sound.peak(window) > 0.05, "it sounds")
	assert_true(
		lowest > -0.02 * Sound.peak(window),
		"waveform 1 is a half sine without the song writing 0x01 (%.3f)" % lowest
	)


func test_a_render_can_be_stopped() -> void:
	var commands: Array[PackedInt32Array] = []
	for index in 300:
		commands.append(PackedInt32Array([Sound.FREQUENCY_LOW, index & 0xFF, 1]))
	var song := GalaxyMusic.parse(Sound.song(commands))
	assert_true(song.render(func() -> bool: return true).is_empty(), "nothing when cancelled")
	assert_true(not song.render(func() -> bool: return false).is_empty(), "rendered otherwise")


func test_cache_names_follow_the_chunk() -> void:
	var chunk := Sound.song(_song_commands())
	var name := GalaxySoundCache.key(chunk)
	assert_equal(name.length(), 64, "a sha-256 in hex")
	assert_equal(GalaxySoundCache.key(chunk.duplicate()), name, "the same bytes, the same name")
	var changed := chunk.duplicate()
	changed[changed.size() - 1] ^= 1
	assert_true(GalaxySoundCache.key(changed) != name, "another chunk, another name")


func test_cache_stores_and_loads() -> void:
	var cache := GalaxySoundCache.new(CACHE_DIRECTORY)
	assert_equal(GalaxySoundCache.new().directory, "user://keen4/cache", "the default folder")
	var name := GalaxySoundCache.key(PackedByteArray([1, 2, 3]))
	assert_true(cache.path_for(name).begins_with(CACHE_DIRECTORY), "in its folder")
	assert_true(cache.load_entry(name).is_empty(), "nothing yet")
	assert_true(not cache.has(name), "not there yet")
	var pcm := GalaxyOpl.to_pcm16(Sound.sine_chip().generate(500))
	assert_true(cache.save_entry(name, pcm, 10, 400), "stored")
	assert_true(cache.has(name), "there now")
	var entry := cache.load_entry(name)
	assert_equal(entry.get("pcm"), pcm, "the same samples back")
	assert_equal(entry.get("loop_begin"), 10, "loop begin")
	assert_equal(entry.get("loop_end"), 400, "loop end")
	var sound := GalaxySoundCache.key(PackedByteArray([4]))
	cache.save_entry(sound, pcm)
	assert_equal(cache.load_entry(sound).get("loop_begin"), -1, "a sound does not loop")
	var leftovers := 0
	for file_name in DirAccess.get_files_at(CACHE_DIRECTORY):
		if not file_name.ends_with(GalaxySoundCache.EXTENSION):
			leftovers += 1
	assert_equal(leftovers, 0, "no half-written files left")
	_remove(CACHE_DIRECTORY)


func _remove(folder: String) -> void:
	for file_name in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(file_name))
	DirAccess.remove_absolute(folder)
