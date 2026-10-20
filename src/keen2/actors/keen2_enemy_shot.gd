class_name Keen2EnemyShot
extends Keen2Shot
## A shot from a Vorticon Elite or a Guard robot. It looks like Keen 2's
## enemy shot (sprite 123, splash 124/125) and flies like a raygun shot,
## only slower. It kills Keen, but only shortens the stun of a stunned Keen.
## It passes through enemies of the kind that fired it; whether it hurts
## the other enemies is [member Keen2LevelSession.enemy_shots_hurt_enemies].
## Fired close to a wall, it splashes against the wall at once, as Keen's
## own shot does ([method Keen2Shot.splash_at_wall_before_start]).

## Commander Genius's RAY_DEFAULTSPEED; Keen's own shot is faster.
const SPEED := 108 * KeenPhysics.SUBPIXEL  # estimate

## The script of the enemy that fired it, for example [Keen2Elite].
var shooter: Script


## A shot of [param shooter_kind] from [param start] towards
## [param flying_direction] (1 right, -1 left).
static func fired_by(shooter_kind: Script, start: Vector2, flying_direction: int) -> Keen2EnemyShot:
	var shot := Keen2EnemyShot.new()
	shot.position = start
	shot.direction = flying_direction
	shot.from_keen = false
	shot.shooter = shooter_kind
	return shot


## [param shooter]'s shot from [param start] (in front of it) the way it
## faces, fired in [param session]: when a wall stands between the
## shooter's middle and the start, the shot splashes against that wall.
static func fired_from(shooter: Enemy, session: LevelSession, start: Vector2) -> Keen2EnemyShot:
	var shot := fired_by(shooter.get_script(), start, shooter.facing)
	var middles := absf(shot.hitbox().get_center().x - shooter.hitbox().get_center().x)
	shot.splash_at_wall_before_start(session, middles + KeenPhysics.SHOT_SIZE.x / 2.0)
	return shot


func step(session: LevelSession) -> void:
	if is_splashing:
		super.step(session)
		return
	var distance := direction * SPEED
	var moved := session.collision.sweep_x(hitbox(), distance)
	position.x += moved
	if moved != distance:
		session.play_sound_at(Sound.Id.SHOT_HIT, position)
		splash()


## Whether this shot flies through [param enemy]: one of the shooter's own
## kind.
func passes_through(enemy: Enemy) -> bool:
	return enemy.get_script() == shooter
