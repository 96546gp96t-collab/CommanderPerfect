class_name Keen3EndText
extends RefCounted
## Lays out Keen 3's end text (ENDTEXT in KEEN3.EXE) as the original's text
## reader shows it (seen in the original, C11). The text is written for an
## 80-column screen, as [TextDocument] reads it, with two differences:
##   ~      at the start of a line marks a highlighted line: red letters on a
##          gray bar the width of the window (the font's second half,
##          [method Keen3Window.label_text]); its text stays where it is
##          typed ("~          CONGRATULATIONS!" stands 10 cells in), it is
##          not centred
##   spaces inside a paragraph are kept when it is wrapped again ("$15
##          each" stays apart from "or" because two spaces follow
##          "Productions."), where [TextDocument] joins the words with one
## A tab stays a character (the font draws it as a blue ball). Only Keen 3
## uses this; [TextDocument] is shared and stays as it is.

const HIGHLIGHT_MARK := "~"
const BREAK_MARK := 0x1F
const END_MARK := 0x1A
const LINE_END := "\r\n"


## Lays out [param data] in lines of [param width] characters at most;
## highlighted lines come back in the font's second half, [param width]
## wide.
static func layout(data: PackedByteArray, width: int) -> PackedStringArray:
	var result := PackedStringArray()
	var paragraph := ""
	for raw in _decode(data).trim_suffix(LINE_END).split(LINE_END):
		var hard_break := raw.ends_with(String.chr(BREAK_MARK))
		var text := raw.trim_suffix(String.chr(BREAK_MARK))
		if text.begins_with(HIGHLIGHT_MARK):
			result.append_array(wrap_paragraph(paragraph, width))
			paragraph = ""
			var bar := text.trim_prefix(HIGHLIGHT_MARK).left(width).rpad(width)
			result.append(Keen3Window.label_text(bar))
			continue
		if text.strip_edges().is_empty():
			result.append_array(wrap_paragraph(paragraph, width))
			paragraph = ""
			result.append("")
			continue
		paragraph = text if paragraph.is_empty() else paragraph + " " + text.strip_edges()
		if hard_break:
			result.append_array(wrap_paragraph(paragraph, width))
			paragraph = ""
	result.append_array(wrap_paragraph(paragraph, width))
	return result


## Splits [param text] into lines of at most [param width] characters at
## its spaces, keeping runs of spaces between the words of a line; the
## spaces where a line breaks are dropped.
static func wrap_paragraph(text: String, width: int) -> PackedStringArray:
	var lines := PackedStringArray()
	if text.strip_edges().is_empty():
		return lines
	var line := ""
	var gap := ""
	var position := 0
	while position < text.length():
		var next := position
		while next < text.length() and text[next] != " ":
			next += 1
		var word := text.substr(position, next - position)
		var spaces_end := next
		while spaces_end < text.length() and text[spaces_end] == " ":
			spaces_end += 1
		var spaces := text.substr(next, spaces_end - next)
		position = spaces_end
		if word.is_empty():
			# Spaces at the start: an indent, kept as it is typed.
			line += spaces
			continue
		if not line.strip_edges().is_empty() and (line + gap + word).length() > width:
			lines.append(line)
			line = word
		else:
			line += gap + word
		gap = spaces
	if not line.strip_edges().is_empty():
		lines.append(line)
	return lines


## The bytes up to the end mark, one character per byte.
static func _decode(data: PackedByteArray) -> String:
	var text := ""
	for byte in data:
		if byte == END_MARK:
			break
		text += String.chr(byte)
	return text
