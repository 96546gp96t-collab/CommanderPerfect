class_name Keen2LevelPlay
extends RefCounted
## Keen 2's levels, one after the other ([Keen2LevelSession]). This is the
## temporary course of the game of milestone B3, until the world map (B6)
## and the menus (B7) come:
##   exit       on to the next level; after the last one the game is over
##              ([signal finished])
##   death      one life less and the same level again; without lives left,
##              [signal game_over]
##   Tantalus   the switch of an intact machine fires the Tantalus Ray:
##              [signal earth_exploded], game over whatever the lives
## Every level starts fresh from its file, so that its items are back. Only
## the logic is here, so that the tests can play it; [Keen2View] draws it.

## A level has started (again): [member session] and [member level] are new.
signal level_started(number: int)
## Keen died and starts the level again with [param lives] lives left.
signal life_lost(lives: int)
## Keen died with no lives left.
signal game_over
## Keen walked out of the last level, or the next level could not be read.
signal finished
## The Tantalus Ray fired: the Earth explodes and the game is over.
signal earth_exploded

enum State { PLAYING, GAME_OVER, FINISHED, EARTH_EXPLODED }

const LEVEL_OPTION := GameLaunch.LEVEL_OPTION
## The level whose Vorticon Elder has the first of the two messages; every
## other Elder has the second. Only levels 8 and 10 have an Elder (tile 559
## with its light below), as in Commander Genius's game code. estimate:
## that level 8 has the first message ("never jumps in the dark").
const FIRST_ELDER_MESSAGE_LEVEL := 8  # estimate

var files: GameFiles
var properties: TileProperties
var inventory: Inventory
var level_number := 0
## The level being played, changed by Keen (items, doors).
var level: LevelData
var session: Keen2LevelSession
var state := State.PLAYING


## Plays the levels in [param game_files] with [param keen_inventory] (a
## new [Keen2Inventory] when none is given). Call [method start] next.
static func create(
	game_files: GameFiles, tile_properties: TileProperties, keen_inventory: Inventory = null
) -> Keen2LevelPlay:
	var play := Keen2LevelPlay.new()
	play.files = game_files
	play.properties = tile_properties
	play.inventory = keen_inventory if keen_inventory != null else Keen2Inventory.new()
	return play


## Whether level [param number] is one that is played in this milestone.
static func is_playable(number: int) -> bool:
	return number >= Keen2Files.FIRST_LEVEL and number <= Keen2Files.LAST_LEVEL


## The level asked for with --level=N in [param arguments], or 0.
static func requested_level(arguments: PackedStringArray) -> int:
	for argument in arguments:
		var value := argument.trim_prefix(LEVEL_OPTION)
		if argument.begins_with(LEVEL_OPTION) and value.is_valid_int():
			return value.to_int()
	return 0


## The cell where Keen starts in [param level_data], or the top left of
## its playable area if it has none.
static func start_cell(level_data: LevelData) -> Vector2i:
	var cell := level_data.find_info(LevelData.PLAYER_START_INFO)
	return cell if cell.x >= 0 else level_data.playable_rect().position


## Which of the two Elder messages (0 or 1) the Elder in level
## [param number] has.
static func elder_message_index(number: int) -> int:
	return 0 if number == FIRST_ELDER_MESSAGE_LEVEL else 1


## Starts an attempt at level [param number]. Returns false (and says why)
## when it is not played yet or cannot be read.
func start(number: int) -> bool:
	if not is_playable(number):
		push_error("Keen 2 level %d is not played yet." % number)
		return false
	var file_name := files.level_file(number)
	var data := LevelData.parse(files.read(file_name))
	if data == null:
		push_error("%s could not be read." % file_name)
		return false
	level_number = number
	level = data
	var start_at := Vector2(start_cell(level) * EgaGraphics.TILE_SIZE)
	session = Keen2LevelSession.begin(level, properties, inventory, start_at)
	state = State.PLAYING
	level_started.emit(number)
	return true


## Advances one tick with the buttons in [param input], and moves on when
## the attempt is over.
func step(input: KeenInput) -> void:
	if state != State.PLAYING or session == null:
		return
	session.step(input)
	if session.tantalus_fired:
		state = State.EARTH_EXPLODED
		earth_exploded.emit()
	elif session.outcome != LevelSession.Outcome.PLAYING:
		_on_level_over(session.outcome)


func _on_level_over(outcome: LevelSession.Outcome) -> void:
	match outcome:
		LevelSession.Outcome.COMPLETED:
			if level_number >= Keen2Files.LAST_LEVEL or not start(level_number + 1):
				state = State.FINISHED
				finished.emit()
		LevelSession.Outcome.DIED:
			if inventory.is_game_over():
				state = State.GAME_OVER
				game_over.emit()
			else:
				life_lost.emit(inventory.lives)
				start(level_number)
		_:
			# Keen 2 has no teleporters and no open sides: this cannot
			# happen, but Keen should not get stuck if it does.
			start(level_number)
