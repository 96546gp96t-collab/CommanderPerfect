class_name Keen3Shot
extends RaygunShot
## A raygun shot in Keen 3. It flies, hits and splashes exactly as in Keen 1
## ([RaygunShot]); only its pictures are Keen 3's sprites: KEENSHOT (102),
## TANKSHOT (103, the wall guns' shot, milestone C5) and the splash,
## SHOTSPLASHR (105) or SHOTSPLASHL (106). Which splash goes with which
## direction is an estimate (the names suggest the side the shot flew to).
## What Keen's shots hit in Keen 3 comes in milestone C4.

const KEEN_SHOT_SPRITE := 102
const ENEMY_SHOT_SPRITE := 103
const SPLASH_RIGHT_SPRITE := 105
const SPLASH_LEFT_SPRITE := 106


## A shot from [param start] towards [param flying_direction] (1 right, -1
## left), fired by Keen unless [param fired_by_keen] is false.
static func fired(start: Vector2, flying_direction: int, fired_by_keen := true) -> Keen3Shot:
	var shot := Keen3Shot.new()
	shot.position = start
	shot.direction = flying_direction
	shot.from_keen = fired_by_keen
	return shot


func sprite_index() -> int:
	if is_splashing:
		return SPLASH_RIGHT_SPRITE if direction > 0 else SPLASH_LEFT_SPRITE  # estimate
	return KEEN_SHOT_SPRITE if from_keen else ENEMY_SHOT_SPRITE
