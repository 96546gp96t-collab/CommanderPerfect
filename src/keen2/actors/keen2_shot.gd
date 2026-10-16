class_name Keen2Shot
extends RaygunShot
## A raygun shot in Keen 2. It flies, hits and splashes exactly as in Keen 1
## ([RaygunShot]); only its pictures are other sprites, because Keen 2 has
## more sprites before them (docs/keen2/research.md, section 5).

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


## A shot from [param start] towards [param flying_direction] (1 right, -1
## left), fired by Keen unless [param fired_by_keen] is false.
static func fired(start: Vector2, flying_direction: int, fired_by_keen := true) -> Keen2Shot:
	var shot := Keen2Shot.new()
	shot.position = start
	shot.direction = flying_direction
	shot.from_keen = fired_by_keen
	return shot


func sprite_index() -> int:
	return SPRITES.get(super.sprite_index(), -1)
