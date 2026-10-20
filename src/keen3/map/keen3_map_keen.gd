class_name Keen3MapKeen
extends MapKeen
## Keen 3's Keen on the world map: Keen 1's [MapKeen] (the box, the
## collisions, the eight directions, up and down winning over left and
## right) with what Keen 3 does differently (Choco `CVort_move_worldmap`):
##   - his sprites are one lower than Keen 1's and 2's: right 31-34, down
##     35-38, left 39-42, up 43-46 (EGAHEAD.CK3 has no KEENSBACK)
##   - he walks 4 px per frame of the original on each pressed axis, about
##     97 px/s; [constant MapKeen.WALK_SPEED] (127.5 px/s) is 30 % faster,
##     too far off to keep, so he has his own speed
##   - a walking frame lasts 16 clock ticks of the original (6.6 of ours),
##     and a step sounds every second frame (WLDBLOCKSND when he is held up
##     on either axis, otherwise WLDWALKSND)
##   - he moves up or down first and then sideways, as the original checks
## [MapKeen]'s constants cannot be overridden, so the numbers have their
## own names here and [method step] and [method sprite_index] are Keen 3's.

const KEEN_3_SPRITE_RIGHT := 31
const KEEN_3_SPRITE_DOWN := 35
const KEEN_3_SPRITE_LEFT := 39
const KEEN_3_SPRITE_UP := 43
## Pixels per tick on each pressed axis: 4 px per frame (Choco).
const KEEN_3_WALK_SPEED := 4.0 * Keen3MapInfo.FRAMES_PER_TICK
## Ticks per walking frame: 16 clock ticks of 145.65 Hz (Choco).
const KEEN_3_FRAME_TICKS := 16.0 / 145.65 * 60.0
## A step sounds every this many walking frames.
const FRAMES_PER_STEP_SOUND := 2

var _walked_ticks := 0.0
var _frame := 0


## Keen at [param start] (the top left of his sprite) on a map with
## [param map_collision].
static func placed(map_collision: LevelCollision, start: Vector2) -> Keen3MapKeen:
	var keen := Keen3MapKeen.new()
	keen.collision = map_collision
	keen.position = start
	return keen


## Walks one tick in the direction of [param input].
func step(input: KeenInput) -> void:
	var direction := Vector2i(input.direction, input.vertical)
	if direction == Vector2i.ZERO:
		_walked_ticks = 0.0
		_frame = 0
		return
	facing = Vector2i(0, direction.y) if direction.y != 0 else Vector2i(direction.x, 0)
	var wanted := Vector2(direction) * KEEN_3_WALK_SPEED
	var moved := Vector2(0.0, collision.sweep_y(hitbox(), wanted.y))
	position.y += moved.y
	moved.x = collision.sweep_x(hitbox(), wanted.x)
	position.x += moved.x
	_walked_ticks += 1.0
	var frame := int(_walked_ticks / KEEN_3_FRAME_TICKS) % WALK_FRAMES
	if frame != _frame:
		_frame = frame
		if frame % FRAMES_PER_STEP_SOUND == 0:
			var held_up := not moved.is_equal_approx(wanted)
			sound_played.emit(Sound.Id.MAP_BLOCKED if held_up else Sound.Id.MAP_WALK)


func sprite_index() -> int:
	var first := KEEN_3_SPRITE_DOWN
	match facing:
		Vector2i.RIGHT:
			first = KEEN_3_SPRITE_RIGHT
		Vector2i.LEFT:
			first = KEEN_3_SPRITE_LEFT
		Vector2i.UP:
			first = KEEN_3_SPRITE_UP
	return first + _frame
