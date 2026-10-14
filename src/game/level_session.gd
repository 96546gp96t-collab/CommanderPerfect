class_name LevelSession
extends RefCounted
## One attempt at a level: Keen, the other [Actor]s and the items, advanced
## one fixed tick at a time (see [KeenPhysics]). This is only the logic, so
## that the tests can play a level; [LevelView] draws it.
##
## What Keen touches:
##   items    picked up: the tile is replaced by the background
##   doors    open when Keen has the keycard of their color, which is used up
##   exit     completes the level
## The attempt ends when Keen reaches the exit or when he has died (after
## the dying animation, or at once when he falls out of the level).

## Emitted when a tile of the level changes, so that it can be redrawn.
signal tile_changed(cell: Vector2i, tile: int)

enum Outcome { PLAYING, COMPLETED, DIED }

## Picked-up items and opened doors leave the gray background behind. Tiles
## from [constant HIGH_TILES_START] on leave a different background (no level
## of Keen 1 has items there, but the game supports it).
const BACKGROUND_TILE := 143
const HIGH_TILES_START := 305
const HIGH_BACKGROUND_TILE := 276
const POINTS: Dictionary[int, int] = {
	TileProperties.Behavior.POINTS_100: 100,
	TileProperties.Behavior.POINTS_200: 200,
	TileProperties.Behavior.POINTS_500: 500,
	TileProperties.Behavior.POINTS_1000: 1000,
	TileProperties.Behavior.POINTS_5000: 5000,
}
## Doors are solid, so Keen touches one when he stands this close to it.
const DOOR_REACH := 1.0

var level: LevelData
var properties: TileProperties
var collision: LevelCollision
var inventory: Inventory
var keen: KeenBody
var actors: Array[Actor] = []
var outcome := Outcome.PLAYING


## Starts an attempt at [param level_data] with Keen's sprite at [param start].
static func create(
	level_data: LevelData,
	tile_properties: TileProperties,
	keen_inventory: Inventory,
	start: Vector2,
) -> LevelSession:
	var session := LevelSession.new()
	session.level = level_data
	session.properties = tile_properties
	session.collision = LevelCollision.create(level_data, tile_properties)
	session.inventory = keen_inventory
	session.keen = KeenBody.create(session.collision, start)
	keen_inventory.enter_level()
	return session


## Advances one tick with the buttons in [param input].
func step(input: KeenInput) -> void:
	if outcome != Outcome.PLAYING:
		return
	keen.has_pogo = inventory.has_pogo
	keen.step(input)
	if keen.fired:
		_fire()
	if not keen.is_dead:
		_touch_tiles(keen.hitbox())
	# Actors can add new actors while they step; those start next tick.
	for actor in actors.duplicate():
		actor.step(self)
	actors = actors.filter(func(actor: Actor) -> bool: return not actor.removed)
	if keen.death_finished and outcome == Outcome.PLAYING:
		inventory.lose_life()
		outcome = Outcome.DIED


func add_actor(actor: Actor) -> void:
	actors.append(actor)


func _fire() -> void:
	if inventory.charges <= 0:
		return
	inventory.charges -= 1
	add_actor(RaygunShot.create(keen.shot_position(), keen.facing))


func _touch_tiles(box: Rect2) -> void:
	for cell in LevelCollision.cells_under(box):
		var tile := collision.tile_at(cell)
		if properties.is_item(tile):
			_pick_up(cell, tile)
		elif properties.is_exit(tile):
			outcome = Outcome.COMPLETED
	for cell in LevelCollision.cells_under(box.grow_individual(DOOR_REACH, 0, DOOR_REACH, 0)):
		var tile := collision.tile_at(cell)
		if properties.is_door(tile) and inventory.has_keycard(properties.door_color(tile)):
			_open_door(cell)


func _pick_up(cell: Vector2i, tile: int) -> void:
	_set_tile(cell, HIGH_BACKGROUND_TILE if tile >= HIGH_TILES_START else BACKGROUND_TILE)
	var behavior := properties.behavior(tile)
	var first_part := TileProperties.Behavior.SHIP_JOYSTICK
	var first_card := TileProperties.Behavior.KEYCARD_YELLOW
	if behavior == TileProperties.Behavior.RAYGUN:
		inventory.charges += Inventory.RAYGUN_CHARGES
	elif behavior == TileProperties.Behavior.POGO:
		inventory.has_pogo = true
	elif behavior >= first_part and behavior <= TileProperties.Behavior.SHIP_WHISKEY:
		inventory.add_ship_part((behavior - first_part) as Inventory.ShipPart)
	elif behavior >= first_card and behavior <= TileProperties.Behavior.KEYCARD_BLUE:
		inventory.keycards[behavior - first_card] = true
	else:
		inventory.add_points(POINTS.get(behavior, 0))


## Opens the whole door that [param cell] is part of: the column of door
## tiles of the same color above and below it.
func _open_door(cell: Vector2i) -> void:
	var color := properties.door_color(level.tile_at(cell))
	var top := cell
	while _is_door_of_color(top + Vector2i.UP, color):
		top += Vector2i.UP
	var door_tiles := PackedInt32Array()
	var current := top
	while _is_door_of_color(current, color):
		door_tiles.append(level.tile_at(current))
		_set_tile(current, BACKGROUND_TILE)
		current += Vector2i.DOWN
	inventory.keycards[color] = false
	add_actor(OpeningDoor.create(top, door_tiles))


func _is_door_of_color(cell: Vector2i, color: TileProperties.KeyColor) -> bool:
	var tile := collision.tile_at(cell)
	return properties.is_door(tile) and properties.door_color(tile) == color


func _set_tile(cell: Vector2i, tile: int) -> void:
	level.set_tile(cell, tile)
	tile_changed.emit(cell, tile)
