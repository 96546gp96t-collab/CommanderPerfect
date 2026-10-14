class_name IceBit
extends Actor
## A shard of a shattered [IceChunk]. It flies off diagonally through
## everything and disappears after a moment. Only for show.

const SPRITE := 113
const SPEED := 80 * KeenPhysics.SUBPIXEL
const LIFE_TICKS := 25

var velocity := Vector2.ZERO
var _ticks_left := LIFE_TICKS


static func create(start: Vector2, direction: Vector2) -> IceBit:
	var bit := IceBit.new()
	bit.position = start
	bit.velocity = direction * SPEED
	return bit


func sprite_index() -> int:
	return SPRITE


func step(_session: LevelSession) -> void:
	position += velocity
	_ticks_left -= 1
	if _ticks_left <= 0:
		removed = true
