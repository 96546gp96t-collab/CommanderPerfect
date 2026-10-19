class_name Keen3Body
extends Keen2Body
## Keen in a Keen 3 level. He moves exactly as in Keen 1 and 2 ([KeenBody],
## the shared physics, unchanged); Keen 3 adds the ankh and its own stun.
## It extends [Keen2Body] for the session's sake (riding, [method
## Keen2Body.is_stunned]), but replaces Keen 2's stun.
##
## The ankh (behaviour 27) protects Keen for [constant ANKH_TICKS] ticks;
## another ankh adds its time to what is left. While it runs
## ([method is_protected]) nothing kills him (deadly tiles, the enemies and
## their shots, which all go through [method KeenBody.kill]) and
## nothing stuns him. Falling out of the level still kills him: that does
## not go through [method KeenBody.kill]. The time only counts down in
## [method step], so only while the game runs (not behind a window or a
## menu). Every level starts with a new Keen and so without the ankh.
##
## While the ankh runs, a halo is drawn around Keen ([method halo_sprite],
## shown by [Keen3AnkhShield]): sprites 61 and 62 in turn; in the last
## [constant ANKH_BLINK_TICKS] ticks it blinks.
##
## Keen 3's own stun (Choco; a youth runs into him, [method stun_with]):
## he takes the youth's speed (sideways at most [constant STUN_SLIDE_SPEED]),
## ignores every button, lies [constant STUN_LYING_TICKS] ticks (frames 28 and 29
## in turn every [constant DAZED_FRAME_TICKS]) while he slides to a stop
## ([constant STUN_FRICTION], also in the air) and falls, then gets up
## (frame 30, KEENMELT; Keen 3 has no KEENSBACK) for
## [constant STUN_GETTING_UP_TICKS]. It is not Keen 2's stun: no knock up,
## and a shot does not cut it short but kills him ([Keen3LevelSession]). A
## stunned Keen still dies to everything deadly; the ankh prevents the stun.
##
## Three of Keen's sounds differ from what [KeenBody] plays (Choco
## `CVort_think_keen_ground`, `_jump_air`, `_pogo_air`, `_pogo_ground`;
## milestone C8): a pogo bounce sounds as a jump ([method sound_for]),
## walking off a ledge plays PLUMMETSND, and pushing against a wall in the
## air bumps (KEENBLOKSND) every [constant AIR_BUMP_TICKS].

## How long one ankh protects: 1400 clock ticks of 145.65 Hz (Choco), 9.6
## seconds, 577 of our ticks.
const ANKH_TICKS := 577
## The halo blinks in the last 250 clock ticks (Choco).
const ANKH_BLINK_TICKS := 103
## The halo changes its picture every 16 clock ticks (Choco).
const HALO_FRAME_TICKS := 6.6
const SPRITE_HALO := 61
const HALO_FRAMES := 2
## The halo (32x40) is drawn this far up and left of Keen's sprite (Choco).
const HALO_OFFSET := Vector2(-8, -8)
## The status screen shows the ankh time in whole "seconds" of 144 clock
## ticks (Choco): 59.3 of our ticks. A fresh ankh shows 9.
const TICKS_PER_ANKH_SECOND := 59.3
## Keen 3's sprite for getting up after a stun (KEENMELT).
const SPRITE_MELT := 30
## The stun: 400 clock ticks lying, 40 getting up, frames every 32 (Choco).
const STUN_LYING_TICKS := 165.0
const STUN_GETTING_UP_TICKS := 16.5
const DAZED_FRAME_TICKS := 13.2
## The youth's speed is cut to 120 by the original's steering helper, and
## falls by 3 per clock tick (Choco), both through that helper.
const STUN_SLIDE_SPEED := 66.7 * KeenPhysics.SUBPIXEL
const STUN_FRICTION := 4.05 * KeenPhysics.SUBPIXEL
## Gravity while stunned, as for the enemies: 3 per clock tick (Choco).
const STUN_GRAVITY := 4.05 * KeenPhysics.SUBPIXEL
const STUN_MAX_FALL := 111 * KeenPhysics.SUBPIXEL
## The original bumps against a wall in the air in every other window of 16
## clock ticks (Choco): once per 32 clock ticks, 13.2 of our ticks. That the
## first bump sounds at once is our reading.
const AIR_BUMP_TICKS := 13.2

## Ticks of protection left; 0 without the ankh.
var ankh_ticks := 0
## Ticks since the halo appeared, for its pictures.
var _halo_ticks := 0
## Ticks since the stun began; -1 when Keen is not stunned.
var _stunned_for := -1
## Ticks until a bump against a wall in the air sounds again.
var _air_bump_wait := 0.0


## Keen 3's Keen at [param start] (top left of the sprite), moving through
## [param level_collision]. The Keen 3 counterpart of
## [method Keen2Body.placed].
static func spawned(level_collision: LevelCollision, start: Vector2) -> Keen3Body:
	var body := Keen3Body.new()
	body.collision = level_collision
	body.reset(start)
	return body


func reset(start: Vector2) -> void:
	ankh_ticks = 0
	_halo_ticks = 0
	_stunned_for = -1
	_air_bump_wait = 0.0
	super.reset(start)


## The sound Keen 3 plays for [param sound] of [KeenBody]: a pogo bounce
## sounds as a jump (Choco plays KEENJUMPSND there, never KEENPOGOSND).
static func sound_for(sound: Sound.Id) -> Sound.Id:
	return Sound.Id.KEEN_JUMP if sound == Sound.Id.KEEN_POGO else sound


## Keen picked up an ankh: its time adds to what is left.
func add_ankh() -> void:
	if ankh_ticks <= 0:
		_halo_ticks = 0
	ankh_ticks += ANKH_TICKS


## Whether the ankh protects Keen now: nothing kills or stuns him then,
## except falling out of the level.
func is_protected() -> bool:
	return ankh_ticks > 0 and not is_dead


## The ankh time as the status screen shows it, in whole "seconds".
func ankh_seconds() -> int:
	return floori(ankh_ticks / TICKS_PER_ANKH_SECOND)


## Kills Keen, unless the ankh protects him.
func kill() -> void:
	if is_protected():
		return
	super.kill()


## Stuns Keen as a youth running toward [param direction] would.
func stun(direction: int) -> void:
	stun_with(Vector2(direction * STUN_SLIDE_SPEED, 0.0))


## Stuns Keen with [param speed], the speed of the youth that ran into him.
## Nothing happens while the ankh protects him, while he is stunned already,
## dead, walking out or in god mode.
func stun_with(speed: Vector2) -> void:
	if is_protected() or is_dead or invincible or state == State.EXITING or is_stunned():
		return
	_stunned_for = 0
	on_pogo = false
	_shoot_timer = 0
	velocity = Vector2(clampf(speed.x, -STUN_SLIDE_SPEED, STUN_SLIDE_SPEED), speed.y)


func is_stunned() -> bool:
	return _stunned_for >= 0 and not is_dead and state != State.EXITING


## Keen 3's stun is not cut short by a shot; the shot kills him instead.
func shorten_stun() -> void:
	pass


## A stunned Keen cannot walk out through the exit.
func can_exit() -> bool:
	return super.can_exit() and not is_stunned()


func step(input: KeenInput) -> void:
	if is_protected():
		ankh_ticks -= 1
		_halo_ticks += 1
	_air_bump_wait = maxf(_air_bump_wait - 1.0, 0.0)
	if is_stunned():
		_lie_stunned()
		return
	super.step(input)


## The halo's sprite now, or -1 when none is drawn: no ankh, or the dark
## half of a blink. When to blink is the original's; how the blink looks
## (every other picture left out) is an estimate.
func halo_sprite() -> int:
	if not is_protected():
		return -1
	var frame := floori(_halo_ticks / HALO_FRAME_TICKS) % HALO_FRAMES
	if ankh_ticks <= ANKH_BLINK_TICKS and frame == 1:  # estimate
		return -1
	return SPRITE_HALO + frame


func sprite_index() -> int:
	if not is_stunned():
		return super.sprite_index()
	if _stunned_for >= STUN_LYING_TICKS:
		return SPRITE_MELT
	return SPRITE_STUNNED + floori(_stunned_for / DAZED_FRAME_TICKS) % STUNNED_FRAMES


## Walking off a ledge plays PLUMMETSND (not on the pogo stick).
func _stand(input: KeenInput) -> void:
	if not on_pogo and collision.floor_under(hitbox()) == TileProperties.Floor.NONE:
		sound_played.emit(Sound.Id.PLUMMET)
	super._stand(input)


## Moves Keen sideways; a wall in the way in the air bumps.
func _move_horizontally() -> bool:
	var free := super._move_horizontally()
	if not free and state in [State.RISING, State.FALLING] and _air_bump_wait <= 0.0:
		_air_bump_wait = AIR_BUMP_TICKS
		sound_played.emit(Sound.Id.KEEN_BLOCKED)
	return free


## One tick of the stun: slide, fall, and get up at the end.
func _lie_stunned() -> void:
	fired = false
	_stunned_for += 1
	velocity.x = move_toward(velocity.x, 0.0, STUN_FRICTION)
	var moved_x := collision.sweep_x(hitbox(), velocity.x)
	position.x += moved_x
	if moved_x != velocity.x:
		velocity.x = 0.0
	velocity.y = minf(velocity.y + STUN_GRAVITY, STUN_MAX_FALL)
	var moved_y := collision.sweep_y(hitbox(), velocity.y)
	position.y += moved_y
	if moved_y != velocity.y:
		velocity.y = 0.0
	var standing := (
		velocity.y >= 0.0 and collision.floor_under(hitbox()) != TileProperties.Floor.NONE
	)
	state = State.STANDING if standing else State.FALLING
	if _stunned_for >= STUN_LYING_TICKS + STUN_GETTING_UP_TICKS:
		_get_up(standing)
	_check_fatal_tiles()


func _get_up(standing: bool) -> void:
	_stunned_for = -1
	if standing:
		_enter_ground_state(State.STANDING)
	else:
		_start_falling(velocity.y, KeenPhysics.LEDGE_FALL_ACCELERATION, false)


## Falling out of the level and deadly tiles, as [method KeenBody.step]
## checks them.
func _check_fatal_tiles() -> void:
	var box := hitbox()
	if collision.is_below_level(box):
		is_dead = true
		death_finished = true
		sound_played.emit(Sound.Id.PLUMMET)
	elif collision.touches_deadly_tile(box):
		kill()
