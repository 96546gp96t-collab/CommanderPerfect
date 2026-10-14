class_name Vorticon
extends Enemy
## A Vorticon: walks around, turns towards Keen now and then, and jumps high
## at random. Touching it is deadly, and it takes several shots. The Vorticon
## in the last level is their commander, who takes many more.

const SPRITE_WALK_LEFT := 70
const SPRITE_WALK_RIGHT := 74
const WALK_FRAMES := 4
const SPRITE_JUMP_LEFT := 80
const SPRITE_JUMP_RIGHT := 81
const SPRITE_DYING := 82
const DYING_FRAMES := 6
## From the sprite table of EGAHEAD.CK1.
const BODY_BOX := Rect2(2, 1, 20, 31)

const HEALTH := 4  # estimate, still to be checked against the original
const COMMANDER_HEALTH := 105  # estimate, still to be checked against the original
const WALK_SPEED := 28 * KeenPhysics.SUBPIXEL
const WALK_FRAME_TICKS := 5
const MIN_JUMP_SPEED := 90 * KeenPhysics.SUBPIXEL
const MAX_JUMP_SPEED := 150 * KeenPhysics.SUBPIXEL
## Chance per tick on the ground that a Vorticon jumps, or turns to Keen.
const JUMP_CHANCE := 1.0 / 50.0  # estimate
const TURN_CHANCE := 1.0 / 60.0  # estimate
const DYING_FRAME_TICKS := 6

var _timer := 0


static func create(start: Vector2, is_commander := false) -> Vorticon:
	var vorticon := Vorticon.new()
	vorticon.position = start
	vorticon.body_box = BODY_BOX
	vorticon.health = COMMANDER_HEALTH if is_commander else HEALTH
	return vorticon


func sprite_index() -> int:
	if is_dead:
		return SPRITE_DYING + mini(_timer / DYING_FRAME_TICKS, DYING_FRAMES - 1)
	if not on_ground:
		return SPRITE_JUMP_RIGHT if facing > 0 else SPRITE_JUMP_LEFT
	var walk_sprite := SPRITE_WALK_RIGHT if facing > 0 else SPRITE_WALK_LEFT
	return walk_sprite + (_timer / WALK_FRAME_TICKS) % WALK_FRAMES


func die() -> void:
	if not is_dead:
		_timer = 0
	super.die()


func _think(session: LevelSession) -> void:
	_fall(session)
	_timer += 1
	if is_dead:
		return
	if on_ground:
		if session.rng.randf() < TURN_CHANCE:
			facing = _direction_to_keen(session)
		if session.rng.randf() < JUMP_CHANCE:
			velocity.y = -session.rng.randf_range(MIN_JUMP_SPEED, MAX_JUMP_SPEED)
	if not _walk(session, WALK_SPEED):
		facing = -facing
