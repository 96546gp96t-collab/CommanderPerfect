class_name Keen3LevelSession
extends Keen2LevelSession
## One attempt at a Keen 3 level. It is a [Keen2LevelSession], so it has the
## riding on carriers, the stun, the "no exit while riding" rule and enemy
## shots that hurt enemies, which Keen 3's enemies and platforms need
## (milestones C4 and C5). The generic rules are [LevelSession]'s: the exit
## (17; any exit tile, so levels 12, 13 and 15 have two), deadly tiles (1),
## an extra life every 20,000 points.
##
## What Keen 3 does differently (docs/keen3/gameplay.md):
##   Keen      a [Keen3Body]: the ankh protects him ([method
##             Keen3Body.is_protected]), with a halo ([Keen3AnkhShield])
##   items     points 6-10 from the table (500, 100, 200, 1000, 5000), the
##             raygun (15, five charges), the keycards (18-21), the single
##             charge (28, one charge) and the ankh (27). A picked up item
##             leaves the first tile of its row in the tile table,
##             (tile / 13) * 13 (Choco): each row has its own background.
##   doors     an opened door's cells get the tile left of the door's top
##             cell (Choco); it sinks as in Keen 1 ([OpeningDoor])
##   22        turns its tile into 143 and does nothing else (Choco); no
##             level uses it
##   enemies   info 1 and 11 grunt, 2 youth, 3 mother, 4 Meep, 5 ninja,
##             6 Foob ([method create_enemy]); 7-18 spawn nothing until
##             milestones C5 and C7. They wake and sleep by the original's
##             rule ([Keen3ActiveArea]); enemies give no points
##   hits      Keen 3's own rules ([method _resolve_hits], Choco): Keen's
##             shot ([Keen3Shot]) splashes on every sprite but Keen and the
##             corpses, also on a fireball (both splash) and a Meep's wave
##             (which flies on); a fireball kills Keen, also a stunned one,
##             and grunts and Foobs, and splashes on anything but a mother
##             or a corpse; a wave kills Keen; touching an enemy does what
##             the enemy says (die, stun, push, or the Foob dies). Shots,
##             splashes and waves are deleted far from the view
##   pogo      Keen has the pogo stick from the start
## Keen 2's switches, lights and Tantalus Ray stay idle: Keen 3 has no
## behaviours 24-26, and its one light switch (tile 271, 23) is in no level.

## Emitted for a sound that only Keen 3 has, by its name in the sound block
## (see [Keen3Sounds]); the shared [signal LevelSession.sound_played] only
## knows Keen 1's names.
signal keen3_sound_played(sound_name: String)

## Item tiles come in rows of this many tiles; the first tile of a row is
## its empty background (Choco).
const ITEM_ROW_TILES := 13
## Behaviour 22 leaves this tile (Choco).
const BEHAVIOR_22 := 22
const BEHAVIOR_22_TILE := 143
## Info values of Keen 3's enemies (Choco); 1 (grunt) and 2 (youth) are
## Keen 2's [constant Keen2LevelSession.INFO_GRUNT] and [constant
## Keen2LevelSession.INFO_YOUTH]. 11 is a second grunt value that no level
## uses.
const INFO_MOM := 3
const INFO_MEEP := 4
const INFO_NINJA := 5
const INFO_FOOB := 6
const INFO_GRUNT_TOO := 11

## The Keen whose tiles are being checked.
var _toucher: Keen3Body


## Starts an attempt at [param level_data] with Keen's sprite at
## [param start], carrying [param keen_inventory] (normally a
## [Keen3Inventory]). The Keen 3 counterpart of [method
## Keen2LevelSession.begin].
static func started(
	level_data: LevelData,
	tile_properties: TileProperties,
	keen_inventory: Inventory,
	start: Vector2,
) -> Keen3LevelSession:
	# Keen 3 has no pogo stick to find: Keen always has it.
	keen_inventory.has_pogo = true
	var session := Keen3LevelSession.new()
	session._set_up(level_data, tile_properties, keen_inventory, start)
	return session


## The tile that a picked up [param tile] leaves: the first of its row.
static func row_background(tile: int) -> int:
	return (tile / ITEM_ROW_TILES) * ITEM_ROW_TILES


## Whether [param behavior] is an item that Keen picks up in Keen 3.
static func is_keen3_item_behavior(behavior: int) -> bool:
	if Keen3Behavior.is_keen3_item(behavior):
		return true
	return (
		behavior >= TileProperties.Behavior.POINTS_500
		and behavior <= TileProperties.Behavior.KEYCARD_BLUE
		and behavior != TileProperties.Behavior.EXIT
		and behavior != TileProperties.Behavior.POGO
		and not is_ship_part(behavior)
	)


## The enemy for info value [param info] at the cell whose top left is
## [param start], or null when the value is no enemy (yet). Each sets off
## toward Keen's start, as in the original.
func create_enemy(info: int, start: Vector2) -> Enemy:
	var direction := Keen3Enemy.toward(start.x, keen.position.x)
	var enemy: Enemy = null
	match info:
		INFO_GRUNT, INFO_GRUNT_TOO:
			enemy = Keen3Grunt.spawned(start, direction)
		INFO_YOUTH:
			enemy = Keen3Youth.spawned(start, direction)
		INFO_MOM:
			enemy = Keen3Mom.spawned(start, direction)
		INFO_MEEP:
			enemy = Keen3Meep.spawned(start, direction)
		INFO_NINJA:
			enemy = Keen3Ninja.spawned(start, direction)
		INFO_FOOB:
			enemy = Keen3Foob.spawned(start, direction)
	return enemy


## Whether a sleeping sprite with its top left at [param point] wakes up.
func wakes_at(point: Vector2) -> bool:
	return Keen3ActiveArea.wakes(_views(), point)


## Whether an awake sprite at [param point] stays awake.
func keeps_awake_at(point: Vector2) -> bool:
	return Keen3ActiveArea.keeps_awake(_views(), point)


## Whether a sprite at [param point] is on the screen.
func is_on_screen(point: Vector2) -> bool:
	return Keen3ActiveArea.on_screen(_views(), point)


## Plays one of Keen 3's own sounds ([Keen3Sounds]).
func play_keen3_sound(sound_name: String) -> void:
	keen3_sound_played.emit(sound_name)


func _spawn_enemies(_has_commander: bool) -> void:
	for y in level.height:
		for x in level.width:
			var cell := Vector2i(x, y)
			var enemy := create_enemy(level.info_at(cell), Vector2(cell) * EgaGraphics.TILE_SIZE)
			if enemy != null:
				add_actor(enemy)
				enemy.settle(self)


## Keen 3's Keen: a [Keen3Body] that stands on carriers as Keen 2's does.
func _create_keen(start: Vector2) -> KeenBody:
	if _keen_collision == null:
		_keen_collision = Keen2RidingCollision.with_carriers(level, properties, carriers)
	if switches == null:
		# Keen 2's switches, which no Keen 3 level has; the session steps them.
		switches = Keen2Switches.create(self)
	var body := Keen3Body.spawned(_keen_collision, start)
	body.sound_played.connect(play_sound)
	keens.append(body)
	return body


func _create_shot(start: Vector2, direction: int) -> RaygunShot:
	return Keen3Shot.fired(start, direction)


## The carriers move their riders first, as in Keen 2; then Keen 3's own
## hits take the place of [LevelSession]'s (Choco). Only awake enemies touch
## anything.
func _resolve_hits() -> void:
	_carry_riders()
	_delete_far_shots()
	var targets := _awake_enemies()
	for actor in actors:
		var shot := actor as Keen3Shot
		if shot == null or not shot.is_flying():
			continue
		if shot.from_keen:
			_hit_with_keen_shot(shot, targets)
		else:
			_hit_with_fireball(shot, targets)
	for actor in actors:
		if actor is Keen3SoundWave:
			_hit_keens(actor.hitbox())
	_touch_enemies(targets)


## Keen's [param shot] splashes on the first living enemy, fireball or wave
## it touches; an enemy loses a hit, a fireball splashes too.
func _hit_with_keen_shot(shot: Keen3Shot, targets: Array[Enemy]) -> void:
	var box := shot.hitbox()
	for enemy in targets:
		if enemy.stops_shots() and box.intersects(enemy.hitbox()):
			_kill(enemy, enemy.hit_by_shot.bind(self))
			_splash(shot)
			return
	for actor in actors:
		if actor == shot or actor.removed or not box.intersects(actor.hitbox()):
			continue
		if actor is Keen3Fireball and actor.is_flying():
			actor.splash()
			_splash(shot)
			return
		if actor is Keen3SoundWave:
			_splash(shot)
			return


## A [param fireball] kills the Keen it touches (the ankh still protects
## him), and grunts and Foobs; it splashes on anything but a mother, a
## corpse or another fireball's splash.
func _hit_with_fireball(fireball: Keen3Shot, targets: Array[Enemy]) -> void:
	var box := fireball.hitbox()
	if _hit_keens(box):
		_splash(fireball)
		return
	for enemy in targets:
		if Keen3Fireball.passes(enemy) or not box.intersects(enemy.hitbox()):
			continue
		var kind := enemy as Keen3Enemy
		if kind != null and kind.hurt_by_enemy_shots():
			_kill(enemy, enemy.die)
		_splash(fireball)
		return
	for actor in actors:
		if actor is Keen3SoundWave and box.intersects(actor.hitbox()):
			_splash(fireball)
			return


## Kills every living Keen in [param box], also a stunned one. Returns
## whether one was there (dead or protected by the ankh or not).
func _hit_keens(box: Rect2) -> bool:
	var hit := false
	for body in keens:
		if not body.is_dead and box.intersects(body.hitbox()):
			body.kill()
			hit = true
	return hit


## Each awake enemy that touches a living Keen does what it does to him.
func _touch_enemies(targets: Array[Enemy]) -> void:
	for body in keens:
		for enemy in targets:
			if body.is_dead or not enemy.touches_keen():
				continue
			if enemy.hitbox().intersects(body.hitbox()):
				_kill(enemy, enemy.touch_keen.bind(self, body))


func _splash(shot: Keen3Shot) -> void:
	play_sound(Sound.Id.SHOT_HIT)
	shot.splash()


## The enemies that are awake, dead or alive.
func _awake_enemies() -> Array[Enemy]:
	var awake: Array[Enemy] = []
	for enemy in enemies():
		if enemy.is_active:
			awake.append(enemy)
	return awake


## Shots, splashes and waves far from the view are deleted (Choco). A wave
## also goes as soon as it leaves the playable area: it flies through the
## walls, and beyond them lie only the border (never shown) and, in a view
## wider than a narrow level, the black bars.
func _delete_far_shots() -> void:
	var playable := Rect2(LevelMap.playable_pixels(level))
	for actor in actors:
		if (actor is Keen3Shot or actor is Keen3SoundWave) and not keeps_awake_at(actor.position):
			actor.removed = true
		var wave := actor as Keen3SoundWave
		if wave != null and not playable.encloses(wave.sprite_rect()):
			wave.removed = true


## What the players see; without a view (in the tests) an original screen
## around each Keen.
func _views() -> Array[Rect2]:
	var views: Array[Rect2] = []
	for rect in view_rects:
		if rect.has_area():
			views.append(rect)
	if views.is_empty():
		for body in keens:
			var center := body.hitbox().get_center()
			views.append(Rect2(center - DEFAULT_VIEW_SIZE / 2.0, DEFAULT_VIEW_SIZE))
	return views


func _touch_tiles(body: KeenBody) -> void:
	_toucher = body as Keen3Body
	super._touch_tiles(body)
	_toucher = null


func _is_item(tile: int) -> bool:
	return is_keen3_item_behavior(properties.behavior(tile))


func _pick_up(cell: Vector2i, tile: int) -> void:
	set_tile(cell, row_background(tile))
	var behavior := properties.behavior(tile)
	var first_card := TileProperties.Behavior.KEYCARD_YELLOW
	var lives := inventory.lives
	if behavior == Keen3Behavior.ANKH:
		_take_ankh()
	elif behavior == Keen3Behavior.SINGLE_CHARGE:
		inventory.charges += 1
		play_sound(Sound.Id.GOT_ITEM)
	elif behavior == TileProperties.Behavior.RAYGUN:
		inventory.charges += Inventory.RAYGUN_CHARGES
		play_sound(Sound.Id.GOT_ITEM)
	elif behavior >= first_card and behavior <= TileProperties.Behavior.KEYCARD_BLUE:
		inventory.keycards[behavior - first_card] = true
		play_sound(Sound.Id.GOT_CARD)
	else:
		inventory.add_points(POINTS.get(behavior, 0) if scores_points else 0)
		play_sound(Sound.Id.GOT_BONUS)
	if inventory.lives > lives:
		play_sound(Sound.Id.EXTRA_LIFE)


## The ankh: more protection for the Keen who touched it, with a halo when
## he had none yet.
func _take_ankh() -> void:
	play_keen3_sound(Keen3Sounds.ANKH)
	if _toucher == null:
		return
	var had_halo := _toucher.is_protected()
	_toucher.add_ankh()
	if not had_halo:
		add_actor(Keen3AnkhShield.around(_toucher))


## Behaviour 22 only turns its tile into 143. Keen 1's teleporter and
## statues and Keen 2's Elders do nothing in Keen 3.
func _touch_special_tile(cell: Vector2i, tile: int) -> void:
	if properties.behavior(tile) == BEHAVIOR_22:
		set_tile(cell, BEHAVIOR_22_TILE)


## Opens the whole door that [param cell] is part of, as [LevelSession]
## does, but its cells get the tile left of the door's top cell.
func _open_door(cell: Vector2i) -> void:
	var color := properties.door_color(level.tile_at(cell))
	var top := cell
	while _is_door_of_color(top + Vector2i.UP, color):
		top += Vector2i.UP
	var behind := level.tile_at(top + Vector2i.LEFT)
	var door_tiles := PackedInt32Array()
	var current := top
	while _is_door_of_color(current, color):
		door_tiles.append(level.tile_at(current))
		set_tile(current, behind)
		current += Vector2i.DOWN
	inventory.keycards[color] = false
	add_actor(OpeningDoor.create(top, door_tiles))
	play_sound(Sound.Id.DOOR_OPEN)
