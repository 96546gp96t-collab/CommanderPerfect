class_name EndingTexts
extends RefCounted
## The texts around Keen's ship, read from KEEN1.EXE: the message when the
## ship is still missing parts, and the messages of the ending.
##
## In the executable (see docs/file-formats.md):
##   - "Your ship is missing\\nthese parts:\\n..." is one record, followed by
##     the record "    GO GET THEM!\\n". The empty lines leave room for the
##     pictures of the missing parts.
##   - The first message of the ending (Keen returns to his ship) is a run of
##     "line\\n\\0" records ending right before the file name "FINALE.CK1".
##   - After that name come the messages shown over the picture of Keen's
##     house, and finally "TO BE CONTINUED....". A message ends with a line
##     without a newline; that gives seven messages (the parents' question
##     and Keen's answer are one).

const MISSING_PARTS_START := "Your ship is missing"
const FINALE_FILE_NAME := "FINALE.CK1"
## Messages shown over the picture of Keen's house.
const HOME_MESSAGE_COUNT := 7
const TO_BE_CONTINUED := "TO BE CONTINUED"
const MESSAGES_AFTER_FINALE := HOME_MESSAGE_COUNT + 1

## "Your ship is missing / these parts:", blank lines and "GO GET THEM!".
var missing_parts := PackedStringArray()
## Keen returns to the ship and repairs it.
var returns_to_ship := PackedStringArray()
## The conversation at home, one message per window.
var home_messages: Array[PackedStringArray] = []
var to_be_continued := ""


## Reads the texts from the program image. Returns null when they are not
## found.
static func find_in_image(image: PackedByteArray) -> EndingTexts:
	var texts := EndingTexts.new()
	var missing_at := ExeStrings.find(image, MISSING_PARTS_START.to_ascii_buffer())
	# With its terminating zero, so that the name is not found inside a path.
	var finale_name := FINALE_FILE_NAME.to_ascii_buffer()
	finale_name.append(0)
	var finale_at := ExeStrings.find(image, finale_name)
	if missing_at < 0 or finale_at < 0:
		push_error("The texts of the ending were not found in the executable.")
		return null

	var missing := ExeStrings.record_at(image, missing_at)
	var go_get_them := ExeStrings.record_at(image, missing_at + missing.length() + 1)
	texts.missing_parts = missing.trim_suffix("\n").split("\n")
	texts.missing_parts.append(go_get_them.trim_suffix("\n"))

	texts.returns_to_ship = ExeStrings.lines_before(image, finale_at)
	var after := ExeStrings.messages_from(
		image, finale_at + finale_name.size(), MESSAGES_AFTER_FINALE
	)
	if (
		texts.returns_to_ship.is_empty()
		or after.size() < MESSAGES_AFTER_FINALE
		or not after[HOME_MESSAGE_COUNT][0].begins_with(TO_BE_CONTINUED)
	):
		push_error("The messages of the ending are incomplete.")
		return null
	texts.home_messages = after.slice(0, HOME_MESSAGE_COUNT)
	texts.to_be_continued = after[HOME_MESSAGE_COUNT][0]
	return texts


## Loads the texts from KEEN1.EXE. Returns null when that fails.
static func load_from(files: GameFiles) -> EndingTexts:
	var image := DosExecutable.load_image(files.read(GameFiles.EXECUTABLE))
	if image.is_empty():
		return null
	return find_in_image(image)
