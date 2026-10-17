class_name Keen2Grunt
extends Keen2Enemy
## The Vorticon grunt of Keen 2 (info value 1). It behaves as the Vorticons
## of the original do (docs/keen2/research.md section 5), which our Keen 1
## [Vorticon] simplifies; that is why it is its own class.
##
##   LOOKING  stands and looks around (two frames); then it sets off, towards
##            Keen when he is near, and away from a wall it stands against
##   WALKING  walks and jumps at random; at a wall it looks around, or, when
##            it hit a wall only a moment ago, jumps out of the pit it is in
##   JUMPING  in the air, still moving on; looks around when it lands
## It walks off ledges. It does not jump in the dark. Touching it is deadly;
## one shot kills it: frame 86 for a moment, then the corpse 87. No white
## flash as in Keen 1.

enum Mode { LOOKING, WALKING, JUMPING }

const SPRITE_WALK_LEFT := 74
const SPRITE_WALK_RIGHT := 78
const WALK_FRAMES := 4
const SPRITE_LOOK := 82
const LOOK_FRAMES := 2
## The names in EGAHEAD.CK2 (VORTJUMPL, VORTJUMPR); Commander Genius has
## them the other way round (docs/keen2/research.md section 5).
const SPRITE_JUMP_LEFT := 84
const SPRITE_JUMP_RIGHT := 85
const SPRITE_DYING := 86
const SPRITE_DEAD := 87
## The collision box inside the sprite, from the sprite table of
## EGAHEAD.CK2.
const BODY_BOX := Rect2(2, 1, 20, 31)

const HEALTH := 1  # estimate
const WALK_SPEED := 28 * Keen2Enemy.SUBPIXEL  # estimate
const WALK_FRAME_TICKS := 5  # estimate
const LOOK_FRAME_TICKS := 16  # estimate
## Chance per tick of a jump while walking (n + 1 in 1000).
const JUMP_CHANCE := 20  # estimate
const MIN_JUMP_SPEED := 90 * Keen2Enemy.SUBPIXEL  # estimate
const MAX_JUMP_SPEED := 149 * Keen2Enemy.SUBPIXEL  # estimate
## Hitting a wall after fewer ticks of walking than this means it is
## trapped; it jumps out with one of these speeds.
const TRAPPED_TICKS := 160  # estimate
const TRAPPED_HIGH_JUMP_SPEED := 150 * Keen2Enemy.SUBPIXEL  # estimate
const TRAPPED_JUMP_SPEEDS: Array[float] = [MIN_JUMP_SPEED, TRAPPED_HIGH_JUMP_SPEED]
## After a look it turns towards Keen when he is this close sideways.
const SIGHT_DISTANCE := 8 * Keen2Enemy.TILE  # estimate
const DYING_TICKS := 26  # estimate

var mode := Mode.LOOKING
## Ticks walked since the last wall.
var _walked := TRAPPED_TICKS + 1


static func create(start: Vector2) -> Keen2Grunt:
	var grunt := Keen2Grunt.new()
	grunt.position = start
	grunt.body_box = BODY_BOX
	grunt.health = HEALTH
	return grunt


func sprite_index() -> int:
	var right := facing > 0
	if is_dead:
		return SPRITE_DEAD if _timer >= DYING_TICKS else SPRITE_DYING
	match mode:
		Mode.LOOKING:
			return SPRITE_LOOK + (_timer / LOOK_FRAME_TICKS) % LOOK_FRAMES
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
		Mode.LOOKING:
			_look(session)
		Mode.WALKING:
			_walk_on(session)
		Mode.JUMPING:
			_walk(session, WALK_SPEED)
			if on_ground:
				_set_mode(Mode.LOOKING)


func _look(session: LevelSession) -> void:
	if _timer < LOOK_FRAMES * LOOK_FRAME_TICKS:
		return
	var keen := session.nearest_keen(hitbox().get_center())
	var toward := _direction_to(keen)
	var distance := absf(keen.hitbox().get_center().x - hitbox().get_center().x)
	if distance <= SIGHT_DISTANCE and not _is_blocked(session, toward):
		facing = toward
	elif _is_blocked(session, facing):
		facing = -facing
	_set_mode(Mode.WALKING)


func _walk_on(session: LevelSession) -> void:
	_walked += 1
	if on_ground and roll(session, JUMP_CHANCE) and _may_jump(session):
		_start_jump(_random_speed(session, MIN_JUMP_SPEED, MAX_JUMP_SPEED))
		return
	if _walk(session, WALK_SPEED):
		return
	if on_ground and _walked < TRAPPED_TICKS and _may_jump(session):
		_start_jump(TRAPPED_JUMP_SPEEDS[session.rng.randi_range(0, 1)])
		return
	_walked = 0
	_set_mode(Mode.LOOKING)


func _may_jump(session: LevelSession) -> bool:
	return not is_dark(session) and not _is_blocked_above(session)


func _start_jump(speed: float) -> void:
	_jump(speed)
	_set_mode(Mode.JUMPING)


func _set_mode(new_mode: Mode) -> void:
	mode = new_mode
	_timer = 0
