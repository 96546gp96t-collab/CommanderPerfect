class_name MapSession
extends RefCounted
## Keen on the world map, advanced one fixed tick at a time like a
## [LevelSession]. Only the logic, so that the tests can walk the map;
## [LevelView] draws it.
##
## Keen walks around; the jump or pogo button uses what he stands on (see
## [MapInfo]):
##   level entrance  enters the level, unless it is done
##   teleporter      takes him to another teleporter ([MapTeleport])
##   ship            the view shows which parts are still missing
## Completed levels show a "done" sign, and the entrances that block the way
## let Keen through once their level is done.

## Emitted when a tile of the map changes, so that it can be redrawn.
signal tile_changed(cell: Vector2i, tile: int)
## Emitted when Keen uses his ship.
signal ship_used

enum Outcome { PLAYING, ENTER_LEVEL }

## The "done" sign for an entrance of one cell, and for one of 2x2 cells
## (top left, top right, bottom left, bottom right).
const DONE_TILE := 77
const BIG_DONE_TILES: PackedInt32Array = [78, 79, 80, 81]
## Where each teleporter leads: to the teleporter with this info value.
## Keen 1 keeps the destinations in its code; these are the places they
## point to (see docs/world-map.md).
const TELEPORTER_DESTINATIONS: Dictionary[int, int] = {38: 41, 41: 38, 46: 41}
## The teleporter in level 13 leads to the teleporter with this value, in a
## part of the map that cannot be reached on foot.
const SECRET_DESTINATION := 46

var level: LevelData
var properties: TileProperties
var collision: MapCollision
var progress: GameProgress
var keen: MapKeen
var outcome := Outcome.PLAYING
## The level Keen enters when the outcome is ENTER_LEVEL.
var chosen_level := 0
var _teleport: MapTeleport
var _action_was_held := false


## Starts Keen on [param map]: where he entered the last level, or at the
## start of the map in a new game.
static func create(
	map: LevelData, tile_properties: TileProperties, game: GameProgress
) -> MapSession:
	var session := MapSession.new()
	session.level = map
	session.properties = tile_properties
	session.progress = game
	session.collision = MapCollision.create_for_map(map, tile_properties, game)
	var start := game.map_position
	if not start.is_finite():
		start = Vector2(map.find_info(LevelData.PLAYER_START_INFO) * EgaGraphics.TILE_SIZE)
	session.keen = MapKeen.create(session.collision, start)
	for number in game.completed_levels():
		session._mark_done(number)
	return session


## Advances one tick with the buttons in [param input].
func step(input: KeenInput) -> void:
	if outcome != Outcome.PLAYING:
		return
	var action := input.jump or input.pogo
	if _teleport != null:
		_teleport.step(self)
		if _teleport.is_done():
			_teleport = null
	else:
		keen.step(input)
		if action and not _action_was_held:
			_use(level.info_at(cell_under_keen()))
	_action_was_held = action


## The cell Keen stands on: the one under the middle of his sprite.
func cell_under_keen() -> Vector2i:
	return Vector2i((keen.center() / EgaGraphics.TILE_SIZE).floor())


## Whether a teleporter is moving Keen.
func is_teleporting() -> bool:
	return _teleport != null


## Keen used the teleporter in level 13: he comes out at the secret place.
func teleport_to_secret_place() -> void:
	var destination := level.find_info(SECRET_DESTINATION)
	if destination.x >= 0:
		_teleport = MapTeleport.create(self, cell_under_keen(), destination)


## Where Keen stands next to his ship at the start of the ending: right of
## it, looking at it.
func place_next_to_ship() -> void:
	var ship := level.find_info(MapInfo.SHIP)
	while MapInfo.is_ship(level.info_at(ship + Vector2i.RIGHT)):
		ship += Vector2i.RIGHT
	keen.position = Vector2((ship + Vector2i.RIGHT) * EgaGraphics.TILE_SIZE)
	keen.facing = Vector2i.LEFT


## Changes a tile of the map and lets the view know.
func set_tile(cell: Vector2i, tile: int) -> void:
	level.set_tile(cell, tile)
	tile_changed.emit(cell, tile)


func _use(info: int) -> void:
	var number := MapInfo.level_of(info)
	if number != 0:
		if not progress.is_completed(number):
			progress.map_position = keen.position
			chosen_level = number
			outcome = Outcome.ENTER_LEVEL
	elif MapInfo.is_ship(info):
		ship_used.emit()
	elif TELEPORTER_DESTINATIONS.has(info):
		var destination := level.find_info(TELEPORTER_DESTINATIONS[info])
		if destination.x >= 0:
			_teleport = MapTeleport.create(self, cell_under_keen(), destination)


## Puts the "done" sign on the entrance of level [param number].
func _mark_done(number: int) -> void:
	var cells: Array[Vector2i] = []
	for index in level.infos.size():
		if MapInfo.level_of(level.infos[index]) == number:
			cells.append(Vector2i(index % level.width, index / level.width))
	if cells.size() != BIG_DONE_TILES.size():
		for cell in cells:
			set_tile(cell, DONE_TILE)
		return
	# The cells are in row order: top left, top right, bottom left, bottom right.
	for corner in cells.size():
		set_tile(cells[corner], BIG_DONE_TILES[corner])
