class_name GameTexts
extends RefCounted
## The texts of a game's own files that a language can translate, by their
## names ("keen1.hint.2"), as read from the player's files: what
## tools/language_template.gd writes out for a translator, and what the
## tests check every translation against. Each game keeps its own list
## (Keen1Texts, ...); the place that shows a text asks [Lang] for it by the
## same name.
##
## The English texts are the player's own and never go into git; only the
## translations in `languages/` do (the user's exception, 26-10-2026).
##
## A text of several lines is one value with its lines joined by "\n". A
## document (a story, an end text) is its file's text as it is, in the
## original's own mark-up ([TextDocument]: "~" at the start of a line,
## "\x1F" for a hard break), so it is laid out the way the original is.

## The line end of the documents in the game files.
const DOCUMENT_LINE_END := "\r\n"
## Names of the high score texts, after a game's prefix ("keen1.").
const SCORE_NAME := "scores.name.%d"
const SCORE_PLACE := "scores.place.%d"


## Name -> English text of every translatable text of game [param game]
## (1-5) in the player's files; empty when they are missing.
static func catalog(game: int) -> Dictionary[String, String]:
	var texts: Dictionary[String, String] = {}
	match game:
		1:
			texts = Keen1Texts.catalog(GameFiles.locate())
		2:
			texts = Keen2Texts.catalog(Keen2Files.locate())
		3:
			texts = Keen3Texts.catalog(Keen3Files.locate())
		_:
			pass
	return texts


## The text of a document's [param data] (up to its end mark), one
## character per byte, with "\n" for its line ends.
static func document_text(data: PackedByteArray) -> String:
	var text := ""
	for byte in data:
		if byte == TextDocument.END_MARK:
			break
		text += String.chr(byte)
	return text.replace(DOCUMENT_LINE_END, "\n")


## The document [param english_data] in the language in use, as the bytes of
## a document file, ready for [method TextDocument.layout]; the bytes as
## they are when there is no translation.
static func document(id: String, english_data: PackedByteArray) -> PackedByteArray:
	if not Lang.has_game(id) or english_data.is_empty():
		return english_data
	var text := Lang.game(id, "").replace("\r", "").replace("\n", DOCUMENT_LINE_END)
	var bytes := PackedByteArray()
	for index in text.length():
		bytes.append(text.unicode_at(index) & 0xFF)
	bytes.append_array(DOCUMENT_LINE_END.to_ascii_buffer())
	bytes.append(TextDocument.END_MARK)
	return bytes


## The lines of [param id] in the language in use, for a box whose lines
## stand at fixed places: a translation with another number of lines is not
## used, and each line is padded with spaces to its English line's length
## (an editor may strip the spaces at the end of a line).
static func fixed_lines(id: String, english: PackedStringArray) -> PackedStringArray:
	var translated := Lang.game_lines(id, english)
	if translated.size() != english.size():
		return english
	var lines := PackedStringArray()
	for index in translated.size():
		lines.append(translated[index].rpad(english[index].length()))
	return lines


## Adds the high score texts of [param scores] (or none when null) under
## [param prefix] ("keen1.") to [param texts].
static func add_score_texts(
	texts: Dictionary[String, String], prefix: String, scores: ScoreTexts
) -> void:
	if scores == null:
		return
	for index in scores.default_names.size():
		texts[prefix + SCORE_NAME % (index + 1)] = scores.default_names[index]
	for index in scores.place_names.size():
		texts[prefix + SCORE_PLACE % (index + 1)] = scores.place_names[index]


## The names of a new high score table in the language in use.
static func score_names(prefix: String, english: PackedStringArray) -> PackedStringArray:
	var names := PackedStringArray()
	for index in english.size():
		names.append(Lang.game(prefix + SCORE_NAME % (index + 1), english[index]))
	return names


## The word for place [param place] (0 for the first) in the language in
## use; [param fallback] when the files have no word for it.
static func place_word(prefix: String, scores: ScoreTexts, place: int, fallback: String) -> String:
	var words := scores.place_names if scores != null else PackedStringArray()
	if place < 0 or place >= words.size():
		return fallback
	return Lang.game(prefix + SCORE_PLACE % (place + 1), words[place])


## [param lines] as one value of a catalog.
static func joined(lines: PackedStringArray) -> String:
	return "\n".join(lines)
