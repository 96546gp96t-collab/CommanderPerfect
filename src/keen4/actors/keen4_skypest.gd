class_name Keen4Skypest
extends GalaxyCreature
## The Skypest of Keen 4 (Omni `ck4_obj1.c`, facts and numbers only;
## docs/keen4/research.md §7):
##   - it flies at random: on odd tics it speeds up 1 in the way it faces,
##     at most 20 sideways and up or down; it turns sideways with a chance
##     of tics in 256 a frame, goes down from up with the same chance and
##     up from down with twice that;
##   - a ceiling sends it down at 8, a wall turns it; on a floor (no wall
##     beside) it lands and preens for 400 tics, then takes off (−16);
##   - in the air it kills Keen; a shot only pushes it (20 in the shot's
##     way);
##   - preening on the ground it is squashed for good when Keen lands on it
##     on his pogo stick; nothing else harms it.

## (Omni CK4_ACT_Skypest*.)
const ROWS: PackedStringArray = [
	"fly_1 SKYPEST_L_1 SKYPEST_R_1 step+ p- 5 0 0 fly flying fly fly_2",
	"fly_2 SKYPEST_L_2 SKYPEST_R_2 step+ p- 5 0 0 fly flying fly fly_1",
	"squashed SKYPEST_SQUASHED SKYPEST_SQUASHED think -- 0 0 0 - - - squashed",
	"preen_1 SKYPEST_REST SKYPEST_REST step -- 100 0 0 - preening - preen_2",
	"preen_2 SKYPEST_PREEN_1 SKYPEST_PREEN_1 step -- 10 0 0 - preening - preen_3",
	"preen_3 SKYPEST_PREEN_2 SKYPEST_PREEN_2 step -- 10 0 0 - preening - preen_4",
	"preen_4 SKYPEST_PREEN_3 SKYPEST_PREEN_3 step -- 10 0 0 - preening - preen_5",
	"preen_5 SKYPEST_PREEN_4 SKYPEST_PREEN_4 step -- 10 0 0 - preening - preen_6",
	"preen_6 SKYPEST_PREEN_3 SKYPEST_PREEN_3 step -- 10 0 0 - preening - preen_7",
	"preen_7 SKYPEST_PREEN_2 SKYPEST_PREEN_2 step -- 10 0 0 - preening - preen_8",
	"preen_8 SKYPEST_PREEN_1 SKYPEST_PREEN_1 step -- 10 0 0 - preening - preen_9",
	"preen_9 SKYPEST_REST SKYPEST_REST step -- 60 0 0 - preening - preen_10",
	"preen_10 SKYPEST_PREEN_5 SKYPEST_PREEN_5 step -- 10 0 0 - preening - preen_11",
	"preen_11 SKYPEST_PREEN_6 SKYPEST_PREEN_6 step -- 10 0 0 - preening - preen_12",
	"preen_12 SKYPEST_PREEN_7 SKYPEST_PREEN_7 step -- 10 0 0 - preening - preen_13",
	"preen_13 SKYPEST_PREEN_8 SKYPEST_PREEN_8 step -- 10 0 0 - preening - preen_14",
	"preen_14 SKYPEST_PREEN_7 SKYPEST_PREEN_7 step -- 10 0 0 - preening - preen_15",
	"preen_15 SKYPEST_PREEN_6 SKYPEST_PREEN_6 step -- 10 0 0 - preening - preen_16",
	"preen_16 SKYPEST_PREEN_5 SKYPEST_PREEN_5 step -- 10 0 0 - preening - preen_17",
	"preen_17 SKYPEST_REST SKYPEST_REST step -- 100 0 0 take_off preening - fly_1",
]
const PRIORITY := 0
const ACCEL := 1
const SPEED := 20
## A ceiling sends it down this fast (Omni).
const CEILING_SPEED := 8
## Landing puts it this much lower (Omni).
const LANDING_DROP := 0x80
## Taking off: its speed, and how far it goes up at once (Omni).
const TAKE_OFF_SPEED := -16
const TAKE_OFF_STEP := -144
## Keen's actions in which he squashes it (Omni CK_ACT_keenPogo1-3).
const POGO_ACTIONS: Array[StringName] = [&"pogo_1", &"pogo_2", &"pogo_3"]

## Squashed by Keen's pogo stick: harmless for good.
var squashed := false


## A Skypest at [param cell] (info 8, 45, 46).
static func spawn(
	world: GalaxyWorld, cell: Vector2i, sprites: Dictionary[StringName, int]
) -> Keen4Skypest:
	var skypest := Keen4Skypest.new()
	skypest.priority = PRIORITY
	var facing := random_side(world)
	skypest.direction = Vector2i(facing, random_side(world))
	var at := Vector2i(GalaxyUnits.from_tile(cell.x), GalaxyUnits.from_tile(cell.y))
	skypest.enter(world, at, ROWS, sprites, &"fly_1")
	return skypest


## Think: it turns at random and speeds up (Omni CK4_SkypestFly).
func _think_fly() -> void:
	if world.random() < world.tics:
		direction.x = -direction.x
	if direction.y == -1 and world.random() < world.tics:
		direction.y = 1
	if direction.y == 1 and world.random() < world.tics * 2:
		direction.y = -direction.y
	GalaxyPhysics.accelerate_x(self, direction.x * ACCEL, SPEED)
	GalaxyPhysics.accelerate_y(self, direction.y * ACCEL, SPEED)


## Think: up again (Omni CK4_SkypestTakeoff).
func _think_take_off() -> void:
	direction.y = -1
	velocity.y = TAKE_OFF_SPEED
	step.y = TAKE_OFF_STEP


## Contact in the air: Keen dies; a shot pushes it (Omni
## CK4_SkypestAirCol).
func _contact_flying(other: GalaxyObject) -> void:
	if is_player(other):
		kill_player()
	var shot := live_shot(other)
	if shot == null:
		return
	if shot.direction.x != 0:
		velocity.x = shot.direction.x * SPEED
	elif shot.direction.y != 0:
		velocity.y = shot.direction.y * SPEED
	shot.hit()


## Contact while preening: Keen on his pogo stick squashes it (Omni
## CK4_SkypestGroundCol).
func _contact_preening(other: GalaxyObject) -> void:
	if other.action != null and other.action.name in POGO_ACTIONS and is_player(other):
		squashed = true
		_become(&"squashed")
		world.play_sound(&"skypest_squish")


## React while flying: ceilings, walls and floors (Omni CK4_SkypestDraw).
func _react_fly() -> void:
	if bottom_hit != 0:
		velocity.y = CEILING_SPEED
		direction.y = 1
	if top_hit != 0 and right_hit == 0 and left_hit == 0:
		position.y += LANDING_DROP
		_become(&"preen_1")
	if left_hit != 0:
		velocity.x = 0
		direction.x = -1
	if right_hit != 0:
		velocity.x = 0
		direction.x = 1
