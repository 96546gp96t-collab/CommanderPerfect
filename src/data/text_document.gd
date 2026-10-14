class_name TextDocument
extends RefCounted
## Reads the text files of the game (ENDTEXT.CK1, and later STORYTXT.CK1 and
## HELPTEXT.CK1) and lays them out for a screen of a given width.
##
## The files are plain text, written for an 80-column screen:
##   CR LF      ends a line
##   ~          at the start of a line: center it
##   0x1F       at the end of a line: break here
##   0x1A       end of the text
## Other lines run on into the next one, so that a paragraph can be wrapped
## again for a narrower screen; an empty line ends the paragraph. Bytes from
## 0x80 on are pictures in the game font (a little Keen face, for example) and
## are kept as characters with that code.

const CENTER_MARK := "~"
const BREAK_MARK := 0x1F
const END_MARK := 0x1A
const LINE_END := "\r\n"


## Lays out [param data] in lines of at most [param width] characters.
static func layout(data: PackedByteArray, width: int) -> PackedStringArray:
	var result := PackedStringArray()
	var paragraph := ""
	for raw in _decode(data).trim_suffix(LINE_END).split(LINE_END):
		var centered := raw.begins_with(CENTER_MARK)
		var hard_break := raw.ends_with(String.chr(BREAK_MARK))
		var text := raw.trim_prefix(CENTER_MARK).trim_suffix(String.chr(BREAK_MARK))
		if centered:
			result.append_array(_wrap(paragraph, width))
			paragraph = ""
			result.append(_center(text.strip_edges(), width))
			continue
		if text.strip_edges().is_empty():
			result.append_array(_wrap(paragraph, width))
			paragraph = ""
			result.append("")
			continue
		paragraph = text if paragraph.is_empty() else paragraph + " " + text.strip_edges()
		if hard_break:
			result.append_array(_wrap(paragraph, width))
			paragraph = ""
	result.append_array(_wrap(paragraph, width))
	return result


## The bytes up to the end mark, one character per byte.
static func _decode(data: PackedByteArray) -> String:
	var text := ""
	for byte in data:
		if byte == END_MARK:
			break
		text += String.chr(byte)
	return text


## Splits [param text] at spaces into lines of at most [param width]
## characters. Text that fits stays as it is, spaces and all, because some
## lines are laid out by hand (the little Keen face in ENDTEXT.CK1).
static func _wrap(text: String, width: int) -> PackedStringArray:
	var lines := PackedStringArray()
	if text.is_empty():
		return lines
	if text.length() <= width:
		lines.append(text)
		return lines
	var indent := text.length() - text.lstrip(" ").length()
	var line := text.substr(0, indent)
	var has_word := false
	for word in text.substr(indent).split(" ", false):
		if has_word and line.length() + 1 + word.length() > width:
			lines.append(line)
			line = word
		else:
			line = line + " " + word if has_word else line + word
		has_word = true
	lines.append(line)
	return lines


static func _center(text: String, width: int) -> String:
	if text.is_empty():
		return text
	return " ".repeat(maxi(0, (width - text.length()) / 2)) + text
