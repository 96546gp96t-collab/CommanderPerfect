class_name Keen2Body
extends KeenBody
## Keen in a Keen 2 level. He moves exactly as in Keen 1 ([KeenBody]); the
## one thing Keen 2 adds is the stun of a Vorticon youth ([Keen2Youth]).
##
## A stunned Keen is knocked up as high as a full jump, puts the pogo stick
## away and faces the way the youth ran. For [constant STUN_TICKS] ticks he
## ignores every button, but he still falls and slows down as usual: the
## stun only takes the buttons away. He lies dazed (frames 28 and 29 in
## turn) and, for the last [constant GETTING_UP_TICKS] ticks, gets up
## (frame 31). An enemy shot does not kill a stunned Keen; it only cuts the
## stun short ([method shorten_stun]).
##
## Keen 1's ice ([method KeenBody.freeze]) looks alike, but its frames change
## at another pace, it plays a sound and pushes Keen; that is why the stun is
## its own state here instead of a frozen Keen. Keen 1 never makes a
## Keen2Body, so its Keen is not touched by any of this.

## How long a stun lasts, and how much is left after a shot. estimate
## (Commander Genius, docs/keen2/research.md section 5).
const STUN_TICKS := 250  # estimate
const STUN_SHORTENED_TICKS := 20  # estimate
## Ticks per dazed frame, and the last ticks in which Keen gets up.
const STUN_FRAME_TICKS := 26  # estimate
const GETTING_UP_TICKS := 20  # estimate
## The knock up is as strong as a full jump.
const STUN_JUMP_SPEED := KeenPhysics.JUMP_SPEED  # estimate
## Keen 2's sprites KEENSICLE1/2 (dazed) and KEENGETSUP.
const SPRITE_STUNNED := 28
const STUNNED_FRAMES := 2
const SPRITE_GETTING_UP := 31

var _stun_ticks := 0


## Keen 2's Keen at [param start] (top left of the sprite), moving through
## [param level_collision]. The Keen 2 counterpart of [method KeenBody.create].
static func placed(level_collision: LevelCollision, start: Vector2) -> Keen2Body:
	var body := Keen2Body.new()
	body.collision = level_collision
	body.reset(start)
	return body


func reset(start: Vector2) -> void:
	_stun_ticks = 0
	super.reset(start)


## Stuns Keen (a Vorticon youth ran into him); he faces [param direction].
## Nothing happens while he is stunned already, dead, walking out or in god
## mode.
func stun(direction: int) -> void:
	if is_dead or invincible or state == State.EXITING or is_stunned():
		return
	_stun_ticks = STUN_TICKS
	facing = direction
	on_pogo = false
	bounce(STUN_JUMP_SPEED)


func is_stunned() -> bool:
	return _stun_ticks > 0 and not is_dead and state != State.EXITING


## An enemy shot hit the stunned Keen: he gets up sooner.
func shorten_stun() -> void:
	_stun_ticks = mini(_stun_ticks, STUN_SHORTENED_TICKS)


func step(input: KeenInput) -> void:
	if is_stunned():
		_stun_ticks -= 1
		input = KeenInput.create(0)
	super.step(input)


func sprite_index() -> int:
	if not is_stunned():
		return super.sprite_index()
	if _stun_ticks <= GETTING_UP_TICKS:
		return SPRITE_GETTING_UP
	var dazed_for := STUN_TICKS - _stun_ticks
	return SPRITE_STUNNED + (dazed_for / STUN_FRAME_TICKS) % STUNNED_FRAMES
