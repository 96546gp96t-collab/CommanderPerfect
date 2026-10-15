class_name GameCatalog
extends RefCounted
## The games the start screen offers, one icon each. For now only Keen 1;
## later games are added here.


## One game: its name on the icon, the scene that plays it, and the
## player's own files for it (null when they were not found).
class Game:
	extends RefCounted
	var title := ""
	var scene := ""
	var files: GameFiles

	func is_available() -> bool:
		return files != null


## Every game, in the order of the icons (from left to right).
static func games() -> Array[Game]:
	var keen_1 := Game.new()
	keen_1.title = "Keen 1"
	keen_1.scene = GameLaunch.KEEN_1_SCENE
	keen_1.files = GameFiles.locate()
	return [keen_1]
