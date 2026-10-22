class_name GameCatalog
extends RefCounted
## The games the start screen offers, one icon each: Keen 1, then Keen 2,
## then Keen 3, then Keen 4, then Keen 5. Later games are added here.


## One game: its name on the icon, the scene that plays it, and the
## player's own files for it (null when they were not found).
class Game:
	extends RefCounted
	var title := ""
	var scene := ""
	var files: GameFiles
	## Where the player puts the files, named when they are missing.
	var data_folder := GameFiles.DEFAULT_SUBFOLDER
	## The game's id online ([constant OnlineProtocol.GAME_ID] for Keen 1).
	var game_id := OnlineProtocol.GAME_ID
	## Makes the picture on the icon (a [Texture2D], or null) for a game
	## whose graphics the shared Keen 1-3 code cannot read. Not set: Keen
	## from the game's own sprites, as for Keen 1-3.
	var icon_picture := Callable()
	## Makes the game's name in its own font for the icon (a [Texture2D],
	## or null), used with [member icon_picture]. Not set: the name in the
	## shared font.
	var icon_title := Callable()

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
	keen_2.game_id = OnlineProtocol.GAME_ID_KEEN_2
	var keen_3 := Game.new()
	keen_3.title = "Keen 3"
	keen_3.scene = GameLaunch.KEEN_3_SCENE
	keen_3.files = Keen3Files.locate()
	keen_3.data_folder = Keen3Files.SUBFOLDER
	keen_3.game_id = OnlineProtocol.GAME_ID_KEEN_3
	var keen_4 := Game.new()
	keen_4.title = "Keen 4"
	keen_4.scene = GameLaunch.KEEN_4_SCENE
	keen_4.files = Keen4Files.locate()
	keen_4.data_folder = Keen4Files.SUBFOLDER
	keen_4.game_id = Keen4Files.GAME_ID
	keen_4.icon_picture = Keen4Icon.picture.bind(keen_4.files)
	keen_4.icon_title = Keen4Icon.title.bind(keen_4.files, keen_4.title)
	return [keen_1, keen_2, keen_3, keen_4, _keen_5()]


## Keen 5: its own picture and font on the icon, as Keen 4. Its online id
## is not yet in [constant OnlineProtocol.GAME_IDS] (milestone E11).
static func _keen_5() -> Game:
	var keen_5 := Game.new()
	keen_5.title = "Keen 5"
	keen_5.scene = GameLaunch.KEEN_5_SCENE
	keen_5.files = Keen5Files.locate()
	keen_5.data_folder = Keen5Files.SUBFOLDER
	keen_5.game_id = Keen5Files.GAME_ID
	keen_5.icon_picture = Keen5Icon.picture.bind(keen_5.files)
	keen_5.icon_title = Keen5Icon.title.bind(keen_5.files, keen_5.title)
	return keen_5


## The game with online id [param game_id], or null.
static func for_game_id(game_id: String) -> Game:
	for game in games():
		if game.game_id == game_id:
			return game
	return null
