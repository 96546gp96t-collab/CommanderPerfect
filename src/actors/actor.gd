class_name Actor
extends RefCounted
## Something that moves through a level besides Keen: a raygun shot, a door
## that slides open, and later the enemies. [LevelSession] steps every actor
## once per tick; [ActorLayer] draws them.

## Top left of the sprite, in level pixels.
var position := Vector2.ZERO
## Set when the actor is gone; the session then drops it.
var removed := false


## Advances one tick.
func step(_session: LevelSession) -> void:
	pass


## Number of the sprite to draw, or -1 to draw nothing.
func sprite_index() -> int:
	return -1


## The box that touches Keen, shots and tiles, in level pixels.
func hitbox() -> Rect2:
	return Rect2(position, Vector2.ZERO)
