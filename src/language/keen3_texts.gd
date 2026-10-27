class_name Keen3Texts
extends RefCounted
## The names of Keen 3's translatable texts (all from KEEN3.EXE) and their
## English as read from the player's files ([method catalog]). The places
## that show a text ask [Lang] for it by the name given here:
##   keen3.status             the status screen's box: 11 lines, the full
##                            ones 28 characters wide, the labels drawn in
##                            the font's second half; the one-space lines
##                            are dividers and stay as they are
##   keen3.mortimer.<n>       Mortimer's nine boxes (1-9), typed letter by
##                            letter in boxes of a fixed size
##                            ([constant Keen3Mortimer.BOX_SIZES])
##   keen3.ending.<n>         the four pages of the ending (1-4), in fixed
##                            frames ([constant Keen3Ending.PAGE_FRAME_ENDS])
##   keen3.theend             the box over the finale picture
##   keen3.endtext            the end text, a document ([Keen3EndText])
##   keen3.endtext.footer     the footer of the end text's reader
##   keen3.ship.<n>           the ship's four messages on the map (1-4), in
##                            a window of 32x6
##   keen3.ship.prompt        the line under them
##   keen3.story              the story, a document
##   keen3.scores.name.<n>    the names of a new high score table
##   keen3.scores.place.<n>   the words for the places ("first", ...)

const PREFIX := "keen3."
const STATUS := "keen3.status"
const MORTIMER := "keen3.mortimer.%d"
const ENDING_PAGE := "keen3.ending.%d"
const THE_END := "keen3.theend"
const END_TEXT := "keen3.endtext"
const READER_FOOTER := "keen3.endtext.footer"
const SHIP := "keen3.ship.%d"
const SHIP_PROMPT := "keen3.ship.prompt"
const STORY := "keen3.story"


## Name -> English of every translatable text in [param files] (null or
## incomplete files give what can be read).
static func catalog(files: GameFiles) -> Dictionary[String, String]:
	var texts: Dictionary[String, String] = {}
	if files == null:
		return texts
	var executable := Keen3Executable.load_from(files)
	if executable == null:
		return texts
	var status := executable.status_box_lines()
	if not status.is_empty():
		texts[STATUS] = GameTexts.joined(status)
	_add_numbered(texts, MORTIMER, executable.mortimer_messages())
	_add_numbered(texts, ENDING_PAGE, executable.ending_pages())
	var the_end := executable.the_end()
	if not the_end.is_empty():
		texts[THE_END] = GameTexts.joined(the_end)
	var footer := executable.reader_footer()
	if not footer.is_empty():
		texts[READER_FOOTER] = footer
	_add_numbered(texts, SHIP, executable.ship_messages())
	var prompt := executable.ship_prompt()
	if not prompt.is_empty():
		texts[SHIP_PROMPT] = prompt
	var blocks := {
		END_TEXT: Keen3Executable.TextBlock.END_TEXT, STORY: Keen3Executable.TextBlock.STORY
	}
	for id: String in blocks:
		if Keen3Executable.find_text_block(executable.image, blocks[id]) >= 0:
			texts[id] = GameTexts.document_text(executable.text(blocks[id]))
	GameTexts.add_score_texts(texts, PREFIX, executable.score_texts())
	return texts


## Each of [param english] (as read) in the language in use, by the names
## [param pattern] % 1, 2, ...
static func numbered(
	pattern: String, english: Array[PackedStringArray]
) -> Array[PackedStringArray]:
	var translated: Array[PackedStringArray] = []
	for index in english.size():
		translated.append(Lang.game_lines(pattern % (index + 1), english[index]))
	return translated


static func _add_numbered(
	texts: Dictionary[String, String], pattern: String, messages: Array[PackedStringArray]
) -> void:
	for index in messages.size():
		texts[pattern % (index + 1)] = GameTexts.joined(messages[index])
