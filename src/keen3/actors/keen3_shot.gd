class_name Keen3Shot
extends RaygunShot
## A raygun shot in Keen 3. It flies straight sideways until it hits a wall
## and splashes, as in Keen 1 ([RaygunShot]), with Keen 3's pictures:
## KEENSHOT (102), TANKSHOT (103, the wall guns' shot, milestone C5) and the
## splash, SHOTSPLASHR (105) or SHOTSPLASHL (106). Which splash goes with
## which direction is an estimate (the original picks one at random; the
## direction keeps the game repeatable).
##
## Keen 3's own numbers (Choco): Keen's shot flies [constant SPEED] and a
## splash stays [constant SPLASH_TICKS_KEEN_3] ticks. What a shot hits is
## decided by [Keen3LevelSession]: Keen's shot splashes on every sprite but
## Keen and the corpses ([Keen3Fireball] for the mother's).

const KEEN_SHOT_SPRITE := 102
const ENEMY_SHOT_SPRITE := 103
const SPLASH_RIGHT_SPRITE := 105
const SPLASH_LEFT_SPRITE := 106
## 400 (Choco).
const SPEED := 121 * KeenPhysics.SUBPIXEL
## 20 clock ticks (Choco).
const SPLASH_TICKS_KEEN_3 := 8


## A shot from [param start] towards [param flying_direction] (1 right, -1
## left), fired by Keen unless [param fired_by_keen] is false.
static func fired(start: Vector2, flying_direction: int, fired_by_keen := true) -> Keen3Shot:
	var shot := Keen3Shot.new()
	shot.position = start
	shot.direction = flying_direction
	shot.from_keen = fired_by_keen
	return shot


func step(session: LevelSession) -> void:
	if is_splashing:
		super.step(session)
		return
	var distance := direction * _speed()
	var moved := session.collision.sweep_x(hitbox(), distance)
	position.x += moved
	if moved != distance:
		session.play_sound(Sound.Id.SHOT_HIT)
		splash()


func splash() -> void:
	if is_splashing:
		return
	super.splash()
	_splash_timer = SPLASH_TICKS_KEEN_3


func sprite_index() -> int:
	if is_splashing:
		return SPLASH_RIGHT_SPRITE if direction > 0 else SPLASH_LEFT_SPRITE  # estimate
	return _flying_sprite()


## How fast it flies, in pixels per tick.
func _speed() -> float:
	return SPEED


func _flying_sprite() -> int:
	return KEEN_SHOT_SPRITE if from_keen else ENEMY_SHOT_SPRITE
