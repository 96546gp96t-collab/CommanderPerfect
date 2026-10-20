extends "res://tests/test_case.gd"
## Tests for the Galaxy sound effects with hand-made chunks
## (tests/galaxy_sound_fixtures.gd): the PC speaker sounds (bytes × 60 at
## about 140 steps a second, the priority) through the shared
## SpeakerSynth, whose new rate parameter must leave Keen 1-3 byte for byte
## as they were; and the AdLib sounds (the instrument's bytes to the two
## operators, the octave, one note byte per step, 0 for silence, the
## connection byte ignored, the waveforms enabled as after the original's
## reset). Facts from Omni `id_sd.c`.

const Sound := preload("res://tests/galaxy_sound_fixtures.gd")
## SpeakerSynth.render_samples before D9 (md5 of the bytes), for three
## divisor lists: the default rate must not change.
const SYNTH_CASES: Array[PackedInt32Array] = [
	[1000, 0],
	[1, 0, 2000, 2000, 5000, 120, 0, 300],
	[800, 900, 1000, 1100, 1200, 1300, 1400, 0, 0, 4000],
]
const SYNTH_MD5: PackedStringArray = [
	"41200e200946987e903dfe85f337c8c0",
	"e5b746866bfa12fcff2e2e357fe33c53",
	"591510218939549cc2f0415a3fcfc216",
]
## All 42 Keen 1 sounds rendered before D9, in name order (md5).
const KEEN1_SOUNDS_MD5 := "acff40f9125147db780a8bd1ee28a456"
const KEEN1_SOUND_COUNT := 42
const PRIORITY := 77
## Byte 20 is divisor 1200: 994.3 Hz; byte 40 half that.
const PC_BYTE := 20
const PC_LOW_BYTE := 40
const TIMER_CLOCK := 1193182.0
## Note 145 in block 5 is 220 Hz; note 200 is 303 Hz.
const NOTE := 145
const OTHER_NOTE := 200
const NOTE_BLOCK := 5
const STEPS := 28
const PITCH_TOLERANCE := 0.01


func _pc_frequency(byte: int) -> float:
	return TIMER_CLOCK / (byte * Sound.PC_DIVISOR_STEP)


func _repeat(value: int, count: int) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(count)
	bytes.fill(value)
	return bytes


func _step_samples(steps: float, rate: float) -> int:
	return roundi(steps * rate / GalaxyAdlibSound.STEPS_PER_SECOND)


func _adlib(notes: PackedByteArray, instrument := Sound.sine_instrument()) -> GalaxyAdlibSound:
	return GalaxyAdlibSound.parse(Sound.adlib_sound(PRIORITY, instrument, NOTE_BLOCK, notes))


func test_pc_sound_is_read() -> void:
	var steps := PackedByteArray([PC_BYTE, 0, PC_LOW_BYTE, 255])
	var sound := GalaxyPcSound.parse(Sound.pc_sound(PRIORITY, steps))
	assert_true(sound != null, "parsed")
	if sound == null:
		return
	assert_equal(sound.priority, PRIORITY, "the priority")
	assert_equal(sound.steps, steps, "the steps, without the trailing byte")
	assert_equal(
		sound.divisors(), PackedInt32Array([1200, 0, 2400, 15300]), "bytes × 60, 0 stays silence"
	)
	assert_true(GalaxyPcSound.parse(PackedByteArray([1, 2, 3])) == null, "too short")


func test_sound_steps_run_at_about_140_a_second() -> void:
	assert_true(
		absf(GalaxyPcSound.STEPS_PER_SECOND - Sound.SOUND_RATE) < 0.5,
		"PC: %.3f steps a second" % GalaxyPcSound.STEPS_PER_SECOND
	)
	assert_true(
		absf(GalaxyAdlibSound.STEPS_PER_SECOND - Sound.SOUND_RATE) < 0.5,
		"AdLib: %.3f steps a second" % GalaxyAdlibSound.STEPS_PER_SECOND
	)
	var sound := GalaxyPcSound.parse(Sound.pc_sound(PRIORITY, _repeat(PC_BYTE, 141)))
	assert_true(
		absf(sound.duration() - 140.0 / GalaxyPcSound.STEPS_PER_SECOND) < 1e-6,
		"141 bytes count as 140 steps, about a second (the last is cut)"
	)


func test_pc_sound_renders_its_pitch_and_length() -> void:
	var steps := _repeat(PC_BYTE, STEPS)
	steps.append_array(_repeat(PC_LOW_BYTE, STEPS))
	var sound := GalaxyPcSound.parse(Sound.pc_sound(PRIORITY, steps))
	var stream := sound.render()
	var rate := float(SpeakerSynth.MIX_RATE)
	assert_equal(stream.mix_rate, SpeakerSynth.MIX_RATE, "the synth's rate")
	var samples := Sound.stream_samples(stream)
	var expected_size := _step_samples(2 * STEPS, rate)
	assert_true(
		absi(samples.size() - expected_size) <= roundi(rate / Sound.SOUND_RATE) + 1,
		"56 steps at 140 a second (%d samples, got %d)" % [expected_size, samples.size()]
	)
	var high := Sound.zero_crossing_frequency(
		samples, rate, _step_samples(2, rate), _step_samples(STEPS - 4, rate)
	)
	var low := Sound.zero_crossing_frequency(
		samples, rate, _step_samples(STEPS + 2, rate), _step_samples(STEPS - 6, rate)
	)
	assert_true(
		absf(high - _pc_frequency(PC_BYTE)) < PITCH_TOLERANCE * high,
		"byte 20 sounds at 994 Hz (%.1f)" % high
	)
	assert_true(
		absf(low - _pc_frequency(PC_LOW_BYTE)) < PITCH_TOLERANCE * low,
		"byte 40 sounds at 497 Hz (%.1f)" % low
	)


func test_pc_sound_silence_steps() -> void:
	var steps := _repeat(PC_BYTE, STEPS)
	steps.append_array(_repeat(0, STEPS))
	steps.append_array(_repeat(PC_BYTE, STEPS))
	var rate := float(SpeakerSynth.MIX_RATE)
	var samples := Sound.stream_samples(GalaxyPcSound.parse(Sound.pc_sound(1, steps)).render())
	var loud := Sound.rms(samples, _step_samples(4, rate), _step_samples(20, rate))
	var quiet := Sound.rms(samples, _step_samples(STEPS + 4, rate), _step_samples(20, rate))
	assert_true(loud > 0.05, "the tone sounds")
	assert_true(quiet < 0.01 * loud, "a 0 is silence")


func test_the_last_pc_step_is_cut_at_once() -> void:
	# Omni SD_PC_SoundService turns the speaker off in the same tick that
	# plays the last byte, so the last step never sounds.
	var steps := _repeat(PC_BYTE, 20)
	steps.append(PC_LOW_BYTE)
	var rate := float(SpeakerSynth.MIX_RATE)
	var samples := Sound.stream_samples(GalaxyPcSound.parse(Sound.pc_sound(1, steps)).render())
	var after := samples.slice(_step_samples(20, rate) + 2)
	assert_true(
		after.is_empty() or Sound.peak(after) < 0.02,
		"nothing after step 20 (%d samples, peak %.3f)" % [after.size(), Sound.peak(after)]
	)


func test_speaker_synth_default_rate_is_unchanged() -> void:
	for index in SYNTH_CASES.size():
		var bytes := SpeakerSynth.render_samples(SYNTH_CASES[index])
		assert_equal(_md5(bytes), SYNTH_MD5[index], "case %d byte for byte as before D9" % index)
		assert_equal(
			SpeakerSynth.render_samples(SYNTH_CASES[index], SoundFile.STEPS_PER_SECOND),
			bytes,
			"the default is SoundFile's rate"
		)
	assert_equal(
		SpeakerSynth.render(SYNTH_CASES[1]).data,
		SpeakerSynth.render_samples(SYNTH_CASES[1]),
		"render uses the same default"
	)


func test_speaker_synth_takes_a_rate() -> void:
	var divisors := PackedInt32Array()
	divisors.resize(14)
	divisors.fill(1000)
	var bytes := SpeakerSynth.render_samples(divisors, Sound.SOUND_RATE)
	assert_equal(
		bytes.size(),
		ceili(14 * SpeakerSynth.MIX_RATE / Sound.SOUND_RATE) * SpeakerSynth.BYTES_PER_SAMPLE,
		"14 steps at 140 a second"
	)
	var stream := SpeakerSynth.render(divisors, Sound.SOUND_RATE)
	assert_equal(stream.data, bytes, "render passes the rate on")


func test_keen1_sounds_are_unchanged() -> void:
	var files := GameFiles.locate()
	if files == null:
		return
	var sound_file := SoundFile.load_from(files)
	if sound_file == null:
		return
	var names := sound_file.sounds.keys()
	names.sort()
	assert_equal(names.size(), KEEN1_SOUND_COUNT, "Keen 1's sounds")
	var context := HashingContext.new()
	context.start(HashingContext.HASH_MD5)
	for sound_name: String in names:
		context.update(SpeakerSynth.render_samples(sound_file.sounds[sound_name].divisors))
	assert_equal(context.finish().hex_encode(), KEEN1_SOUNDS_MD5, "all rendered as before D9")


func test_adlib_sound_is_read() -> void:
	var instrument := Sound.sine_instrument()
	instrument[Sound.N_CONN] = 0x0B
	var notes := PackedByteArray([NOTE, 0, OTHER_NOTE])
	var sound := GalaxyAdlibSound.parse(
		Sound.adlib_sound(PRIORITY, instrument, 0x0C | NOTE_BLOCK, notes)
	)
	assert_true(sound != null, "parsed")
	if sound == null:
		return
	assert_equal(sound.priority, PRIORITY, "the priority")
	assert_equal(sound.instrument, instrument, "the 16 instrument bytes")
	assert_equal(sound.block, NOTE_BLOCK, "the octave (three bits)")
	assert_equal(sound.notes, notes, "the notes, without the trailing byte")
	# It counts as playing until the service reads the last byte (Omni).
	assert_true(
		absf(sound.duration() - 2.0 / GalaxyAdlibSound.STEPS_PER_SECOND) < 1e-6,
		"three notes count as two steps"
	)
	assert_true(
		GalaxyAdlibSound.parse(Sound.pc_sound(1, PackedByteArray([1]))) == null, "too short"
	)


func test_adlib_note_and_octave_give_the_pitch() -> void:
	for case: Array in [[NOTE, NOTE_BLOCK], [NOTE, 3], [OTHER_NOTE, 4]]:
		var sound := GalaxyAdlibSound.parse(
			Sound.adlib_sound(1, Sound.sine_instrument(), case[1], _repeat(case[0], 42))
		)
		var samples := sound.render_samples()
		var expected := Sound.opl_frequency(case[0], case[1])
		var found := Sound.zero_crossing_frequency(
			samples, Sound.rate(), Sound.samples_for(0.03), Sound.samples_for(0.2)
		)
		assert_true(
			absf(found - expected) < PITCH_TOLERANCE * expected,
			"note %d in block %d: %.1f Hz, got %.1f" % [case[0], case[1], expected, found]
		)


func test_adlib_notes_step_at_140_a_second() -> void:
	var notes := _repeat(NOTE, STEPS)
	notes.append_array(_repeat(0, STEPS))
	notes.append_array(_repeat(OTHER_NOTE, STEPS))
	var samples := _adlib(notes).render_samples()
	var rate := Sound.rate()
	var steps_shorter := _step_samples(3 * STEPS - 1, rate)
	assert_true(
		samples.size() >= steps_shorter and samples.size() < _step_samples(3 * STEPS, rate) + rate,
		"84 steps and at most a second of release (%d samples)" % samples.size()
	)
	var window := _step_samples(STEPS - 6, rate)
	var first := Sound.rms(samples, _step_samples(3, rate), window)
	var pause := Sound.rms(samples, _step_samples(STEPS + 3, rate), window)
	assert_true(first > 0.05, "the first note sounds (%.3f)" % first)
	assert_true(pause < 0.01 * first, "a 0 turns the key off (%.4f)" % pause)
	var second := Sound.zero_crossing_frequency(
		samples, rate, _step_samples(2 * STEPS + 3, rate), window
	)
	var expected := Sound.opl_frequency(OTHER_NOTE, NOTE_BLOCK)
	assert_true(
		absf(second - expected) < PITCH_TOLERANCE * expected,
		"the third part at the other note (%.1f)" % second
	)


func test_the_last_adlib_note_is_cut_at_once() -> void:
	# Omni SD_AL_SoundService turns the key off in the same tick that writes
	# the last note, so it never sounds.
	var notes := _repeat(NOTE, 20)
	notes.append(OTHER_NOTE)
	var samples := _adlib(notes).render_samples()
	var rate := Sound.rate()
	var start := _step_samples(20, rate)
	var count := _step_samples(1, rate)
	var held := Sound.strength(samples, rate, Sound.opl_frequency(NOTE, NOTE_BLOCK), 0, start)
	var last := Sound.strength(
		samples, rate, Sound.opl_frequency(OTHER_NOTE, NOTE_BLOCK), start, count
	)
	assert_true(last < 0.1 * held, "the last note does not sound (%.4f of %.4f)" % [last, held])


func test_the_instrument_goes_to_both_operators() -> void:
	var start := Sound.samples_for(0.03)
	var count := Sound.samples_for(0.2)
	var notes := _repeat(NOTE, 42)
	var plain := _adlib(notes).render_samples()
	var plain_level := Sound.rms(plain, start, count)
	var louder := Sound.sine_instrument()
	louder[Sound.C_CHAR] = Sound.SUSTAINED | 0x02
	var octave := _adlib(notes, louder).render_samples()
	var found := Sound.zero_crossing_frequency(octave, Sound.rate(), start, count)
	assert_true(
		absf(found - 2 * Sound.opl_frequency(NOTE, NOTE_BLOCK)) < 4.0,
		"cChar (byte 1) is the carrier's multiple (%.1f)" % found
	)
	var softer := Sound.sine_instrument()
	softer[Sound.C_SCALE] = 16
	var soft_level := Sound.rms(_adlib(notes, softer).render_samples(), start, count)
	assert_true(
		absf(Sound.decibels(soft_level / plain_level) + 12.0) < 1.0,
		"cScale (byte 3) is the carrier's level: 16 is -12 dB"
	)
	var modulated := Sound.sine_instrument()
	modulated[Sound.M_ATTACK] = 0xF0
	modulated[Sound.M_SCALE] = 32
	var fm := _adlib(notes, modulated).render_samples()
	var fundamental := Sound.opl_frequency(NOTE, NOTE_BLOCK)
	var ratio := (
		Sound.strength(fm, Sound.rate(), 2 * fundamental, start, count)
		/ Sound.strength(fm, Sound.rate(), fundamental, start, count)
	)
	var plain_ratio := (
		Sound.strength(plain, Sound.rate(), 2 * fundamental, start, count)
		/ Sound.strength(plain, Sound.rate(), fundamental, start, count)
	)
	assert_true(plain_ratio < 0.02, "a silent modulator: a pure tone (%.4f)" % plain_ratio)
	assert_true(ratio > 0.1, "mAttack and mScale (bytes 4, 2) wake the modulator (%.3f)" % ratio)


func test_adlib_waveforms_are_enabled_as_after_the_reset() -> void:
	var instrument := Sound.sine_instrument()
	instrument[Sound.C_WAVE] = 1
	var samples := _adlib(_repeat(NOTE, 42), instrument).render_samples()
	var window := samples.slice(Sound.samples_for(0.03), Sound.samples_for(0.25))
	var lowest := 0.0
	for sample in window:
		lowest = minf(lowest, sample)
	assert_true(Sound.peak(window) > 0.05, "it sounds")
	assert_true(lowest > -0.02 * Sound.peak(window), "cWave 1: a half sine (0x01 = 0x20)")


func test_adlib_connection_byte_is_not_used() -> void:
	# Omni SD_AL_SetAdlibSfxInstrument writes no 0xC0: an AdLib sound plays
	# with frequency modulation whatever nConn says.
	var instrument := Sound.sine_instrument()
	instrument[Sound.M_ATTACK] = 0xF0
	instrument[Sound.M_SCALE] = 16
	var notes := _repeat(NOTE, 30)
	var plain := _adlib(notes, instrument).render_samples()
	instrument[Sound.N_CONN] = 0x0B
	var connected := _adlib(notes, instrument).render_samples()
	assert_equal(connected, plain, "nConn 0x0B renders as nConn 0")


func test_a_slow_release_rings_on_and_fades_at_the_cap() -> void:
	var instrument := Sound.sine_instrument()
	instrument[Sound.C_SUS] = 0x01
	var notes := _repeat(NOTE, 20)
	notes.append(0)
	var samples := _adlib(notes, instrument).render_samples()
	var end := _step_samples(20, Sound.rate())
	assert_true(
		Sound.rms(samples, end + Sound.samples_for(0.5), Sound.samples_for(0.02)) > 0.01,
		"release rate 1 still sounds well after the notes"
	)
	var cap := end + Sound.samples_for(GalaxyAdlibSound.MAX_TAIL_SECONDS)
	assert_true(
		(
			samples.size() >= cap - GalaxyAdlibSound.TAIL_PIECE
			and samples.size() <= cap + GalaxyAdlibSound.TAIL_PIECE
		),
		"cut at the tail's cap (%d samples, cap %d)" % [samples.size(), cap]
	)
	var before_fade := Sound.rms(samples, samples.size() - Sound.samples_for(0.1), Sound.window())
	var last := absf(samples[samples.size() - 1])
	assert_true(before_fade > 0.01, "loud before the end (%.4f)" % before_fade)
	assert_true(last < 0.05 * before_fade, "faded to nothing, no click (%.5f)" % last)


func test_the_tail_ends_when_the_carrier_is_quiet() -> void:
	# A slow modulator is not heard in FM: only the carrier's release counts.
	var instrument := Sound.sine_instrument()
	instrument[Sound.M_ATTACK] = 0xF0
	instrument[Sound.M_SUS] = 0x01
	var notes := _repeat(NOTE, 20)
	var samples := _adlib(notes, instrument).render_samples()
	var end := _step_samples(19, Sound.rate())
	assert_true(
		samples.size() < end + Sound.samples_for(0.1),
		(
			"a fast carrier release ends the sound (%.3f s after the notes)"
			% ((samples.size() - end) / Sound.rate())
		)
	)


func _md5(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_MD5)
	context.update(bytes)
	return context.finish().hex_encode()
