class_name Keen3Fireball
extends Keen3Shot
## The Vorticon mother's fireball (Choco): it flies straight, without
## gravity, at [constant FIREBALL_SPEED], its two frames taking turns every
## [constant Keen3Enemy.FAST_FRAME_TICKS] ticks (57-58 flying left, 59-60
## right). It splashes on a wall (SHOTHIT) and on any sprite except a mother
## or a corpse, so Keen can shoot it down. It kills Keen (also a stunned
## one, not with the ankh), grunts and Foobs ([Keen3LevelSession] decides
## what it touches). When it starts in a wall it splashes at once.

const SPRITE_LEFT := 57
const SPRITE_RIGHT := 59
const FRAMES := 2
## 150 (Choco).
const FIREBALL_SPEED := 45.5 * KeenPhysics.SUBPIXEL

var _age := 0


## A fireball from [param start] toward [param flying_direction] (1 right,
## -1 left), spat in [param session].
static func spat(session: LevelSession, start: Vector2, flying_direction: int) -> Keen3Fireball:
	var fireball := Keen3Fireball.new()
	fireball.position = start
	fireball.direction = flying_direction
	fireball.from_keen = false
	if fireball._starts_in_wall(session):
		session.play_sound(Sound.Id.SHOT_HIT)
		fireball.splash()
	return fireball


## Whether a fireball flies through [param enemy] unharmed: a mother, or
## any corpse.
static func passes(enemy: Enemy) -> bool:
	return enemy is Keen3Mom or enemy.is_dead


func step(session: LevelSession) -> void:
	_age += 1
	super.step(session)


func _speed() -> float:
	return FIREBALL_SPEED


func _flying_sprite() -> int:
	var first := SPRITE_RIGHT if direction > 0 else SPRITE_LEFT
	return first + Keen3Enemy.frame_after(_age, Keen3Enemy.FAST_FRAME_TICKS, FRAMES)


## Whether a wall's side that faces the way it flies overlaps it.
func _starts_in_wall(session: LevelSession) -> bool:
	var edge := LevelCollision.Edge.LEFT if direction > 0 else LevelCollision.Edge.RIGHT
	for cell in LevelCollision.cells_under(hitbox()):
		if session.collision.is_solid(cell, edge):
			return true
	return false
