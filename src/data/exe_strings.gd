class_name ExeStrings
extends RefCounted
## Helpers for reading texts out of the program image of KEEN1.EXE (see
## [method DosExecutable.load_image]).
##
## The game keeps its texts as zero-terminated records. A message of several
## lines is usually one record per line, each ending in a newline:
## "line\\n\\0line\\n\\0". The last line of a message often has no newline.

const NEWLINE := 0x0A
const FIRST_PRINTABLE := 0x20
const LAST_PRINTABLE := 0x7E


## Position of the first [param needle] in [param haystack], or -1.
static func find(haystack: PackedByteArray, needle: PackedByteArray, from := 0) -> int:
	var first := needle[0]
	var position := haystack.find(first, from)
	while position >= 0 and position + needle.size() <= haystack.size():
		if haystack.slice(position, position + needle.size()) == needle:
			return position
		position = haystack.find(first, position + 1)
	return -1


## The zero-terminated record that starts at [param start], without its zero.
static func record_at(image: PackedByteArray, start: int) -> String:
	var end := image.find(0, start)
	if end < 0:
		end = image.size()
	return image.slice(start, end).get_string_from_ascii()


## The records from [param start] on, grouped into messages: a record that
## ends in a newline continues the message, one without ends it. Returns at
## most [param count] messages, each as its lines.
static func messages_from(
	image: PackedByteArray, start: int, count: int
) -> Array[PackedStringArray]:
	var messages: Array[PackedStringArray] = []
	var lines := PackedStringArray()
	var position := start
	while messages.size() < count and position < image.size():
		var record := record_at(image, position)
		position += record.length() + 1
		lines.append(record.trim_suffix("\n"))
		if not record.ends_with("\n"):
			messages.append(lines)
			lines = PackedStringArray()
	return messages


## The lines that end right before [param end], oldest first. Each line is a
## record "text\\n\\0"; the walk goes back from the zero before [param end]
## and stops at the first record that is not such a line. A record that runs
## into other data (no zero in front of it) is cut off at its first
## printable character.
static func lines_before(image: PackedByteArray, end: int) -> PackedStringArray:
	var lines := PackedStringArray()
	var zero := end - 1
	while zero > 0 and image[zero] == 0:
		var start := zero - 1
		while start >= 0 and image[start] != 0:
			start -= 1
		var record := image.slice(start + 1, zero)
		if record.size() < 2 or record[-1] != NEWLINE:
			break
		var first := record.size() - 1
		while first > 0 and is_printable(record[first - 1]):
			first -= 1
		lines.insert(0, record.slice(first, record.size() - 1).get_string_from_ascii())
		if first > 0:
			break
		zero = start
	return lines


static func is_printable(character: int) -> bool:
	return character >= FIRST_PRINTABLE and character <= LAST_PRINTABLE
