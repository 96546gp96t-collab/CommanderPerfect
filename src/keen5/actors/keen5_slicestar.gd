class_name Keen5Slicestar
extends GalaxyPlatform
## The Slicestar of Keen 5 (Omni `ck5_obj2.c`, `ck_obj.c`; facts and
## numbers only; docs/keen5/research.md §7), three kinds:
##   - **vertical** (info 10-12, starting up) and **horizontal** (22-24,
##     starting right): it moves along its axis as a red platform does
##     ([GalaxyPlatform]: 12 units a tic, turning at the B-blocks, info
##     31), clipped as a creature; 20 hit points;
##   - **diagonal** (19-21): 24 units a tic both ways, its 2 × 2 tile box
##     kept out of the walls ([GalaxyClip.update_simple_box]), bouncing
##     off them (sound "slice_bump"); it starts left-up, right-down or
##     left-down, never right-up (the original's table names left-up
##     twice); 50 hit points.
## Touching it kills Keen. A stunner shot is absorbed and costs a hit
## point; at none it bursts (one picture of 20 tics) and is gone. Keen
## never rides it.

## (Omni CK5_ACT_Slice0, CK5_ACT_SliceDiag0, CK5_ACT_SliceDie0.)
const ROWS: PackedStringArray = [
	"axis SLICESTAR SLICESTAR think -- 0 0 0 axis slicestar - -",
	"diagonal SLICESTAR SLICESTAR slide -- 0 24 24 - slicestar bounce diagonal",
	"burst SLICESTARBOOM SLICESTARBOOM step -- 20 0 0 - - - -",
]
const PRIORITY := 2
## Hit points (Omni).
const STRAIGHT_HEALTH := 20
const DIAGONAL_HEALTH := 50
## The diagonal one's box: 2 × 2 tiles (Omni CK_PhysFullClipToWalls).
const BOX := Vector2i(512, 512)
## Its first way by a random number / 64 (Omni: left-up twice, so never
## right-up).
const DIAGONAL_STARTS: Array[Vector2i] = [
	Vector2i(-1, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(-1, -1)
]
const START_DIVISOR := 0x40
## The info values' headings ([constant GalaxyPlatform.HEADINGS]): up,
## right.
const UP := 0
const RIGHT := 1

## Shots it can still take (Omni user4).
var health := STRAIGHT_HEALTH


## A straight Slicestar at [param cell] going [param heading] (0 up for
## info 10-12, 1 right for 22-24).
static func spawn_straight(
	world: GalaxyWorld, cell: Vector2i, heading: int, sprites: Dictionary[StringName, int]
) -> Keen5Slicestar:
	var star := Keen5Slicestar.new()
	star.priority = PRIORITY
	star.direction = HEADINGS[heading]
	var at := Vector2i(GalaxyUnits.from_tile(cell.x), GalaxyUnits.from_tile(cell.y))
	star.enter(world, at, ROWS, sprites, &"axis")
	return star


## A diagonal Slicestar at [param cell] (info 19-21), going a random way.
static func spawn_diagonal(
	world: GalaxyWorld, cell: Vector2i, sprites: Dictionary[StringName, int]
) -> Keen5Slicestar:
	var star := Keen5Slicestar.new()
	star.priority = PRIORITY
	star.clip = Clip.SIMPLE
	star.simple_box_size = BOX
	star.health = DIAGONAL_HEALTH
	star.direction = DIAGONAL_STARTS[world.random() / START_DIVISOR]
	var at := Vector2i(GalaxyUnits.from_tile(cell.x), GalaxyUnits.from_tile(cell.y))
	star.enter(world, at, ROWS, sprites, &"diagonal")
	return star


## Keen never rides it.
func touched_by_player(_player: GalaxyObject, _holding: bool) -> void:
	pass


## Contact: Keen dies; a shot is absorbed and costs a hit point, the last
## one bursts it (Omni CK5_SliceCol).
func _contact_slicestar(other: GalaxyObject) -> void:
	if is_player(other):
		kill_player(other)
		return
	var shot := live_shot(other)
	if shot == null:
		return
	shot.hit()
	health -= 1
	if health == 0:
		action_timer = 0
		start(actions[&"burst"])


## React of the diagonal one: a floor or ceiling turns it up or down, a
## wall left or right, each with its sound (Omni CK5_SliceDiagTileCol).
func _react_bounce() -> void:
	if top_hit != 0:
		direction.y = -1
		world.play_sound(&"slice_bump")
	elif bottom_hit != 0:
		direction.y = 1
		world.play_sound(&"slice_bump")
	if left_hit != 0:
		direction.x = -1
		world.play_sound(&"slice_bump")
	elif right_hit != 0:
		direction.x = 1
		world.play_sound(&"slice_bump")
