class_name Keen5Spindred
extends Keen5Creature
## The Spindred of Keen 5 (Omni `ck5_obj3.c`, facts and numbers only;
## docs/keen5/research.md §7): it bounces between floor and ceiling. Its
## speed changes by 3 on every odd tic towards the way it falls (down or,
## upside down, up), at most 70. Hitting the floor while falling down it
## bounces up at 40 (sound "spindred_slam"); every third time it flies up at
## 68 instead and falls up from then on (sound "spindred_fly_up"), and the
## same the other way round at the ceiling ("spindred_fly_down"). Four
## pictures of 8 tics. Touching it kills Keen; a shot is absorbed.

## (Omni CK5_ACT_Spindred*.)
const ROWS: PackedStringArray = [
	"spin_1 SPINDRED1 SPINDRED1 step+ -- 8 0 0 bounce deadly bounce spin_2",
	"spin_2 SPINDRED2 SPINDRED2 step+ -- 8 0 0 bounce deadly bounce spin_3",
	"spin_3 SPINDRED3 SPINDRED3 step+ -- 8 0 0 bounce deadly bounce spin_4",
	"spin_4 SPINDRED4 SPINDRED4 step+ -- 8 0 0 bounce deadly bounce spin_1",
]
const RISE := Vector2i(0, -0x80)
const PRIORITY := 0
## Its fall: the change on odd tics and the fastest speed (Omni).
const PULL := 3
const MAX_SPEED := 70
## Bounces: off the floor or ceiling, the flight to the other side, and
## every how many (Omni).
const SLAM_SPEED := 40
const FLY_SPEED := 68
const BOUNCES := 3

## Bounces since it last turned (Omni user1).
var bounces := 0


## A Spindred at [param cell] (info 77, 78, 79), falling down.
static func spawn(
	world: GalaxyWorld, cell: Vector2i, sprites: Dictionary[StringName, int]
) -> Keen5Spindred:
	var spindred := Keen5Spindred.new()
	spindred.priority = PRIORITY
	spindred.direction = Vector2i(0, 1)
	spindred.place(world, cell, RISE, ROWS, sprites, &"spin_1")
	return spindred


## Think: its own gravity, down or up (Omni CK5_SpindredBounce; as
## [GalaxyPhysics] does gravity: the speed changes on odd tics, and a
## speed that would cross zero stops the move there).
func _think_bounce() -> void:
	var pull := PULL * direction.y
	for tic in range(world.tic - world.tics, world.tic):
		if tic & 1:
			if velocity.y * direction.y < 0 and absi(velocity.y) <= PULL:
				step.y += velocity.y
				velocity.y = 0
				return
			velocity.y = clampi(velocity.y + pull, -MAX_SPEED, MAX_SPEED)
		step.y += velocity.y


## React: the floor and the ceiling bounce it (Omni CK5_SpindredTileCol).
func _react_bounce() -> void:
	if bottom_hit != 0:
		velocity.y = 0
		if direction.y == -1:
			_bounce(&"spindred_fly_down")
	if top_hit != 0:
		velocity.y = 0
		if direction.y == 1:
			_bounce(&"spindred_fly_up")


## Off the side it fell to: back at 40, or every third time across at 68,
## falling the other way from now on.
func _bounce(flight_sound: StringName) -> void:
	bounces += 1
	if bounces == BOUNCES:
		bounces = 0
		velocity.y = FLY_SPEED * -direction.y
		direction.y = -direction.y
		world.play_sound(flight_sound)
	else:
		world.play_sound(&"spindred_slam")
		velocity.y = SLAM_SPEED * -direction.y
