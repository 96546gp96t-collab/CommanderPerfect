class_name LevelSession
extends RefCounted
## One attempt at a level: Keen, the other [Actor]s and the items, advanced
## one fixed tick at a time (see [KeenPhysics]). This is only the logic, so
## that the tests can play a level; [LevelView] draws it.
##
## When two play, there is a second Keen ([method add_player]). Both share
## the [Inventory], and everything below goes for either of them; enemies
## go after the nearest one. As in the original, the attempt is over as soon
## as one of them has died; it is complete when one of them walks out
## through the exit.
##
## What Keen touches:
##   items    picked up: the tile is replaced by the background
##   doors    open when Keen has the keycard of their color, which is used up
##   exit     Keen walks through the door; then the level is complete
##   statues  show a message once, then stop glowing
##   teleporter  takes Keen out of the level to a secret place on the map
## Enemies start where the info layer of the level says (see
## [constant ENEMY_INFOS]); their shots, and Keen's, are actors too.
## The attempt ends when Keen reaches the exit, uses the teleporter, or has
## died (after the dying animation, or at once when he falls out of the
## level). In a level with open sides ([method open_sides], the ship levels)
## it also ends when Keen walks out of it there.
##
## Two switches for the extra levels: without [member scores_points] the
## items give no points (a level that is played again), and without
## [member picks_up_items] items stay where they are (the parts in the ship).
## [member exit_cells] work as exit doors that are not drawn.

## Emitted when a tile of the level changes, so that it can be redrawn.
signal tile_changed(cell: Vector2i, tile: int)
## Emitted when Keen touches a Yorp or Garg statue; the view shows its
## message. Each statue speaks only once.
signal hint_touched
## Emitted for every sound that Keen, an actor or an item makes.
signal sound_played(sound: Sound.Id)

## TELEPORTED: Keen left through the teleporter; the level is not done.
## WALKED_AWAY: Keen walked out at an open side; the level is not done.
enum Outcome { PLAYING, COMPLETED, DIED, TELEPORTED, WALKED_AWAY }

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
## The original screen, used as the view when there is none.
const DEFAULT_VIEW_SIZE := Vector2(320, 200)
## Seed for the enemies' random choices, so that every attempt at a level
## starts out the same (and the tests are repeatable).
const RANDOM_SEED := 1990

var level: LevelData
var properties: TileProperties
var collision: LevelCollision
var inventory: Inventory
## Every Keen in the level: player 1 first, then player 2 if two play.
var keens: Array[KeenBody] = []
## Player 1's Keen, the only one when one plays.
var keen: KeenBody
var actors: Array[Actor] = []
var outcome := Outcome.PLAYING
var rng := RandomNumberGenerator.new()
## What the players see, in level pixels: one rectangle, or one per player
## when the screen is split. Set by the view every frame. Enemies wake up
## when they come into it. Without a view (in the tests) it is the area of
## an original 320x200 screen around each Keen.
var view_rects: Array[Rect2] = []
var scores_points := true
var picks_up_items := true
var exit_cells: Array[Vector2i] = []


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
	session._set_up(level_data, tile_properties, keen_inventory, start, level_number)
	return session


## What [method create] does to a new session. A session of another
## episode (a subclass) calls it from its own constructor.
func _set_up(
	level_data: LevelData,
	tile_properties: TileProperties,
	keen_inventory: Inventory,
	start: Vector2,
	level_number := 0,
) -> void:
	rng.seed = RANDOM_SEED
	level = level_data
	properties = tile_properties
	collision = LevelCollision.create(level_data, tile_properties)
	inventory = keen_inventory
	keen = _create_keen(start)
	keen_inventory.enter_level()
	_spawn_enemies(level_number == COMMANDER_LEVEL)


## A second player joins: a new Keen with his sprite at [param start],
## looking the same way as player 1.
func add_player(start: Vector2) -> KeenBody:
	var body := _create_keen(start)
	body.invincible = keen.invincible
	body.facing = keen.facing
	return body


## Player 2 leaves: his Keen is taken out of the level. Player 1 stays.
func remove_player(body: KeenBody) -> void:
	if body != keen:
		keens.erase(body)


## Opens the left and right sides of the level: Keen can walk out of sight
## there, and that ends the attempt.
func open_sides(left := true, right := true) -> void:
	collision.open_left = left
	collision.open_right = right


## God mode (a cheat) for every Keen, also for one that joins later.
func set_invincible(invincible: bool) -> void:
	for body in keens:
		body.invincible = invincible


## Advances one tick with the buttons in [param input], for player 1.
func step(input: KeenInput) -> void:
	step_players([input])


## Advances one tick with the buttons of each player in [param inputs], in
## the order of [member keens]. A Keen without input stands still.
func step_players(inputs: Array[KeenInput]) -> void:
	if outcome != Outcome.PLAYING:
		return
	for index in keens.size():
		var body := keens[index]
		body.has_pogo = inventory.has_pogo
		body.step(inputs[index] if index < inputs.size() else KeenInput.new())
		if body.fired:
			_fire(body)
		if not body.is_dead and body.state != KeenBody.State.EXITING:
			_touch_tiles(body)
	# Actors can add new actors while they step; those start next tick.
	for actor in actors.duplicate():
		actor.step(self)
	_resolve_hits()
	actors = actors.filter(func(actor: Actor) -> bool: return not actor.removed)
	_check_outcome()


func add_actor(actor: Actor) -> void:
	actors.append(actor)


## Whether [param box] is in sight, so that an enemy there wakes up. One
## tile around the view counts too, so that enemies are already moving when
## they scroll into sight.
func is_in_view(box: Rect2) -> bool:
	for area in _view_areas():
		if area.intersects(box):
			return true
	return false


func is_point_in_view(point: Vector2) -> bool:
	for area in _view_areas():
		if area.has_point(point):
			return true
	return false


## The living Keen nearest to [param point]; player 1 when all are dead.
func nearest_keen(point: Vector2) -> KeenBody:
	var nearest := keen
	var nearest_distance := INF
	for body in keens:
		var distance := body.hitbox().get_center().distance_to(point)
		if not body.is_dead and distance < nearest_distance:
			nearest = body
			nearest_distance = distance
	return nearest


## Whether one of the Keens is dead or dying.
func has_dead_keen() -> bool:
	return keens.any(func(body: KeenBody) -> bool: return body.is_dead)


## Whether one of the Keens is walking out through the exit.
func is_exiting() -> bool:
	return keens.any(func(body: KeenBody) -> bool: return body.state == KeenBody.State.EXITING)


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
			_kill(enemy, enemy.die)
	for body in keens:
		if body.hitbox().intersects(area):
			body.kill()


func play_sound(sound: Sound.Id) -> void:
	sound_played.emit(sound)


## Plays [param sound] only when [param point] is in sight, so that cannons
## and robots far away stay quiet.
func play_sound_at(sound: Sound.Id, point: Vector2) -> void:
	if is_point_in_view(point):
		play_sound(sound)


## Changes a tile of the level and lets the view know.
func set_tile(cell: Vector2i, tile: int) -> void:
	level.set_tile(cell, tile)
	tile_changed.emit(cell, tile)


func _create_keen(start: Vector2) -> KeenBody:
	var body := KeenBody.create(collision, start)
	body.sound_played.connect(play_sound)
	keens.append(body)
	return body


## The views, one tile larger on every side.
func _view_areas() -> Array[Rect2]:
	var areas: Array[Rect2] = []
	for rect in view_rects:
		if rect.has_area():
			areas.append(rect.grow(EgaGraphics.TILE_SIZE))
	if areas.is_empty():
		for body in keens:
			var center := body.hitbox().get_center()
			var area := Rect2(center - DEFAULT_VIEW_SIZE / 2.0, DEFAULT_VIEW_SIZE)
			areas.append(area.grow(EgaGraphics.TILE_SIZE))
	return areas


## The level is complete when a Keen has walked out through the exit, and
## over when a Keen has died. Once a Keen is on his way out, nothing can
## stop that any more.
func _check_outcome() -> void:
	for body in keens:
		if body.exit_finished:
			outcome = Outcome.COMPLETED
			return
	if is_exiting():
		return
	if keens.any(_has_walked_away):
		outcome = Outcome.WALKED_AWAY
		return
	for body in keens:
		if body.death_finished and outcome == Outcome.PLAYING:
			inventory.lose_life()
			outcome = Outcome.DIED
			return


## Whether [param body] is out of the playable area at the left or right.
func _has_walked_away(body: KeenBody) -> bool:
	var playable := Rect2(LevelMap.playable_pixels(level))
	var box := body.hitbox()
	if collision.open_left and box.end.x <= playable.position.x:
		return true
	return collision.open_right and box.position.x >= playable.end.x


func _spawn_enemies(has_commander: bool) -> void:
	for y in level.height:
		for x in level.width:
			var start := Vector2(x, y) * EgaGraphics.TILE_SIZE
			var enemy := _create_enemy(level.info_at(Vector2i(x, y)), start, has_commander)
			if enemy != null:
				add_actor(enemy)
				enemy.settle(self)


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


## Shots against enemies and Keens, and enemies against Keens.
func _resolve_hits() -> void:
	var targets := enemies()
	for actor in actors:
		var shot := actor as RaygunShot
		if shot == null or not shot.is_flying():
			continue
		if not shot.from_keen:
			_shoot_keens(shot)
			continue
		for enemy in targets:
			if enemy.stops_shots() and shot.hitbox().intersects(enemy.hitbox()):
				play_sound(Sound.Id.SHOT_HIT)
				_kill(enemy, enemy.hit_by_shot.bind(self))
				shot.splash()
				break
	for body in keens:
		if body.is_dead:
			continue
		for enemy in targets:
			if enemy.touches_keen() and enemy.hitbox().intersects(body.hitbox()):
				enemy.touch_keen(self, body)


## An enemy's [param shot] kills the first Keen it hits.
func _shoot_keens(shot: RaygunShot) -> void:
	for body in keens:
		if not body.is_dead and shot.hitbox().intersects(body.hitbox()):
			body.kill()
			shot.splash()
			return


## Does [param attack] to [param enemy], and lets it scream if that kills it.
func _kill(enemy: Enemy, attack: Callable) -> void:
	var was_dead := enemy.is_dead
	attack.call()
	if enemy.is_dead and not was_dead:
		play_sound(enemy.death_sound())


func _fire(body: KeenBody) -> void:
	if inventory.charges <= 0:
		play_sound(Sound.Id.GUN_CLICK)
		return
	play_sound(Sound.Id.KEEN_FIRE)
	inventory.charges -= 1
	add_actor(_create_shot(body.shot_position(), body.facing))


## The shot that Keen fires from [param start] towards [param direction]. A
## subclass for another episode overrides it to draw its own sprites.
func _create_shot(start: Vector2, direction: int) -> RaygunShot:
	return RaygunShot.create(start, direction)


## What [param body] touches. A Keen cannot walk out while the other one is
## dying: the attempt is lost then, as in the original.
func _touch_tiles(body: KeenBody) -> void:
	var box := body.hitbox()
	for cell in LevelCollision.cells_under(box):
		var tile := collision.tile_at(cell)
		if _is_item(tile) and picks_up_items:
			_pick_up(cell, tile)
		elif _is_exit(cell, tile) and body.can_exit() and not has_dead_keen():
			body.start_exit(cell.x)
			play_sound(Sound.Id.LEVEL_DONE)
		else:
			_touch_special_tile(cell, tile)
	for cell in LevelCollision.cells_under(box.grow_individual(DOOR_REACH, 0, DOOR_REACH, 0)):
		var tile := collision.tile_at(cell)
		if properties.is_door(tile) and inventory.has_keycard(properties.door_color(tile)):
			_open_door(cell)


## Whether Keen picks up [param tile]. A subclass for another episode
## overrides it when that episode has fewer kinds of items.
func _is_item(tile: int) -> bool:
	return properties.is_item(tile)


## What a touched tile that is no item and no exit does: Keen 1's
## teleporter and statues. A subclass for another episode overrides it.
func _touch_special_tile(cell: Vector2i, tile: int) -> void:
	if properties.is_teleporter(tile) and outcome == Outcome.PLAYING:
		outcome = Outcome.TELEPORTED
	elif properties.is_hint(tile):
		var garg := tile >= FIRST_GARG_STATUE and tile <= LAST_GARG_STATUE
		set_tile(cell, SILENT_GARG_STATUE if garg else SILENT_YORP_STATUE)
		hint_touched.emit()


func _is_exit(cell: Vector2i, tile: int) -> bool:
	return properties.is_exit(tile) or exit_cells.has(cell)


func _pick_up(cell: Vector2i, tile: int) -> void:
	set_tile(cell, HIGH_BACKGROUND_TILE if tile >= HIGH_TILES_START else BACKGROUND_TILE)
	var behavior := properties.behavior(tile)
	var first_part := TileProperties.Behavior.SHIP_JOYSTICK
	var first_card := TileProperties.Behavior.KEYCARD_YELLOW
	var lives := inventory.lives
	if behavior == TileProperties.Behavior.RAYGUN:
		inventory.charges += Inventory.RAYGUN_CHARGES
		play_sound(Sound.Id.GOT_ITEM)
	elif behavior == TileProperties.Behavior.POGO:
		inventory.has_pogo = true
		play_sound(Sound.Id.GOT_ITEM)
	elif behavior >= first_part and behavior <= TileProperties.Behavior.SHIP_WHISKEY:
		inventory.add_ship_part((behavior - first_part) as Inventory.ShipPart)
		play_sound(Sound.Id.GOT_PART)
	elif behavior >= first_card and behavior <= TileProperties.Behavior.KEYCARD_BLUE:
		inventory.keycards[behavior - first_card] = true
		play_sound(Sound.Id.GOT_CARD)
	else:
		inventory.add_points(POINTS.get(behavior, 0) if scores_points else 0)
		play_sound(Sound.Id.GOT_BONUS)
	if inventory.lives > lives:
		play_sound(Sound.Id.EXTRA_LIFE)


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
	play_sound(Sound.Id.DOOR_OPEN)


func _is_door_of_color(cell: Vector2i, color: TileProperties.KeyColor) -> bool:
	var tile := collision.tile_at(cell)
	return properties.is_door(tile) and properties.door_color(tile) == color
