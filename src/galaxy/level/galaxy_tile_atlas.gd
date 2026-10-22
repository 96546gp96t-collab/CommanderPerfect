class_name GalaxyTileAtlas
extends RefCounted
## One tile set of a Galaxy level (the background tiles, or the foreground
## tiles) as a Godot [TileSet] with a single atlas texture.
##
## Only the tiles a level can show go in (its own tiles and every tile of
## their animation loops; [GalaxyLevelMap] adds more when a tile changes):
## Keen 4 has 1296 + 2916 tiles, and with xBRZ (six times larger) an atlas
## of all of them would take over 100 MB. Each tile has a border that
## repeats its edge pixels, so that smoothly scaled graphics never pick up
## a line of the neighbouring tile.
##
## With scaled images the texture holds those, drawn at the size of the
## original tiles (as [GraphicsTextures] does for Keen 1-3), so the level
## never needs to know which graphics it shows.

const SOURCE_ID := 0
const TILE_SIZE := GalaxyGraphics.TILE16_SIZE
## Original pixels of border around every tile.
const PADDING := 1

## The tile set to give the [TileMapLayer]s.
var tile_set: TileSet
## The tile numbers in the atlas.
var tiles := PackedInt32Array()
var _coords: Dictionary[int, Vector2i] = {}
var _by_coords: Dictionary[Vector2i, int] = {}


## An atlas of [param images] (tile number to its 16×16 image); with
## [param scaled] (tile number to an image [param factor] times as large,
## for every tile in [param images]) the texture shows those instead.
static func build(
	images: Dictionary[int, Image], scaled: Dictionary[int, Image] = {}, factor := 1
) -> GalaxyTileAtlas:
	var atlas := GalaxyTileAtlas.new()
	var numbers := images.keys()
	numbers.sort()
	var columns := maxi(1, ceili(sqrt(numbers.size())))
	for index in numbers.size():
		atlas._coords[numbers[index]] = Vector2i(index % columns, index / columns)
		atlas._by_coords[atlas._coords[numbers[index]]] = numbers[index]
		atlas.tiles.append(numbers[index])
	var original := _sheet(images, atlas._coords, columns, 1)
	var texture := ImageTexture.create_from_image(original)
	if not scaled.is_empty() and factor > 1:
		texture = ImageTexture.create_from_image(_sheet(scaled, atlas._coords, columns, factor))
		texture.set_size_override(original.get_size())
	var source := TileSetAtlasSource.new()
	# Our own border instead of Godot's, which would be made from the
	# larger images inside a scaled texture.
	source.use_texture_padding = false
	source.texture = texture
	source.margins = Vector2i(PADDING, PADDING)
	source.separation = Vector2i(2 * PADDING, 2 * PADDING)
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for number: int in numbers:
		source.create_tile(atlas._coords[number])
	atlas.tile_set = TileSet.new()
	atlas.tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	atlas.tile_set.add_source(source, SOURCE_ID)
	return atlas


## Whether tile [param tile] is in the atlas.
func has(tile: int) -> bool:
	return _coords.has(tile)


## The atlas cell of tile [param tile] (only when [method has]).
func coords_of(tile: int) -> Vector2i:
	return _coords[tile]


## The tile at atlas cell [param coords], or -1.
func tile_at(coords: Vector2i) -> int:
	return _by_coords.get(coords, -1)


## [param images] in a grid of [param columns] at the cells in
## [param coords], [param factor] times the tile size, each with a border.
static func _sheet(
	images: Dictionary[int, Image], coords: Dictionary[int, Vector2i], columns: int, factor: int
) -> Image:
	var tile := TILE_SIZE * factor
	var border := PADDING * factor
	var cell := tile + 2 * border
	var rows := maxi(1, ceili(coords.size() / float(columns)))
	var sheet := Image.create_empty(columns * cell, rows * cell, false, Image.FORMAT_RGBA8)
	for number: int in coords:
		var image: Image = images.get(number)
		if image == null:
			continue
		var source := image.duplicate() as Image
		source.convert(Image.FORMAT_RGBA8)
		var inside := Rect2i(coords[number] * cell + Vector2i(border, border), Vector2i(tile, tile))
		sheet.blit_rect(source, Rect2i(Vector2i.ZERO, inside.size), inside.position)
		_repeat_edges(sheet, inside, border)
	return sheet


## Copies the edge pixels of [param rect] in [param image] outward over
## [param border] pixels.
static func _repeat_edges(image: Image, rect: Rect2i, border: int) -> void:
	for step in border:
		var top := rect.position.y - 1 - step
		var bottom := rect.end.y + step
		image.blit_rect(
			image, Rect2i(rect.position, Vector2i(rect.size.x, 1)), Vector2i(rect.position.x, top)
		)
		image.blit_rect(
			image,
			Rect2i(rect.position.x, rect.end.y - 1, rect.size.x, 1),
			Vector2i(rect.position.x, bottom)
		)
		var height := bottom - top + 1
		image.blit_rect(
			image,
			Rect2i(rect.position.x, top, 1, height),
			Vector2i(rect.position.x - 1 - step, top)
		)
		image.blit_rect(
			image, Rect2i(rect.end.x - 1, top, 1, height), Vector2i(rect.end.x + step, top)
		)
