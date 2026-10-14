class_name KeenInput
extends RefCounted
## The buttons held during one tick. Kept apart from Godot's Input so that
## [KeenBody] can be driven by tests and, later, by a second player or a
## recorded demo.

## -1 for left, 1 for right, 0 for neither (or both).
var direction := 0
## -1 for up, 1 for down, 0 for neither. Only used on the world map.
var vertical := 0
var jump := false
var pogo := false
var fire := false


static func create(
	held_direction: int, held_jump := false, held_pogo := false, held_fire := false
) -> KeenInput:
	var input := KeenInput.new()
	input.direction = held_direction
	input.jump = held_jump
	input.pogo = held_pogo
	input.fire = held_fire
	return input


## Input for walking over the world map in [param held_direction], which
## may be diagonal.
static func toward(held_direction: Vector2i, held_jump := false) -> KeenInput:
	var input := create(held_direction.x, held_jump)
	input.vertical = held_direction.y
	return input


## The state of the input actions right now.
static func from_actions() -> KeenInput:
	var held_direction := int(signf(Input.get_axis("move_left", "move_right")))
	var input := create(
		held_direction,
		Input.is_action_pressed("jump"),
		Input.is_action_pressed("pogo"),
		Input.is_action_pressed("fire"),
	)
	input.vertical = int(signf(Input.get_axis("move_up", "move_down")))
	return input
