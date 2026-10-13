class_name FreeLook
extends Node2D
## A point that the player moves with the movement keys to look around a
## level. The [LevelCamera] child follows it. Keen takes over this job in
## milestone 3.

## Game pixels per second.
const SCROLL_SPEED := 240.0

## The area this point stays inside, see [method LevelCamera.center_range].
var bounds := Rect2()


func _process(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction != Vector2.ZERO:
		move_to(position + direction * SCROLL_SPEED * delta)


## Moves to [param target], kept inside [member bounds].
func move_to(target: Vector2) -> void:
	position = target.clamp(bounds.position, bounds.end)
