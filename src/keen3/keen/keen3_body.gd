class_name Keen3Body
extends Keen2Body
## Keen in a Keen 3 level. He moves exactly as in Keen 1 and 2 ([KeenBody],
## the shared physics, unchanged) and can be stunned as in Keen 2
## ([Keen2Body]); Keen 3 adds the ankh.
##
## The ankh (behaviour 27) protects Keen for [constant ANKH_TICKS] ticks;
## another ankh adds its time to what is left. While it runs
## ([method is_protected]) nothing kills him (deadly tiles, and in C4 the
## enemies and their shots, which all go through [method KeenBody.kill]) and
## nothing stuns him. Falling out of the level still kills him: that does
## not go through [method KeenBody.kill]. The time only counts down in
## [method step], so only while the game runs (not behind a window or a
## menu). Every level starts with a new Keen and so without the ankh.
##
## While the ankh runs, a halo is drawn around Keen ([method halo_sprite],
## shown by [Keen3AnkhShield]): sprites 61 and 62 in turn; in the last
## [constant ANKH_BLINK_TICKS] ticks it blinks.
##
## Keen 3's stun frames: the last one, getting up, is sprite 30 (KEENMELT;
## Keen 3 has no KEENSBACK). How long a stun lasts is Keen 2's for now
## (milestone C4 gives Keen 3 its own).

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

## Ticks of protection left; 0 without the ankh.
var ankh_ticks := 0
## Ticks since the halo appeared, for its pictures.
var _halo_ticks := 0


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
	super.reset(start)


## Keen picked up an ankh: its time adds to what is left.
func add_ankh() -> void:
	if ankh_ticks <= 0:
		_halo_ticks = 0
	ankh_ticks += ANKH_TICKS


## Whether the ankh protects Keen now: nothing kills or stuns him then,
## except falling out of the level. Enemies (milestone C4) can ask this too.
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


## Stuns Keen, unless the ankh protects him.
func stun(direction: int) -> void:
	if is_protected():
		return
	super.stun(direction)


func step(input: KeenInput) -> void:
	if is_protected():
		ankh_ticks -= 1
		_halo_ticks += 1
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
	var index := super.sprite_index()
	if is_stunned() and index == Keen2Body.SPRITE_GETTING_UP:
		return SPRITE_MELT
	return index
