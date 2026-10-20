class_name Keen4Schoolfish
extends GalaxyCreature
## A school fish of Keen 4's Well of Wishes (info 16; Omni `ck4_obj3.c`,
## CK4_SpawnSchoolfish, CK4_SchoolfishMove and CK4_FishDraw, facts and
## numbers only; docs/keen4/research.md §7): it swims after Keen, speeding
## up 1 on odd tics towards him on both axes, at most 10 a tic, with the
## simple box clip (256 × 128 units). Harmless; the Dopefish eats it
## ([Keen4Dopefish], which swims by the same rules).
##   - A wall turns it round and stops it sideways; while it touches a
##     floor or a ceiling it keeps its facing instead of turning to Keen
##     (Omni user1).

## (Omni CK4_ACT_SchoolfishSwim0-1, CK4_ACT_SchoolfishEaten0.)
const ROWS: PackedStringArray = [
	"swim_1 SCHOOLFISH_L_1 SCHOOLFISH_R_1 step+ -- 20 0 0 move - fish swim_2",
	"swim_2 SCHOOLFISH_L_2 SCHOOLFISH_R_2 step+ -- 20 0 0 move - fish swim_1",
	"eaten SCHOOLFISH_L_1 SCHOOLFISH_R_1 think -- 0 0 0 - - - -",
]
const PRIORITY := 0
## Its box for the simple clip, in units (Omni).
const BOX := Vector2i(0x100, 0x80)
## Speeding up on odd tics, and its top speed (Omni).
const ACCEL := 1
const TOP_SPEED := 10

## Keeps its facing (bumped into something), instead of turning to Keen.
var bumped := false
## Its top speed (the Dopefish's differs).
var top_speed := TOP_SPEED


## A school fish at [param cell] (info 16), facing right.
static func spawn(
	world: GalaxyWorld, cell: Vector2i, sprites: Dictionary[StringName, int]
) -> Keen4Schoolfish:
	var fish := Keen4Schoolfish.new()
	fish.priority = PRIORITY
	fish.clip = Clip.SIMPLE
	fish.simple_box_size = BOX
	fish.direction = Vector2i(1, 1)
	var at := Vector2i(GalaxyUnits.from_tile(cell.x), GalaxyUnits.from_tile(cell.y))
	fish.enter(world, at, ROWS, sprites, &"swim_1")
	return fish


## The Dopefish caught it: it is held until eaten (Omni).
func be_caught() -> void:
	_become(&"eaten")


## Whether it is being eaten.
func is_caught() -> bool:
	return action == actions[&"eaten"]


## Think: after Keen (Omni CK4_SchoolfishMove, CK4_DopefishMove).
func _think_move() -> void:
	var keen := nearest_player()
	if not bumped:
		direction.x = 1 if position.x < keen.position.x else -1
	GalaxyPhysics.accelerate_x_only(self, direction.x * ACCEL, top_speed)
	GalaxyPhysics.accelerate_y(self, 1 if position.y < keen.position.y else -1, top_speed)


## React: walls turn it round; floors and ceilings keep its facing (Omni
## CK4_FishDraw).
func _react_fish() -> void:
	if (bottom_hit != 0 or top_hit != 0) and not bumped:
		bumped = true
	if right_hit != 0 or left_hit != 0:
		velocity.x = 0
		direction.x = -direction.x
		bumped = true
	if bottom_hit == 0 and top_hit == 0:
		bumped = false
