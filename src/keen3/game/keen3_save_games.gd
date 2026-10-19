class_name Keen3SaveGames
extends SaveGames
## Keen 3's saved games (milestone C8): nine slots, as Keen 1's and Keen 2's,
## in Keen 3's own folder ([constant DIRECTORY]) so that no game of another
## episode is offered. The file is the shared format of [SaveGames]; it
## holds [method Keen3Progress.to_dict], which adds the view's corner. A game
## read back is a [Keen3Progress].

const DIRECTORY := "user://keen3/saves"


## The saved games in [param path].
static func in_folder(path := DIRECTORY) -> Keen3SaveGames:
	var saves := Keen3SaveGames.new()
	saves.directory = path
	return saves


## The game in slot [param slot] as a [Keen3Progress], or null when there is
## none or it cannot be read.
func read(slot: int) -> GameProgress:
	var game := super.read(slot)
	if game == null:
		return null
	# SaveGames has checked the file; this adds what only Keen 3 saves.
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(_path(slot)))
	var saved: Variant = data.get("game") if data is Dictionary else null
	return Keen3Progress.from_game(game, saved if saved is Dictionary else {})
