class_name Robot
extends Enemy
## Base class for the two robots: they walk back and forth, stop to turn at
## walls and ledges, shrug off Keen's shots and push Keen away instead of
## killing him. [ButlerRobot] and [TankRobot] fill in the details.

var walk_speed := 0.0
var push_speed := 0.0
## Ticks a robot stands still when it turns.
var turn_ticks := 0
var _turn_timer := 0
var _walk_timer := 0


func hit_by_shot(_session: LevelSession) -> void:
	pass


func touch_keen(_session: LevelSession, keen: KeenBody) -> void:
	_push_keen(keen, facing, push_speed)


func is_turning() -> bool:
	return _turn_timer > 0


func _think(session: LevelSession) -> void:
	_fall(session)
	if _turn_timer > 0:
		_turn_timer -= 1
		if _turn_timer == 0:
			facing = -facing
		return
	_walk_timer += 1
	if _at_ledge(session) or not _walk(session, walk_speed):
		_turn_timer = turn_ticks
