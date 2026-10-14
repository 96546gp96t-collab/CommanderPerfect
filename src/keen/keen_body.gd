class_name KeenBody
extends RefCounted
## Keen's movement through a level: walking, jumping, pogo-jumping, sliding
## on ice and bumping into tiles, one fixed tick at a time (see
## [KeenPhysics]). This class only does the logic; [Keen] draws it.
##
## Keen is always in one [enum State]:
##   STANDING         on the ground; walks, slides on ice, starts a jump
##   CROUCHING        winding up for a jump; the longer, the higher
##   RISING           going up after a jump or pogo bounce
##   FALLING          going down, after a jump or off a ledge
##   POGO_COMPRESSED  on the ground on the pogo stick, about to bounce
##   DYING            killed: lies still for a moment, then flies off the screen
## The pogo stick is a separate switch: with it out, Keen keeps bouncing.
## Firing the raygun is one too: Keen holds it out for a moment, and on the
## ground he stands still meanwhile. An ice chunk freezes him: for a while he
## ignores all buttons, but still slides and falls.

enum State { STANDING, CROUCHING, RISING, FALLING, POGO_COMPRESSED, DYING }

var collision: LevelCollision
## Top left of the sprite, in level pixels.
var position := Vector2.ZERO
## Pixels per tick; positive y is down.
var velocity := Vector2.ZERO
## 1 when looking right, -1 when looking left.
var facing := 1
var state := State.FALLING
## Keen 1 starts without the pogo stick; he has to find it first.
var has_pogo := false
var on_pogo := false
## Killed; from then on he only plays the dying animation.
var is_dead := false
## The dying animation is over, or Keen fell out of the level.
var death_finished := false
## Set during a tick in which Keen pulled the trigger. Whether a shot comes
## out depends on the charges, which [LevelSession] keeps.
var fired := false

var _timer := 0
var _crouch_frame := 0
var _walk_frame := 0
var _walk_timer := 0
var _is_walking := false
## In the air because of a jump or bounce, rather than off a ledge.
var _jumped := false
var _fall_acceleration := KeenPhysics.LEDGE_FALL_ACCELERATION
var _pogo_was_held := false
var _fire_was_held := false
var _shoot_timer := 0
var _first_bounce := false
var _death_start_y := 0.0
var _frozen_ticks := 0
## Sideways speed of a push, on top of Keen's own movement.
var _push_speed := 0.0


static func create(level_collision: LevelCollision, start: Vector2) -> KeenBody:
	var body := KeenBody.new()
	body.collision = level_collision
	body.reset(start)
	return body


## Puts Keen at [param start] (top left of the sprite), standing still.
func reset(start: Vector2) -> void:
	position = start
	velocity = Vector2.ZERO
	facing = 1
	on_pogo = false
	is_dead = false
	death_finished = false
	fired = false
	_shoot_timer = 0
	_frozen_ticks = 0
	_push_speed = 0.0
	_start_falling(0.0, KeenPhysics.LEDGE_FALL_ACCELERATION, false)


## The box that collides with tiles, in level pixels.
func hitbox() -> Rect2:
	return Rect2(position + KeenPhysics.HITBOX.position, KeenPhysics.HITBOX.size)


## Whether Keen is holding the raygun out after firing.
func is_shooting() -> bool:
	return _shoot_timer > 0


## Kills Keen: he starts the dying animation. Nothing happens if he is
## already dead.
func kill() -> void:
	if is_dead:
		return
	is_dead = true
	on_pogo = false
	state = State.DYING
	_timer = 0
	_death_start_y = position.y
	velocity = Vector2(-facing * KeenPhysics.DIE_DRIFT_SPEED, -KeenPhysics.DIE_RISE_SPEED)


func is_frozen() -> bool:
	return _frozen_ticks > 0


## Pushes Keen sideways with [param speed] (pixels per tick; negative is
## left), for example when a robot walks into him. The push dies down by
## itself; until then Keen cannot walk.
func push(speed: float) -> void:
	_push_speed = speed
	velocity.x = 0.0


## Makes Keen hop up from where he is, for example off a Yorp's head.
func bounce(speed: float) -> void:
	if not is_dead:
		_launch(speed)


## Freezes Keen in a block of ice and pushes him with [param push_speed].
func freeze(push_speed: float) -> void:
	if is_dead:
		return
	_frozen_ticks = KeenPhysics.FROZEN_TICKS
	on_pogo = false
	_shoot_timer = 0
	velocity.x = push_speed
	if state == State.CROUCHING or state == State.POGO_COMPRESSED:
		_enter_ground_state(State.STANDING)


## Advances one tick with the buttons in [param input].
func step(input: KeenInput) -> void:
	fired = false
	if state == State.DYING:
		_die()
		return
	if is_dead:
		return
	if _frozen_ticks > 0:
		_frozen_ticks -= 1
		input = KeenInput.create(0)
	elif _push_speed != 0.0:
		input = KeenInput.create(0, input.jump, input.pogo, input.fire)
	_apply_push()
	_handle_fire_button(input)
	_handle_pogo_button(input)
	if is_shooting() and state == State.STANDING:
		input = KeenInput.create(0)
	match state:
		State.STANDING:
			_stand(input)
		State.CROUCHING:
			_crouch(input)
		State.POGO_COMPRESSED:
			_compress(input)
		State.RISING:
			_rise(input)
		State.FALLING:
			_fall(input)
	var box := hitbox()
	if collision.is_below_level(box):
		is_dead = true
		death_finished = true
	elif collision.touches_deadly_tile(box):
		kill()


## Top left of a raygun shot fired now: just in front of the raygun.
func shot_position() -> Vector2:
	var box := hitbox()
	var y := position.y + KeenPhysics.SHOT_HEIGHT
	if facing > 0:
		return Vector2(box.end.x + velocity.x, y)
	return Vector2(box.position.x + velocity.x - KeenPhysics.SHOT_SIZE.x, y)


## Number of the sprite to draw, see the sprite constants in [KeenPhysics].
func sprite_index() -> int:
	var right := facing > 0
	if state == State.DYING:
		return (
			KeenPhysics.SPRITE_DEAD
			+ (_timer / KeenPhysics.DIE_FRAME_TICKS) % KeenPhysics.DEAD_FRAMES
		)
	if is_frozen():
		return _frozen_sprite()
	if is_shooting():
		return KeenPhysics.SPRITE_SHOOT_RIGHT if right else KeenPhysics.SPRITE_SHOOT_LEFT
	if on_pogo:
		var compressed := 1 if state == State.POGO_COMPRESSED else 0
		return (
			(KeenPhysics.SPRITE_POGO_RIGHT if right else KeenPhysics.SPRITE_POGO_LEFT) + compressed
		)
	return _moving_sprite()


func _frozen_sprite() -> int:
	if _frozen_ticks <= KeenPhysics.THAW_TICKS:
		return KeenPhysics.SPRITE_THAWING
	var frame := (_frozen_ticks / KeenPhysics.FROZEN_FRAME_TICKS) % KeenPhysics.FROZEN_FRAMES
	return KeenPhysics.SPRITE_FROZEN + frame


## Walking, standing, crouching or in the air.
func _moving_sprite() -> int:
	var right := facing > 0
	var jump_sprite := KeenPhysics.SPRITE_JUMP_RIGHT if right else KeenPhysics.SPRITE_JUMP_LEFT
	match state:
		State.CROUCHING:
			return jump_sprite + _crouch_frame
		State.RISING, State.FALLING:
			return jump_sprite + KeenPhysics.CROUCH_FRAMES
	return (KeenPhysics.SPRITE_WALK_RIGHT if right else KeenPhysics.SPRITE_WALK_LEFT) + _walk_frame


func _apply_push() -> void:
	if _push_speed == 0.0:
		return
	var moved := collision.sweep_x(hitbox(), _push_speed)
	position.x += moved
	if moved != _push_speed:
		_push_speed = 0.0
	_push_speed = move_toward(_push_speed, 0.0, KeenPhysics.PUSH_DECELERATION)


## The fire button fires once per press, and not again until the raygun has
## almost been put away. Firing puts the pogo stick away.
func _handle_fire_button(input: KeenInput) -> void:
	var pressed := input.fire and not _fire_was_held
	_fire_was_held = input.fire
	if _shoot_timer > 0:
		_shoot_timer -= 1
	if not pressed or _shoot_timer >= KeenPhysics.SHOOT_REPEAT_TICKS:
		return
	fired = true
	_shoot_timer = KeenPhysics.SHOOT_FRAME_TICKS
	on_pogo = false
	if state == State.CROUCHING or state == State.POGO_COMPRESSED:
		state = State.STANDING


## Lies still for a moment, then flies up and off the screen, through
## everything.
func _die() -> void:
	_timer += 1
	if _timer <= KeenPhysics.DIE_WAIT_TICKS:
		return
	position += velocity
	if _death_start_y - position.y >= KeenPhysics.DIE_RISE_DISTANCE:
		death_finished = true


## The pogo button takes the stick out or puts it away, once per press.
func _handle_pogo_button(input: KeenInput) -> void:
	var pressed := input.pogo and not _pogo_was_held
	_pogo_was_held = input.pogo
	if not pressed or not has_pogo:
		return
	on_pogo = not on_pogo
	_first_bounce = on_pogo
	if state == State.CROUCHING or state == State.POGO_COMPRESSED:
		state = State.STANDING


func _stand(input: KeenInput) -> void:
	var floor_type := collision.floor_under(hitbox())
	if floor_type == TileProperties.Floor.NONE:
		_start_falling(
			KeenPhysics.LEDGE_FALL_START_SPEED, KeenPhysics.LEDGE_FALL_ACCELERATION, false
		)
		_fall(input)
	elif on_pogo:
		_enter_ground_state(State.POGO_COMPRESSED)
	elif input.jump:
		_enter_ground_state(State.CROUCHING)
		_crouch_frame = 0
		if floor_type != TileProperties.Floor.ICE:
			velocity.x = 0.0
	elif floor_type == TileProperties.Floor.ICE:
		_slide_on_ice(input)
	else:
		_walk(input, floor_type)


func _walk(input: KeenInput, floor_type: TileProperties.Floor) -> void:
	if input.direction == 0:
		if floor_type != TileProperties.Floor.SLIPPERY:
			velocity.x = move_toward(velocity.x, 0.0, KeenPhysics.GROUND_FRICTION)
		_stop_walk_animation()
	else:
		facing = input.direction
		if signf(velocity.x) == -input.direction:
			velocity.x = 0.0
		if absf(velocity.x) < KeenPhysics.WALK_START_SPEED:
			velocity.x = input.direction * KeenPhysics.WALK_START_SPEED
		var target := input.direction * KeenPhysics.WALK_MAX_SPEED
		velocity.x = move_toward(velocity.x, target, KeenPhysics.WALK_ACCELERATION)
		_advance_walk_animation()
	_move_horizontally()


## On ice Keen cannot stop or turn: he slides at full speed the way he faces,
## until a wall stops him. Only then can he walk away.
func _slide_on_ice(input: KeenInput) -> void:
	_stop_walk_animation()
	var blocked := is_zero_approx(collision.sweep_x(hitbox(), facing * KeenPhysics.SUBPIXEL))
	if blocked:
		if input.direction == 0:
			velocity.x = 0.0
			return
		facing = input.direction
	velocity.x = facing * KeenPhysics.WALK_MAX_SPEED
	_move_horizontally()


func _crouch(input: KeenInput) -> void:
	_timer += 1
	if _timer < KeenPhysics.CROUCH_FRAME_TICKS:
		return
	_timer = 0
	if input.jump and _crouch_frame < KeenPhysics.CROUCH_FRAMES:
		_crouch_frame += 1
		return
	var strength := maxi(_crouch_frame, 1) / float(KeenPhysics.CROUCH_FRAMES)
	# On ice Keen keeps sliding; elsewhere the jump sets his sideways speed.
	if collision.floor_under(hitbox()) != TileProperties.Floor.ICE:
		velocity.x = input.direction * KeenPhysics.JUMP_HORIZONTAL_SPEED
	if input.direction != 0:
		facing = input.direction
	_launch(KeenPhysics.JUMP_SPEED * strength)


func _compress(input: KeenInput) -> void:
	if input.direction != 0:
		facing = input.direction
	_timer += 1
	if _timer < KeenPhysics.POGO_COMPRESS_TICKS:
		return
	var speed := KeenPhysics.POGO_LOW_SPEED
	if input.jump:
		speed = (
			KeenPhysics.POGO_FIRST_BOUNCE_SPEED if _first_bounce else KeenPhysics.POGO_HIGH_SPEED
		)
	_first_bounce = false
	_launch(speed)


func _launch(speed: float) -> void:
	state = State.RISING
	_jumped = true
	velocity.y = -speed


func _rise(input: KeenInput) -> void:
	_steer_in_air(input)
	_move_horizontally()
	var moved := collision.sweep_y(hitbox(), velocity.y)
	position.y += moved
	if moved != velocity.y:
		# Bumped his head: the upward speed drops off quickly, but not at once.
		velocity.y /= 2.0
		if velocity.y > -KeenPhysics.SUBPIXEL:
			velocity.y = 0.0
	else:
		velocity.y += KeenPhysics.JUMP_DECELERATION
	if velocity.y >= 0.0:
		_start_falling(0.0, KeenPhysics.JUMP_FALL_ACCELERATION, true)


func _fall(input: KeenInput) -> void:
	_steer_in_air(input)
	_move_horizontally()
	velocity.y = minf(velocity.y + _fall_acceleration, KeenPhysics.MAX_FALL_SPEED)
	var moved := collision.sweep_y(hitbox(), velocity.y)
	position.y += moved
	if moved != velocity.y:
		velocity.y = 0.0
		_enter_ground_state(State.POGO_COMPRESSED if on_pogo else State.STANDING)


func _start_falling(speed: float, acceleration: float, after_jump: bool) -> void:
	state = State.FALLING
	velocity.y = speed
	_fall_acceleration = acceleration
	_jumped = after_jump
	_stop_walk_animation()


func _enter_ground_state(new_state: State) -> void:
	state = new_state
	_timer = 0


## Sideways control in the air. It is weaker than on the ground, and differs
## between jumping, bouncing on the pogo stick and falling off a ledge.
func _steer_in_air(input: KeenInput) -> void:
	if input.direction != 0:
		facing = input.direction
	if input.direction == 0:
		var friction := KeenPhysics.AIR_FRICTION if _jumped else KeenPhysics.AIR_FRICTION / 2.0
		# The pogo stick keeps its speed, unless it is above walking speed.
		if not on_pogo or absf(velocity.x) > KeenPhysics.WALK_MAX_SPEED:
			velocity.x = move_toward(velocity.x, 0.0, friction)
	elif on_pogo:
		velocity.x += input.direction * KeenPhysics.POGO_AIR_CONTROL
	elif _jumped:
		if signf(velocity.x) == -input.direction:
			velocity.x = 0.0
		velocity.x += input.direction * KeenPhysics.JUMP_AIR_CONTROL
	else:
		_steer_off_ledge(input.direction)
	velocity.x = clampf(velocity.x, -KeenPhysics.WALK_MAX_SPEED, KeenPhysics.WALK_MAX_SPEED)


## Falling off a ledge while walking keeps at least half of the walking speed.
func _steer_off_ledge(direction: int) -> void:
	var half_speed := KeenPhysics.WALK_MAX_SPEED / 2.0
	if signf(velocity.x) == direction and absf(velocity.x) < half_speed:
		velocity.x = direction * half_speed
	else:
		velocity.x += direction * KeenPhysics.LEDGE_AIR_CONTROL


func _move_horizontally() -> void:
	var moved := collision.sweep_x(hitbox(), velocity.x)
	position.x += moved
	if moved != velocity.x:
		velocity.x = 0.0


func _advance_walk_animation() -> void:
	if not _is_walking:
		_is_walking = true
		_walk_frame = 1
		_walk_timer = 0
		return
	_walk_timer += 1
	if _walk_timer >= KeenPhysics.WALK_FRAME_TICKS:
		_walk_timer = 0
		_walk_frame = (_walk_frame + 1) % KeenPhysics.WALK_FRAMES


func _stop_walk_animation() -> void:
	_is_walking = false
	_walk_frame = 0
	_walk_timer = 0
