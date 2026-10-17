class_name Keen2Carrier
extends Keen2Enemy
## Something that Keen can stand on and ride: the moving platform
## ([Keen2Platform]) and the Scrub ([Keen2Scrub]). It is harmless.
##
## Its top is a floor for Keen ([Keen2RidingCollision]), and
## [Keen2LevelSession] moves a Keen who stands on it by [member last_move]
## every tick. Keen cannot walk through it: when he runs into its side, or
## it into his, he is pushed out sideways. When his feet are only a little
## below its top (it rose into him), he is put on top instead.

## Feet this far below the top still count as standing on it (Commander
## Genius: 8 pixels).
const CLIMB_REACH := 8.0  # estimate

## How far the carrier moved in its last tick.
var last_move := Vector2.ZERO


func step(session: LevelSession) -> void:
	var before := position
	super.step(session)
	last_move = position - before


func top() -> float:
	return hitbox().position.y


## Whether [param box] stands on this carrier: its feet are on the top. With
## [param before_move], on the top as it was before the last tick.
func carries(box: Rect2, before_move := false) -> bool:
	if is_dead:
		return false
	var surface := hitbox()
	if before_move:
		surface.position -= last_move
	return (
		_overlaps_horizontally(box, surface)
		and absf(box.end.y - surface.position.y) <= LevelCollision.EDGE_TOLERANCE
	)


## Whether [param box], moving down, would land on this carrier: it is
## above the top and not beside it.
func can_land_on(box: Rect2) -> bool:
	var surface := hitbox()
	return (
		not is_dead
		and _overlaps_horizontally(box, surface)
		and box.end.y <= surface.position.y + LevelCollision.EDGE_TOLERANCE
	)


func touch_keen(session: LevelSession, keen: KeenBody) -> void:
	var box := keen.hitbox()
	if box.end.y - top() <= CLIMB_REACH and keen.velocity.y >= 0.0:
		keen.position.y += session.collision.sweep_y(box, top() - box.end.y)
		return
	var own := hitbox()
	var shift := own.position.x - box.end.x
	if box.get_center().x >= own.get_center().x:
		shift = own.end.x - box.position.x
	keen.position.x += session.collision.sweep_x(box, shift)


static func _overlaps_horizontally(a: Rect2, b: Rect2) -> bool:
	return a.position.x < b.end.x and a.end.x > b.position.x
