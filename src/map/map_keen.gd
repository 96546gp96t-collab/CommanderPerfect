class_name MapKeen
extends RefCounted
## Keen walking over the world map, seen from above: he walks in eight
## directions at a steady speed and bumps into everything solid. Only the
## logic; [MapSession] steps him and the [Keen] node draws him.

## Collision box inside the 16x16 sprite, from the sprite table of
## EGAHEAD.CK1 (MAPKEEN*: left 2, top 1, right 9, bottom 15).
const HITBOX := Rect2(2, 1, 8, 15)
const SPRITE_SIZE := Vector2(16, 16)
## Pixels per tick. An estimate: as fast as he walks in a level, still to be
## compared with the original.
const WALK_SPEED := KeenPhysics.WALK_MAX_SPEED
const WALK_FRAME_TICKS := KeenPhysics.WALK_FRAME_TICKS
const WALK_FRAMES := 4
## First of the four walking frames for each direction he faces.
const SPRITE_RIGHT := 32
const SPRITE_DOWN := 36
const SPRITE_LEFT := 40
const SPRITE_UP := 44

var collision: LevelCollision
## Top left of the sprite, in map pixels.
var position := Vector2.ZERO
## The direction he looks in: one of the four axis directions.
var facing := Vector2i.DOWN
## Set while a teleporter moves him: he is not drawn then.
var hidden := false
var _walk_frame := 0
var _walk_timer := 0


static func create(map_collision: LevelCollision, start: Vector2) -> MapKeen:
	var keen := MapKeen.new()
	keen.collision = map_collision
	keen.position = start
	return keen


## Walks one tick in the direction of [param input].
func step(input: KeenInput) -> void:
	var direction := Vector2i(input.direction, input.vertical)
	if direction == Vector2i.ZERO:
		_walk_frame = 0
		_walk_timer = 0
		return
	# Up and down win over left and right, like the sprite of the original.
	facing = Vector2i(0, direction.y) if direction.y != 0 else Vector2i(direction.x, 0)
	position.x += collision.sweep_x(hitbox(), direction.x * WALK_SPEED)
	position.y += collision.sweep_y(hitbox(), direction.y * WALK_SPEED)
	_walk_timer += 1
	if _walk_timer >= WALK_FRAME_TICKS:
		_walk_timer = 0
		_walk_frame = (_walk_frame + 1) % WALK_FRAMES


func hitbox() -> Rect2:
	return Rect2(position + HITBOX.position, HITBOX.size)


## The middle of the sprite: the cell under it is the one Keen stands on.
func center() -> Vector2:
	return position + SPRITE_SIZE / 2.0


func sprite_index() -> int:
	var first := SPRITE_DOWN
	match facing:
		Vector2i.RIGHT:
			first = SPRITE_RIGHT
		Vector2i.LEFT:
			first = SPRITE_LEFT
		Vector2i.UP:
			first = SPRITE_UP
	return first + _walk_frame
