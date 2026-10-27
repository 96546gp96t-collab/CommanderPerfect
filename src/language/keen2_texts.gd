class_name Keen2Texts
extends RefCounted
## The names of Keen 2's translatable texts (all from KEEN2.EXE) and their
## English as read from the player's files ([method catalog]). The places
## that show a text ask [Lang] for it by the name given here:
##   keen2.elder.<n>          the two Vorticon Elders' messages (1-2)
##   keen2.elder.prompt       "Press ENTER:" under a message that has none
##   keen2.city.<n>           the eight cities on the status screen, in the
##                            order of their levels (1-8); a name in the
##                            left column ends before the right one starts
##   keen2.status             the status screen's box: 12 lines of 28
##                            characters, the numbers stand at fixed places
##   keen2.ending.<text>      the texts of the ending ([enum
##                            Keen2Executable.EndingText] in lower case:
##                            ship_home, mothership, home_1 ... home_4,
##                            to_be_continued)
##   keen2.endtext            the end text, a document
##   keen2.story              the story, a document
##   keen2.scores.name.<n>    the names of a new high score table
##   keen2.scores.place.<n>   the words for the places ("first", ...)

const PREFIX := "keen2."
const ELDER := "keen2.elder.%d"
const ELDER_PROMPT := "keen2.elder.prompt"
const CITY := "keen2.city.%d"
const STATUS := "keen2.status"
const ENDING := "keen2.ending.%s"
const END_TEXT := "keen2.endtext"
const STORY := "keen2.story"


## Name -> English of every translatable text in [param files] (null or
## incomplete files give what can be read).
static func catalog(files: GameFiles) -> Dictionary[String, String]:
	var texts: Dictionary[String, String] = {}
	if files == null:
		return texts
	var executable := Keen2Executable.load_from(files)
	if executable == null:
		return texts
	var image := executable.image
	for index in Keen2Executable.ELDER_MESSAGE_OFFSETS.size():
		var message := executable.elder_message(index)
		if not message.is_empty():
			texts[ELDER % (index + 1)] = GameTexts.joined(message)
	texts[ELDER_PROMPT] = Keen2View.ELDER_PROMPT
	if Keen2Executable.find_city_names(image) >= 0:
		var cities := executable.city_names()
		for index in cities.size():
			texts[CITY % (index + 1)] = cities[index]
	var status := executable.status_box_lines()
	if not status.is_empty():
		texts[STATUS] = GameTexts.joined(status)
	for which in Keen2Executable.EndingText.size():
		var lines := executable.ending_text(which as Keen2Executable.EndingText)
		if not lines.is_empty():
			texts[ending_name(which)] = GameTexts.joined(lines)
	var blocks := {
		END_TEXT: Keen2Executable.TextBlock.END_TEXT, STORY: Keen2Executable.TextBlock.STORY
	}
	for id: String in blocks:
		if Keen2Executable.find_text_block(image, blocks[id]) >= 0:
			texts[id] = GameTexts.document_text(executable.text(blocks[id]))
	GameTexts.add_score_texts(texts, PREFIX, ScoreTexts.find_in_image(image))
	return texts


## The name of ending text [param which] ([enum Keen2Executable.EndingText]).
static func ending_name(which: int) -> String:
	return ENDING % String(Keen2Executable.EndingText.keys()[which]).to_lower()


## The names of the eight cities in the language in use.
static func city_names(english: PackedStringArray) -> PackedStringArray:
	var names := PackedStringArray()
	for index in english.size():
		names.append(Lang.game(CITY % (index + 1), english[index]))
	return names
