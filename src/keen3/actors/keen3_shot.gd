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
##
## Keen's shot starts just in front of him ([method KeenBody.shot_position]),
## so close to a wall it would start inside the wall, and the sweep, which
## only looks at the tiles ahead of the shot, would let it fly on behind a
## thin wall. In the original a shot that starts against a wall splashes at
## once (Choco), so [method fired_by_keen] checks the way from Keen's middle
## to the start and splashes at the wall when it is blocked.

const KEEN_SHOT_SPRITE := 102
const ENEMY_SHOT_SPRITE := 103
const SPLASH_RIGHT_SPRITE := 105
const SPLASH_LEFT_SPRITE := 106
## 400 (Choco).
const SPEED := 121 * KeenPhysics.SUBPIXEL
## 20 clock ticks (Choco).
const SPLASH_TICKS_KEEN_3 := 8
## From Keen's middle to the back of a shot that starts in front of him:
## half his box and the shot's own width (the speed he moves with this tick
## is at most a few pixels, well inside the other half of his box).
const FROM_KEENS_MIDDLE := KeenPhysics.HITBOX.size.x / 2.0 + KeenPhysics.SHOT_SIZE.x


## A shot from [param start] towards [param flying_direction] (1 right, -1
## left), fired by Keen unless [param fired_by_keen] is false.
static func fired(start: Vector2, flying_direction: int, fired_by_keen := true) -> Keen3Shot:
	var shot := Keen3Shot.new()
	shot.position = start
	shot.direction = flying_direction
	shot.from_keen = fired_by_keen
	return shot


## Keen's shot from [param start] (in front of him, see
## [method KeenBody.shot_position]) towards [param flying_direction], fired
## in [param session]. When a wall stands between Keen's middle and the
## start, the shot is put against that wall and splashes at once (SHOTHIT).
static func fired_by_keen(
	session: LevelSession, start: Vector2, flying_direction: int
) -> Keen3Shot:
	var shot := fired(start, flying_direction)
	shot._stop_at_wall_behind_start(session)
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


## Sweeps the shot's box from Keen's middle to where it starts; a wall on
## the way stops it there, splashing.
func _stop_at_wall_behind_start(session: LevelSession) -> void:
	var way := direction * FROM_KEENS_MIDDLE
	var from_middle := hitbox()
	from_middle.position.x -= way
	var moved := session.collision.sweep_x(from_middle, way)
	if moved == way:
		return
	position.x += moved - way
	session.play_sound(Sound.Id.SHOT_HIT)
	splash()


## How fast it flies, in pixels per tick.
func _speed() -> float:
	return SPEED


func _flying_sprite() -> int:
	return KEEN_SHOT_SPRITE if from_keen else ENEMY_SHOT_SPRITE
