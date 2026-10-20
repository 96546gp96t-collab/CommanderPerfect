class_name Keen3Grunt
extends Keen3Enemy
## The Vorticon grunt of Keen 3 (info values 1 and 11), as Chocolate Keen
## has it:
##   WALKING  walks toward Keen as it starts; every tick a chance of 2 to
##            jump (up to [constant MAX_JUMP_SPEED]) and, if not, a chance
##            of 2 to switch between its two speeds. Turns round at a wall
##            (back at the slow speed); walks off ledges
##   JUMPING  in the air (also after walking off a ledge), moving on;
##            turns round at a wall
##   LOOKING  after every landing: stands and looks around for
##            [constant LOOK_TICKS] ticks, then walks toward Keen, however
##            far away he is
## Touching it kills Keen. One shot kills it, from Keen or from an enemy
## (a fireball, a wall gun). Enemies give no points in Keen 3.

enum Mode { WALKING, JUMPING, LOOKING }

const SPRITE_WALK_LEFT := 63
const SPRITE_WALK_RIGHT := 67
const WALK_FRAMES := 4
const SPRITE_LOOK := 71
const LOOK_FRAMES := 4
## GRUNTJUMPL is shown while it moves right, GRUNTJUMPR while it moves left
## (Choco; Commander Genius has them the other way round).
const SPRITE_JUMP_MOVING_RIGHT := 73
const SPRITE_JUMP_MOVING_LEFT := 74
const SPRITE_DYING := 75
## The collision box: GRUNTLEFT1's box (2, 1, 21, 31) in EGAHEAD.CK3.
const BODY_BOX := Rect2(2, 1, 20, 31)

const HEALTH := 1  # (Choco)
## 90 and 120 (Choco).
const WALK_SPEED := 27.3 * Keen2Enemy.SUBPIXEL
const FAST_SPEED := 36.4 * Keen2Enemy.SUBPIXEL
const JUMP_CHANCE := 2  # (Choco)
const SPEED_CHANCE := 2  # (Choco)
## A jump of at most 300 (Choco).
const MAX_JUMP_SPEED := 167 * Keen2Enemy.SUBPIXEL
## 80 clock ticks (Choco).
const LOOK_TICKS := 33.0

var mode := Mode.WALKING
var speed := WALK_SPEED


## A grunt at [param start] that sets off toward [param direction] (1
## right, -1 left).
static func spawned(start: Vector2, direction: int) -> Keen3Grunt:
	var grunt := Keen3Grunt.new()
	grunt.position = start
	grunt.body_box = BODY_BOX
	grunt.health = HEALTH
	grunt.facing = direction
	grunt.first_dying_sprite = SPRITE_DYING
	return grunt


func hurt_by_enemy_shots() -> bool:
	return true


func death_sound() -> Sound.Id:
	return Sound.Id.VORTICON_SCREAM


func _living_sprite() -> int:
	match mode:
		Mode.LOOKING:
			return SPRITE_LOOK + frame_after(_age, SLOW_FRAME_TICKS, LOOK_FRAMES)
		Mode.JUMPING:
			return SPRITE_JUMP_MOVING_RIGHT if facing > 0 else SPRITE_JUMP_MOVING_LEFT
	var first := SPRITE_WALK_RIGHT if facing > 0 else SPRITE_WALK_LEFT
	return first + frame_after(_age, WALK_FRAME_TICKS, WALK_FRAMES)


func _think(session: LevelSession) -> void:
	match mode:
		Mode.WALKING:
			_walk_on(session)
		Mode.JUMPING:
			_fly(session)
		Mode.LOOKING:
			_look(session)


func _walk_on(session: LevelSession) -> void:
	if chance(session, JUMP_CHANCE):
		_jump(_random_up_to(session, MAX_JUMP_SPEED))
		mode = Mode.JUMPING
	elif chance(session, SPEED_CHANCE):
		speed = FAST_SPEED if speed == WALK_SPEED else WALK_SPEED
	_move(session)
	if mode == Mode.WALKING and not on_ground:
		mode = Mode.JUMPING


func _fly(session: LevelSession) -> void:
	_move(session)
	if on_ground:
		_set_mode(Mode.LOOKING)


func _look(session: LevelSession) -> void:
	_fall(session)
	if _mode_ticks < LOOK_TICKS:
		return
	facing = toward(position.x, session.nearest_keen(hitbox().get_center()).position.x)
	speed = WALK_SPEED
	_set_mode(Mode.WALKING)


## Falls and moves on; turns round at a wall, at the slow speed.
func _move(session: LevelSession) -> void:
	_fall(session)
	if not _walk(session, speed):
		facing = -facing
		speed = WALK_SPEED


func _set_mode(new_mode: Mode) -> void:
	mode = new_mode
	_mode_ticks = 0
