class_name Keen3GameData
extends RefCounted
## What Keen 3 reads from the player's files before it can show anything:
## the graphics (EGAHEAD.CK3 and the others), the tile properties, the
## sounds and the texts from KEEN3.EXE (the four text blocks, the status
## screen's box, Mortimer's messages, the pages of the ending, the box over
## the finale picture, the ship's messages and the high score texts), and
## FINALE.CK3.

var files: GameFiles
var graphics: EgaGraphics
var properties: TileProperties
## The PC speaker sounds; null when there are none (the game is silent then).
var sounds: SoundFile
## The picture of FINALE.CK3; null when it is missing.
var finale: Image
## The four text blocks, ready for [method TextDocument.layout]; a block
## that was not found is empty.
var help := PackedByteArray()
var end_text := PackedByteArray()
var previews := PackedByteArray()
var story := PackedByteArray()
## The lines of the status screen's box; empty when not found.
var status_lines := PackedStringArray()
## Mortimer's nine boxes in level 16; empty when not found.
var mortimer_messages: Array[PackedStringArray] = []
## The four pages of the ending; empty when not found.
var ending_pages: Array[PackedStringArray] = []
## The box over the finale picture; empty when not found.
var the_end := PackedStringArray()
## The ship's four messages on the world map; empty when not found.
var ship_messages: Array[PackedStringArray] = []
## The names of a new high score table and the words for the places; null
## when not found.
var score_texts: ScoreTexts


## Reads everything from [param game_files]. Returns null (and says why)
## when the graphics or the tile properties cannot be read.
static func load_from(game_files: GameFiles) -> Keen3GameData:
	var data := Keen3GameData.new()
	data.files = game_files
	data.graphics = EgaGraphics.load_from(game_files, Keen3Files.EXTENSION)
	if data.graphics == null:
		push_error("The Keen 3 graphics in %s could not be read." % game_files.directory)
		return null
	var executable := Keen3Executable.load_from(game_files)
	if executable == null:
		push_error("%s could not be read." % Keen3Files.EXECUTABLE)
		return null
	data.properties = executable.tile_properties(data.graphics.tiles.size())
	if data.properties == null:
		return null
	data.sounds = executable.sounds()
	_read_text_blocks(data, executable)
	_read_messages(data, executable)
	if game_files.has_file(Keen3Files.FINALE):
		data.finale = FinaleImage.load_from(game_files, Keen3Files.FINALE)
	return data


## The four text blocks. A missing block is no error: the screen that shows
## it does without.
static func _read_text_blocks(data: Keen3GameData, executable: Keen3Executable) -> void:
	data.help = _text_or_empty(executable, Keen3Executable.TextBlock.HELP)
	data.end_text = _text_or_empty(executable, Keen3Executable.TextBlock.END_TEXT)
	data.previews = _text_or_empty(executable, Keen3Executable.TextBlock.PREVIEWS)
	data.story = _text_or_empty(executable, Keen3Executable.TextBlock.STORY)


## The status box, Mortimer, the ending, the ship and the high scores.
static func _read_messages(data: Keen3GameData, executable: Keen3Executable) -> void:
	data.status_lines = executable.status_box_lines()
	data.mortimer_messages = executable.mortimer_messages()
	data.ending_pages = executable.ending_pages()
	data.the_end = executable.the_end()
	data.ship_messages = executable.ship_messages()
	data.score_texts = executable.score_texts()


static func _text_or_empty(
	executable: Keen3Executable, block: Keen3Executable.TextBlock
) -> PackedByteArray:
	if Keen3Executable.find_text_block(executable.image, block) < 0:
		return PackedByteArray()
	return executable.text(block)
