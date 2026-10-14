class_name IceChunk
extends Actor
## A chunk of ice from an [IceCannon]. It flies in a straight line until it
## hits a wall or Keen, and then shatters into four [IceBit]s. Keen is frozen
## and pushed along in the chunk's direction.

const SPRITE := 112
const SIZE := Vector2(16, 16)
## From the sprite table of EGAHEAD.CK1.
const BODY_BOX := Rect2(4, 4, 7, 7)
const DIAGONAL_SPEED := 60 * KeenPhysics.SUBPIXEL
const STRAIGHT_SPEED := 80 * KeenPhysics.SUBPIXEL
## A chunk flying straight up or down pushes Keen only gently.
const VERTICAL_PUSH_SPEED := 16 * KeenPhysics.SUBPIXEL

var velocity := Vector2.ZERO


static func create(start: Vector2, direction: Vector2i) -> IceChunk:
	var chunk := IceChunk.new()
	chunk.position = start
	var speed := DIAGONAL_SPEED if direction.x != 0 else STRAIGHT_SPEED
	chunk.velocity = Vector2(direction) * speed
	return chunk


func hitbox() -> Rect2:
	return Rect2(position + BODY_BOX.position, BODY_BOX.size)


func sprite_index() -> int:
	return SPRITE


func step(session: LevelSession) -> void:
	var keen := session.keen
	if not keen.is_dead and hitbox().intersects(keen.hitbox()):
		keen.freeze(_push_speed(session))
		_shatter(session)
		return
	var box := hitbox()
	var moved := Vector2(
		session.collision.sweep_x(box, velocity.x), session.collision.sweep_y(box, velocity.y)
	)
	position += moved
	if moved != velocity:
		_shatter(session)


func _push_speed(session: LevelSession) -> float:
	if velocity.x != 0.0:
		return signf(velocity.x) * KeenPhysics.WALK_MAX_SPEED
	return VERTICAL_PUSH_SPEED * (1.0 if session.rng.randf() < 0.5 else -1.0)


func _shatter(session: LevelSession) -> void:
	removed = true
	for direction in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		session.add_actor(IceBit.create(position, direction))
