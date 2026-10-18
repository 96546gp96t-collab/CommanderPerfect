class_name Keen3LevelPlay
extends RefCounted
## The course of a game of Keen 3 (milestone C6, as Keen 2's after B6): the
## world map and the levels, until the game is won or over.
##   map        Keen walks over map 80 ([Keen3MapSession]): the jump or pogo
##              button on an entrance starts its level; done levels show
##              their sign and open their blocked cells
##   exit       the level is done, the keycards are taken away (they only
##              count in their level, Choco), and Keen is back on the map
##              where he entered it, with the view as it was; when the level
##              was level 16, [signal won]
##   death      one life less and back on the map ([signal life_lost]);
##              without lives left, [signal game_over]
## Every level and the map start fresh from their file, so a level's items
## are back and Keen has no ankh. Only the logic is here, so that the tests
## can play it; [Keen3View] draws it.

## A level has started (again): [member session] and [member level] are new.
signal level_started(number: int)
## Keen is on the world map: [member map_session] and [member level] are new.
signal map_started
## Keen died and is back on the map with [param lives] lives left.
signal life_lost(lives: int)
## Keen died with no lives left.
signal game_over
## Level 16 is done: the game is won (the ending comes in milestone C7).
signal won

enum State { MAP, PLAYING, GAME_OVER, WON }

## Keen's sprite starts this far below the top of the cell with info 255
## (Choco).
const START_OFFSET := Vector2(0, 8)

var files: GameFiles
var properties: TileProperties
var progress: Keen3Progress
## What Keen carries: [member progress]'s inventory.
var inventory: Inventory
## The level or map on the screen.
var level_number := 0
## The level or map being played, changed by Keen (items, doors, signs).
var level: LevelData
## Keen in a level; null on the map.
var session: Keen3LevelSession
## Keen on the map; null in a level.
var map_session: Keen3MapSession
var state := State.MAP
## The size of the view in pixels, for the map's scrolling.
var view_size := Keen3MapScroll.ORIGINAL_VIEW


## Plays the game in [param game_files] with [param keen_inventory] (a new
## [Keen3Inventory] when none is given). Call [method start_map] (a new
## game) or [method start] (a level) next.
static func create(
	game_files: GameFiles, tile_properties: TileProperties, keen_inventory: Inventory = null
) -> Keen3LevelPlay:
	var play := Keen3LevelPlay.new()
	play.files = game_files
	play.properties = tile_properties
	play.new_game(Keen3Progress.new(keen_inventory))
	return play


## Starts over with [param game], or with a new game when none is given.
## Call [method start_map] next.
func new_game(game: Keen3Progress = null) -> void:
	progress = game if game != null else Keen3Progress.new()
	inventory = progress.inventory
	session = null
	map_session = null
	state = State.MAP


## Whether level [param number] is one that Keen can play (1-16).
static func is_playable(number: int) -> bool:
	return number >= Keen3Files.FIRST_LEVEL and number <= Keen3Files.LAST_LEVEL


## The cell where Keen starts in [param level_data], or the top left of its
## playable area if it has none. Level 9 has two starts; the original scans
## the level row by row and keeps the last one it finds (Choco), so the
## last one counts here too, not the first one that
## [method LevelData.find_info] gives.
static func start_cell(level_data: LevelData) -> Vector2i:
	var index := level_data.infos.rfind(LevelData.PLAYER_START_INFO)
	if index < 0:
		return level_data.playable_rect().position
	return Vector2i(index % level_data.width, index / level_data.width)


## Where Keen's sprite starts in [param level_data], in level pixels.
static func start_position(level_data: LevelData) -> Vector2:
	return Vector2(start_cell(level_data) * EgaGraphics.TILE_SIZE) + START_OFFSET


## Starts an attempt at level [param number]. Returns false (and says why)
## when it is no level or cannot be read.
func start(number: int) -> bool:
	if not is_playable(number):
		push_error("Keen 3 has no level %d." % number)
		return false
	var data := _read(number)
	if data == null:
		return false
	level_number = number
	level = data
	map_session = null
	session = Keen3LevelSession.started(level, properties, inventory, start_position(level))
	state = State.PLAYING
	level_started.emit(number)
	return true


## Puts Keen on the world map, where he entered the last level (at its start
## in a new game). Returns false (and says why) when it cannot be read.
func start_map() -> bool:
	var data := _read(Keen3Files.WORLD_MAP_LEVEL)
	if data == null:
		return false
	level_number = Keen3Files.WORLD_MAP_LEVEL
	level = data
	session = null
	map_session = Keen3MapSession.opened(level, properties, progress, view_size)
	state = State.MAP
	map_started.emit()
	return true


## Advances one tick with the buttons in [param input], and moves on when
## Keen enters a level or his attempt is over.
func step(input: KeenInput) -> void:
	if state == State.MAP and map_session != null:
		map_session.step(input)
		if map_session.outcome == MapSession.Outcome.ENTER_LEVEL:
			start(map_session.chosen_level)
	elif state == State.PLAYING and session != null:
		session.step(input)
		if session.outcome != LevelSession.Outcome.PLAYING:
			_on_level_over(session.outcome)


func _on_level_over(outcome: LevelSession.Outcome) -> void:
	# Keycards only count in the level they were found in (Choco).
	inventory.keycards.fill(false)
	if outcome == LevelSession.Outcome.DIED:
		if inventory.is_game_over():
			state = State.GAME_OVER
			game_over.emit()
		else:
			start_map()
			life_lost.emit(inventory.lives)
		return
	# Any other end counts as done (the original: anything but a death).
	progress.complete_level(level_number)
	if progress.is_won():
		state = State.WON
		won.emit()
	else:
		start_map()


## Map or level [param number] fresh from its file; null (and says why) when
## it cannot be read.
func _read(number: int) -> LevelData:
	var file_name := files.level_file(number)
	var data := LevelData.parse(files.read(file_name))
	if data == null:
		push_error("%s could not be read." % file_name)
	return data
