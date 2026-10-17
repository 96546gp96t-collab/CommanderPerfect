class_name Keen2SpaceSprite
extends Actor
## Something that flies over map 81 while the Earth explodes
## ([Keen2EarthExplosion]): the Tantalus Ray's beam, an explosion or a chunk
## of the Earth. It moves in a straight line and cycles through its frames;
## an explosion is gone after its last frame. [ActorLayer] draws it like any
## other actor.

## The sprites it shows in turn.
var frames := PackedInt32Array()
## Ticks per frame.
var frame_ticks := 1
## Pixels per tick.
var velocity := Vector2.ZERO
## Whether it disappears after showing every frame once.
var once := false
var _timer := 0


## A sprite at [param start] (top left) showing [param sprite_frames], each
## for [param ticks_per_frame] ticks, moving [param speed] per tick.
static func flying(
	start: Vector2, sprite_frames: PackedInt32Array, ticks_per_frame: int, speed := Vector2.ZERO
) -> Keen2SpaceSprite:
	var sprite := Keen2SpaceSprite.new()
	sprite.position = start
	sprite.frames = sprite_frames
	sprite.frame_ticks = ticks_per_frame
	sprite.velocity = speed
	return sprite


## Moves on by one tick.
func advance() -> void:
	position += velocity
	_timer += 1
	if once and _timer >= frames.size() * frame_ticks:
		removed = true


func step(_session: LevelSession) -> void:
	advance()


func sprite_index() -> int:
	if frames.is_empty() or removed:
		return -1
	return frames[(_timer / frame_ticks) % frames.size()]
