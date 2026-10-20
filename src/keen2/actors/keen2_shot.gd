class_name Keen2Shot
extends RaygunShot
## A raygun shot in Keen 2. It flies, hits and splashes exactly as in Keen 1
## ([RaygunShot]); only its pictures are other sprites, because Keen 2 has
## more sprites before them (docs/keen2/research.md, section 5).
##
## A shot starts just in front of whoever fires it, so close to a wall it
## would start inside the wall, and the sweep, which only looks at the tiles
## ahead of the shot, would let it fly on behind a thin wall. A shot that
## starts against a wall splashes at once instead (as Keen 3's, decided by
## the user after C11): [method splash_at_wall_before_start] checks the way
## from the shooter's middle to the start. Keen 3 uses
## [method put_against_wall] for its own shots too; Keen 1 keeps the old
## behaviour.

const KEEN_SHOT_SPRITE := 122
const ENEMY_SHOT_SPRITE := 123
const ZAP_SPRITE := 124
const ZOT_SPRITE := 125
## Keen 1's sprite for each picture, and Keen 2's.
const SPRITES: Dictionary[int, int] = {
	RaygunShot.SPRITE_KEEN_SHOT: KEEN_SHOT_SPRITE,
	RaygunShot.SPRITE_ENEMY_SHOT: ENEMY_SHOT_SPRITE,
	RaygunShot.SPRITE_ZAP: ZAP_SPRITE,
	RaygunShot.SPRITE_ZOT: ZOT_SPRITE,
}
## From Keen's middle to the front of a shot that starts in front of him:
## half his box and the shot's own width (the speed he moves with this tick
## is at most a few pixels, well inside the other half of his box).
const FROM_KEENS_MIDDLE := KeenPhysics.HITBOX.size.x / 2.0 + KeenPhysics.SHOT_SIZE.x


## A shot from [param start] towards [param flying_direction] (1 right, -1
## left), fired by Keen unless [param fired_by_keen] is false.
static func fired(start: Vector2, flying_direction: int, fired_by_keen := true) -> Keen2Shot:
	var shot := Keen2Shot.new()
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
) -> Keen2Shot:
	var shot := fired(start, flying_direction)
	shot.splash_at_wall_before_start(session, FROM_KEENS_MIDDLE)
	return shot


## Sweeps the box of [param shot] over the last [param way] pixels before
## its start, from its shooter's middle. When a wall is in the way, the shot
## is moved against that wall and the answer is true; the caller splashes
## it.
static func put_against_wall(shot: RaygunShot, collision: LevelCollision, way: float) -> bool:
	var signed_way := shot.direction * way
	var from_middle := shot.hitbox()
	from_middle.position.x -= signed_way
	var moved := collision.sweep_x(from_middle, signed_way)
	if moved == signed_way:
		return false
	shot.position.x += moved - signed_way
	return true


## Splashes this shot at once, with SHOTHIT, against a wall that stands
## within [param way] pixels before its start (see [method put_against_wall]).
func splash_at_wall_before_start(session: LevelSession, way: float) -> void:
	if not put_against_wall(self, session.collision, way):
		return
	session.play_sound_at(Sound.Id.SHOT_HIT, position)
	splash()


func sprite_index() -> int:
	return SPRITES.get(super.sprite_index(), -1)
