class_name KeenInput
extends RefCounted
## The buttons held during one tick. Kept apart from Godot's Input so that
## [KeenBody] can be driven by tests, by each of two players, and later
## perhaps by a recorded demo.

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


## The state of the input actions for playing alone right now.
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


## The state of the keys of [param player] (0 or 1) when two play on one
## keyboard; see [constant KeyBindings.PLAYER_ACTIONS].
static func for_player(player: int) -> KeenInput:
	var prefix := "p%d_" % (player + 1)
	return create(
		int(signf(Input.get_axis(prefix + "left", prefix + "right"))),
		Input.is_action_pressed(prefix + "jump"),
		Input.is_action_pressed(prefix + "pogo"),
		Input.is_action_pressed(prefix + "fire"),
	)


## Everything held in [param inputs] together: a button counts when it is
## held in any of them, a direction when some hold it and none the other
## way. For the world map, where player 1 walks alone but both players' keys
## steer him.
static func combine(inputs: Array[KeenInput]) -> KeenInput:
	var combined := KeenInput.new()
	var horizontal_bits := 0
	var vertical_bits := 0
	for input in inputs:
		combined.jump = combined.jump or input.jump
		combined.pogo = combined.pogo or input.pogo
		combined.fire = combined.fire or input.fire
		horizontal_bits |= _direction_bits(input.direction)
		vertical_bits |= _direction_bits(input.vertical)
	combined.direction = _direction_from_bits(horizontal_bits)
	combined.vertical = _direction_from_bits(vertical_bits)
	return combined


## 1 for a negative direction, 2 for a positive one.
static func _direction_bits(direction: int) -> int:
	if direction < 0:
		return 1
	return 2 if direction > 0 else 0


static func _direction_from_bits(bits: int) -> int:
	match bits:
		1:
			return -1
		2:
			return 1
	return 0
