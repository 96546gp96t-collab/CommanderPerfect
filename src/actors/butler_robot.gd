class_name ButlerRobot
extends Robot
## The small butler robot: patrols its platform and shoves Keen along, often
## right off the edge.

const SPRITE_WALK_RIGHT := 88
const SPRITE_WALK_LEFT := 92
const WALK_FRAMES := 4
const SPRITE_TURN_LEFT := 96
const SPRITE_TURN_RIGHT := 97
## From the sprite table of EGAHEAD.CK1.
const BODY_BOX := Rect2(3, 3, 10, 13)

const WALK_SPEED := 28 * KeenPhysics.SUBPIXEL
const WALK_FRAME_TICKS := 6
const TURN_TICKS := 10
const PUSH_SPEED := 60 * KeenPhysics.SUBPIXEL


static func create(start: Vector2) -> ButlerRobot:
	var butler := ButlerRobot.new()
	butler.position = start
	butler.body_box = BODY_BOX
	butler.walk_speed = WALK_SPEED
	butler.push_speed = PUSH_SPEED
	butler.turn_ticks = TURN_TICKS
	return butler


func sprite_index() -> int:
	if is_turning():
		return SPRITE_TURN_LEFT if facing > 0 else SPRITE_TURN_RIGHT
	var walk_sprite := SPRITE_WALK_RIGHT if facing > 0 else SPRITE_WALK_LEFT
	return walk_sprite + (_walk_timer / WALK_FRAME_TICKS) % WALK_FRAMES
