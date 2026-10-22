class_name BackdropHoles
extends RefCounted
## Which pixels of a level's tiles are left out for what is drawn behind
## them (milestone AB2), and what takes their place:
##   - the sky ([LevelBackdrop], a picture that glides behind the level):
##     the colour rule, every pixel of [member sky_color] that touches the
##     edge of its tile, directly or through more of that colour (as since
##     the first picture of 16-10)
##   - the wall ([LevelWall], a texture fixed to the level): the same colour
##     rule for [member wall_color] (Keen 1's black, Keen 2's teal of level
##     12), and the pattern rule of [member lattice] (Keen 2's lattice, with
##     its dark and shadowed kinds, [LatticeWalls])
## A pixel the sky takes is not the wall's. [GraphicsTextures] cuts the
## holes out of the tile atlas, [method mask] gives the wall its shape.

## What takes a pixel's place: nothing (the tile stays), the sky, or the
## wall, lit, in the dark or in a wall's shadow.
enum Kind { NONE, SKY, LIT, DARK, SHADOW }

## How bright the wall is drawn in each kind of hole. The dark and shadowed
## lattice of the original is about a third and a half as bright as the lit
## one (85 and 170 against 170 and 255); the shadow a little lighter than
## the dark, so that a wall's shadow is still seen in the dark shafts.
const LIT_BRIGHTNESS := 1.0
const DARK_BRIGHTNESS := 0.35
const SHADOW_BRIGHTNESS := 0.45

## The colour the sky takes the place of; transparent for none.
var sky_color := Color.TRANSPARENT
## The plain colour the wall takes the place of; transparent for none.
var wall_color := Color.TRANSPARENT
## The patterned wall; null for none.
var lattice: LatticeWalls
## Tells this set of holes from others that differ, for the caches.
var name := ""


## Holes for the sky in [param sky], the wall in [param wall] and the
## patterned wall [param lattice_walls] (called [param lattice_name]).
static func create(
	sky: Color, wall := Color.TRANSPARENT, lattice_walls: LatticeWalls = null, lattice_name := ""
) -> BackdropHoles:
	var holes := BackdropHoles.new()
	holes.sky_color = sky
	holes.wall_color = wall
	holes.lattice = lattice_walls
	holes.name = lattice_name
	return holes


## A text that is the same for holes that are the same.
func key() -> String:
	var parts := PackedStringArray([_color_key(sky_color), _color_key(wall_color), name])
	return "/".join(parts)


func has_sky() -> bool:
	return sky_color.a > 0.0


func has_wall() -> bool:
	return wall_color.a > 0.0 or lattice != null


## The [enum Kind] of every pixel of [param tile], row by row.
func kinds(tile: Image) -> PackedByteArray:
	var size := tile.get_width() * tile.get_height()
	var result := PackedByteArray()
	result.resize(size)
	if has_sky():
		_mark(result, edge_flood(tile, sky_color), Kind.SKY)
	if wall_color.a > 0.0:
		_mark(result, edge_flood(tile, wall_color), Kind.LIT)
	if lattice != null:
		var walls := lattice.kinds(tile)
		for i in size:
			if result[i] == Kind.NONE:
				result[i] = walls[i]
	return result


## [param tile] with the pixels of [param kinds] left out: every hole, or
## with [param keep_sky] only the wall's.
static func cut(tile: Image, kinds: PackedByteArray, keep_sky := false) -> Image:
	var image := tile.duplicate() as Image
	image.convert(Image.FORMAT_RGBA8)
	var width := image.get_width()
	for i in kinds.size():
		if kinds[i] == Kind.NONE or (keep_sky and kinds[i] == Kind.SKY):
			continue
		image.set_pixel(i % width, i / width, Color.TRANSPARENT)
	return image


## The wall's shape in a tile with [param kinds] (as wide as
## [param width]): grey as bright as the wall is drawn there, transparent
## where it is not drawn.
static func mask(kinds: PackedByteArray, width: int) -> Image:
	var image := Image.create_empty(width, kinds.size() / width, false, Image.FORMAT_RGBA8)
	for i in kinds.size():
		var brightness := brightness_of(kinds[i])
		if brightness > 0.0:
			image.set_pixel(i % width, i / width, Color(brightness, brightness, brightness))
	return image


## Whether a tile with [param kinds] has some wall.
static func has_wall_in(kinds: PackedByteArray) -> bool:
	return kinds.has(Kind.LIT) or kinds.has(Kind.DARK) or kinds.has(Kind.SHADOW)


## How bright the wall is drawn in a hole of [param kind]; 0 where none is.
static func brightness_of(kind: int) -> float:
	match kind:
		Kind.LIT:
			return LIT_BRIGHTNESS
		Kind.DARK:
			return DARK_BRIGHTNESS
		Kind.SHADOW:
			return SHADOW_BRIGHTNESS
	return 0.0


## 1 for every pixel of [param color] in [param image] that touches its edge,
## directly or through more of that colour (a flood fill from the edges).
static func edge_flood(image: Image, color: Color) -> PackedByteArray:
	var size := image.get_size()
	var result := PackedByteArray()
	result.resize(size.x * size.y)
	var pending: Array[Vector2i] = []
	for x in size.x:
		pending.append_array([Vector2i(x, 0), Vector2i(x, size.y - 1)])
	for y in size.y:
		pending.append_array([Vector2i(0, y), Vector2i(size.x - 1, y)])
	var area := Rect2i(Vector2i.ZERO, size)
	while not pending.is_empty():
		var pixel: Vector2i = pending.pop_back()
		if not area.has_point(pixel) or result[pixel.y * size.x + pixel.x]:
			continue
		if not image.get_pixelv(pixel).is_equal_approx(color):
			continue
		result[pixel.y * size.x + pixel.x] = 1
		for step in LatticeWalls.NEIGHBOURS:
			pending.append(pixel + step)
	return result


static func _mark(kinds: PackedByteArray, flood: PackedByteArray, kind: Kind) -> void:
	for i in kinds.size():
		if flood[i] and kinds[i] == Kind.NONE:
			kinds[i] = kind


static func _color_key(color: Color) -> String:
	return color.to_html() if color.a > 0.0 else "-"
