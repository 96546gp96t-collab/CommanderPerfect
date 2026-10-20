class_name SpeakerSynth
extends RefCounted
## Turns a PC speaker sound ([member SoundFile.Entry.divisors]) into audio.
##
## The PC speaker can only be on or off, so it plays square waves. Each step
## of a sound holds one frequency for one tick of the game's sound timer
## ([constant SoundFile.STEPS_PER_SECOND], 145.65 a second); the wave keeps
## its phase from one step to the next, as the timer chip does. A gentle
## low-pass filter takes the harsh edge off the square, the way the small
## speaker in a PC did. Frequencies too high to hear on a real speaker are
## left out, because at the mix rate they would fold back into audible
## noise.
##
## The step rate can be given: Keen 4 and later play their PC speaker sounds
## at about 140 steps a second.

const MIX_RATE := 44100
## Loudness of the square wave, as a fraction of full scale.
const VOLUME := 0.18
## Strength of the low-pass filter, from 0 (no sound) to 1 (no filtering).
const SMOOTHING := 0.35
## Frequencies above this many Hz are played as silence.
const MAX_FREQUENCY := 15000.0
const FULL_SCALE := 32767.0
const BYTES_PER_SAMPLE := 2


## The sound with timer divisors [param divisors] as 16-bit mono audio, one
## divisor per step of 1 / [param steps_per_second] s.
static func render(
	divisors: PackedInt32Array, steps_per_second := SoundFile.STEPS_PER_SECOND
) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = render_samples(divisors, steps_per_second)
	return stream


## The raw 16-bit little-endian samples of the sound.
static func render_samples(
	divisors: PackedInt32Array, steps_per_second := SoundFile.STEPS_PER_SECOND
) -> PackedByteArray:
	var samples_per_step := MIX_RATE / steps_per_second
	var total := ceili(divisors.size() * samples_per_step)
	var bytes := PackedByteArray()
	bytes.resize(total * BYTES_PER_SAMPLE)
	var phase := 0.0
	var level := 0.0
	var amplitude := VOLUME * FULL_SCALE
	for index in total:
		var divisor := divisors[mini(int(index / samples_per_step), divisors.size() - 1)]
		var target := 0.0
		if divisor > 0:
			var frequency := SoundFile.TIMER_FREQUENCY / divisor
			if frequency <= MAX_FREQUENCY:
				phase = fmod(phase + frequency / MIX_RATE, 1.0)
				target = amplitude if phase < 0.5 else -amplitude
		level += (target - level) * SMOOTHING
		bytes.encode_s16(index * BYTES_PER_SAMPLE, roundi(level))
	return bytes
