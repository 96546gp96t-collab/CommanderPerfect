class_name Keen
extends SpriteView
## Draws Keen: the sprite that [KeenBody] (in a level) or [MapKeen] (on the
## world map) asks for, at its position. The logic itself runs in
## [LevelSession] and [MapSession].


## Shows [param body] as it is now.
func show_body(body: KeenBody) -> void:
	show_frame(body.position, body.sprite_index(), body.visible_width())


## Shows sprite [param sprite_index] at [param at], with only the left
## [param width] pixels of it: walking through the exit door, Keen
## disappears behind it bit by bit. Online, the other player's Keen is
## shown this way from what the host sends.
func show_frame(at: Vector2, sprite_index: int, width: float) -> void:
	show_sprite(at, sprite_index)
	if width < KeenPhysics.SPRITE_SIZE.x:
		clip_width(width, KeenPhysics.SPRITE_SIZE.y)


## Shows Keen on the world map.
func show_on_map(map_keen: MapKeen) -> void:
	show_sprite(map_keen.position, -1 if map_keen.hidden else map_keen.sprite_index())
