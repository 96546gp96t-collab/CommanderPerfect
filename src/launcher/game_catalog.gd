class_name GameCatalog
extends RefCounted
## The games the start screen offers, one icon each: Keen 1, then Keen 2.
## Later games are added here.


## One game: its name on the icon, the scene that plays it, and the
## player's own files for it (null when they were not found).
class Game:
	extends RefCounted
	var title := ""
	var scene := ""
	var files: GameFiles
	## Where the player puts the files, named when they are missing.
	var data_folder := GameFiles.DEFAULT_SUBFOLDER

	func is_available() -> bool:
		return files != null


## Every game, in the order of the icons (from left to right).
static func games() -> Array[Game]:
	var keen_1 := Game.new()
	keen_1.title = "Keen 1"
	keen_1.scene = GameLaunch.KEEN_1_SCENE
	keen_1.files = GameFiles.locate()
	var keen_2 := Game.new()
	keen_2.title = "Keen 2"
	keen_2.scene = GameLaunch.KEEN_2_SCENE
	keen_2.files = Keen2Files.locate()
	keen_2.data_folder = Keen2Files.SUBFOLDER
	return [keen_1, keen_2]
