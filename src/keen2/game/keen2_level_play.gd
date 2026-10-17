class_name Keen2LevelPlay
extends RefCounted
## The course of a game of Keen 2 (milestone B6): the world map and the
## levels, until the game is won or over.
##   map        Keen walks over map 80 ([MapSession], as for Keen 1): the jump
##              or pogo button on an entrance starts its level; done levels
##              show their sign and cannot be entered again; entrances with
##              0x8000 block the way until their level is done
##   exit       the level is done (a city is saved when it is one of
##              [constant Keen2Progress.CITY_LEVELS]) and Keen is back on the
##              map where he entered it; with all eight cities saved,
##              [signal won] (the ending)
##   death      one life less and back on the map ([signal life_lost]);
##              without lives left, [signal game_over]
##   Tantalus   the switch of an intact machine fires the Tantalus Ray:
##              [signal earth_exploded], game over whatever the lives
## Every level and the map start fresh from their file. Only the logic is
## here, so that the tests can play it; [Keen2View] draws it.

## A level has started (again): [member session] and [member level] are new.
signal level_started(number: int)
## Keen is on the world map: [member map_session] and [member level] are new.
signal map_started
## Keen died and is back on the map with [param lives] lives left.
signal life_lost(lives: int)
## Keen died with no lives left.
signal game_over
## All eight cities are saved: the ending starts.
signal won
## The Tantalus Ray fired: the Earth explodes and the game is over.
signal earth_exploded

enum State { MAP, PLAYING, GAME_OVER, WON, EARTH_EXPLODED }

const LEVEL_OPTION := GameLaunch.LEVEL_OPTION
## The level whose Vorticon Elder has the first of the two messages; every
## other Elder has the second. Only levels 8 and 10 have an Elder (tile 559
## with its light below), as in Commander Genius's game code. estimate:
## that level 8 has the first message ("never jumps in the dark").
const FIRST_ELDER_MESSAGE_LEVEL := 8  # estimate

var files: GameFiles
var properties: TileProperties
var progress: Keen2Progress
## What Keen carries: [member progress]'s inventory.
var inventory: Inventory
## The level or map on the screen.
var level_number := 0
## The level or map being played, changed by Keen (items, doors, signs).
var level: LevelData
## Keen in a level; null on the map.
var session: Keen2LevelSession
## Keen on the map; null in a level.
var map_session: MapSession
var state := State.MAP


## Plays the game in [param game_files] with [param keen_inventory] (a new
## [Keen2Inventory] when none is given). Call [method start_map] (a new
## game) or [method start] (a level) next.
static func create(
	game_files: GameFiles, tile_properties: TileProperties, keen_inventory: Inventory = null
) -> Keen2LevelPlay:
	var play := Keen2LevelPlay.new()
	play.files = game_files
	play.properties = tile_properties
	play.progress = Keen2Progress.new(keen_inventory)
	play.inventory = play.progress.inventory
	return play


## Whether level [param number] is one that Keen can play (1-16).
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
## when it is no level or cannot be read.
func start(number: int) -> bool:
	if not is_playable(number):
		push_error("Keen 2 has no level %d." % number)
		return false
	var data := _read(number)
	if data == null:
		return false
	level_number = number
	level = data
	map_session = null
	var start_at := Vector2(start_cell(level) * EgaGraphics.TILE_SIZE)
	session = Keen2LevelSession.begin(level, properties, inventory, start_at)
	state = State.PLAYING
	level_started.emit(number)
	return true


## Puts Keen on the world map, where he entered the last level (at its start
## in a new game). Returns false (and says why) when it cannot be read. With
## every city saved, the game is won at once.
func start_map() -> bool:
	var data := _read(Keen2Files.WORLD_MAP_LEVEL)
	if data == null:
		return false
	level_number = Keen2Files.WORLD_MAP_LEVEL
	level = data
	session = null
	map_session = MapSession.create(level, properties, progress)
	state = State.MAP
	map_started.emit()
	if progress.all_cities_saved():
		state = State.WON
		won.emit()
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
		if session.tantalus_fired:
			state = State.EARTH_EXPLODED
			earth_exploded.emit()
		elif session.outcome != LevelSession.Outcome.PLAYING:
			_on_level_over(session.outcome)


func _on_level_over(outcome: LevelSession.Outcome) -> void:
	match outcome:
		LevelSession.Outcome.COMPLETED:
			progress.complete_level(level_number)
			start_map()
		LevelSession.Outcome.DIED:
			if inventory.is_game_over():
				state = State.GAME_OVER
				game_over.emit()
			else:
				start_map()
				life_lost.emit(inventory.lives)
		_:
			# Keen 2 has no teleporters and no open sides: this cannot
			# happen, but Keen should not get stuck if it does.
			start_map()


## Map or level [param number] fresh from its file; null (and says why) when
## it cannot be read.
func _read(number: int) -> LevelData:
	var file_name := files.level_file(number)
	var data := LevelData.parse(files.read(file_name))
	if data == null:
		push_error("%s could not be read." % file_name)
	return data
