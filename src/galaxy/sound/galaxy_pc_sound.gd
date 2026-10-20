class_name GalaxyPcSound
extends RefCounted
## A Galaxy PC speaker sound: a 32-bit length (the number of steps), a
## 16-bit priority, then one byte per step: the timer divisor divided by
## [constant DIVISOR_FACTOR], or 0 for silence (Omni `id_sd.c`,
## SD_PC_SoundService). The steps run at the same rate as the AdLib
## sounds' ([constant GalaxyAdlibSound.STEPS_PER_SECOND], about 140 a
## second) and are played by the shared [SpeakerSynth]. The service that
## reads the last step turns the speaker off at once (Omni: it checks the
## end right after setting the speaker), so the last step is never heard.

const HEADER_SIZE := 6
const DIVISOR_FACTOR := 60
const STEPS_PER_SECOND := GalaxyAdlibSound.STEPS_PER_SECOND

var priority := 0
var steps := PackedByteArray()


## The sound in [param chunk]; null (with the reason) when it is too short.
static func parse(chunk: PackedByteArray) -> GalaxyPcSound:
	if chunk.size() < HEADER_SIZE:
		push_error("A PC speaker sound chunk is too short.")
		return null
	var sound := GalaxyPcSound.new()
	var length := chunk.decode_u32(0)
	sound.priority = chunk.decode_u16(4)
	sound.steps = chunk.slice(HEADER_SIZE, HEADER_SIZE + mini(length, chunk.size() - HEADER_SIZE))
	return sound


## The timer divisor of every step, as [SpeakerSynth] takes them.
func divisors() -> PackedInt32Array:
	var result := PackedInt32Array()
	result.resize(steps.size())
	for index in steps.size():
		result[index] = steps[index] * DIVISOR_FACTOR
	return result


## The steps that are heard: all but the last.
func heard_divisors() -> PackedInt32Array:
	var all := divisors()
	return all.slice(0, maxi(all.size() - 1, 0))


## How long the sound lasts (and counts as playing), in seconds.
func duration() -> float:
	return heard_divisors().size() / STEPS_PER_SECOND


func render() -> AudioStreamWAV:
	return SpeakerSynth.render(heard_divisors(), STEPS_PER_SECOND)


## The raw 16-bit samples of [method render].
func render_samples() -> PackedByteArray:
	return SpeakerSynth.render_samples(heard_divisors(), STEPS_PER_SECOND)
