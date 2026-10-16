class_name OnlineSpawn
extends RefCounted
## Where the Keen of a player who joins appears: always next to the host's
## Keen, wherever he is in the level. Beside him when there is room (in
## front first), otherwise on the same spot.


## The top left for a new Keen next to [param body] in [param session].
static func beside(session: LevelSession, body: KeenBody) -> Vector2:
	var step := KeenPhysics.SPRITE_SIZE.x * 0.75
	for side in [body.facing, -body.facing]:
		var distance: float = step * side
		var moved := session.collision.sweep_x(body.hitbox(), distance)
		if is_equal_approx(moved, distance):
			return body.position + Vector2(distance, 0.0)
	return body.position
