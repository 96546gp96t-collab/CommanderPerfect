class_name Keen1Texts
extends RefCounted
## The names of Keen 1's translatable texts (from KEEN1.EXE, STORYTXT.CK1
## and ENDTEXT.CK1) and their English as read from the player's files
## ([method catalog]). The places that show a text ask [Lang] for it by the
## name given here:
##   keen1.hint.<level>       a statue's message (levels 2, 6, 9-12, 15),
##                            its header lines included
##   keen1.hint.prompt        "Press ENTER:" under it
##   keen1.ship.missing       the ship's missing parts: the part pictures
##                            stand on its empty lines, so the lines keep
##                            their places
##   keen1.ending.ship        Keen back at his ship
##   keen1.ending.home.<n>    the seven messages at home (1-7)
##   keen1.endtext            ENDTEXT.CK1, a document
##   keen1.story              STORYTXT.CK1, a document
##   keen1.scores.name.<n>    the names of a new high score table (1-3)
##   keen1.scores.place.<n>   the words for the places (1-7: "first", ...)

const PREFIX := "keen1."
const HINT := "keen1.hint.%d"
const HINT_PROMPT := "keen1.hint.prompt"
const MISSING_PARTS := "keen1.ship.missing"
const RETURNS_TO_SHIP := "keen1.ending.ship"
const HOME_MESSAGE := "keen1.ending.home.%d"
const END_TEXT := "keen1.endtext"
const STORY := "keen1.story"


## Name -> English of every translatable text in [param files] (null or
## incomplete files give what can be read).
static func catalog(files: GameFiles) -> Dictionary[String, String]:
	var texts: Dictionary[String, String] = {}
	if files == null:
		return texts
	var hints := HintTexts.load_from(files)
	if hints != null:
		for level in HintTexts.HINT_LEVELS:
			texts[HINT % level] = GameTexts.joined(hints.for_level(level))
		texts[HINT_PROMPT] = HintTexts.PROMPT
	var ending := EndingTexts.load_from(files)
	if ending != null:
		texts[MISSING_PARTS] = GameTexts.joined(ending.missing_parts)
		texts[RETURNS_TO_SHIP] = GameTexts.joined(ending.returns_to_ship)
		for index in ending.home_messages.size():
			texts[HOME_MESSAGE % (index + 1)] = GameTexts.joined(ending.home_messages[index])
	if files.has_file(GameFiles.END_TEXT):
		texts[END_TEXT] = GameTexts.document_text(files.read(GameFiles.END_TEXT))
	if files.has_file(GameFiles.STORY_TEXT):
		texts[STORY] = GameTexts.document_text(files.read(GameFiles.STORY_TEXT))
	GameTexts.add_score_texts(texts, PREFIX, ScoreTexts.load_from(files))
	return texts


## The statue message of [param level] ([param english] as read) with the
## prompt under it, in the language in use.
static func hint(level: int, english: PackedStringArray) -> PackedStringArray:
	var lines := Lang.game_lines(HINT % level, english)
	lines.append_array(["", Lang.game(HINT_PROMPT, HintTexts.PROMPT)])
	return lines


## The message at home [param index] (0 for the first).
static func home_message(index: int, english: PackedStringArray) -> PackedStringArray:
	return Lang.game_lines(HOME_MESSAGE % (index + 1), english)
