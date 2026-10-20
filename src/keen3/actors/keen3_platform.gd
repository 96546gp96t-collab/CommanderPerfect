class_name Keen3Platform
extends Keen3Carrier
## The moving platforms of Keen 3, as Chocolate Keen has them:
##   sideways   (info value 9) 4 px above its cell, sets off to the right;
##              at a wall it stands still [constant WAIT_TICKS] ticks, then
##              goes back
##   up, down   (info value 10) in its cell, sets off downwards; at a floor
##              it turns up at once, at a ceiling it stands still
##              [constant WAIT_TICKS] ticks, then goes down again
## Both move at [constant SPEED] and show 107 and 108 in turn every
## [constant FRAME_TICKS]. They always move, also far out of sight. Keen
## rides on them ([Keen3Carrier]); every shot splashes on them and they
## never break. One that carries Keen up into a ceiling stops under him
## as at the ceiling ([method Keen3Carrier.give_way]).

const SPRITE_FIRST := 107
const FRAMES := 2
## PLATFORM1's box (0, 0, 31, 7) in EGAHEAD.CK3: the whole 32x8 sprite.
const BODY_BOX := Rect2(0, 0, 32, 8)
## The sideways platform is placed this far above the top of its cell
## (Choco).
const RAISE := 4.0
## 75 (Choco).
const SPEED := 22.8 * Keen2Enemy.SUBPIXEL
## More than 75 clock ticks (Choco).
const WAIT_TICKS := 31
## 32 clock ticks (Choco).
const FRAME_TICKS := 13.2

## Whether it goes up and down (info value 10) rather than sideways.
var vertical := false
## Ticks it still stands still before it sets off with [member _next_velocity].
var _wait := 0
var _next_velocity := Vector2.ZERO


## The sideways platform for the cell whose top left is [param cell_start].
static func sideways(cell_start: Vector2) -> Keen3Platform:
	var platform := _made(cell_start + Vector2(0, -RAISE))
	platform.velocity = Vector2(SPEED, 0.0)
	platform.facing = 1
	return platform


## The platform that goes up and down, for the cell whose top left is
## [param cell_start].
static func up_and_down(cell_start: Vector2) -> Keen3Platform:
	var platform := _made(cell_start)
	platform.vertical = true
	platform.velocity = Vector2(0.0, SPEED)
	return platform


static func _made(start: Vector2) -> Keen3Platform:
	var platform := Keen3Platform.new()
	platform.position = start
	platform.body_box = BODY_BOX
	platform.falls = false
	platform.is_active = true
	return platform


## Whether it stands still at a wall or a ceiling now.
func is_waiting() -> bool:
	return _wait > 0


func sprite_index() -> int:
	return SPRITE_FIRST + Keen3Enemy.frame_after(_timer, FRAME_TICKS, FRAMES)


func hit_by_shot(_session: LevelSession) -> void:
	pass


func _think(session: LevelSession) -> void:
	_timer += 1
	if _wait > 0:
		_wait -= 1
		if _wait == 0:
			velocity = _next_velocity
		return
	var moved_x := session.collision.sweep_x(hitbox(), velocity.x)
	position.x += moved_x
	var moved_y := session.collision.sweep_y(hitbox(), velocity.y)
	position.y += moved_y
	if moved_x != velocity.x:
		_stopped(Vector2(signf(velocity.x), 0.0))
	elif moved_y != velocity.y:
		_stopped(Vector2(0.0, signf(velocity.y)))


func _stopped(direction: Vector2) -> void:
	if direction == Vector2.ZERO or is_waiting():
		return
	if direction.y > 0.0:
		# A floor: straight back up (Choco).
		velocity = Vector2(0.0, -SPEED)
		return
	# A wall: back the other way; a ceiling: down again. Both after a wait.
	velocity = Vector2.ZERO
	_next_velocity = -direction * SPEED
	_wait = WAIT_TICKS
