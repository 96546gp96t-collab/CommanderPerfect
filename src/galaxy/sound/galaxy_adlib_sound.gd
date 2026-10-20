class_name GalaxyAdlibSound
extends RefCounted
## A Galaxy AdLib sound: a 32-bit length (the number of notes), a 16-bit
## priority, a 16-byte instrument, the octave (block), then one note byte
## per step of [constant STEPS_PER_SECOND] on channel 0 of the OPL2.
##
## How the original plays it (Omni `id_sd.c`, SD_AL_PlaySound and
## SD_AL_SoundService): the instrument goes to the channel's two operators
## (registers 0x20, 0x40, 0x60, 0x80 and 0xE0; the instrument's
## connection byte is not written), then each step writes a note as the
## F-number's low byte with the key on and the block in register 0xB0 (the
## F-number's top bits stay 0), or turns the key off for a 0. After the
## last step the key goes off. [method render_samples] renders that on a
## fresh chip, plus the release that still sounds afterwards.

const HEADER_SIZE := 6
const INSTRUMENT_SIZE := 16
const BLOCK_OFFSET := HEADER_SIZE + INSTRUMENT_SIZE
const NOTES_OFFSET := BLOCK_OFFSET + 1
## The sound timer runs at a quarter of the music's rate (Omni
## SDL_t0Service, with AdLib music on): 140.2 steps a second.
const STEPS_PER_SECOND := GalaxyMusic.TICKS_PER_SECOND / 4.0
## The instrument's bytes: modulator and carrier of each register pair.
const INSTRUMENT_REGISTERS: PackedInt32Array = [
	GalaxyOpl.CHARACTER,
	GalaxyOpl.LEVELS,
	GalaxyOpl.ATTACK_DECAY,
	GalaxyOpl.SUSTAIN_RELEASE,
	GalaxyOpl.WAVEFORM
]
## Channel 0's modulator and carrier register offsets.
const MODULATOR := 0
const CARRIER := 3
const BLOCK_SHIFT := 2
## The longest release rendered after the last note.
const MAX_TAIL_SECONDS := 1.0
const TAIL_PIECE := 512

var priority := 0
var instrument := PackedByteArray()
var block := 0
var notes := PackedByteArray()


## The sound in [param chunk]; null (with the reason) when it is too short.
static func parse(chunk: PackedByteArray) -> GalaxyAdlibSound:
	if chunk.size() < NOTES_OFFSET:
		push_error("An AdLib sound chunk is too short.")
		return null
	var sound := GalaxyAdlibSound.new()
	var length := chunk.decode_u32(0)
	sound.priority = chunk.decode_u16(4)
	sound.instrument = chunk.slice(HEADER_SIZE, BLOCK_OFFSET)
	sound.block = chunk[BLOCK_OFFSET] & 7
	sound.notes = chunk.slice(
		NOTES_OFFSET, NOTES_OFFSET + mini(length, chunk.size() - NOTES_OFFSET)
	)
	return sound


## How long the notes last, in seconds (the time the original counts the
## sound as playing).
func duration() -> float:
	return notes.size() / STEPS_PER_SECOND


## The sound at [constant GalaxyOpl.CHIP_RATE], 1.0 = 16-bit full scale.
## [param connection] is what channel 0's register 0xC0 holds (0 after
## the original resets the chip).
func render_samples(connection := 0) -> PackedFloat32Array:
	var chip := GalaxyOpl.new()
	chip.write(GalaxyOpl.TEST_REGISTER, GalaxyMusic.RESET_TEST_VALUE)
	chip.write(GalaxyOpl.FEEDBACK_CONNECTION, connection)
	for index in INSTRUMENT_REGISTERS.size():
		chip.write(INSTRUMENT_REGISTERS[index] + MODULATOR, instrument[index * 2])
		chip.write(INSTRUMENT_REGISTERS[index] + CARRIER, instrument[index * 2 + 1])
	var key_block := GalaxyOpl.KEY_ON | (block << BLOCK_SHIFT)
	var samples := PackedFloat32Array()
	for index in notes.size():
		var note := notes[index]
		if note == 0:
			chip.write(GalaxyOpl.KEY_BLOCK, 0)
		else:
			chip.write(GalaxyOpl.F_NUMBER_LOW, note)
			chip.write(GalaxyOpl.KEY_BLOCK, key_block)
		samples.append_array(chip.generate(_sample_at(index + 1) - _sample_at(index)))
	chip.write(GalaxyOpl.KEY_BLOCK, 0)
	var tail := 0
	var max_tail := int(MAX_TAIL_SECONDS * GalaxyOpl.CHIP_RATE)
	while tail < max_tail and not chip.is_channel_silent(0):
		samples.append_array(chip.generate(TAIL_PIECE))
		tail += TAIL_PIECE
	return samples


static func _sample_at(step: int) -> int:
	return roundi(step * GalaxyOpl.CHIP_RATE / STEPS_PER_SECOND)
