class_name GalaxyTextPages
extends RefCounted
## A text of a Galaxy episode with its page mark-up (the help topics, the
## end; EGAGRAPH's text chunks), split into pages. Lines end in CR LF;
## commands start with a caret (Omni `ck_text.c`, facts only;
## docs/keen4/file-formats.md, "Texts"):
##   - [code]^P[/code] starts a page (the rest of its line is skipped),
##     [code]^E[/code] ends the text;
##   - [code]^G y,x,chunk[/code] a picture, [code]^T y,x,chunk,tics[/code] a
##     picture after a pause, [code]^L y,x[/code] where the next words go,
##     [code]^C[/code] / [code]^c[/code] and one hex digit a text colour,
##     [code]^B y,x,width,height,...[/code] a bar.
## The picture numbers are chunk numbers of the version they come from.
## Laying a page out is [GalaxyPageLayout]'s job; this class only cuts the
## text and reads the numbers.

const CARET := 0x5E
const NEWLINE := 0x0A
const PAGE := 0x50
const END := 0x45
const LOWER_CASE := 0x20
const DIGIT_ZERO := 0x30
const DIGIT_NINE := 0x39

## The text as bytes (characters above 127 kept as they are).
var bytes := PackedByteArray()
## Where each page's text starts: right after its ^P line.
var page_starts := PackedInt32Array()
## Where the text ends (its ^E, or its last byte).
var end := 0


## The pages of [param text]; empty (no pages) when it has no ^P.
static func parse(text: PackedByteArray) -> GalaxyTextPages:
	var pages := GalaxyTextPages.new()
	pages.bytes = text
	pages.end = text.size()
	var at := 0
	while at < text.size():
		var command := command_at(text, at)
		if command == END:
			pages.end = at
			break
		if command == PAGE:
			pages.page_starts.append(line_end(text, at))
		at += 1
	return pages


func page_count() -> int:
	return page_starts.size()


## Where page [param index]'s text stops: at the next ^P or ^E.
func page_end(index: int) -> int:
	if index + 1 < page_starts.size():
		var at := page_starts[index + 1] - 1
		while at > 0 and command_at(bytes, at) != PAGE:
			at -= 1
		return at
	return end


## The command letter (upper case) when a caret starts at [param at],
## otherwise -1.
static func command_at(text: PackedByteArray, at: int) -> int:
	if at + 1 >= text.size() or text[at] != CARET:
		return -1
	return upper(text[at + 1])


static func upper(character: int) -> int:
	if character >= 0x61 and character <= 0x7A:
		return character - LOWER_CASE
	return character


## The position after the newline that ends the line [param at] is on.
static func line_end(text: PackedByteArray, at: int) -> int:
	var position := at
	while position < text.size() and text[position] != NEWLINE:
		position += 1
	return mini(position + 1, text.size())


## Reads [param count] numbers from [param at] on (anything that is not a
## digit separates them). Returns the numbers and, last, the position after
## the last digit.
static func numbers_at(text: PackedByteArray, at: int, count: int) -> PackedInt32Array:
	var found := PackedInt32Array()
	var position := at
	while found.size() < count and position < text.size():
		while position < text.size() and not _is_digit(text[position]):
			position += 1
		var value := 0
		var digits := 0
		while position < text.size() and _is_digit(text[position]):
			value = value * 10 + text[position] - DIGIT_ZERO
			position += 1
			digits += 1
		if digits > 0:
			found.append(value)
	found.append(position)
	return found


static func _is_digit(character: int) -> bool:
	return character >= DIGIT_ZERO and character <= DIGIT_NINE
