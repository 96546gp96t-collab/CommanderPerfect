class_name Keen4Smirky
extends GalaxyCreature
## Smirky, the treasure eater of Keen 4 (Omni `ck4_obj3.c`, facts and
## numbers only; docs/keen4/research.md §7 and §12 point 4):
##   - it stands 40 tics, then looks: a point item, drop or stunner tile up
##     to 3 tiles above it makes it jump straight up (−48, gravity mid);
##     otherwise it hops sideways (20, −24) where there is ground 4 tiles
##     ahead, or back the way it came; every second time it finds no ground
##     (or after two walls) it teleports;
##   - it eats every item tile its box touches in the air (the tile is
##     gone) and every item lying as a sprite that it touches (the item
##     disappears in its grab);
##   - teleporting it vanishes in a puff (4 × 20 tics), appears at an item
##     still lying in the level and comes out of the puff (4 × 20 tics);
##     with no item left it is gone;
##   - it never hurts Keen; a shot stuns it for good (it hops −16).

## (Omni CK4_ACT_Smirky*, CK4_ACT_StolenItem*.)
const ROWS: PackedStringArray = [
	"stand_1 SMIRKY_STAND_1 SMIRKY_STAND_1 step -- 20 0 0 - smirky - stand_2",
	"stand_2 SMIRKY_STAND_2 SMIRKY_STAND_2 step -- 20 0 0 look smirky - -",
	"vanish_1 PUFF_1 PUFF_1 step -- 20 0 0 - smirky - vanish_2",
	"vanish_2 PUFF_2 PUFF_2 step -- 20 0 0 - smirky - vanish_3",
	"vanish_3 PUFF_3 PUFF_3 step -- 20 0 0 - smirky - vanish_4",
	"vanish_4 PUFF_4 PUFF_4 step -- 20 0 0 teleport smirky - appear_1",
	"appear_1 PUFF_4 PUFF_4 step -- 20 0 0 - smirky - appear_2",
	"appear_2 PUFF_3 PUFF_3 step -- 20 0 0 - smirky - appear_3",
	"appear_3 PUFF_2 PUFF_2 step -- 20 0 0 - smirky - appear_4",
	"appear_4 PUFF_1 PUFF_1 step -- 20 0 0 - smirky - jump_1",
	"jump_1 SMIRKY_JUMP_L_1 SMIRKY_JUMP_R_1 step+ -- 6 0 0 fall_mid smirky jump jump_2",
	"jump_2 SMIRKY_JUMP_L_2 SMIRKY_JUMP_R_2 step+ -- 6 0 0 fall_mid smirky jump jump_3",
	"jump_3 SMIRKY_JUMP_L_3 SMIRKY_JUMP_R_3 step+ -- 6 0 0 fall_mid smirky jump jump_4",
	"jump_4 SMIRKY_JUMP_L_2 SMIRKY_JUMP_R_2 step+ -- 6 0 0 fall_mid smirky jump jump_1",
	"stunned_1 SMIRKY_JUMP_L_1 SMIRKY_JUMP_L_1 think -- 0 0 0 fall - stunned stunned_2",
	"stunned_2 SMIRKY_STUN SMIRKY_STUN think -- 0 0 0 fall - stunned -",
	"eaten_1 SMIRKY_GET_1 SMIRKY_GET_1 slide -- 10 0 8 - - - eaten_2",
	"eaten_2 SMIRKY_GET_2 SMIRKY_GET_2 slide -- 10 0 8 - - - eaten_3",
	"eaten_3 SMIRKY_GET_3 SMIRKY_GET_3 slide -- 10 0 8 - - - eaten_4",
	"eaten_4 SMIRKY_GET_4 SMIRKY_GET_4 slide -- 10 0 8 - - - -",
]
## It stands this far above the info tile's corner (Omni).
const RISE := 0x180
const PRIORITY := 3
## It looks for item tiles this many tiles above it (Omni).
const LOOK_UP_TILES := 3
const ITEM_JUMP := Vector2i(0, -48)
const HOP := Vector2i(20, -24)
## Ground is looked for 4 tiles ahead, in the 4 rows from 2 above its
## bottom row (Omni).
const AHEAD_TILES := 4
const GROUND_ROWS := 4
const GROUND_FROM := -2
## Teleporting after this many misses (Omni).
const MISSES_TO_TELEPORT := 2
## It appears this far left of the item (Omni).
const ITEM_OFFSET := -0x80
const SHOT_HOP := -16
const STARS := Vector2i(0x80, 0)

## Walls hit and hops without ground ahead (Omni user1).
var misses := 0
## What it ate shows its grab (shares the class for its rows).
var is_eaten_item := false


## Smirky at [param cell] (info 18).
static func spawn(
	world: GalaxyWorld, cell: Vector2i, sprites: Dictionary[StringName, int]
) -> Keen4Smirky:
	var smirky := Keen4Smirky.new()
	smirky.priority = PRIORITY
	smirky.direction = Vector2i(random_side(world), 1)
	smirky.stars_offset = STARS
	var at := Vector2i(GalaxyUnits.from_tile(cell.x), GalaxyUnits.from_tile(cell.y) - RISE)
	smirky.enter(world, at, ROWS, sprites, &"stand_1")
	return smirky


## Whether a foreground tile of misc [param kind] is something it eats: a
## drop or an item (Omni MF_Centilife, MF_Points100 … MF_Stunner).
static func eats(kind: int) -> bool:
	return kind == GalaxyTileKinds.DROP or GalaxyTileKinds.is_item(kind)


## Think after standing: jump for items, hop on, or teleport (Omni
## CK4_SmirkySearch).
func _think_look() -> void:
	_continue_as(&"jump_1")
	if _items_above():
		velocity = ITEM_JUMP
		return
	if misses >= MISSES_TO_TELEPORT:
		_continue_as(&"vanish_1")
		return
	if _ground_ahead():
		velocity = Vector2i(direction.x * HOP.x, HOP.y)
		return
	misses += 1
	if misses == MISSES_TO_TELEPORT:
		_continue_as(&"vanish_1")
		return
	velocity = Vector2i(-direction.x * HOP.x, HOP.y)


## Think in the puff: to an item still lying in the level, or gone when
## there is none (Omni CK4_SmirkyTeleport; see docs/keen4/gameplay.md).
func _think_teleport() -> void:
	misses = 0
	var target: GalaxyItem = null
	for object in world.objects:
		var item := object as GalaxyItem
		if item != null and not item.taken and not item.removed:
			target = item
	if target == null:
		world.remove(self)
		return
	position = target.position + Vector2i(ITEM_OFFSET, 0)
	reset_box()


## Contact: it eats items lying as sprites; a shot stuns it (Omni
## CK4_SmirkyCol).
func _contact_smirky(other: GalaxyObject) -> void:
	var item := other as GalaxyItem
	if item != null:
		if not item.taken:
			item.taken = true
			world.remove(item)
			_show_eaten(item.position, item.direction.y)
		return
	var shot := live_shot(other)
	if shot == null:
		return
	shot.hit()
	_become(&"stunned_1")
	stunned = true
	velocity.y += SHOT_HOP


## React in the air: it eats the item tiles it touches, lands, and turns
## at walls (Omni CK4_SmirkyDraw, CK4_SmirkyCheckTiles).
func _react_jump() -> void:
	_eat_tiles()
	if top_hit != 0:
		_become(&"stand_1")
	if left_hit != 0 or right_hit != 0:
		misses += 1
		direction.x = -direction.x
		velocity.x = 0
	if top_hit != 0:
		velocity.y = 0


func _eat_tiles() -> void:
	for y in range(box.tile_top, box.tile_bottom + 1):
		for x in range(box.tile_left, box.tile_right + 1):
			if eats(world.misc_of(world.fore_tile(x, y))):
				world.set_fore_tile(Vector2i(x, y), GalaxyTileKinds.EMPTY_TILE)
				_show_eaten(GalaxyUnits.PER_TILE * Vector2i(x, y), 0)


## The grab where it ate something at [param at] (units); an item lying
## as a sprite rises with it ([param rising] −1), a tile's stays (0).
func _show_eaten(at: Vector2i, rising: int) -> void:
	var eaten := Keen4Smirky.new()
	eaten.is_eaten_item = true
	eaten.priority = PRIORITY
	eaten.clip = Clip.NONE
	eaten.activity = Activity.ON_SCREEN_ONLY
	eaten.direction = Vector2i(0, rising)
	eaten.enter(world, at, ROWS, sprites, &"eaten_1")


## Whether an item tile lies up to 3 tiles above it. (Omnispeak also
## looks for items lying as sprites, with a test no item can pass.)
func _items_above() -> bool:
	for y in range(box.tile_top - LOOK_UP_TILES, box.tile_top):
		for x in range(box.tile_left, box.tile_right + 1):
			if eats(world.misc_of(world.fore_tile(x, y))):
				return true
	return false


## Whether a tile with a top lies 4 tiles ahead, in the rows from 2 above
## its feet down.
func _ground_ahead() -> bool:
	var x := box.tile_middle + direction.x * AHEAD_TILES
	for row in GROUND_ROWS:
		var y := box.tile_bottom + GROUND_FROM + row
		if world.clip.top_of(world.fore_tile(x, y)) != 0:
			return true
	return false
