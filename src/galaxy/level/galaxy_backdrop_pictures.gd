class_name GalaxyBackdropPictures
extends BackdropPictures
## The pictures behind a Galaxy episode's levels (an extra, widescreen
## only, on by default): [BackdropPictures] with the episode's own folder
## (such as assets/backgrounds/keen4) and the player's own folder
## (game_data/keen4/backgrounds), for the levels where they look right.
##
## A Galaxy level draws its background with tiles full of pictures (trees,
## hills, pyramids, cave walls), not with one plain tile as Keen 1-3. A
## picture may only take the place of **sky**: the episode names its plain
## sky tiles (one colour, nothing on them), and a level shows a picture
## when the first row the view can show (row 2, inside the border) has sky.
## The picture then shows through that sky colour where it touches the
## edge of a background tile (around clouds, trees and hill tops), as Keen
## 1's pictures do. A level whose top is a forest, a cave or rock keeps its
## own background. For Keen 4 see docs/keen4/gameplay.md, "Pictures behind
## the levels".

## The first row the view shows: the map's border is 2 tiles.
const FIRST_ROW := GalaxyCamera.BORDER_TILES

var _sky_tiles := PackedInt32Array()
var _first_level := 0
var _last_level := 0


## The pictures for the levels [param first_level]-[param last_level] of
## the game in [param files]; those that come with the game are in
## [param folder]. [param sky_tiles] are the episode's plain sky tiles.
static func for_episode(
	files: GameFiles, folder: String, sky_tiles: PackedInt32Array, first_level: int, last_level: int
) -> GalaxyBackdropPictures:
	var pictures := GalaxyBackdropPictures.new()
	pictures._files = files
	pictures._folder = folder
	pictures._sky_tiles = sky_tiles
	pictures._first_level = first_level
	pictures._last_level = last_level
	return pictures


## The sky tile of [param map] (the most used one in its first row), or -1
## when its top is no sky or it is no level.
func sky_tile(map: GalaxyMap) -> int:
	if map == null or map.number < _first_level or map.number > _last_level:
		return -1
	var counts: Dictionary[int, int] = {}
	for x in range(FIRST_ROW, map.width - FIRST_ROW):
		var tile := map.tile(GalaxyMap.Layer.BACKGROUND, x, FIRST_ROW)
		if _sky_tiles.has(tile):
			counts[tile] = counts.get(tile, 0) + 1
	var best := -1
	for tile in counts:
		if best < 0 or counts[tile] > counts[best]:
			best = tile
	return best


## The picture for [param map], or null when it has none or may not show
## one.
func picture_for(map: GalaxyMap) -> Texture2D:
	return picture(map.number) if sky_tile(map) >= 0 else null


## [param image] (a background tile) with every pixel of [param color]
## that touches its edge, directly or through more of that color, made
## see-through.
static func cleared(image: Image, color: Color) -> Image:
	var result := image.duplicate() as Image
	result.convert(Image.FORMAT_RGBA8)
	var size := result.get_size()
	var pending: Array[Vector2i] = []
	for x in size.x:
		pending.append_array([Vector2i(x, 0), Vector2i(x, size.y - 1)])
	for y in size.y:
		pending.append_array([Vector2i(0, y), Vector2i(size.x - 1, y)])
	var whole := Rect2i(Vector2i.ZERO, size)
	while not pending.is_empty():
		var pixel: Vector2i = pending.pop_back()
		if not whole.has_point(pixel) or not result.get_pixelv(pixel).is_equal_approx(color):
			continue
		result.set_pixelv(pixel, Color.TRANSPARENT)
		for step in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			pending.append(pixel + step)
	return result


## [param big] (a scaled tile) with the see-through pixels of
## [param small] (the cleared original) cut out.
static func with_holes_of(big: Image, small: Image) -> Image:
	var size := big.get_size()
	var mask := small.duplicate() as Image
	mask.resize(size.x, size.y, Image.INTERPOLATE_NEAREST)
	var source := big.duplicate() as Image
	source.convert(Image.FORMAT_RGBA8)
	var result := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	result.blit_rect_mask(source, mask, Rect2i(Vector2i.ZERO, size), Vector2i.ZERO)
	return result
