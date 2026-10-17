class_name Keen2GameData
extends RefCounted
## What Keen 2's game screen reads from the player's files before it can
## show a level: the graphics (EGAHEAD.CK2 and the others), the tile
## properties, the sounds, the Vorticon Elders' messages, the city names, the
## status screen's box and the texts of the ending from KEEN2.EXE, and
## FINALE.CK2.
##
## Keen 2 keeps its sounds inside KEEN2.EXE. When that has no sound block
## and a SOUNDS.CK2 file lies next to it, that file is used instead: the
## real game has no such file, but the Keen 1 files under Keen 2 names (the
## stand-in data of the tests) do.

## Not part of Keen 2; see above.
const SOUNDS_FILE := "SOUNDS.CK2"

var files: GameFiles
var graphics: EgaGraphics
var properties: TileProperties
## The PC speaker sounds; null when there are none (the game is silent then).
var sounds: SoundFile
## The picture of FINALE.CK2; null when it is missing.
var finale: Image
## The two Elder messages as lines; a message that was not found is empty.
var elder_messages: Array[PackedStringArray] = []
## The eight city names in the order of [constant Keen2Progress.CITY_LEVELS];
## empty when they were not found.
var city_names := PackedStringArray()
## The lines of the status screen's box; empty when not found.
var status_lines := PackedStringArray()
## The texts of the ending, in the order of [enum Keen2Executable.EndingText];
## a text that was not found is empty.
var ending_texts: Array[PackedStringArray] = []
## The end text block, ready for [method TextDocument.layout]; empty when
## not found.
var end_text := PackedByteArray()
## The story block for the menu, the same way; empty when not found.
var story := PackedByteArray()
## The names of a new high score table and the words for the places
## ("first"...), as in Keen 1's executable; null when not found.
var score_texts: ScoreTexts


## Reads everything from [param game_files]. Returns null (and says why)
## when the graphics or the tile properties cannot be read.
static func load_from(game_files: GameFiles) -> Keen2GameData:
	var data := Keen2GameData.new()
	data.files = game_files
	data.graphics = EgaGraphics.load_from(game_files, Keen2Files.EXTENSION)
	if data.graphics == null:
		push_error("The Keen 2 graphics in %s could not be read." % game_files.directory)
		return null
	var executable := Keen2Executable.load_from(game_files)
	if executable == null:
		push_error("%s could not be read." % Keen2Files.EXECUTABLE)
		return null
	data.properties = executable.tile_properties(data.graphics.tiles.size())
	if data.properties == null:
		return null
	data.sounds = _sounds_from(executable, game_files)
	for index in Keen2Executable.ELDER_MESSAGE_OFFSETS.size():
		data.elder_messages.append(executable.elder_message(index))
	_read_texts(data, executable)
	if game_files.has_file(Keen2Files.FINALE):
		data.finale = FinaleImage.load_from(game_files, Keen2Files.FINALE)
	return data


## The city names, the status screen and the ending. Missing texts are no
## error: the screens that use them do without.
static func _read_texts(data: Keen2GameData, executable: Keen2Executable) -> void:
	if Keen2Executable.find_city_names(executable.image) >= 0:
		data.city_names = executable.city_names()
	data.status_lines = executable.status_box_lines()
	for which in Keen2Executable.EndingText.size():
		data.ending_texts.append(executable.ending_text(which as Keen2Executable.EndingText))
	var end := Keen2Executable.TextBlock.END_TEXT
	if Keen2Executable.find_text_block(executable.image, end) >= 0:
		data.end_text = executable.text(end)
	var story := Keen2Executable.TextBlock.STORY
	if Keen2Executable.find_text_block(executable.image, story) >= 0:
		data.story = executable.text(story)
	data.score_texts = ScoreTexts.find_in_image(executable.image)


## The sounds inside [param executable], or those of [constant SOUNDS_FILE];
## null when neither has them.
static func _sounds_from(executable: Keen2Executable, game_files: GameFiles) -> SoundFile:
	if Keen2Executable.find_sound_block(executable.image) >= 0:
		return executable.sounds()
	if game_files.has_file(SOUNDS_FILE):
		return SoundFile.parse(game_files.read(SOUNDS_FILE))
	return null
