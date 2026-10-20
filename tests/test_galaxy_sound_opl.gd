extends "res://tests/test_case.gd"
## Tests for GalaxyOpl, our OPL2 (YM3812) synthesiser, with hand-made
## register writes and the numbers of the public YM3812 data sheet: the
## pitch of an F-number and block, the frequency multiples, total level and
## key scaling in dB, feedback and the two connections, the waveforms (only
## with register 0x01 bit 5), the nine channels, and the plain helpers
## (samples to 16-bit, streams). The envelope, tremolo and vibrato are in
## test_galaxy_sound_envelope.gd. Nothing is listened to:
## the audio is measured (tests/galaxy_sound_fixtures.gd).

const Sound := preload("res://tests/galaxy_sound_fixtures.gd")
## Total level steps are 0.75 dB.
const LEVEL_STEP_DB := 0.75
const PITCH_TOLERANCE := 0.005
const LEVEL_TOLERANCE_DB := 1.0
## The multiples the data sheet gives for MULT 0-15.
const MULTIPLES: PackedFloat32Array = [0.5, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 10, 12, 12, 15, 15]


func test_a_fresh_chip_is_silent() -> void:
	var chip := GalaxyOpl.new()
	var samples := chip.generate(1000)
	assert_equal(samples.size(), 1000, "exactly the samples asked for")
	assert_equal(Sound.peak(samples), 0.0, "nothing sounds after reset")
	for channel in 9:
		assert_true(chip.is_channel_silent(channel), "channel %d silent" % channel)


func test_the_chip_rate() -> void:
	assert_equal(GalaxyOpl.CHIP_RATE, roundi(Sound.OPL_RATE), "the clock / 72")


func test_note_frequency_follows_the_data_sheet() -> void:
	for case: Array in [[580, 4, 1.0], [0x2AE, 4, 1.0], [1023, 7, 1.0], [345, 2, 3.0]]:
		var expected := Sound.opl_frequency(case[0], case[1], case[2])
		var found := GalaxyOpl.note_frequency(case[0], case[1], case[2])
		assert_true(
			absf(found - expected) < 0.01 * expected,
			"F-number %d block %d: %.2f Hz, got %.2f" % [case[0], case[1], expected, found]
		)


func test_a_sine_sounds_at_its_pitch() -> void:
	for case: Array in [
		[Sound.A440_F_NUMBER, Sound.A440_BLOCK], [0x2AE, 4], [0x158, 5], [1000, 3], [580, 6]
	]:
		var expected := Sound.opl_frequency(case[0], case[1])
		var samples := Sound.sine_chip(0, case[0], case[1]).generate(Sound.samples_for(0.3))
		var found := Sound.zero_crossing_frequency(
			samples, Sound.rate(), Sound.samples_for(0.05), Sound.samples_for(0.25)
		)
		assert_true(
			absf(found - expected) < PITCH_TOLERANCE * expected,
			"F-number %d block %d sounds at %.1f Hz, got %.1f" % [case[0], case[1], expected, found]
		)


func test_a_sine_is_loud_and_clean() -> void:
	var samples := Sound.sine_chip().generate(Sound.samples_for(0.2))
	var loudest := Sound.peak(samples)
	assert_true(loudest > 0.05 and loudest <= 1.0, "a full-level sine is loud (%.3f)" % loudest)
	var start := Sound.samples_for(0.05)
	var count := Sound.samples_for(0.15)
	var fundamental := Sound.strength(samples, Sound.rate(), Sound.A440, start, count)
	for harmonic: int in [2, 3, 4]:
		var overtone := Sound.strength(samples, Sound.rate(), Sound.A440 * harmonic, start, count)
		assert_true(
			overtone < 0.02 * fundamental,
			"no harmonic %d in a pure sine (%.4f of %.4f)" % [harmonic, overtone, fundamental]
		)


func test_frequency_multiples() -> void:
	var f_number := 580
	var block := 2
	for multiple: int in [0, 1, 2, 5, 10, 11, 12, 13, 14, 15]:
		var chip := Sound.sine_chip(0, f_number, block)
		chip.write(Sound.CHARACTER + Sound.CARRIERS[0], Sound.SUSTAINED | multiple)
		var samples := chip.generate(Sound.samples_for(0.3))
		var expected := Sound.opl_frequency(f_number, block, MULTIPLES[multiple])
		var found := Sound.zero_crossing_frequency(
			samples, Sound.rate(), Sound.samples_for(0.05), Sound.samples_for(0.25)
		)
		assert_true(
			absf(found - expected) < PITCH_TOLERANCE * expected,
			"MULT %d: %.1f Hz, got %.1f" % [multiple, expected, found]
		)


func test_total_level_attenuates_in_steps_of_0_75_db() -> void:
	var full := Sound.full_rms()
	assert_true(full > 0.0, "the full-level sine sounds")
	for level: int in [4, 8, 16, 32]:
		var samples := Sound.sine_chip(0, Sound.A440_F_NUMBER, Sound.A440_BLOCK, level).generate(
			Sound.samples_for(0.2)
		)
		var found := Sound.decibels(
			Sound.rms(samples, Sound.samples_for(0.1), Sound.samples_for(0.1)) / full
		)
		var expected := -LEVEL_STEP_DB * level
		assert_true(
			absf(found - expected) <= LEVEL_TOLERANCE_DB,
			"total level %d: %.2f dB, got %.2f" % [level, expected, found]
		)
	var silent_chip := Sound.sine_chip(0, Sound.A440_F_NUMBER, Sound.A440_BLOCK, Sound.SILENT_LEVEL)
	var quiet := silent_chip.generate(Sound.samples_for(0.2))
	var found_quiet := Sound.decibels(
		Sound.rms(quiet, Sound.samples_for(0.1), Sound.samples_for(0.1)) / full
	)
	assert_true(found_quiet < -40.0, "total level 63 is about -47 dB (got %.1f)" % found_quiet)


func test_key_scale_level_attenuates_high_notes() -> void:
	# KSL in bits 7-6: 00 none, 01 3 dB/octave, 10 1.5 dB/octave, 11 6 dB/octave.
	var attenuation: Dictionary[int, float] = {}
	var plain := 0.0
	for key_scale: int in [0, 1, 2, 3]:
		var chip := Sound.sine_chip(0, Sound.A440_F_NUMBER, 7, key_scale << 6)
		var samples := chip.generate(Sound.samples_for(0.15))
		var loudness := Sound.rms(samples, Sound.samples_for(0.05), Sound.samples_for(0.1))
		if key_scale == 0:
			plain = loudness
		else:
			attenuation[key_scale] = -Sound.decibels(loudness / plain)
	assert_true(attenuation[2] > 1.0, "1.5 dB/octave attenuates block 7 (%.2f)" % attenuation[2])
	assert_true(
		absf(attenuation[1] / attenuation[2] - 2.0) < 0.5,
		"3 dB/octave is twice 1.5 (%.2f, %.2f)" % [attenuation[1], attenuation[2]]
	)
	assert_true(
		absf(attenuation[3] / attenuation[2] - 4.0) < 1.0,
		"6 dB/octave is four times 1.5 (%.2f, %.2f)" % [attenuation[3], attenuation[2]]
	)
	var low_plain := Sound.sine_chip(0, 300, 0).generate(Sound.samples_for(0.3))
	var low_scaled := Sound.sine_chip(0, 300, 0, 3 << 6).generate(Sound.samples_for(0.3))
	assert_true(
		(
			absf(
				Sound.decibels(
					(
						Sound.rms(low_scaled, Sound.samples_for(0.1), Sound.samples_for(0.2))
						/ Sound.rms(low_plain, Sound.samples_for(0.1), Sound.samples_for(0.2))
					)
				)
			)
			< 0.5
		),
		"no key scaling in the lowest block"
	)


func test_a_new_f_number_changes_the_pitch_of_a_held_note() -> void:
	var chip := Sound.sine_chip()
	chip.generate(Sound.samples_for(0.05))
	Sound.apply(chip, Sound.key_on_writes(0, Sound.A440_F_NUMBER, Sound.A440_BLOCK + 1))
	var samples := chip.generate(Sound.samples_for(0.2))
	var found := Sound.zero_crossing_frequency(samples, Sound.rate(), 0, samples.size())
	assert_true(
		absf(found - 2.0 * Sound.A440) < 2.0 * Sound.A440 * PITCH_TOLERANCE,
		"an octave up (%.1f)" % found
	)


func test_frequency_modulation_adds_harmonics() -> void:
	var start := Sound.samples_for(0.05)
	var count := Sound.samples_for(0.15)
	var pure := Sound.sine_chip().generate(Sound.samples_for(0.2))
	var chip := Sound.sine_chip()
	# -24 dB: a modulation index of a radian or two.
	Sound.wake_modulator(chip, 0, 32)
	var modulated := chip.generate(Sound.samples_for(0.2))
	var pure_ratio := _overtone_ratio(pure, start, count)
	var modulated_ratio := _overtone_ratio(modulated, start, count)
	assert_true(pure_ratio < 0.02, "a silent modulator leaves a pure sine (%.4f)" % pure_ratio)
	assert_true(modulated_ratio > 0.3, "a modulator (FM) adds harmonics (%.3f)" % modulated_ratio)


func test_additive_connection_mixes_both_operators() -> void:
	var chip := Sound.sine_chip()
	Sound.wake_modulator(chip, 0, 0)
	chip.write(Sound.CHARACTER + Sound.CARRIERS[0], Sound.SUSTAINED | 0x02)
	chip.write(Sound.FEEDBACK_CONNECTION, 0x01)
	var samples := chip.generate(Sound.samples_for(0.2))
	var start := Sound.samples_for(0.05)
	var count := Sound.samples_for(0.15)
	var low := Sound.strength(samples, Sound.rate(), Sound.A440, start, count)
	var high := Sound.strength(samples, Sound.rate(), 2 * Sound.A440, start, count)
	assert_true(low > 0.02 and high > 0.02, "both operators sound (%.3f, %.3f)" % [low, high])
	assert_true(
		absf(Sound.decibels(low / high)) < 2.0,
		"equally loud at the same level (%.3f, %.3f)" % [low, high]
	)
	var between := Sound.strength(samples, Sound.rate(), 3 * Sound.A440, start, count)
	assert_true(between < 0.05 * low, "no FM sidebands when added (%.4f)" % between)


func test_feedback_roughens_the_modulator() -> void:
	var start := Sound.samples_for(0.05)
	var count := Sound.samples_for(0.15)
	var ratios: Array[float] = []
	for feedback: int in [0, 5]:
		var chip := Sound.sine_chip()
		Sound.wake_modulator(chip, 0, 0)
		chip.write(Sound.LEVEL + Sound.CARRIERS[0], Sound.SILENT_LEVEL)
		chip.write(Sound.FEEDBACK_CONNECTION, (feedback << 1) | 0x01)
		var samples := chip.generate(Sound.samples_for(0.2))
		var fundamental := maxf(
			Sound.strength(samples, Sound.rate(), Sound.A440, start, count), 1e-6
		)
		var overtones := 0.0
		for harmonic: int in [2, 3, 4, 5]:
			overtones += Sound.strength(samples, Sound.rate(), Sound.A440 * harmonic, start, count)
		ratios.append(overtones / fundamental)
	assert_true(ratios[0] < 0.03, "no feedback: the modulator alone is a sine (%.4f)" % ratios[0])
	assert_true(ratios[1] > 0.1, "feedback 5 adds overtones (%.3f)" % ratios[1])


func test_waveforms_need_the_enable_bit() -> void:
	# Only what the data sheet is clear about: a waveform chosen while bit 5
	# of register 0x01 is clear stays a sine; chosen with it set, it counts.
	# (Chips and emulators differ on toggling the bit later.)
	var start := Sound.samples_for(0.05)
	var count := Sound.samples_for(0.15)
	var chip := GalaxyOpl.new()
	Sound.apply(chip, Sound.sine_writes(0))
	chip.write(Sound.WAVEFORM + Sound.CARRIERS[0], 1)
	Sound.apply(chip, Sound.key_on_writes(0, Sound.A440_F_NUMBER, Sound.A440_BLOCK))
	var disabled := chip.generate(Sound.samples_for(0.2)).slice(start, start + count)
	assert_true(Sound.peak(disabled) > 0.05, "the sine sounds")
	assert_true(_lowest(disabled) < -0.5 * Sound.peak(disabled), "without 0x01 bit 5: a sine")
	var half := Sound.sine_chip()
	half.write(Sound.WAVEFORM + Sound.CARRIERS[0], 1)
	var samples := half.generate(Sound.samples_for(0.2)).slice(start, start + count)
	assert_true(Sound.peak(samples) > 0.05, "the half sine sounds")
	assert_true(
		_lowest(samples) > -0.02 * Sound.peak(samples),
		"waveform 1 with the bit: a half sine, never negative"
	)


func test_waveform_2_is_a_rectified_sine() -> void:
	var chip := Sound.sine_chip()
	chip.write(Sound.WAVEFORM + Sound.CARRIERS[0], 2)
	var samples := chip.generate(Sound.samples_for(0.2))
	var start := Sound.samples_for(0.05)
	var count := Sound.samples_for(0.15)
	var window := samples.slice(start, start + count)
	assert_true(_lowest(window) > -0.02 * Sound.peak(window), "never negative")
	var strongest := Sound.strongest_frequency(
		samples, Sound.rate(), 300.0, 1000.0, 10.0, start, count
	)
	assert_true(
		absf(strongest - 2 * Sound.A440) <= 10.0, "two humps per period: 880 Hz (%.0f)" % strongest
	)


func test_waveform_3_is_quarter_sine_pulses() -> void:
	var chip := Sound.sine_chip()
	chip.write(Sound.WAVEFORM + Sound.CARRIERS[0], 3)
	var samples := chip.generate(Sound.samples_for(0.2))
	var start := Sound.samples_for(0.05)
	var count := Sound.samples_for(0.15)
	var window := samples.slice(start, start + count)
	assert_true(_lowest(window) > -0.02 * Sound.peak(window), "never negative")
	var silent := 0
	for sample in window:
		if absf(sample) < 0.01 * Sound.peak(window):
			silent += 1
	assert_true(
		silent > window.size() * 0.4,
		"silent for half of each period (%d of %d)" % [silent, window.size()]
	)


func test_all_nine_channels_sound_on_their_own() -> void:
	var start := Sound.samples_for(0.05)
	var count := Sound.samples_for(0.1)
	for channel in 9:
		var samples := Sound.sine_chip(channel).generate(Sound.samples_for(0.15))
		var found := Sound.strength(samples, Sound.rate(), Sound.A440, start, count)
		assert_true(found > 0.05, "channel %d sounds (%.3f)" % [channel, found])


func test_channels_mix() -> void:
	var chip := GalaxyOpl.new()
	chip.write(Sound.TEST_REGISTER, Sound.WAVE_SELECT_ENABLE)
	Sound.apply(chip, Sound.sine_writes(0))
	Sound.apply(chip, Sound.sine_writes(5))
	Sound.apply(chip, Sound.key_on_writes(0, Sound.A440_F_NUMBER, Sound.A440_BLOCK))
	var other := roundi(Sound.A440_F_NUMBER * 1.5)
	Sound.apply(chip, Sound.key_on_writes(5, other, Sound.A440_BLOCK))
	var samples := chip.generate(Sound.samples_for(0.2))
	var start := Sound.samples_for(0.05)
	var count := Sound.samples_for(0.15)
	var first := Sound.strength(samples, Sound.rate(), Sound.A440, start, count)
	var second := Sound.strength(
		samples, Sound.rate(), Sound.opl_frequency(other, Sound.A440_BLOCK), start, count
	)
	assert_true(first > 0.05 and second > 0.05, "both notes (%.3f, %.3f)" % [first, second])
	assert_true(absf(Sound.decibels(first / second)) < 1.0, "equally loud")
	assert_true(chip.is_channel_silent(3), "an unused channel stays silent")


func test_generating_in_pieces_is_the_same_as_at_once() -> void:
	var whole := Sound.sine_chip().generate(3000)
	var chip := Sound.sine_chip()
	var pieces := chip.generate(1000)
	pieces.append_array(chip.generate(1234))
	pieces.append_array(chip.generate(766))
	assert_equal(pieces, whole, "the chip keeps its state between calls")


func test_samples_to_16_bit() -> void:
	var pcm := GalaxyOpl.to_pcm16(PackedFloat32Array([0.0, 0.5, -0.5, 2.0, -2.0]))
	assert_equal(pcm.size(), 10, "two bytes a sample")
	assert_equal(pcm.decode_s16(0), 0, "zero")
	assert_true(absi(pcm.decode_s16(2) - 16384) <= 1, "half")
	assert_true(absi(pcm.decode_s16(4) + 16384) <= 1, "minus half")
	assert_equal(pcm.decode_s16(6), 32767, "clamped high")
	assert_true(pcm.decode_s16(8) <= -32767, "clamped low")


func test_streams() -> void:
	var pcm := GalaxyOpl.to_pcm16(Sound.sine_chip().generate(1000))
	var stream := GalaxyOpl.make_stream(pcm)
	assert_equal(stream.mix_rate, GalaxyOpl.CHIP_RATE, "at the chip's rate")
	assert_equal(stream.format, AudioStreamWAV.FORMAT_16_BITS, "16 bits")
	assert_true(not stream.stereo, "mono")
	assert_equal(stream.loop_mode, AudioStreamWAV.LOOP_DISABLED, "no loop by default")
	assert_equal(stream.data, pcm, "the samples")
	var looping := GalaxyOpl.make_stream(pcm, 100, 900)
	assert_equal(looping.loop_mode, AudioStreamWAV.LOOP_FORWARD, "a song loops")
	assert_equal(looping.loop_begin, 100, "loop begin")
	assert_equal(looping.loop_end, 900, "loop end")


func _lowest(samples: PackedFloat32Array) -> float:
	var lowest := 0.0
	for sample in samples:
		lowest = minf(lowest, sample)
	return lowest


## The strength of harmonics 2-5 of 440 Hz against the fundamental.
func _overtone_ratio(samples: PackedFloat32Array, start: int, count: int) -> float:
	var fundamental := maxf(Sound.strength(samples, Sound.rate(), Sound.A440, start, count), 1e-6)
	var overtones := 0.0
	for harmonic: int in [2, 3, 4, 5]:
		overtones += Sound.strength(samples, Sound.rate(), Sound.A440 * harmonic, start, count)
	return overtones / fundamental
