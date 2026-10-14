class_name Yorp
extends Enemy
## The one-eyed Yorp: harmless, but it gets in the way.
##
##   LOOKING   stands and looks left and right, then sets off towards Keen
##   WALKING   walks and hops now and then; looks around again after a while
##             or when a wall stops it
##   STUNNED   Keen jumped on its head; it lies dazed for a while
## Walking into a Yorp pushes Keen back. One shot kills it.

enum Mode { LOOKING, WALKING, STUNNED }

const SPRITE_STAND := 48
const SPRITE_LOOK_LEFT := 49
const SPRITE_LOOK_RIGHT := 51
const SPRITE_WALK_RIGHT := 52
const SPRITE_WALK_LEFT := 54
const SPRITE_STUNNED := 56
const SPRITE_DYING := 58
const SPRITE_DEAD := 59
## From the sprite table of EGAHEAD.CK1.
const BODY_BOX := Rect2(4, 4, 8, 20)

const WALK_SPEED := 19 * KeenPhysics.SUBPIXEL
const WALK_FRAME_TICKS := 6
## The looking-around frames in order, each shown [constant LOOK_FRAME_TICKS].
const LOOK_FRAMES: PackedInt32Array = [
	SPRITE_LOOK_LEFT, SPRITE_STAND, SPRITE_LOOK_RIGHT, SPRITE_STAND
]
const LOOK_FRAME_TICKS := 16  # estimate
const LOOK_ROUNDS := 2  # estimate
## After walking this many ticks, a Yorp may stop to look around.
const MIN_WALK_TICKS := 50
## Chance per tick that a Yorp on the ground stops to look, or hops.
const LOOK_CHANCE := 1.0 / 30.0
const HOP_CHANCE := 1.0 / 50.0  # estimate
const HOP_SPEED := 40 * KeenPhysics.SUBPIXEL
const STUN_TICKS := 120  # estimate
const STUN_FRAME_TICKS := 6
const PUSH_SPEED := 60 * KeenPhysics.SUBPIXEL
const DIE_POP_SPEED := 40 * KeenPhysics.SUBPIXEL

var mode := Mode.LOOKING
var _timer := 0
var _frame := 0


static func create(start: Vector2) -> Yorp:
	var yorp := Yorp.new()
	yorp.position = start
	yorp.body_box = BODY_BOX
	return yorp


func sprite_index() -> int:
	if is_dead:
		return SPRITE_DEAD if on_ground else SPRITE_DYING
	match mode:
		Mode.LOOKING:
			return LOOK_FRAMES[(_timer / LOOK_FRAME_TICKS) % LOOK_FRAMES.size()]
		Mode.STUNNED:
			return SPRITE_STUNNED + (_timer / STUN_FRAME_TICKS) % 2
	var walk_sprite := SPRITE_WALK_RIGHT if facing > 0 else SPRITE_WALK_LEFT
	return walk_sprite + (_timer / WALK_FRAME_TICKS) % 2


func die() -> void:
	if is_dead:
		return
	super.die()
	velocity.y = -DIE_POP_SPEED


func death_sound() -> Sound.Id:
	return Sound.Id.YORP_SCREAM


func touch_keen(session: LevelSession, keen: KeenBody) -> void:
	if mode == Mode.STUNNED:
		return
	if keen.hitbox().end.y < hitbox().end.y - EgaGraphics.TILE_SIZE:
		# Landed on its head.
		_set_mode(Mode.STUNNED)
		session.play_sound(Sound.Id.YORP_BOP)
		keen.on_pogo = false
		keen.bounce(KeenPhysics.STOMP_BOUNCE_SPEED)
	else:
		if not keen.is_pushed():
			session.play_sound(Sound.Id.YORP_BUMP)
		_push_keen(keen, _direction_to(keen), PUSH_SPEED)


func _think(session: LevelSession) -> void:
	_fall(session)
	if is_dead:
		return
	_timer += 1
	match mode:
		Mode.LOOKING:
			if _timer >= LOOK_ROUNDS * LOOK_FRAMES.size() * LOOK_FRAME_TICKS:
				facing = _direction_to_keen(session)
				_set_mode(Mode.WALKING)
		Mode.STUNNED:
			if _timer >= STUN_TICKS:
				_set_mode(Mode.LOOKING)
		Mode.WALKING:
			_walk_around(session)


func _walk_around(session: LevelSession) -> void:
	if on_ground and _timer > MIN_WALK_TICKS and session.rng.randf() < LOOK_CHANCE:
		_set_mode(Mode.LOOKING)
		return
	if on_ground and session.rng.randf() < HOP_CHANCE:
		velocity.y = -HOP_SPEED
	if not _walk(session, WALK_SPEED):
		_set_mode(Mode.LOOKING)


func _set_mode(new_mode: Mode) -> void:
	mode = new_mode
	_timer = 0
