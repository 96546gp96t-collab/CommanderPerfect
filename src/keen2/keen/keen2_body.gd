class_name Keen2Body
extends KeenBody
## Keen in a Keen 2 level. He moves exactly as in Keen 1 ([KeenBody]); Keen
## 2 adds the stun of a Vorticon youth ([Keen2Youth]) and the switches: the
## pogo button presses a switch near Keen instead of taking out the pogo
## stick ([member switch_user]).
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

## Presses a switch near this Keen, if there is one, and returns whether it
## did ([method Keen2Switches.use_near]). The session sets it; without it
## the pogo button only works the pogo stick.
var switch_user := Callable()
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


## The pogo button presses a switch when there is one near Keen. The pogo
## stick is put away then, and the held button does nothing more until it
## is let go (docs/keen2/research.md section 10, item 13).
func _handle_pogo_button(input: KeenInput) -> void:
	var pressed := input.pogo and not _pogo_was_held
	if not pressed or not switch_user.is_valid() or not switch_user.call(self):
		super._handle_pogo_button(input)
		return
	_pogo_was_held = true
	on_pogo = false
	if state == State.CROUCHING or state == State.POGO_COMPRESSED:
		state = State.STANDING


func sprite_index() -> int:
	if not is_stunned():
		return super.sprite_index()
	if _stun_ticks <= GETTING_UP_TICKS:
		return SPRITE_GETTING_UP
	var dazed_for := STUN_TICKS - _stun_ticks
	return SPRITE_STUNNED + (dazed_for / STUN_FRAME_TICKS) % STUNNED_FRAMES
