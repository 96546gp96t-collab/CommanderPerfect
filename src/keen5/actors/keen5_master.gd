class_name Keen5Master
extends Keen5Creature
## The Shikadi Master of Keen 5 (Omni `ck5_obj3.c`, facts and numbers only;
## docs/keen5/research.md §7): it stands, four pictures of 8 tics; after
## each round, with 64 in 256, it acts, by turns: it throws a ball at Keen
## ([Keen5MasterBall]: 48 sideways, −16 up, 30 tics casting and 8 more), or
## it teleports: two pictures of 20 tics, then sound "master_teleport", two
## sparks running off where it was, and it appears at a random spot near
## Keen (up to 16 tiles left of or above his middle column and bottom row,
## 15 right or below; up to nine tries for a spot inside the map's edges
## whose 5 × 5 tiles hold no wall, floor, ceiling or tile drawn in front);
## it falls there and stands 60 tics. Touching it kills Keen. A stunner
## shot is absorbed and it throws at once. Kept from the original: a shot
## Master faces right unless Keen's x is exactly its own; with no spot
## found it stays, one unit to the left, and stands at once.
## Seen in the user's v1.4 (milestone E12; research.md, "Watched in E12"):
## it stood 4, 4, 8, 8, 3, 1 and 8 rounds before acting, so it acts with
## 64 in 256 (Omnispeak reads the chance the other way round), and two of
## three teleports in view ended where it stood (Omnispeak's wall check
## never looks at a tile, so in level 12 it never fails).

## (Omni CK5_ACT_Master*.)
const ROWS: PackedStringArray = [
	"stand_1 MASTER1 MASTER1 step -- 8 0 0 - master - stand_2",
	"stand_2 MASTER2 MASTER2 step -- 8 0 0 - master - stand_3",
	"stand_3 MASTER3 MASTER3 step -- 8 0 0 - master - stand_4",
	"stand_4 MASTER4 MASTER4 step -- 8 0 0 decide master - stand_1",
	"cast_1 MASTERCASTL MASTERCASTR step -- 30 0 0 throw deadly - cast_2",
	"cast_2 MASTERCASTL MASTERCASTR step -- 8 0 0 - deadly - stand_1",
	"vanish_1 MASTERTELEPORT1 MASTERTELEPORT1 step -s 20 0 0 - deadly - vanish_2",
	"vanish_2 MASTERTELEPORT2 MASTERTELEPORT2 step -s 20 0 0 teleport deadly - land",
	"land MASTERTELEPORT2 MASTERTELEPORT2 think -- 0 0 0 fall - land appear",
	"appear MASTERTELEPORT2 MASTERTELEPORT2 step -- 60 0 0 - deadly - stand_1",
]
const RISE := Vector2i(0, -0x180)
const PRIORITY := 0
## Below this random number it acts after a round (the number Omni's; the
## way round seen in E12).
const ACT_CHANCE := 0x40
## The ball: where it starts (facing right / left), its speed (Omni).
const BALL_RIGHT := 0x100
const BALL_LEFT := 0
const BALL_DROP := 0x80
const BALL_SPEED := Vector2i(48, -16)
## The spot near Keen: random / 8 plus his tile minus 16, both ways; it
## tries while the count stays below 10 (nine tries); the spot must be at
## least 2 tiles inside the map's top and left edges and 5 inside the
## others (Omni).
const SPOT_DIVISOR := 8
const SPOT_BACK := 16
const TRIES := 10
const NEAR_EDGE := 2
const FAR_EDGE := 5
## The tiles its box covers at the new spot, from the spot (Omni).
const SPOT_BOX_START := -1
const SPOT_BOX_END := 4

## It teleports next instead of throwing (Omni user1).
var teleports_next := false


## A Shikadi Master at [param cell] (info 88, 89, 90).
static func spawn(
	world: GalaxyWorld, cell: Vector2i, sprites: Dictionary[StringName, int]
) -> Keen5Master:
	var master := Keen5Master.new()
	master.priority = PRIORITY
	master.direction = Vector2i.ZERO
	master.place(world, cell, RISE, ROWS, sprites, &"stand_1")
	return master


## Think after a round of standing: throw, or teleport after a throw (Omni
## CK5_MasterStand).
func _think_decide() -> void:
	if world.random() >= ACT_CHANCE:
		return
	if teleports_next:
		_continue_as(&"vanish_1")
		teleports_next = false
		return
	teleports_next = true
	direction.x = 1 if _keen().position.x > position.x else -1
	_continue_as(&"cast_1")


## Think: the ball leaves its hand (Omni CK5_MasterShoot).
func _think_throw() -> void:
	var x := position.x + (BALL_RIGHT if direction.x == 1 else BALL_LEFT)
	var speed := Vector2i(direction.x * BALL_SPEED.x, BALL_SPEED.y)
	var ball := Keen5MasterBall.throw_ball(
		world, Vector2i(x, position.y + BALL_DROP), speed, sprites
	)
	if ball != null:
		world.play_sound(&"master_shot")


## Think: sparks where it was, then a spot near Keen (Omni CK5_MasterTele).
func _think_teleport() -> void:
	Keen5MasterBall.spark(world, position, 1, sprites)
	Keen5MasterBall.spark(world, position, -1, sprites)
	world.play_sound(&"master_teleport")
	var keen := _keen()
	var size := Vector2i(world.map.width, world.map.height)
	for _attempt in range(1, TRIES):
		var tile := Vector2i(
			world.random() / SPOT_DIVISOR + keen.box.tile_middle - SPOT_BACK,
			world.random() / SPOT_DIVISOR + keen.box.tile_bottom - SPOT_BACK
		)
		if tile.y < NEAR_EDGE or tile.x < NEAR_EDGE:
			continue
		if tile.x > size.x - FAR_EDGE or tile.y > size.y - FAR_EDGE:
			continue
		if not _room_at(tile):
			continue
		_appear_at(tile)
		return
	world.random()
	_continue_as(&"stand_1")
	position.x -= 1
	step = Vector2i(1, 0)


## Contact: a stunner shot makes it throw at once; Keen dies (Omni
## CK5_MasterCol).
func _contact_master(other: GalaxyObject) -> void:
	var shot := live_shot(other)
	if shot != null:
		shot.hit()
		# The original faces right whenever Keen's x is not its own.
		direction.x = 1 if _keen().position.x != position.x else -1
		teleports_next = true
		_become(&"cast_1")
	elif is_player(other):
		kill_player(other)


## React after the teleport: it falls to the floor, then stands (Omni
## CK5_MasterTeleTileCol).
func _react_land() -> void:
	if right_hit != 0 or left_hit != 0:
		velocity.x = 0
	if bottom_hit != 0:
		velocity.y = 0
	if top_hit != 0:
		velocity.y = 0
		if action.next == null:
			world.remove(self)
		else:
			set_action(action.next)


## Whether the tiles its box would cover at [param tile] are all free: no
## side of any of them stops a fall or a walk, none is drawn in front
## (seen in E12: a spot in a wall is tried again).
func _room_at(tile: Vector2i) -> bool:
	for y in range(tile.y + SPOT_BOX_START, tile.y + SPOT_BOX_END):
		for x in range(tile.x + SPOT_BOX_START, tile.x + SPOT_BOX_END):
			if _blocks(world.fore_tile(x, y)):
				return false
	return true


## Whether foreground [param tile] has a solid side or is drawn in front.
func _blocks(tile: int) -> bool:
	var info := world.tile_info
	if info.is_in_front(tile):
		return true
	for side in [
		GalaxyTileInfo.Fore.TOP,
		GalaxyTileInfo.Fore.RIGHT,
		GalaxyTileInfo.Fore.BOTTOM,
		GalaxyTileInfo.Fore.LEFT
	]:
		if info.fore(side, tile) != 0:
			return true
	return false


## At [param tile]: its place, and the tiles its box covers until it is
## clipped again (Omni).
func _appear_at(tile: Vector2i) -> void:
	position = Vector2i(GalaxyUnits.from_tile(tile.x), GalaxyUnits.from_tile(tile.y))
	box.tile_left = tile.x + SPOT_BOX_START
	box.tile_right = tile.x + SPOT_BOX_END
	box.tile_top = tile.y + SPOT_BOX_START
	box.tile_bottom = tile.y + SPOT_BOX_END
	step = Vector2i.ZERO
