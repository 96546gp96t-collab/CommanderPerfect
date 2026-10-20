class_name Keen2LevelSession
extends LevelSession
## One attempt at a Keen 2 level. The generic rules are [LevelSession]'s,
## unchanged: points for items with behaviours 6-10 (500, 100, 200, 1000,
## 5000), the raygun (15, five charges), the keycards (18-21) and the doors
## they open (2-5; the door becomes tile 143), the exit (17), deadly tiles
## (1), an extra life every 20,000 points, and the background that a picked
## up item leaves (tile 276 for items from tile 305 on, otherwise 143).
##
## What Keen 2 does differently (docs/keen2/gameplay.md):
##   enemies    the info layer: 1 grunt, 2 youth, 3 Elite, 4 Scrub, 5 Guard
##              robot, 6 moving platform, 7 the spark of a Tantalus Ray
##              machine ([method create_enemy]). Nothing spawns at a switch:
##              its info value points to the bridge it moves.
##   riding     Keen stands on platforms and Scrubs and moves along with
##              them ([Keen2Carrier], [Keen2RidingCollision]); he cannot
##              walk out through the exit while he rides.
##   stun       Keen is a [Keen2Body]: a youth stuns him, and an enemy shot
##              only cuts a stun short.
##   enemy shots  hurt other enemies too, except their own kind and the
##              Guard robots' shots on an Elite
##              ([member enemy_shots_hurt_enemies]).
##   items      Keen 1's ship parts (behaviours 11-14) are no items: Keen 2
##              has none.
##   switches   23, 25 and 26 are switches, used with the pogo button
##              ([Keen2Switches]): bridges, the lights ([method is_dark]) and
##              the Tantalus Ray ([signal tantalus_ray_fired]).
##   machines   shooting a spark wrecks its machine ([Keen2Tantalus]); the
##              session counts them ([method all_machines_destroyed]).
##   Elder      behaviour 22 is the Vorticon Elder's message, not a statue:
##              only with tile 429 right below it, which then becomes 182
##              ([signal elder_message_touched]). 24 is no teleporter.
##   shots      Keen's shots use Keen 2's sprites ([Keen2Shot]); fired close
##              to a wall, a shot splashes against it at once.
##   pogo       Keen has the pogo stick from the start.

## The lights went off ([param dark] true) or on.
signal lights_changed(dark: bool)
## Keen touched a Vorticon Elder that has a message for him.
signal elder_message_touched
## Keen pressed the switch of a machine that was not destroyed: the
## Tantalus Ray fires and the Earth explodes. The level stops at once.
signal tantalus_ray_fired

## Info layer values of the enemies in Keen 2.
const INFO_GRUNT := 1
const INFO_YOUTH := 2
const INFO_ELITE := 3
const INFO_SCRUB := 4
const INFO_GUARD_ROBOT := 5
const INFO_PLATFORM := 6
## The spark of a Tantalus Ray machine.
const INFO_SPARK := 7
## An Elder speaks only with this tile (its light: the glowing blue floor,
## 429-432) right below the touched tile, as under tile 559 in levels 8 and
## 10; afterwards the light goes out and the floor is plain blue (182).
const ELDER_LIGHT := 429
const ELDER_LIGHT_OFF := 182  # estimate: Commander Genius's choice; the picture fits
## Commander Genius lets the enemies' shots hit other enemies; whether the
## original does is not known (docs/keen2/research.md section 5).
const ENEMY_SHOTS_HURT_ENEMIES := true  # estimate
## Keen's states in which he stands on something and rides along with it.
const STANDING_STATES: Array[KeenBody.State] = [
	KeenBody.State.STANDING, KeenBody.State.CROUCHING, KeenBody.State.POGO_COMPRESSED
]

## Whether an enemy shot hurts enemies of another kind. Starts as
## [constant ENEMY_SHOTS_HURT_ENEMIES]; a test can turn it off.
var enemy_shots_hurt_enemies := ENEMY_SHOTS_HURT_ENEMIES
## The switches and bridges of the level.
var switches: Keen2Switches
## Whether the Tantalus Ray has fired; nothing moves any more then.
var tantalus_fired := false
## The Tantalus Ray machines (sparks) in the level, and how many of them
## Keen destroyed.
var machine_count := 0
var machines_destroyed := 0
## Keen's collision: the tiles and the tops of the carriers.
var _keen_collision: Keen2RidingCollision
## Whether the Keen whose tiles are being checked rides a carrier.
var _toucher_rides := false
## Every level starts with the lights on.
var _dark := false


## Starts an attempt at [param level_data] with Keen's sprite at
## [param start], carrying [param keen_inventory] (normally a
## [Keen2Inventory]).
static func begin(
	level_data: LevelData,
	tile_properties: TileProperties,
	keen_inventory: Inventory,
	start: Vector2,
) -> Keen2LevelSession:
	# Keen 2 has no pogo stick to find: Keen always has it.
	keen_inventory.has_pogo = true
	var session := Keen2LevelSession.new()
	session._set_up(level_data, tile_properties, keen_inventory, start)
	return session


## Whether the lights are off. The Vorticons do not jump in the dark.
func is_dark() -> bool:
	return _dark


## Turns the lights off ([param dark] true) or on.
func set_dark(dark: bool) -> void:
	if dark == _dark:
		return
	_dark = dark
	lights_changed.emit(dark)


## The Tantalus Ray fires (the switch of an intact machine): the lights come
## on and the level stops. It is game over, whatever the lives.
func fire_tantalus_ray() -> void:
	if tantalus_fired:
		return
	tantalus_fired = true
	set_dark(false)
	tantalus_ray_fired.emit()


## Keen shot the spark of a machine.
func machine_destroyed() -> void:
	machines_destroyed += 1


## Whether the level had machines and Keen destroyed them all.
func all_machines_destroyed() -> bool:
	return machine_count > 0 and machines_destroyed >= machine_count


## Advances one tick; nothing moves after the Tantalus Ray fired.
func step_players(inputs: Array[KeenInput]) -> void:
	if tantalus_fired or outcome != Outcome.PLAYING:
		return
	super.step_players(inputs)
	if not tantalus_fired:
		switches.step()


## The enemy for info value [param info] at the cell whose top left is
## [param start], or null when the value is no enemy (yet).
func create_enemy(info: int, start: Vector2) -> Enemy:
	var enemy: Enemy = null
	match info:
		INFO_GRUNT:
			enemy = Keen2Grunt.create(start)
		INFO_YOUTH:
			enemy = Keen2Youth.create(start, -1 if rng.randi_range(0, 1) == 0 else 1)
		INFO_ELITE:
			enemy = Keen2Elite.create(start)
		INFO_SCRUB:
			enemy = Keen2Scrub.create(start)
		INFO_GUARD_ROBOT:
			enemy = Keen2GuardRobot.create(start)
		INFO_PLATFORM:
			enemy = Keen2Platform.create(start)
		INFO_SPARK:
			enemy = Keen2Spark.create(start)
	return enemy


## The platforms and Scrubs in the level.
func carriers() -> Array[Keen2Carrier]:
	var found: Array[Keen2Carrier] = []
	for actor in actors:
		if actor is Keen2Carrier and not actor.removed:
			found.append(actor)
	return found


## The carrier that [param body] stands on, or null.
func carrier_of(body: KeenBody) -> Keen2Carrier:
	if not _stands(body):
		return null
	return _keen_collision.carrier_under(body.hitbox())


func is_riding(body: KeenBody) -> bool:
	return carrier_of(body) != null


func _spawn_enemies(_has_commander: bool) -> void:
	for y in level.height:
		for x in level.width:
			var cell := Vector2i(x, y)
			if Keen2Switches.is_switch(properties, level.tile_at(cell)):
				continue
			var enemy := create_enemy(level.info_at(cell), Vector2(cell) * EgaGraphics.TILE_SIZE)
			if enemy == null:
				continue
			add_actor(enemy)
			enemy.settle(self)
			if enemy is Keen2Spark:
				machine_count += 1


## Keen 2's Keen: a [Keen2Body] that also stands on carriers and uses the
## switches.
func _create_keen(start: Vector2) -> KeenBody:
	if _keen_collision == null:
		_keen_collision = Keen2RidingCollision.with_carriers(level, properties, carriers)
	if switches == null:
		switches = Keen2Switches.create(self)
	var body := Keen2Body.placed(_keen_collision, start)
	body.switch_user = switches.use_near
	body.sound_played.connect(play_sound)
	keens.append(body)
	return body


## The carriers have moved: their riders go along before anything touches.
func _resolve_hits() -> void:
	_carry_riders()
	super._resolve_hits()


func _carry_riders() -> void:
	for body in keens:
		if not _stands(body):
			continue
		for carrier in carriers():
			if carrier.carries(body.hitbox(), true):
				body.position.x += collision.sweep_x(body.hitbox(), carrier.last_move.x)
				body.position.y += collision.sweep_y(body.hitbox(), carrier.last_move.y)
				break


## Whether [param body] is on his feet (or his pogo stick) on something.
func _stands(body: KeenBody) -> bool:
	return not body.is_dead and body.state in STANDING_STATES


## An enemy shot: a stunned Keen only gets up sooner; other enemies may be
## hit as well.
func _shoot_keens(shot: RaygunShot) -> void:
	for body in keens:
		if body.is_dead or not shot.hitbox().intersects(body.hitbox()):
			continue
		var keen_2 := body as Keen2Body
		if keen_2 != null and keen_2.is_stunned():
			keen_2.shorten_stun()
		else:
			body.kill()
		shot.splash()
		return
	if enemy_shots_hurt_enemies:
		_shoot_enemies(shot)


## [param shot] hits the first enemy in its way that is not of the
## shooter's kind. An Elite stops a Guard robot's shot unharmed. Only Keen
## destroys a spark.
func _shoot_enemies(shot: RaygunShot) -> void:
	var enemy_shot := shot as Keen2EnemyShot
	var shooter: Script = enemy_shot.shooter if enemy_shot != null else null
	for enemy in enemies():
		if not enemy.stops_shots() or not shot.hitbox().intersects(enemy.hitbox()):
			continue
		if enemy is Keen2Spark:
			continue
		if enemy_shot != null and enemy_shot.passes_through(enemy):
			continue
		play_sound_at(Sound.Id.SHOT_HIT, shot.position)
		if not (enemy is Keen2Elite and Keen2Elite.is_immune_to(shooter)):
			_kill(enemy, enemy.hit_by_shot.bind(self))
		shot.splash()
		return


## Keen cannot walk out through the exit while he rides a carrier.
func _touch_tiles(body: KeenBody) -> void:
	_toucher_rides = is_riding(body)
	super._touch_tiles(body)
	_toucher_rides = false


func _is_exit(cell: Vector2i, tile: int) -> bool:
	return super._is_exit(cell, tile) and not _toucher_rides


func _is_item(tile: int) -> bool:
	return properties.is_item(tile) and not is_ship_part(properties.behavior(tile))


## A Vorticon Elder (behaviour 22) speaks once, and only with its light
## (tile 429) right below the touched tile; Commander Genius notes that the
## original has behaviour 22 elsewhere too, where nothing should happen.
## Keen 1's teleporter and statues do nothing in Keen 2.
func _touch_special_tile(cell: Vector2i, tile: int) -> void:
	if properties.behavior(tile) != Keen2Switches.BEHAVIOR_ELDER:
		return
	var below := cell + Vector2i.DOWN
	if collision.tile_at(below) != ELDER_LIGHT:
		return
	set_tile(below, ELDER_LIGHT_OFF)
	elder_message_touched.emit()


## Keen's shot; close to a wall it splashes at that wall at once.
func _create_shot(start: Vector2, direction: int) -> RaygunShot:
	return Keen2Shot.fired_by_keen(self, start, direction)


## Whether [param behavior] is one of Keen 1's ship parts.
static func is_ship_part(behavior: int) -> bool:
	return (
		behavior >= TileProperties.Behavior.SHIP_JOYSTICK
		and behavior <= TileProperties.Behavior.SHIP_WHISKEY
	)
