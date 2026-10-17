class_name Keen2GameData
extends RefCounted
## What Keen 2's game screen reads from the player's files before it can
## show a level: the graphics (EGAHEAD.CK2 and the others), the tile
## properties, the sounds and the Vorticon Elders' messages from KEEN2.EXE,
## and FINALE.CK2 for the scaled graphics.
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
	if game_files.has_file(Keen2Files.FINALE):
		data.finale = FinaleImage.load_from(game_files, Keen2Files.FINALE)
	return data


## The sounds inside [param executable], or those of [constant SOUNDS_FILE];
## null when neither has them.
static func _sounds_from(executable: Keen2Executable, game_files: GameFiles) -> SoundFile:
	if Keen2Executable.find_sound_block(executable.image) >= 0:
		return executable.sounds()
	if game_files.has_file(SOUNDS_FILE):
		return SoundFile.parse(game_files.read(SOUNDS_FILE))
	return null
