class_name LevelImageBuilder
extends RefCounted
## Draws a complete level into a single image.
##
## This is a preview for the data viewer and the export tool. The game itself
## draws levels with [LevelMap] instead. Unlike the game, this preview also
## shows the border around the playable area.

const INFO_MARKER_COLOR := Color(1.0, 0.0, 1.0, 0.45)


## Returns an image of the whole level. With [param show_infos] every cell
## that has something in the info layer gets a highlighted square.
static func build(level: LevelData, graphics: EgaGraphics, show_infos := false) -> Image:
	var tile_size := EgaGraphics.TILE_SIZE
	var image := Image.create_empty(
		level.width * tile_size, level.height * tile_size, false, Image.FORMAT_RGBA8
	)
	var tile_rect := Rect2i(0, 0, tile_size, tile_size)

	for y in level.height:
		for x in level.width:
			var cell := Vector2i(x, y)
			var tile_number := level.tile_at(cell)
			if tile_number < graphics.tiles.size():
				image.blit_rect(graphics.tiles[tile_number], tile_rect, cell * tile_size)
			if show_infos and level.info_at(cell) != 0:
				_blend_rect(image, Rect2i(cell * tile_size, tile_rect.size), INFO_MARKER_COLOR)
	return image


static func _blend_rect(image: Image, rect: Rect2i, color: Color) -> void:
	var overlay := Image.create_empty(rect.size.x, rect.size.y, false, Image.FORMAT_RGBA8)
	overlay.fill(color)
	image.blend_rect(overlay, Rect2i(Vector2i.ZERO, rect.size), rect.position)
