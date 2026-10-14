class_name Garg
extends Enemy
## The Garg: looks around, and as soon as it sees Keen at its own height it
## charges at him, jumping over gaps. Touching it is deadly; one shot kills
## it.
##
##   LOOKING   stands still and looks around
##   WALKING   wanders slowly; turns at walls and ledges
##   CHARGING  runs at Keen; jumps at ledges, stops at walls

enum Mode { LOOKING, WALKING, CHARGING }

const SPRITE_LOOK := 60
const LOOK_FRAMES := 4
const SPRITE_WALK_RIGHT := 64
const SPRITE_WALK_LEFT := 66
const SPRITE_DYING := 68
const SPRITE_DEAD := 69
## From the sprite table of EGAHEAD.CK1.
const BODY_BOX := Rect2(4, 4, 12, 28)

const WALK_SPEED := 19 * KeenPhysics.SUBPIXEL
const WALK_FRAME_TICKS := 5
const CHARGE_SPEED := 68 * KeenPhysics.SUBPIXEL
const CHARGE_FRAME_TICKS := 7
const JUMP_SPEED := 96 * KeenPhysics.SUBPIXEL
const LOOK_FRAME_TICKS := 17
const LOOK_ROUNDS := 3
## While wandering, a Garg checks this often whether Keen is at its height.
const SEARCH_TICKS := 50
## A Garg wanders at least this long before it may stop to look around.
const MIN_WALK_TICKS := 100
const LOOK_CHANCE := 1.0 / 100.0
const DIE_POP_SPEED := 40 * KeenPhysics.SUBPIXEL

var mode := Mode.LOOKING
var _timer := 0


static func create(start: Vector2) -> Garg:
	var garg := Garg.new()
	garg.position = start
	garg.body_box = BODY_BOX
	return garg


func sprite_index() -> int:
	if is_dead:
		return SPRITE_DEAD if on_ground else SPRITE_DYING
	if mode == Mode.LOOKING:
		return SPRITE_LOOK + (_timer / LOOK_FRAME_TICKS) % LOOK_FRAMES
	var frame_ticks := CHARGE_FRAME_TICKS if mode == Mode.CHARGING else WALK_FRAME_TICKS
	var walk_sprite := SPRITE_WALK_RIGHT if facing > 0 else SPRITE_WALK_LEFT
	return walk_sprite + (_timer / frame_ticks) % 2


func death_sound() -> Sound.Id:
	return Sound.Id.GARG_SCREAM


func die() -> void:
	if is_dead:
		return
	super.die()
	velocity.y = -DIE_POP_SPEED


func _think(session: LevelSession) -> void:
	_fall(session)
	if is_dead:
		return
	_timer += 1
	match mode:
		Mode.LOOKING:
			if _timer >= LOOK_ROUNDS * LOOK_FRAMES * LOOK_FRAME_TICKS:
				_after_looking(session)
		Mode.WALKING:
			_wander(session)
		Mode.CHARGING:
			_charge(session)


func _after_looking(session: LevelSession) -> void:
	if _keen_at_same_height(session):
		facing = _direction_to_keen(session)
		_set_mode(Mode.CHARGING)
	else:
		facing = 1 if session.rng.randf() < 0.5 else -1
		_set_mode(Mode.WALKING)


func _wander(session: LevelSession) -> void:
	if _timer % SEARCH_TICKS == 0 and _keen_at_same_height(session):
		_set_mode(Mode.LOOKING)
		return
	if on_ground and _timer > MIN_WALK_TICKS and session.rng.randf() < LOOK_CHANCE:
		_set_mode(Mode.LOOKING)
		return
	if _at_ledge(session) or not _walk(session, WALK_SPEED):
		facing = -facing


func _charge(session: LevelSession) -> void:
	if _at_ledge(session):
		velocity.y = -JUMP_SPEED
	if not _walk(session, CHARGE_SPEED):
		_set_mode(Mode.LOOKING)


func _set_mode(new_mode: Mode) -> void:
	mode = new_mode
	_timer = 0
