class_name Keen3LevelPlay
extends RefCounted
## Keen 3's levels, one after the other ([Keen3LevelSession]). This is the
## temporary course of the game of milestone C3, as Keen 2 had in B3, until
## the world map (C6) and the menus (C8) come:
##   exit       on to the next level; after the last one the game is over
##              ([signal finished]). The keycards are taken away.
##   death      one life less and the same level again; without lives left,
##              [signal game_over]
## Every level starts fresh from its file, so that its items are back, and
## with a new Keen, so without the ankh. Only the logic is here, so that the
## tests can play it; [Keen3View] draws it.

## A level has started (again): [member session] and [member level] are new.
signal level_started(number: int)
## Keen died and has started the level again with [param lives] lives left.
signal life_lost(lives: int)
## Keen died with no lives left.
signal game_over
## Keen walked out of the last level, or the next level could not be read.
signal finished

enum State { PLAYING, GAME_OVER, FINISHED }

## Keen's sprite starts this far below the top of the cell with info 255
## (Choco).
const START_OFFSET := Vector2(0, 8)

var files: GameFiles
var properties: TileProperties
var inventory: Inventory
var level_number := 0
## The level being played, changed by Keen (items, doors).
var level: LevelData
var session: Keen3LevelSession
var state := State.PLAYING


## Plays the levels in [param game_files] with [param keen_inventory] (a
## new [Keen3Inventory] when none is given). Call [method start] next.
static func create(
	game_files: GameFiles, tile_properties: TileProperties, keen_inventory: Inventory = null
) -> Keen3LevelPlay:
	var play := Keen3LevelPlay.new()
	play.files = game_files
	play.properties = tile_properties
	play.inventory = keen_inventory if keen_inventory != null else Keen3Inventory.new()
	return play


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
	var file_name := files.level_file(number)
	var data := LevelData.parse(files.read(file_name))
	if data == null:
		push_error("%s could not be read." % file_name)
		return false
	level_number = number
	level = data
	session = Keen3LevelSession.started(level, properties, inventory, start_position(level))
	state = State.PLAYING
	level_started.emit(number)
	return true


## Advances one tick with the buttons in [param input], and moves on when
## the attempt is over.
func step(input: KeenInput) -> void:
	if state != State.PLAYING or session == null:
		return
	session.step(input)
	if session.outcome != LevelSession.Outcome.PLAYING:
		_on_level_over(session.outcome)


func _on_level_over(outcome: LevelSession.Outcome) -> void:
	match outcome:
		LevelSession.Outcome.COMPLETED:
			# Keycards only count in the level they were found in (Choco).
			inventory.keycards.fill(false)
			if level_number >= Keen3Files.LAST_LEVEL or not start(level_number + 1):
				state = State.FINISHED
				finished.emit()
		LevelSession.Outcome.DIED:
			if inventory.is_game_over():
				state = State.GAME_OVER
				game_over.emit()
			else:
				# First the level, then "Keens Left" over it.
				start(level_number)
				life_lost.emit(inventory.lives)
		_:
			# Keen 3 has no teleporters in levels and no open sides: this
			# cannot happen, but Keen should not get stuck if it does.
			start(level_number)
