class_name IceCannon
extends Enemy
## An invisible cannon built into the scenery. Every
## [constant FIRE_INTERVAL_TICKS] ticks it fires an [IceChunk] in its
## direction. It cannot be shot or touched.

const FIRE_INTERVAL_TICKS := 64

## Direction of the chunks: x is -1, 0 or 1, y is -1 (up) or 1 (down).
var direction := Vector2i.UP
var _timer := 0


static func create(start: Vector2, fire_direction: Vector2i) -> IceCannon:
	var cannon := IceCannon.new()
	cannon.position = start
	cannon.direction = fire_direction
	cannon.body_box = Rect2()
	cannon.falls = false
	return cannon


func stops_shots() -> bool:
	return false


func touches_keen() -> bool:
	return false


func _think(session: LevelSession) -> void:
	_timer += 1
	if _timer < FIRE_INTERVAL_TICKS:
		return
	_timer = 0
	var start := position
	if direction.x > 0:
		start.x += EgaGraphics.TILE_SIZE
	session.add_actor(IceChunk.create(start, direction))
