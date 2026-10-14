class_name TankRobot
extends Robot
## The tank robot: patrols like the butler, but every now and then it stops,
## looks around and fires a deadly shot in the direction it faces.

const SPRITE_WALK_RIGHT := 98
const SPRITE_WALK_LEFT := 102
const WALK_FRAMES := 4
const SPRITE_LOOK := 106
const LOOK_FRAMES := 2
## From the sprite table of EGAHEAD.CK1.
const BODY_BOX := Rect2(0, 0, 16, 24)

const WALK_SPEED := 28 * KeenPhysics.SUBPIXEL
const WALK_FRAME_TICKS := 6
const TURN_TICKS := 25
const LOOK_FRAME_TICKS := 4
const PUSH_SPEED := 16 * KeenPhysics.SUBPIXEL
## A tank walks a random number of ticks in this range before it fires.
const MIN_WALK_TICKS := 20
const MAX_WALK_TICKS := 200
## It aims for this long before the shot, and stands still briefly after.
const AIM_TICKS := 30
const AFTER_SHOT_TICKS := 14
## The shot leaves the gun this many pixels below the top of the sprite.
const SHOT_HEIGHT := 7

var _aim_timer := 0
var _walk_left := MAX_WALK_TICKS


static func create(start: Vector2) -> TankRobot:
	var tank := TankRobot.new()
	tank.position = start
	tank.body_box = BODY_BOX
	tank.walk_speed = WALK_SPEED
	tank.push_speed = PUSH_SPEED
	tank.turn_ticks = TURN_TICKS
	return tank


func sprite_index() -> int:
	if is_turning() or _aim_timer > 0:
		return SPRITE_LOOK + (_walk_timer / LOOK_FRAME_TICKS) % LOOK_FRAMES
	var walk_sprite := SPRITE_WALK_RIGHT if facing > 0 else SPRITE_WALK_LEFT
	return walk_sprite + (_walk_timer / WALK_FRAME_TICKS) % WALK_FRAMES


func _think(session: LevelSession) -> void:
	if _aim_timer > 0:
		_fall(session)
		_walk_timer += 1
		_aim_timer -= 1
		if _aim_timer == AFTER_SHOT_TICKS:
			_fire(session)
		if _aim_timer == 0:
			_walk_left = session.rng.randi_range(MIN_WALK_TICKS, MAX_WALK_TICKS)
		return
	super._think(session)
	if not is_turning():
		_walk_left -= 1
		if _walk_left <= 0:
			_aim_timer = AIM_TICKS + AFTER_SHOT_TICKS


func _fire(session: LevelSession) -> void:
	var x := hitbox().end.x if facing > 0 else hitbox().position.x - KeenPhysics.SHOT_SIZE.x
	var start := Vector2(x, position.y + SHOT_HEIGHT)
	session.add_actor(RaygunShot.create(start, facing, false))
