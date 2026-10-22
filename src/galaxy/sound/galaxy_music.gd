class_name GalaxyMusic
extends RefCounted
## A Galaxy song: a 16-bit length in bytes, then commands of four bytes
## (an OPL2 register, its value, and a 16-bit delay in ticks before the
## next command). The original plays them at [constant TICKS_PER_SECOND]
## and starts again at the first command after the last (Omni
## `id_sd.c:SD_AL_MusicService`): every command whose time has come is
## written, then the tick ends; the last command's delay is never waited
## for, and the first tick of the next round follows the tick of the last
## command. So one round lasts [method loop_ticks].
##
## [method render] plays a song once on a fresh [GalaxyOpl] (the original
## resets the chip and enables the waveforms) and on into the next round
## for [constant LEAD_SECONDS], and gives the loop as the part from
## that lead time to the same point one round later: the chip is then in
## the state of the second round, with the last notes of the first still
## sounding, as in the original.

const LENGTH_SIZE := 2
const COMMAND_SIZE := 4
## The PC's timer clock, and the divisor the original programs for 560 Hz:
## 1192030 / 560 (Omni `id_sd.c`, SD_SOUND_PART_RATE_BASE), so the music
## really ticks at 560.7 Hz.
const PIT_CLOCK := 1193182.0
const MUSIC_DIVISOR := 2128
const TICKS_PER_SECOND := PIT_CLOCK / MUSIC_DIVISOR
## How far into the second round the loop starts.
const LEAD_SECONDS := 3.0
## The commands rendered between two looks at the cancel callable.
const CANCEL_CHECK_COMMANDS := 64
## The chip's state when the original starts a song (Omni SD_AL_Reset).
const RESET_TEST_VALUE := 0x20

## The commands, three numbers each: register, value, delay.
var commands := PackedInt32Array()


## The song in [param chunk]; null (with the reason) when it is too short.
static func parse(chunk: PackedByteArray) -> GalaxyMusic:
	if chunk.size() < LENGTH_SIZE:
		push_error("A song chunk is too short.")
		return null
	var length := mini(chunk.decode_u16(0), chunk.size() - LENGTH_SIZE)
	var music := GalaxyMusic.new()
	var count := length / COMMAND_SIZE
	music.commands.resize(count * 3)
	for index in count:
		var at := LENGTH_SIZE + index * COMMAND_SIZE
		music.commands[index * 3] = chunk[at]
		music.commands[index * 3 + 1] = chunk[at + 1]
		music.commands[index * 3 + 2] = chunk.decode_u16(at + 2)
	return music


func command_count() -> int:
	return commands.size() / 3


## The sum of every command's delay, in ticks.
func delay_sum() -> int:
	var total := 0
	for index in command_count():
		total += commands[index * 3 + 2]
	return total


## The ticks of one round as the original plays it (see the class).
func loop_ticks() -> int:
	if command_count() == 0:
		return 0
	return delay_sum() - commands[commands.size() - 1] + 1


## One round in seconds.
func duration() -> float:
	return loop_ticks() / TICKS_PER_SECOND


## The song at [constant GalaxyOpl.CHIP_RATE]: {"samples":
## PackedFloat32Array, "loop_begin": int, "loop_end": int} (in samples).
## Empty when [param cancel] (returns true to stop) asks to stop.
func render(cancel := Callable()) -> Dictionary:
	var round_ticks := loop_ticks()
	if round_ticks <= 0:
		return {}
	var lead_ticks := roundi(LEAD_SECONDS * TICKS_PER_SECOND)
	var end_tick := round_ticks + lead_ticks
	var chip := GalaxyOpl.new()
	chip.write(GalaxyOpl.TEST_REGISTER, RESET_TEST_VALUE)
	var samples := PackedFloat32Array()
	var tick := 0
	var round_start := 0
	var index := 0
	var count := command_count()
	while tick < end_tick:
		if index == count:
			round_start += round_ticks
			tick = round_start
			index = 0
		chip.write(commands[index * 3], commands[index * 3 + 1])
		var next := tick + commands[index * 3 + 2]
		if index == count - 1:
			next = round_start + round_ticks
		next = mini(next, end_tick)
		if next > tick:
			samples.append_array(chip.generate(_sample_at(next) - _sample_at(tick)))
		tick = next
		index += 1
		if index % CANCEL_CHECK_COMMANDS == 0 and cancel.is_valid() and cancel.call():
			return {}
	return {
		"samples": samples,
		"loop_begin": _sample_at(lead_ticks),
		"loop_end": _sample_at(end_tick),
	}


static func _sample_at(tick: int) -> int:
	return roundi(tick * GalaxyOpl.CHIP_RATE / TICKS_PER_SECOND)
