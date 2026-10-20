class_name Keen4Cloud
extends GalaxyCreature
## The cloud of Keen 4 (Omni `ck4_obj2.c`, facts and numbers only;
## docs/keen4/research.md §7): it sleeps until Keen touches it, wakes up for
## 100 tics, then drifts after him (speeding up 1 on odd tics, at most 10;
## it may turn to him with a chance of tics in 256 a frame). When Keen is
## under it (his feet not above its bottom, his head at most 4 tiles below)
## it lines up on 8 pixels, flashes, and strikes: the bolt kills for 48
## tics; then it drifts on 60 tics before it looks again. The stunner does
## nothing to it (the shot flies through).

## (Omni CK4_ACT_Cloud*, CK4_ACT_Lightning*.)
const ROWS: PackedStringArray = [
	"asleep CLOUD_ASLEEP CLOUD_ASLEEP think -- 20 0 0 - cloud - -",
	"waking CLOUD_AWAKE CLOUD_AWAKE step -- 100 0 0 - - drift move",
	"move CLOUD_AWAKE CLOUD_AWAKE think -- 20 0 0 move - drift -",
	"aim CLOUD_AWAKE CLOUD_AWAKE think -- 20 0 0 aim - drift -",
	"drift CLOUD_AWAKE CLOUD_AWAKE step+ -- 60 0 0 glide - drift move",
	"strike_1 CLOUD_ANGRY CLOUD_ANGRY step -- 10 0 0 - - - strike_2",
	"strike_2 CLOUD_AWAKE CLOUD_AWAKE step -- 10 0 0 - - - strike_3",
	"strike_3 CLOUD_ANGRY CLOUD_ANGRY step -- 10 0 0 - - - strike_4",
	"strike_4 CLOUD_AWAKE CLOUD_AWAKE step -- 10 0 0 strike - - strike_5",
	"strike_5 CLOUD_ANGRY CLOUD_ANGRY step -- 10 0 0 - - - strike_6",
	"strike_6 CLOUD_AWAKE CLOUD_AWAKE step -- 10 0 0 - - - strike_7",
	"strike_7 CLOUD_ANGRY CLOUD_ANGRY step -- 10 0 0 - - - strike_8",
	"strike_8 CLOUD_AWAKE CLOUD_AWAKE step -- 10 0 0 - - - strike_9",
	"strike_9 CLOUD_ANGRY CLOUD_ANGRY step -- 48 0 0 - - - drift",
	"bolt_1 BOLT_1 BOLT_1 step -- 8 0 0 - lethal - bolt_2",
	"bolt_2 BOLT_2 BOLT_2 step -- 8 0 0 - lethal - bolt_3",
	"bolt_3 BOLT_1 BOLT_1 step -- 8 0 0 - lethal - bolt_4",
	"bolt_4 BOLT_2 BOLT_2 step -- 8 0 0 - lethal - bolt_5",
	"bolt_5 BOLT_1 BOLT_1 step -- 8 0 0 - lethal - bolt_6",
	"bolt_6 BOLT_2 BOLT_2 step -- 8 0 0 - lethal - -",
]
const PRIORITY := 2
const ACCEL := 1
const SPEED := 10
## Keen's head at most this far below its bottom (Omni).
const STRIKE_DEPTH := 0x400
## It lines up on this grid (8 pixels) before it strikes (Omni).
const GRID := 0x80
const GRID_MASK := 0x7F
## The bolt starts this far from the cloud (Omni).
const BOLT_OFFSET := Vector2i(0x100, 0x100)


## A cloud at [param cell] (info 9).
static func spawn(
	world: GalaxyWorld, cell: Vector2i, sprites: Dictionary[StringName, int]
) -> Keen4Cloud:
	var cloud := Keen4Cloud.new()
	cloud.priority = PRIORITY
	var at := Vector2i(GalaxyUnits.from_tile(cell.x), GalaxyUnits.from_tile(cell.y))
	cloud.enter(world, at, ROWS, sprites, &"asleep")
	return cloud


## Whether it is awake (it was touched).
func is_awake_cloud() -> bool:
	return action != actions[&"asleep"]


## Think: after Keen, and over him it aims (Omni CK4_CloudMove).
func _think_move() -> void:
	var keen := world.player()
	if world.random() < world.tics:
		direction.x = -1 if keen.position.x < position.x else 1
	GalaxyPhysics.accelerate_x(self, direction.x * ACCEL, SPEED)
	var under := (
		keen.box.bottom >= box.bottom
		and keen.box.top - box.bottom <= STRIKE_DEPTH
		and box.left < keen.box.right
		and box.right > keen.box.left
	)
	if under:
		_continue_as(&"aim")


## Think: it drifts on to the next 8-pixel line and strikes there (Omni
## CK4_CloudCheckStrike).
func _think_aim() -> void:
	GalaxyPhysics.accelerate_x(self, direction.x * ACCEL, SPEED)
	var within := position.x & GRID_MASK
	if step.x < 0 and within + step.x <= 0:
		step.x = -within
		_continue_as(&"strike_1")
	if step.x > 0 and within + step.x >= GRID:
		step.x = GRID - within
		_continue_as(&"strike_1")


## Think: the bolt (Omni CK4_CloudStrike).
func _think_strike() -> void:
	var bolt := Keen4Cloud.new()
	bolt.activity = Activity.ON_SCREEN_ONLY
	bolt.clip = Clip.NONE
	bolt.priority = 0
	bolt.direction = Vector2i.ZERO
	bolt.enter(world, position + BOLT_OFFSET, ROWS, sprites, &"bolt_1")


## Contact while asleep: Keen wakes it (Omni CK4_CloudCol).
func _contact_cloud(other: GalaxyObject) -> void:
	if is_player(other):
		_become(&"waking")


## React: a wall turns it (Omni CK4_CloudDraw).
func _react_drift() -> void:
	if left_hit != 0:
		velocity.x = 0
		direction.x = -1
	elif right_hit != 0:
		velocity.x = 0
		direction.x = 1
