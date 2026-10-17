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
##   enemies   none yet: the info values 1-18 spawn nothing until
##             milestones C4 and C5 ([method create_enemy])
##   shots     Keen's shots use Keen 3's sprites ([Keen3Shot])
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
## [param start]. None yet: Keen 3's enemies come in milestones C4 and C5.
func create_enemy(_info: int, _start: Vector2) -> Enemy:
	return null


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
	keen3_sound_played.emit(Keen3Sounds.ANKH)
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
