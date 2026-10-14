class_name LevelSession
extends RefCounted
## One attempt at a level: Keen, the other [Actor]s and the items, advanced
## one fixed tick at a time (see [KeenPhysics]). This is only the logic, so
## that the tests can play a level; [LevelView] draws it.
##
## What Keen touches:
##   items    picked up: the tile is replaced by the background
##   doors    open when Keen has the keycard of their color, which is used up
##   exit     Keen walks through the door; then the level is complete
##   statues  show a message once, then stop glowing
## Enemies start where the info layer of the level says (see
## [constant ENEMY_INFOS]); their shots, and Keen's, are actors too.
## The attempt ends when Keen reaches the exit or when he has died (after
## the dying animation, or at once when he falls out of the level).

## Emitted when a tile of the level changes, so that it can be redrawn.
signal tile_changed(cell: Vector2i, tile: int)
## Emitted when Keen touches a Yorp or Garg statue; the view shows its
## message. Each statue speaks only once.
signal hint_touched

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
## After its message, a statue becomes this tile: the same statue without
## its glow. Garg statues are tiles 435-438, Yorp statues 485-488.
const FIRST_GARG_STATUE := 435
const LAST_GARG_STATUE := 438
const SILENT_GARG_STATUE := 434
const SILENT_YORP_STATUE := 315
## Doors are solid, so Keen touches one when he stands this close to it.
const DOOR_REACH := 1.0
## Info layer values of the enemies in Keen 1. Ice cannons fire in the
## direction given by their value.
const INFO_YORP := 1
const INFO_GARG := 2
const INFO_VORTICON := 3
const INFO_BUTLER := 4
const INFO_TANK := 5
const INFO_CHAIN := 10
const ICE_CANNON_INFOS: Dictionary[int, Vector2i] = {
	6: Vector2i(1, -1),
	7: Vector2i(0, -1),
	8: Vector2i(0, 1),
	9: Vector2i(-1, -1),
}
## The Vorticon in this level is their commander.
const COMMANDER_LEVEL := 16
## Seed for the enemies' random choices, so that every attempt at a level
## starts out the same (and the tests are repeatable).
const RANDOM_SEED := 1990

var level: LevelData
var properties: TileProperties
var collision: LevelCollision
var inventory: Inventory
var keen: KeenBody
var actors: Array[Actor] = []
var outcome := Outcome.PLAYING
var rng := RandomNumberGenerator.new()


## Starts an attempt at [param level_data] with Keen's sprite at [param start].
## [param level_number] tells which enemies are special.
static func create(
	level_data: LevelData,
	tile_properties: TileProperties,
	keen_inventory: Inventory,
	start: Vector2,
	level_number := 0,
) -> LevelSession:
	var session := LevelSession.new()
	session.rng.seed = RANDOM_SEED
	session.level = level_data
	session.properties = tile_properties
	session.collision = LevelCollision.create(level_data, tile_properties)
	session.inventory = keen_inventory
	session.keen = KeenBody.create(session.collision, start)
	keen_inventory.enter_level()
	session._spawn_enemies(level_number == COMMANDER_LEVEL)
	return session


## Advances one tick with the buttons in [param input].
func step(input: KeenInput) -> void:
	if outcome != Outcome.PLAYING:
		return
	keen.has_pogo = inventory.has_pogo
	keen.step(input)
	if keen.fired:
		_fire()
	if not keen.is_dead and keen.state != KeenBody.State.EXITING:
		_touch_tiles(keen.hitbox())
	# Actors can add new actors while they step; those start next tick.
	for actor in actors.duplicate():
		actor.step(self)
	_resolve_hits()
	actors = actors.filter(func(actor: Actor) -> bool: return not actor.removed)
	if keen.exit_finished:
		outcome = Outcome.COMPLETED
	if keen.death_finished and outcome == Outcome.PLAYING:
		inventory.lose_life()
		outcome = Outcome.DIED


func add_actor(actor: Actor) -> void:
	actors.append(actor)


## The enemies of the level that are still around, dead or alive.
func enemies() -> Array[Enemy]:
	var result: Array[Enemy] = []
	for actor in actors:
		if actor is Enemy and not actor.removed:
			result.append(actor)
	return result


## Kills everything in [param area], Keen included: the falling stone.
func crush(area: Rect2) -> void:
	for enemy in enemies():
		if enemy.touches_keen() and enemy.hitbox().intersects(area):
			enemy.die()
	if keen.hitbox().intersects(area):
		keen.kill()


## Changes a tile of the level and lets the view know.
func set_tile(cell: Vector2i, tile: int) -> void:
	level.set_tile(cell, tile)
	tile_changed.emit(cell, tile)


func _spawn_enemies(has_commander: bool) -> void:
	for y in level.height:
		for x in level.width:
			var start := Vector2(x, y) * EgaGraphics.TILE_SIZE
			var enemy := _create_enemy(level.info_at(Vector2i(x, y)), start, has_commander)
			if enemy != null:
				add_actor(enemy)


static func _create_enemy(info: int, start: Vector2, has_commander: bool) -> Enemy:
	match info:
		INFO_YORP:
			return Yorp.create(start)
		INFO_GARG:
			return Garg.create(start)
		INFO_VORTICON:
			return Vorticon.create(start, has_commander)
		INFO_BUTLER:
			return ButlerRobot.create(start)
		INFO_TANK:
			return TankRobot.create(start)
		INFO_CHAIN:
			return StoneChain.create(start)
	if ICE_CANNON_INFOS.has(info):
		return IceCannon.create(start, ICE_CANNON_INFOS[info])
	return null


## Shots against enemies and Keen, and enemies against Keen.
func _resolve_hits() -> void:
	var targets := enemies()
	for actor in actors:
		var shot := actor as RaygunShot
		if shot == null or not shot.is_flying():
			continue
		if not shot.from_keen:
			if not keen.is_dead and shot.hitbox().intersects(keen.hitbox()):
				keen.kill()
				shot.splash()
			continue
		for enemy in targets:
			if enemy.stops_shots() and shot.hitbox().intersects(enemy.hitbox()):
				enemy.hit_by_shot(self)
				shot.splash()
				break
	if keen.is_dead:
		return
	for enemy in targets:
		if enemy.touches_keen() and enemy.hitbox().intersects(keen.hitbox()):
			enemy.touch_keen(self)


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
		elif properties.is_exit(tile) and keen.can_exit():
			keen.start_exit(cell.x)
		elif properties.is_hint(tile):
			var garg := tile >= FIRST_GARG_STATUE and tile <= LAST_GARG_STATUE
			set_tile(cell, SILENT_GARG_STATUE if garg else SILENT_YORP_STATUE)
			hint_touched.emit()
	for cell in LevelCollision.cells_under(box.grow_individual(DOOR_REACH, 0, DOOR_REACH, 0)):
		var tile := collision.tile_at(cell)
		if properties.is_door(tile) and inventory.has_keycard(properties.door_color(tile)):
			_open_door(cell)


func _pick_up(cell: Vector2i, tile: int) -> void:
	set_tile(cell, HIGH_BACKGROUND_TILE if tile >= HIGH_TILES_START else BACKGROUND_TILE)
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
		set_tile(current, BACKGROUND_TILE)
		current += Vector2i.DOWN
	inventory.keycards[color] = false
	add_actor(OpeningDoor.create(top, door_tiles))


func _is_door_of_color(cell: Vector2i, color: TileProperties.KeyColor) -> bool:
	var tile := collision.tile_at(cell)
	return properties.is_door(tile) and properties.door_color(tile) == color
