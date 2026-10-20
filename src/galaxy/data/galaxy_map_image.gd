class_name GalaxyMapImage
extends RefCounted
## A picture of a whole Galaxy map for the data viewer and the graphics
## export: the background tiles, the foreground tiles over them, and a
## coloured square on every cell with an info value (the same value gets
## the same colour). Not how the game draws a level (that is D3): no
## animation, and sprites are not placed.

const TILE := GalaxyGraphics.TILE16_SIZE
const INFO_ALPHA := 0.55
const INFO_INSET := 3
const HIGH_BYTE := 8
## Spread the hues of nearby values apart.
const LOW_HUE_STEP := 0.137
const HIGH_HUE_STEP := 0.31
const INFO_SATURATION := 0.9


## [param map] with [param graphics]; [param layers] says per
## [enum GalaxyMap.Layer] whether it is drawn.
static func build(
	map: GalaxyMap, graphics: GalaxyGraphics, layers: Array[bool] = [true, true, true]
) -> Image:
	var image := Image.create_empty(
		maxi(1, map.width * TILE), maxi(1, map.height * TILE), false, Image.FORMAT_RGBA8
	)
	image.fill(Color.BLACK)
	var whole := Rect2i(0, 0, TILE, TILE)
	for y in map.height:
		for x in map.width:
			var cell := Vector2i(x, y) * TILE
			if layers[GalaxyMap.Layer.BACKGROUND]:
				var back := graphics.back_tile(map.tile(GalaxyMap.Layer.BACKGROUND, x, y))
				if back != null:
					image.blit_rect(back, whole, cell)
			if layers[GalaxyMap.Layer.FOREGROUND]:
				var fore := graphics.fore_tile(map.tile(GalaxyMap.Layer.FOREGROUND, x, y))
				if fore != null:
					image.blend_rect(fore, whole, cell)
			var info := map.tile(GalaxyMap.Layer.INFO, x, y)
			if info != 0 and layers[GalaxyMap.Layer.INFO]:
				var square := Rect2i(cell, Vector2i(TILE, TILE)).grow(-INFO_INSET)
				image.blend_rect(
					_square(square.size, info_color(info)),
					Rect2i(Vector2i.ZERO, square.size),
					square.position
				)
	return image


## The colour of info value [param value].
static func info_color(value: int) -> Color:
	var hue := fmod(
		float(value & 0xFF) * LOW_HUE_STEP + float(value >> HIGH_BYTE) * HIGH_HUE_STEP, 1.0
	)
	return Color.from_hsv(hue, INFO_SATURATION, 1.0, INFO_ALPHA)


static func _square(size: Vector2i, color: Color) -> Image:
	var square := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	square.fill(color)
	return square
