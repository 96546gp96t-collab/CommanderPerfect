class_name Keen3Jack
extends Keen3Enemy
## The jack of Keen 3 (info value 8), as Chocolate Keen has it: it flies
## and bounces exactly as the ball ([method Keen3Ball.bounce]), its four
## pictures (110-113) taking turns every [constant Keen3Enemy.FAST_FRAME_TICKS]
## ticks. Touching it kills Keen (not while the ankh protects him). Every
## shot splashes on it; it never dies. It is not solid: nobody rides it.

const SPRITE_FIRST := 110
const FRAMES := 4
## JACK1's box (0, 0, 15, 15) in EGAHEAD.CK3: the whole sprite.
const BODY_BOX := Rect2(0, 0, 16, 16)


## A jack at [param start] (the top left of its cell); Keen's sprite is at
## [param keen_at].
static func spawned(start: Vector2, keen_at: Vector2) -> Keen3Jack:
	var jack := Keen3Jack.new()
	jack.position = start
	jack.body_box = BODY_BOX
	jack.falls = false
	jack.velocity = Keen3Ball.start_velocity(start, keen_at)
	return jack


func hit_by_shot(_session: LevelSession) -> void:
	pass


func _living_sprite() -> int:
	return SPRITE_FIRST + frame_after(_age, FAST_FRAME_TICKS, FRAMES)


func _think(session: LevelSession) -> void:
	Keen3Ball.bounce(self, session)
