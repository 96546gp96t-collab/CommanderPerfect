class_name Keen3Carrier
extends Keen2Carrier
## Something solid in a Keen 3 level that Keen can ride: the ball
## ([Keen3Ball]) and the platforms ([Keen3Platform]). The original "carries"
## Keen with them (Choco): he stands on their top and goes along, and they
## are solid on every side.
##
## Standing and riding are Keen 2's ([Keen2Carrier], [Keen2RidingCollision]
## and the session's riding step). What Keen 3 adds, in [method touch_keen]:
##   from above   Keen's feet are just below the top: he is put on top;
##                while he rises (he has just jumped off it), only as far
##                as it rose into him, so he keeps his place sideways
##   from below   his head is just above its bottom while he rises or it
##                comes down: he is pushed down and his jump ends
##   from aside   otherwise he is pushed out sideways
## Every push goes through the tiles, so Keen never ends up inside a wall.
## When a tile holds him, the push stops there and the carrier moves on
## through him, harmless: in the original (js-dos, level 2) a platform that
## came down on Keen standing at the bottom of its shaft went on to the
## floor past him and turned up there. Only when it carries Keen up into a
## ceiling does the carrier give way ([method give_way]): it stops under
## him as if it had reached the ceiling itself (*estimate*; Commander Genius
## pushes Keen down through it).

## His head this far above the bottom still counts as hitting it from below
## (a rising Keen moves up to ~7 px per tick, the ball 3.8).
const HEAD_REACH := 12.0  # estimate
## Pushes shorter than this count as made in full.
const PUSH_TOLERANCE := 0.001


func touch_keen(session: LevelSession, keen: KeenBody) -> void:
	var box := keen.hitbox()
	var own := hitbox()
	if _is_under_feet(box, own, keen):
		_put_on_top(session, keen)
	elif own.end.y - box.position.y <= HEAD_REACH and _closes_in_from_above(keen):
		_push_under(session, keen)
	else:
		_push_aside(session, keen)


## Moves back by [param shift] (the part of a lift that a ceiling stopped,
## the other way round), through the tiles, and reacts as if a tile stood
## in the way it was going.
func give_way(session: LevelSession, shift: Vector2) -> void:
	position.x += session.collision.sweep_x(hitbox(), shift.x)
	position.y += session.collision.sweep_y(hitbox(), shift.y)
	var blocked := Vector2(-signf(shift.x), -signf(shift.y))
	if blocked != Vector2.ZERO:
		_stopped(blocked)


## A tile (or a Keen held by a ceiling) stopped it on the side
## [param direction] (one axis: -1 or 1). Each kind fills it in.
func _stopped(_direction: Vector2) -> void:
	pass


## Whether [param own] (its box) is just under the feet of [param keen]
## (in [param box]): his feet are up to [constant CLIMB_REACH] into its top
## while he stands or comes down, or, while he goes up, no further than it
## rose this tick. That is a lift that rises into a Keen who has just
## jumped off it (he only starts to move the tick after the jump), or a
## ball rising faster than him: he goes up on it and keeps his place
## sideways. A rising Keen that runs into its side is pushed out.
func _is_under_feet(box: Rect2, own: Rect2, keen: KeenBody) -> bool:
	var depth := box.end.y - own.position.y
	if keen.velocity.y >= 0.0:
		return depth <= CLIMB_REACH
	return depth <= maxf(-last_move.y, 0.0) + LevelCollision.EDGE_TOLERANCE


## Whether Keen, below it, rises into it or it comes down onto him.
func _closes_in_from_above(keen: KeenBody) -> bool:
	return keen.velocity.y < 0.0 or last_move.y > 0.0


func _put_on_top(session: LevelSession, keen: KeenBody) -> void:
	var lift := top() - keen.hitbox().end.y
	var moved := session.collision.sweep_y(keen.hitbox(), lift)
	keen.position.y += moved
	if absf(moved - lift) <= PUSH_TOLERANCE:
		return
	if last_move.y < 0.0:
		give_way(session, Vector2(0.0, moved - lift))
	else:
		_push_aside(session, keen)


func _push_under(session: LevelSession, keen: KeenBody) -> void:
	var push := hitbox().end.y - keen.hitbox().position.y
	var moved := session.collision.sweep_y(keen.hitbox(), push)
	keen.position.y += moved
	var in_air := keen.state in [KeenBody.State.RISING, KeenBody.State.FALLING]
	if in_air and keen.velocity.y < last_move.y:
		# He bumps his head: from now on he goes no faster up than it does.
		keen.velocity.y = last_move.y


func _push_aside(session: LevelSession, keen: KeenBody) -> void:
	var box := keen.hitbox()
	var own := hitbox()
	var shift := own.position.x - box.end.x
	if box.get_center().x >= own.get_center().x:
		shift = own.end.x - box.position.x
	keen.position.x += session.collision.sweep_x(box, shift)
