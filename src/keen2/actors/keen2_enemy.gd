class_name Keen2Enemy
extends Enemy
## Base class of Keen 2's enemies. They wake up, walk, fall and get shot as
## Keen 1's do ([Enemy]); this adds what they share in Keen 2: chances as the
## original rolls them, looking for walls, the darkness and firing.
## docs/keen2/gameplay.md describes each kind.

const SUBPIXEL := KeenPhysics.SUBPIXEL
const TILE := float(EgaGraphics.TILE_SIZE)
## A chance of n means n + 1 out of this many, per tick, as Commander Genius
## rolls them (docs/keen2/research.md section 5).
const CHANCE_RANGE := 1000
## How far a box reaches out to feel a wall, floor or ceiling next to it.
const PROBE := 1.0 / 64.0

## Ticks in the current mode; drives the animations.
var _timer := 0


## Whether a chance of [param chance] (n + 1 in 1000) comes up this tick.
static func roll(session: LevelSession, chance: int) -> bool:
	return session.rng.randi_range(0, CHANCE_RANGE - 1) <= chance


## Whether the lights are off in [param session]. Vorticons do not jump in
## the dark. The lights come in milestone B5.
static func is_dark(session: LevelSession) -> bool:
	var keen_2 := session as Keen2LevelSession
	return keen_2 != null and keen_2.is_dark()


## Whether a wall touches this enemy on the side [param direction] (-1 left,
## 1 right).
func _is_blocked(session: LevelSession, direction: int) -> bool:
	return is_zero_approx(session.collision.sweep_x(hitbox(), direction * PROBE))


func _is_blocked_above(session: LevelSession) -> bool:
	return is_zero_approx(session.collision.sweep_y(hitbox(), -PROBE))


## Jumps up with [param speed]. The Vorticons use it.
func _jump(speed: float) -> void:
	velocity.y = -speed
	on_ground = false


## A random jump speed from [param lowest] to [param highest] pixels per
## tick, in whole sub-pixels as in the original.
static func _random_speed(session: LevelSession, lowest: float, highest: float) -> float:
	var sub_pixels := session.rng.randi_range(roundi(lowest / SUBPIXEL), roundi(highest / SUBPIXEL))
	return sub_pixels * SUBPIXEL


## Fires an enemy shot from [param start] the way this enemy faces, with
## [param sound].
func _fire_shot(session: LevelSession, start: Vector2, sound: Sound.Id) -> void:
	session.add_actor(Keen2EnemyShot.fired_by(get_script(), start, facing))
	session.play_sound_at(sound, start)


## Where a shot starts that leaves this enemy's front edge, its top
## [param height] pixels below the top of the sprite. [param gap] pixels
## lie between the enemy and the shot.
func _shot_start(height: float, gap: float) -> Vector2:
	var box := hitbox()
	var y := position.y + height
	if facing > 0:
		return Vector2(box.end.x + gap, y)
	return Vector2(box.position.x - gap - KeenPhysics.SHOT_SIZE.x, y)
