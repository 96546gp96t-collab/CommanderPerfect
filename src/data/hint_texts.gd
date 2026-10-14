class_name HintTexts
extends RefCounted
## The messages of the Yorp and Garg statues, read from KEEN1.EXE.
##
## The executable keeps them as a run of zero-terminated lines, each padded
## with spaces to about 20 characters and ending in a newline, directly
## followed by the prompt "Press ENTER:". Every message starts with a header
## of two lines, the second ending in a colon ("You hear in your" / "mind:"),
## and a blank line. Right before the first line is a table of numbers
## without a zero in between, so that line is cut off at its first printable
## character. The messages are in the order of the levels that have a
## statue, see [constant HINT_LEVELS] (docs/file-formats.md).

const PROMPT := "Press ENTER:"
## Levels with a statue, in the order of their messages.
const HINT_LEVELS: PackedInt32Array = [2, 6, 9, 10, 11, 12, 15]

## Each message as lines without the trailing spaces.
var messages: Array[PackedStringArray] = []


## Reads the messages from the program image (see
## [method DosExecutable.load_image]). Returns null when they are not found.
static func find_in_image(image: PackedByteArray) -> HintTexts:
	var prompt_at := ExeStrings.find(image, PROMPT.to_ascii_buffer())
	if prompt_at < 0:
		push_error("The statue messages were not found in the executable.")
		return null
	var lines := ExeStrings.lines_before(image, prompt_at)
	var hints := HintTexts.new()
	for index in lines.size():
		if hints.messages.is_empty() or _starts_message(lines, index):
			hints.messages.append(PackedStringArray())
		hints.messages[-1].append(lines[index].strip_edges(false, true))
	if hints.messages.size() != HINT_LEVELS.size():
		push_error(
			"Found %d statue messages instead of %d." % [hints.messages.size(), HINT_LEVELS.size()]
		)
		return null
	return hints


## Loads the messages from KEEN1.EXE. Returns null when that fails.
static func load_from(files: GameFiles) -> HintTexts:
	var image := DosExecutable.load_image(files.read(GameFiles.EXECUTABLE))
	if image.is_empty():
		return null
	return find_in_image(image)


## The message of the statue in [param level_number], or an empty array.
func for_level(level_number: int) -> PackedStringArray:
	var index := HINT_LEVELS.find(level_number)
	if index < 0 or index >= messages.size():
		return PackedStringArray()
	return messages[index]


## Whether line [param index] is the first of a message header.
static func _starts_message(lines: PackedStringArray, index: int) -> bool:
	return (
		index + 2 < lines.size()
		and lines[index + 1].strip_edges().ends_with(":")
		and lines[index + 2].strip_edges().is_empty()
	)
