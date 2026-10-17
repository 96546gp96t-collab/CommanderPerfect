class_name Keen3SoundWave
extends Actor
## The sound wave a Meep sings (Choco): it flies straight at
## [constant SPEED], **through walls**, its two frames taking turns every
## [constant Keen3Enemy.FAST_FRAME_TICKS] ticks (126-127 flying right,
## 128-129 left). It kills Keen. Keen's shots splash on it and it flies on;
## it is deleted once it leaves the area where sprites stay awake or the
## playable area ([Keen3LevelSession]). It touches no enemy.

const SPRITE_RIGHT := 126
const SPRITE_LEFT := 128
const FRAMES := 2
## The collision box: MEEPWAVER1's box (2, 2, 5, 13) in EGAHEAD.CK3.
const BODY_BOX := Rect2(2, 2, 4, 12)
const SPRITE_SIZE := Vector2(8, 16)
## 200 (Choco).
const SPEED := 60.7 * KeenPhysics.SUBPIXEL

## 1 right, -1 left.
var direction := 1
var _age := 0


## A wave from [param start] (top left of its sprite) toward
## [param flying_direction].
static func sent(start: Vector2, flying_direction: int) -> Keen3SoundWave:
	var wave := Keen3SoundWave.new()
	wave.position = start
	wave.direction = flying_direction
	return wave


func step(_session: LevelSession) -> void:
	_age += 1
	position.x += direction * SPEED


func sprite_index() -> int:
	var first := SPRITE_RIGHT if direction > 0 else SPRITE_LEFT
	return first + Keen3Enemy.frame_after(_age, Keen3Enemy.FAST_FRAME_TICKS, FRAMES)


## The whole picture, in level pixels.
func sprite_rect() -> Rect2:
	return Rect2(position, SPRITE_SIZE)


func hitbox() -> Rect2:
	return Rect2(position + BODY_BOX.position, BODY_BOX.size)
