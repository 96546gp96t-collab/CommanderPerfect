class_name SoundFile
extends RefCounted
## Reads SOUNDS.CK1: the PC speaker sounds of the game.
##
## The file starts with a header of 16 bytes:
##   0   "SND\\0"
##   4   u16 size of the file
##   6   u16 number of entries in the table
##   8   u16 unknown (60 in version 1.1)
## Then follows a table of 16-byte entries:
##   0   u16 offset of the sound data in the file
##   2   u8  priority: a sound only interrupts one of lower or equal priority
##   3   u8  unknown (8 for the real sounds, 1 for the empty slots)
##   4   12 bytes name, zero-padded (for example "KEENJUMPSND")
## The data of a sound is a list of u16 values ending with 0xFFFF. Each value
## is one step of [constant STEPS_PER_SECOND]: 0 means silence, anything
## else is the divisor for the PC's timer chip, so the speaker sounds at
## [constant TIMER_FREQUENCY] / value Hz. See docs/file-formats.md.

const SIGNATURE := "SND"
const HEADER_SIZE := 16
const ENTRY_SIZE := 16
const NAME_SIZE := 12
const COUNT_OFFSET := 6
const END_MARK := 0xFFFF
## The clock of the PC's programmable interval timer, which drives the speaker.
const TIMER_FREQUENCY := 1193182.0
## The game plays one value of a sound per tick of its 140 Hz sound timer.
const STEPS_PER_SECOND := 140.0

## Every sound in the file by name, as [Entry].
var sounds: Dictionary[String, Entry] = {}


## One sound: how important it is and its timer divisors.
class Entry:
	extends RefCounted
	var priority := 0
	## One timer divisor per step; 0 is silence.
	var divisors := PackedInt32Array()


## Reads the sounds from the contents of SOUNDS.CK1. Returns null when the
## data is not a sound file.
static func parse(data: PackedByteArray) -> SoundFile:
	if data.size() < HEADER_SIZE or data.slice(0, 3).get_string_from_ascii() != SIGNATURE:
		push_error("This is not a sound file.")
		return null
	var count := data.decode_u16(COUNT_OFFSET)
	if HEADER_SIZE + count * ENTRY_SIZE > data.size():
		push_error("The sound table runs past the end of the file.")
		return null
	var file := SoundFile.new()
	for index in count:
		var at := HEADER_SIZE + index * ENTRY_SIZE
		var name := data.slice(at + 4, at + 4 + NAME_SIZE).get_string_from_ascii()
		var entry := _read_entry(data, data.decode_u16(at), data[at + 2])
		if entry == null:
			push_error("Sound %s runs past the end of the file." % name)
			return null
		if not name.is_empty() and not file.sounds.has(name.to_upper()):
			file.sounds[name.to_upper()] = entry
	return file


## Loads SOUNDS.CK1 from the game files. Returns null when that fails.
static func load_from(files: GameFiles) -> SoundFile:
	var data := files.read(GameFiles.SOUNDS)
	if data.is_empty():
		push_error("%s could not be read." % GameFiles.SOUNDS)
		return null
	return parse(data)


static func _read_entry(data: PackedByteArray, offset: int, priority: int) -> Entry:
	var entry := Entry.new()
	entry.priority = priority
	var position := offset
	while position + 1 < data.size():
		var value := data.decode_u16(position)
		if value == END_MARK:
			return entry
		entry.divisors.append(value)
		position += 2
	return null
