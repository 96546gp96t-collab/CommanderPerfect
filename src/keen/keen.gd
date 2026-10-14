class_name Keen
extends SpriteView
## Draws Keen: the sprite that [KeenBody] (in a level) or [MapKeen] (on the
## world map) asks for, at its position. The logic itself runs in
## [LevelSession] and [MapSession].


## Shows [param body] as it is now.
func show_body(body: KeenBody) -> void:
	show_sprite(body.position, body.sprite_index())
	# Walking through the exit door, Keen disappears behind it bit by bit.
	var width := body.visible_width()
	if width < KeenPhysics.SPRITE_SIZE.x:
		clip_width(width, KeenPhysics.SPRITE_SIZE.y)


## Shows Keen on the world map.
func show_on_map(map_keen: MapKeen) -> void:
	show_sprite(map_keen.position, -1 if map_keen.hidden else map_keen.sprite_index())
