class_name Keen2Elite
extends Keen2Enemy
## The Vorticon Elite of Keen 2 (info value 3): a Vorticon with a raygun.
##
##   WALKING  walks; turns at walls (not at ledges: it walks off them).
##            When Keen stands at about its height it mostly turns to him,
##            and when he is also close it charges at double speed. Now and
##            then it jumps, or stops to fire (not in the dark).
##   JUMPING  in the air, still moving on; walks again when it lands
##   AIMING   holds the raygun out, then fires a shot the way it faces
##   FIRED    keeps holding it out for a moment
## Hitting a wall soon after the last one means it is trapped: it jumps.
## Touching it is deadly; it takes [constant HEALTH] shots, and the Guard
## robots' shots do not hurt it. Dying: frame 100 for a while, then the
## corpse 101.

enum Mode { WALKING, JUMPING, AIMING, FIRED }

const SPRITE_WALK_LEFT := 88
const SPRITE_WALK_RIGHT := 92
const WALK_FRAMES := 4
const SPRITE_FIRE_LEFT := 96
const SPRITE_FIRE_RIGHT := 97
## ELITEJUMPL and ELITEJUMPR in EGAHEAD.CK2.
const SPRITE_JUMP_LEFT := 98
const SPRITE_JUMP_RIGHT := 99
const SPRITE_DYING := 100
const SPRITE_DEAD := 101
## The collision box inside the sprite, from the sprite table of
## EGAHEAD.CK2.
const BODY_BOX := Rect2(2, 1, 20, 31)

## Commander Genius has 4 on normal, and an unused constant of 3.
const HEALTH := 4  # estimate
const WALK_SPEED := 31 * Keen2Enemy.SUBPIXEL  # estimate
const CHARGE_SPEED := 62 * Keen2Enemy.SUBPIXEL  # estimate
const WALK_FRAME_TICKS := 7  # estimate
## It sees Keen when his feet are less than this far above or below its
## own, and charges when he is also less than [constant CHARGE_DISTANCE]
## away sideways.
const SIGHT_HEIGHT := 2 * Keen2Enemy.TILE  # estimate
const CHARGE_DISTANCE := 6 * Keen2Enemy.TILE  # estimate
## Out of this many times it turns to a Keen it sees all but once; it aims
## at him all but once out of [constant AIM_ODDS].
const TURN_ODDS := 10  # estimate
const AIM_ODDS := 5  # estimate
## Chances per tick (n + 1 in 1000).
const JUMP_CHANCE := 15  # estimate
const FIRE_CHANCE := 8  # estimate
const MIN_JUMP_SPEED := 90 * Keen2Enemy.SUBPIXEL  # estimate
const MAX_JUMP_SPEED := 149 * Keen2Enemy.SUBPIXEL  # estimate
const TRAPPED_TICKS := 150  # estimate
## Ticks of walking between two shots at least; ticks with the raygun out
## before and after the shot.
const FIRE_COOLDOWN := 26  # estimate
const AIM_TICKS := 23  # estimate
const FIRED_TICKS := 21  # estimate
## The shot leaves this far below the top of the sprite, this far in front.
const SHOT_HEIGHT := 9.0  # estimate
const SHOT_GAP := 1.0  # estimate
const DYING_TICKS := 46  # estimate

var mode := Mode.WALKING
var is_charging := false
var _walked := TRAPPED_TICKS + 1
var _since_shot := 0


static func create(start: Vector2) -> Keen2Elite:
	var elite := Keen2Elite.new()
	elite.position = start
	elite.body_box = BODY_BOX
	elite.health = HEALTH
	return elite


## Whether a shot fired by [param shooter] leaves it unharmed: the Guard
## robots' shots.
static func is_immune_to(shooter: Script) -> bool:
	return shooter == Keen2GuardRobot


func sprite_index() -> int:
	var right := facing > 0
	if is_dead:
		return SPRITE_DEAD if _timer >= DYING_TICKS else SPRITE_DYING
	match mode:
		Mode.AIMING, Mode.FIRED:
			return SPRITE_FIRE_RIGHT if right else SPRITE_FIRE_LEFT
		Mode.JUMPING:
			return SPRITE_JUMP_RIGHT if right else SPRITE_JUMP_LEFT
	var walk_sprite := SPRITE_WALK_RIGHT if right else SPRITE_WALK_LEFT
	return walk_sprite + (_timer / WALK_FRAME_TICKS) % WALK_FRAMES


func die() -> void:
	if not is_dead:
		_timer = 0
	super.die()


func death_sound() -> Sound.Id:
	return Sound.Id.VORTICON_SCREAM


func _think(session: LevelSession) -> void:
	_fall(session)
	_timer += 1
	if is_dead:
		return
	match mode:
		Mode.WALKING:
			_walk_on(session)
		Mode.JUMPING:
			_walk(session, _speed())
			if on_ground:
				_set_mode(Mode.WALKING)
		Mode.AIMING:
			if _timer >= AIM_TICKS:
				_fire_shot(session, _shot_start(SHOT_HEIGHT, SHOT_GAP), Sound.Id.KEEN_FIRE)
				_set_mode(Mode.FIRED)
		Mode.FIRED:
			if _timer >= FIRED_TICKS:
				_since_shot = 0
				_set_mode(Mode.WALKING)


func _walk_on(session: LevelSession) -> void:
	_watch_keen(session)
	if on_ground and not is_dark(session) and _decide(session):
		return
	_walked += 1
	if _walk(session, _speed()):
		return
	facing = -facing
	if on_ground and _walked < TRAPPED_TICKS and not is_dark(session):
		_start_jump(session)
		return
	_walked = 0


## Turns to a Keen at about its height and charges when he is close.
func _watch_keen(session: LevelSession) -> void:
	var keen := session.nearest_keen(hitbox().get_center())
	is_charging = false
	if keen.is_dead or absf(keen.hitbox().end.y - hitbox().end.y) >= SIGHT_HEIGHT:
		return
	if session.rng.randi_range(1, TURN_ODDS) != 1:
		facing = _direction_to(keen)
	var distance := absf(keen.hitbox().get_center().x - hitbox().get_center().x)
	is_charging = distance < CHARGE_DISTANCE


## Maybe jumps or starts to aim. Returns true when it did.
func _decide(session: LevelSession) -> bool:
	if roll(session, JUMP_CHANCE) and not _is_blocked_above(session):
		_start_jump(session)
		return true
	if _since_shot < FIRE_COOLDOWN:
		_since_shot += 1
		return false
	if not roll(session, FIRE_CHANCE):
		return false
	if session.rng.randi_range(1, AIM_ODDS) != 1:
		facing = _direction_to_keen(session)
	_set_mode(Mode.AIMING)
	return true


func _start_jump(session: LevelSession) -> void:
	_jump(_random_speed(session, MIN_JUMP_SPEED, MAX_JUMP_SPEED))
	_set_mode(Mode.JUMPING)


func _speed() -> float:
	return CHARGE_SPEED if is_charging else WALK_SPEED


func _set_mode(new_mode: Mode) -> void:
	mode = new_mode
	_timer = 0
