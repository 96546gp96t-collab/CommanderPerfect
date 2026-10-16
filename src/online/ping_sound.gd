class_name PingSound
extends RefCounted
## The "ping" the host hears when someone joins: a short rising pair of
## tones in the style of the PC speaker, made with the same [SpeakerSynth]
## as the game's own sounds. It is not one of the original sounds.

## Frequencies in Hz, each held for [constant STEPS_PER_TONE] steps of
## 1/140 s.
const TONES: Array[float] = [1318.5, 1975.5]
const STEPS_PER_TONE := 9


static func render() -> AudioStreamWAV:
	return SpeakerSynth.render(divisors())


## The timer divisors of the ping, like those in SOUNDS.CK1.
static func divisors() -> PackedInt32Array:
	var result := PackedInt32Array()
	for frequency in TONES:
		for step in STEPS_PER_TONE:
			result.append(roundi(SoundFile.TIMER_FREQUENCY / frequency))
	return result
