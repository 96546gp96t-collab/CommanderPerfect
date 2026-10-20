extends RefCounted
## Hand-made Galaxy sound data and measuring tools for the sound tests:
## PC speaker sounds, AdLib sounds and songs in the layout of AUDIO.CK4
## (docs/keen4/file-formats.md, "AUDIO.CK4"), OPL2 register writes, and
## ways to measure rendered audio without listening to it (loudness,
## pitch by zero crossings, the strength of one frequency by the Goertzel
## filter). None of it comes from the game.

const Fixtures := preload("res://tests/galaxy_fixtures.gd")
const FULL_SCALE := 32768.0
const BYTES_PER_SAMPLE := 2
## Sound effects step at 140 Hz, songs at 560 Hz (research.md §10).
const SOUND_RATE := 140.0
const SONG_RATE := 560.0
## The OPL2's own sample rate: its 3.579545 MHz clock divided by 72.
const OPL_RATE := 3579545.0 / 72.0
## The PC speaker byte is the timer divisor divided by this.
const PC_DIVISOR_STEP := 60
const SOUND_HEADER_SIZE := 6
const INSTRUMENT_SIZE := 16
## OPL2 registers (YM3812 data sheet).
const TEST_REGISTER := 0x01
const WAVE_SELECT_ENABLE := 0x20
const CHARACTER := 0x20
const LEVEL := 0x40
const ATTACK_DECAY := 0x60
const SUSTAIN_RELEASE := 0x80
const FREQUENCY_LOW := 0xA0
const KEY_BLOCK := 0xB0
const RHYTHM := 0xBD
const FEEDBACK_CONNECTION := 0xC0
const WAVEFORM := 0xE0
const KEY_ON := 0x20
## Operator offsets of the modulator and carrier of channels 0-8.
const MODULATORS: PackedInt32Array = [0x00, 0x01, 0x02, 0x08, 0x09, 0x0A, 0x10, 0x11, 0x12]
const CARRIERS: PackedInt32Array = [0x03, 0x04, 0x05, 0x0B, 0x0C, 0x0D, 0x13, 0x14, 0x15]
## Instrument bytes (Omni `id_sd.c`, SD_AdlibInstrument).
const M_CHAR := 0
const C_CHAR := 1
const M_SCALE := 2
const C_SCALE := 3
const M_ATTACK := 4
const C_ATTACK := 5
const M_SUS := 6
const C_SUS := 7
const M_WAVE := 8
const C_WAVE := 9
const N_CONN := 10
## Character bits: sustain while the key is held, frequency multiple 1.
const SUSTAINED := 0x20
const MULTIPLE_1 := 0x01
const SILENT_LEVEL := 0x3F
## 580 in block 4 is 440 Hz (the data sheet's formula).
const A440_F_NUMBER := 580
const A440_BLOCK := 4
const A440 := 440.0
## Block 1 has key scale number 2 or 3, so the envelope runs at the data
## sheet's table rates (rate offset 0 without KSR); multiple 8 brings the
## note to 440 Hz again.
const ENVELOPE_BLOCK := 1
const MULTIPLE_8 := 0x08


## A PC speaker sound chunk: length, priority, one byte per step and the
## trailing byte Keen 4's chunks have.
static func pc_sound(priority: int, steps: PackedByteArray) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(SOUND_HEADER_SIZE)
	bytes.encode_u32(0, steps.size())
	bytes.encode_u16(4, priority)
	bytes.append_array(steps)
	bytes.append(0)
	return bytes


## An AdLib sound chunk: length, priority, the 16-byte instrument, the
## octave (block), one note byte per step and a trailing byte.
static func adlib_sound(
	priority: int, instrument: PackedByteArray, block: int, notes: PackedByteArray
) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(SOUND_HEADER_SIZE)
	bytes.encode_u32(0, notes.size())
	bytes.encode_u16(4, priority)
	var padded := instrument.duplicate()
	padded.resize(INSTRUMENT_SIZE)
	bytes.append_array(padded)
	bytes.append(block)
	bytes.append_array(notes)
	bytes.append(0)
	return bytes


## An instrument whose carrier is a held sine with a fast attack and
## release, and the modulator silent (attack rate 0): mChar, cChar,
## mScale, cScale, mAttack, cAttack, mSus, cSus, mWave, cWave, nConn, then
## five unused bytes.
static func sine_instrument() -> PackedByteArray:
	return PackedByteArray(
		[
			SUSTAINED | MULTIPLE_1,
			SUSTAINED | MULTIPLE_1,
			SILENT_LEVEL,
			0x00,
			0x00,
			0xF0,
			0x0F,
			0x0F,
			0,
			0,
			0,
			0,
			0,
			0,
			0,
			0,
		]
	)


## An AUDIO file holding [param chunks] (packed with a hand-made
## Huffman dictionary), as [GalaxyAudioFile] reads it.
static func audio_file(chunks: Array[PackedByteArray]) -> GalaxyAudioFile:
	var tree := Fixtures.dictionary()
	var data := PackedByteArray()
	var offsets := PackedInt32Array()
	for contents in chunks:
		offsets.append(data.size())
		data.append_array(Fixtures.chunk(tree, contents))
	offsets.append(data.size())
	return GalaxyAudioFile.create(data, offsets, GalaxyHuffman.from_bytes(tree))


## A song chunk: a 16-bit length, then (register, value, 16-bit delay)
## commands. [param commands] holds [register, value, delay] triples.
static func song(commands: Array[PackedInt32Array]) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(2)
	bytes.encode_u16(0, commands.size() * 4)
	for command in commands:
		var at := bytes.size()
		bytes.resize(at + 4)
		bytes[at] = command[0]
		bytes[at + 1] = command[1]
		bytes.encode_u16(at + 2, command[2])
	return bytes


## Register writes for a held sine on [param channel]: the modulator
## silent, the carrier at full level with an instant attack. The modulator
## is kept quiet by attack rate 0 (its envelope never rises): total level
## 63 alone is only -47 dB, and a modulator that quiet still bends the
## carrier's phase by about 0.1 radian (sidebands of about 5 %).
static func sine_writes(channel: int, level := 0) -> Array[PackedInt32Array]:
	var modulator := MODULATORS[channel]
	var carrier := CARRIERS[channel]
	return [
		PackedInt32Array([CHARACTER + modulator, SUSTAINED | MULTIPLE_1]),
		PackedInt32Array([LEVEL + modulator, SILENT_LEVEL]),
		PackedInt32Array([ATTACK_DECAY + modulator, 0x00]),
		PackedInt32Array([SUSTAIN_RELEASE + modulator, 0x0F]),
		PackedInt32Array([CHARACTER + carrier, SUSTAINED | MULTIPLE_1]),
		PackedInt32Array([LEVEL + carrier, level]),
		PackedInt32Array([ATTACK_DECAY + carrier, 0xF0]),
		PackedInt32Array([SUSTAIN_RELEASE + carrier, 0x0F]),
		PackedInt32Array([FEEDBACK_CONNECTION + channel, 0]),
	]


## The two writes that start a note: F-number low bits, then key on with
## the block and the F-number's top two bits.
static func key_on_writes(channel: int, f_number: int, block: int) -> Array[PackedInt32Array]:
	return [
		PackedInt32Array([FREQUENCY_LOW + channel, f_number & 0xFF]),
		PackedInt32Array([KEY_BLOCK + channel, KEY_ON | (block << 2) | (f_number >> 8)]),
	]


## The frequency the YM3812 data sheet gives for an F-number and block.
static func opl_frequency(f_number: int, block: int, multiple := 1.0) -> float:
	return f_number * OPL_RATE / pow(2.0, 20 - block) * multiple


## 16-bit little-endian mono samples as floats from -1 to 1.
static func samples_of(bytes: PackedByteArray) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(bytes.size() / BYTES_PER_SAMPLE)
	for index in samples.size():
		samples[index] = bytes.decode_s16(index * BYTES_PER_SAMPLE) / FULL_SCALE
	return samples


## The samples of a 16-bit mono [AudioStreamWAV] as floats.
static func stream_samples(stream: AudioStreamWAV) -> PackedFloat32Array:
	if stream == null:
		return PackedFloat32Array()
	return samples_of(stream.data)


## Root mean square of [param count] samples from [param start].
static func rms(samples: PackedFloat32Array, start: int, count: int) -> float:
	var end := mini(samples.size(), start + count)
	if end <= start:
		return 0.0
	var total := 0.0
	for index in range(start, end):
		total += samples[index] * samples[index]
	return sqrt(total / (end - start))


## The largest absolute sample.
static func peak(samples: PackedFloat32Array) -> float:
	var loudest := 0.0
	for sample in samples:
		loudest = maxf(loudest, absf(sample))
	return loudest


static func decibels(ratio: float) -> float:
	return 20.0 * log(maxf(ratio, 1e-9)) / log(10.0)


## The pitch from rising zero crossings, interpolated between samples.
static func zero_crossing_frequency(
	samples: PackedFloat32Array, rate: float, start: int, count: int
) -> float:
	var end := mini(samples.size(), start + count)
	var first := -1.0
	var last := -1.0
	var crossings := 0
	for index in range(start + 1, end):
		var before := samples[index - 1]
		var after := samples[index]
		if before < 0.0 and after >= 0.0:
			var at := index - 1 + before / (before - after)
			if first < 0.0:
				first = at
			else:
				crossings += 1
			last = at
	if crossings == 0:
		return 0.0
	return crossings * rate / (last - first)


## The amplitude of [param frequency] in a window (Goertzel filter), so
## that a full-scale sine there gives about 1.
static func strength(
	samples: PackedFloat32Array, rate: float, frequency: float, start: int, count: int
) -> float:
	var end := mini(samples.size(), start + count)
	var length := end - start
	if length <= 0:
		return 0.0
	var coefficient := 2.0 * cos(TAU * frequency / rate)
	var previous := 0.0
	var before_previous := 0.0
	for index in range(start, end):
		var current := samples[index] + coefficient * previous - before_previous
		before_previous = previous
		previous = current
	var power := (
		previous * previous
		+ before_previous * before_previous
		- coefficient * previous * before_previous
	)
	return 2.0 * sqrt(maxf(power, 0.0)) / length


## The frequency between [param low] and [param high] (in [param step]
## Hz steps) that is strongest in the window.
static func strongest_frequency(
	samples: PackedFloat32Array,
	rate: float,
	low: float,
	high: float,
	step: float,
	start: int,
	count: int
) -> float:
	var best := low
	var best_strength := -1.0
	var frequency := low
	while frequency <= high:
		var found := strength(samples, rate, frequency, start, count)
		if found > best_strength:
			best_strength = found
			best = frequency
		frequency += step
	return best


static func rate() -> float:
	return float(GalaxyOpl.CHIP_RATE)


static func samples_for(seconds: float) -> int:
	return roundi(seconds * rate())


## Two periods of 440 Hz, the window for loudness over time.
static func window() -> int:
	return roundi(2.0 * rate() / A440)


static func apply(chip: GalaxyOpl, writes: Array[PackedInt32Array]) -> void:
	for pair in writes:
		chip.write(pair[0], pair[1])


## A chip (waveforms enabled) with a held sine on [param channel], keyed on.
static func sine_chip(
	channel := 0, f_number := A440_F_NUMBER, block := A440_BLOCK, level := 0
) -> GalaxyOpl:
	var chip := GalaxyOpl.new()
	chip.write(TEST_REGISTER, WAVE_SELECT_ENABLE)
	apply(chip, sine_writes(channel, level))
	apply(chip, key_on_writes(channel, f_number, block))
	return chip


## A carrier on channel 0 at 440 Hz in block 1 with the given envelope
## registers, keyed on.
static func envelope_chip(character: int, attack_decay: int, sustain_release: int) -> GalaxyOpl:
	var chip := GalaxyOpl.new()
	chip.write(TEST_REGISTER, WAVE_SELECT_ENABLE)
	apply(chip, sine_writes(0))
	chip.write(CHARACTER + CARRIERS[0], character)
	chip.write(ATTACK_DECAY + CARRIERS[0], attack_decay)
	chip.write(SUSTAIN_RELEASE + CARRIERS[0], sustain_release)
	apply(chip, key_on_writes(0, A440_F_NUMBER, ENVELOPE_BLOCK))
	return chip


## Lets the modulator of [param channel] sound at total level
## [param level] (instant attack).
static func wake_modulator(chip: GalaxyOpl, channel: int, level: int) -> void:
	chip.write(ATTACK_DECAY + MODULATORS[channel], 0xF0)
	chip.write(LEVEL + MODULATORS[channel], level)


static func key_off(chip: GalaxyOpl, channel: int, f_number: int, block: int) -> void:
	chip.write(KEY_BLOCK + channel, (block << 2) | (f_number >> 8))


## The loudness of the window starting at [param seconds], in dB against
## [param reference] (an RMS).
static func level_db(samples: PackedFloat32Array, seconds: float, reference: float) -> float:
	return decibels(rms(samples, samples_for(seconds), window()) / reference)


## The RMS of a steady full-level 440 Hz sine.
static func full_rms() -> float:
	var samples := sine_chip().generate(samples_for(0.2))
	return rms(samples, samples_for(0.1), samples_for(0.1))
