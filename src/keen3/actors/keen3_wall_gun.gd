class_name Keen3WallGun
extends Enemy
## An invisible gun in a wall of Keen 3 (info value 14 fires right, 15
## fires down), as Chocolate Keen has it. Every gun of a level fires at the
## same moment, every [constant PERIOD_TICKS] ticks from the start of the
## level: the session keeps the one clock and calls [method fire] (with one
## TANKFIRE for them all). Guns fire far out of sight too, so the sound is
## always heard; a shot that would start where sprites are deleted is
## deleted at once (it is not made).
##
## It has no picture and no size: it never wakes, nothing touches it and
## shots fly past it. Its shot is a [Keen3GunShot].

## 400 clock ticks, 2.75 s (Choco).
const PERIOD_TICKS := 165
## Where the shot starts, from the top left of the gun's cell (Choco).
const RIGHT_SHOT_OFFSET := Vector2(0, 3)
const DOWN_SHOT_OFFSET := Vector2(4, 0)

## Whether it fires down (info value 15) rather than right.
var downward := false


## A gun in the cell whose top left is [param cell_start], firing down when
## [param fires_down].
static func placed(cell_start: Vector2, fires_down: bool) -> Keen3WallGun:
	var gun := Keen3WallGun.new()
	gun.position = cell_start
	gun.downward = fires_down
	gun.body_box = Rect2()
	gun.falls = false
	gun.facing = 1
	return gun


## It fires one shot, unless the shot would start far from every view.
func fire(session: Keen3LevelSession) -> void:
	var start := position + (DOWN_SHOT_OFFSET if downward else RIGHT_SHOT_OFFSET)
	if session.keeps_awake_at(start):
		session.add_actor(Keen3GunShot.fired_from(start, downward))


func step(_session: LevelSession) -> void:
	pass


func stops_shots() -> bool:
	return false


func touches_keen() -> bool:
	return false
