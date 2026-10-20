extends "res://tests/test_case.gd"
## Tests for the envelope of GalaxyOpl, our OPL2 (YM3812) synthesiser,
## against the times of the public YM3812 data sheet: attack, decay to the
## sustain level, release after key off, sustained and percussive notes, a
## new key on; and tremolo and vibrato with their two depths. Measured,
## not listened to (tests/galaxy_sound_fixtures.gd).

const Sound := preload("res://tests/galaxy_sound_fixtures.gd")
## The data sheet's time for rate 8 with rate offset 0: decay or release
## over 96 dB in 306.88 ms.
const RATE_8_DECAY_MS_PER_96_DB := 306.88
const DB_RANGE := 96.0
## Sustain level steps are 3 dB.
const SUSTAIN_STEP_DB := 3.0
const TREMOLO_DEEP_DB := 4.8
const TREMOLO_SHALLOW_DB := 1.0


func test_attack_rate_15_is_instant_and_0_never_starts() -> void:
	var full := Sound.full_rms()
	var instant := Sound.envelope_chip(Sound.SUSTAINED | Sound.MULTIPLE_8, 0xF0, 0x0F).generate(
		Sound.samples_for(0.05)
	)
	var at_once := Sound.level_db(instant, 0.002, full)
	assert_true(at_once > -1.0, "attack 15 is at full level within 2 ms (%.2f dB)" % at_once)
	var never := Sound.envelope_chip(Sound.SUSTAINED | Sound.MULTIPLE_8, 0x00, 0x0F)
	var never_samples := never.generate(Sound.samples_for(0.3))
	assert_true(Sound.peak(never_samples) < 1e-4, "attack 0 never rises")


func test_attack_rate_8_takes_about_22_ms() -> void:
	var full := Sound.full_rms()
	var samples := Sound.envelope_chip(Sound.SUSTAINED | Sound.MULTIPLE_8, 0x80, 0x0F).generate(
		Sound.samples_for(0.1)
	)
	var reached := -1.0
	var step := 0.001
	var seconds := 0.0
	while seconds < 0.09:
		if Sound.level_db(samples, seconds, full) > -1.0:
			reached = seconds
			break
		seconds += step
	assert_true(
		reached > 0.005 and reached < 0.04,
		"attack 8 reaches full level after about 22 ms (window from %.3f s)" % reached
	)
	assert_true(Sound.level_db(samples, 0.0, full) < -6.0, "and starts quiet")


func test_decay_falls_to_the_sustain_level() -> void:
	var full := Sound.full_rms()
	var sustain_level := 4
	var chip := Sound.envelope_chip(Sound.SUSTAINED | Sound.MULTIPLE_8, 0xF8, sustain_level << 4)
	var samples := chip.generate(Sound.samples_for(0.4))
	var expected := -SUSTAIN_STEP_DB * sustain_level
	var held := Sound.level_db(samples, 0.3, full)
	assert_true(
		absf(held - expected) <= 1.5,
		"decay stops at sustain level 4 (%.1f dB, got %.2f)" % [expected, held]
	)
	# Rate 8 falls 96 dB in 306.88 ms: about -6 dB some 19 ms in.
	var early := Sound.level_db(samples, 0.017, full)
	assert_true(early < -2.5 and early > -10.0, "decay 8 is about -6 dB after 19 ms (%.2f)" % early)


func test_sustain_level_15_is_93_db_down() -> void:
	var full := Sound.full_rms()
	var samples := Sound.envelope_chip(Sound.SUSTAINED | Sound.MULTIPLE_8, 0xFF, 0xF0).generate(
		Sound.samples_for(0.3)
	)
	assert_true(Sound.level_db(samples, 0.25, full) < -60.0, "sustain level 15 is (nearly) silent")


func test_release_after_key_off() -> void:
	var full := Sound.full_rms()
	var hold := Sound.samples_for(0.1)
	for release: int in [0, 8, 15]:
		var chip := Sound.envelope_chip(Sound.SUSTAINED | Sound.MULTIPLE_8, 0xF0, release)
		var before := chip.generate(hold)
		var held := Sound.level_db(before, 0.08, full)
		Sound.key_off(chip, 0, Sound.A440_F_NUMBER, Sound.ENVELOPE_BLOCK)
		var after := chip.generate(Sound.samples_for(0.25))
		match release:
			0:
				var still := Sound.level_db(after, 0.2, full)
				assert_true(absf(still - held) < 0.5, "release 0 keeps the level (%.2f)" % still)
			8:
				# 96 dB in 306.88 ms: about -15.6 dB 50 ms after key off.
				var expected := -DB_RANGE * 50.0 / RATE_8_DECAY_MS_PER_96_DB
				var found := Sound.level_db(after, 0.048, full)
				assert_true(
					found < expected + 6.0 and found > expected - 8.0,
					"release 8: about %.1f dB after 50 ms, got %.2f" % [expected, found]
				)
			15:
				var gone := Sound.level_db(after, 0.02, full)
				assert_true(gone < -60.0, "release 15 is silent within 20 ms (%.1f)" % gone)
				assert_true(chip.is_channel_silent(0), "and the channel counts as silent")


func test_a_held_key_keeps_sounding_only_when_sustained() -> void:
	var full := Sound.full_rms()
	var sustained := Sound.envelope_chip(Sound.SUSTAINED | Sound.MULTIPLE_8, 0xF0, 0x08).generate(
		Sound.samples_for(0.15)
	)
	assert_true(
		Sound.level_db(sustained, 0.12, full) > -1.0,
		"sustained: the level holds while the key is down"
	)
	var percussive := Sound.envelope_chip(Sound.MULTIPLE_8, 0xF0, 0x08).generate(
		Sound.samples_for(0.15)
	)
	var fallen := Sound.level_db(percussive, 0.1, full)
	assert_true(
		fallen < -15.0, "not sustained: release starts after the decay (%.1f dB at 0.1 s)" % fallen
	)


func test_a_key_on_again_restarts_the_note() -> void:
	var chip := Sound.envelope_chip(Sound.SUSTAINED | Sound.MULTIPLE_8, 0xF0, 0x0F)
	chip.generate(Sound.samples_for(0.05))
	Sound.key_off(chip, 0, Sound.A440_F_NUMBER, Sound.ENVELOPE_BLOCK)
	chip.generate(Sound.samples_for(0.05))
	assert_true(chip.is_channel_silent(0), "released")
	Sound.apply(chip, Sound.key_on_writes(0, Sound.A440_F_NUMBER, Sound.ENVELOPE_BLOCK))
	var again := chip.generate(Sound.samples_for(0.05))
	assert_true(not chip.is_channel_silent(0), "keyed on again")
	assert_true(Sound.peak(again) > 0.05, "it sounds again")


func test_tremolo_depths() -> void:
	var swings: Array[float] = []
	for setting: Array in [[0, 0x80], [0x80, 0x00], [0x80, 0x80]]:
		var chip := Sound.sine_chip()
		chip.write(Sound.RHYTHM, setting[1])
		chip.write(
			Sound.CHARACTER + Sound.CARRIERS[0], Sound.SUSTAINED | Sound.MULTIPLE_1 | setting[0]
		)
		var samples := chip.generate(Sound.samples_for(1.0))
		swings.append(_swing_db(samples))
	assert_true(swings[0] < 0.3, "no AM bit: a steady level (%.2f dB)" % swings[0])
	assert_true(
		swings[1] > TREMOLO_SHALLOW_DB * 0.5 and swings[1] < TREMOLO_SHALLOW_DB * 1.8,
		"AM with the shallow depth swings about 1 dB (%.2f)" % swings[1]
	)
	assert_true(
		swings[2] > TREMOLO_DEEP_DB * 0.7 and swings[2] < TREMOLO_DEEP_DB * 1.3,
		"AM with 0xBD bit 7 swings about 4.8 dB (%.2f)" % swings[2]
	)


func test_vibrato_depths() -> void:
	var spreads: Array[float] = []
	for setting: Array in [[0, 0x40], [0x40, 0x00], [0x40, 0x40]]:
		var chip := Sound.sine_chip()
		chip.write(Sound.RHYTHM, setting[1])
		chip.write(
			Sound.CHARACTER + Sound.CARRIERS[0], Sound.SUSTAINED | Sound.MULTIPLE_1 | setting[0]
		)
		var samples := chip.generate(Sound.samples_for(0.6))
		spreads.append(_pitch_spread_cents(samples))
	assert_true(spreads[0] < 3.0, "no VIB bit: a steady pitch (%.2f cents)" % spreads[0])
	assert_true(spreads[2] > 6.0 and spreads[2] < 60.0, "deep vibrato (%.1f cents)" % spreads[2])
	assert_true(
		spreads[1] > 2.0 and spreads[1] < spreads[2],
		"the shallow vibrato is smaller (%.1f, %.1f)" % [spreads[1], spreads[2]]
	)


## The difference between the loudest and quietest window, in dB.
func _swing_db(samples: PackedFloat32Array) -> float:
	var loudest := 0.0
	var quietest := INF
	var window := Sound.window()
	var at := Sound.samples_for(0.02)
	while at + window <= samples.size():
		var level := Sound.rms(samples, at, window)
		loudest = maxf(loudest, level)
		quietest = minf(quietest, level)
		at += window
	return Sound.decibels(loudest / quietest)


## The difference between the highest and lowest pitch over 10 ms
## windows, in cents.
func _pitch_spread_cents(samples: PackedFloat32Array) -> float:
	var highest := 0.0
	var lowest := INF
	var window := Sound.samples_for(0.01)
	var at := Sound.samples_for(0.02)
	while at + window <= samples.size():
		var pitch := Sound.zero_crossing_frequency(samples, Sound.rate(), at, window)
		highest = maxf(highest, pitch)
		lowest = minf(lowest, pitch)
		at += window / 2
	return 1200.0 * log(highest / lowest) / log(2.0)
