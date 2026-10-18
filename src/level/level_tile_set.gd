class_name LevelTileSet
extends RefCounted
## Turns the decoded 16x16 tiles into a Godot TileSet for [LevelMap].
##
## All tiles go into one atlas texture, so a level is drawn from a single
## texture. Tile number n sits at atlas cell [method atlas_coords_of] n, which
## lets a tile number from a level file be used directly. Every tile has a
## border that repeats its edge pixels, so that smoothly scaled graphics
## never show a line of the neighbouring tile in the atlas.
##
## The tile set also knows which tiles have a mask ([MaskedTiles]).

const SOURCE_ID := 0
const ATLAS_COLUMNS := 16
const PADDING := 1


## Returns a TileSet that holds every tile of [param graphics]. With
## [param textures] the tiles come from there (and can be xBRZ or HD). With
## a [param backdrop_color] that background color is left out of the tiles,
## for a picture behind the level ([LevelBackdrop]).
static func build(
	graphics: EgaGraphics, textures: GraphicsTextures = null, backdrop_color := Color.TRANSPARENT
) -> TileSet:
	if textures == null:
		textures = GraphicsTextures.create(graphics)
	var tile_size := Vector2i(EgaGraphics.TILE_SIZE, EgaGraphics.TILE_SIZE)
	var source := TileSetAtlasSource.new()
	# Our own border instead of the one Godot can add, which would be made
	# from the larger images inside scaled textures.
	source.use_texture_padding = false
	if backdrop_color.a > 0.0:
		source.texture = textures.backdrop_tile_atlas(ATLAS_COLUMNS, PADDING, backdrop_color)
	else:
		source.texture = textures.tile_atlas(ATLAS_COLUMNS, PADDING)
	source.margins = Vector2i(PADDING, PADDING)
	source.separation = Vector2i(2 * PADDING, 2 * PADDING)
	source.texture_region_size = tile_size
	for tile_number in graphics.tiles.size():
		source.create_tile(atlas_coords_of(tile_number))

	var tile_set := TileSet.new()
	tile_set.tile_size = tile_size
	tile_set.add_source(source, SOURCE_ID)
	MaskedTiles.mark(tile_set, graphics, backdrop_color)
	return tile_set


## Atlas cell of a tile number; matches [method EgaGraphics.create_tile_atlas].
static func atlas_coords_of(tile_number: int) -> Vector2i:
	return Vector2i(tile_number % ATLAS_COLUMNS, tile_number / ATLAS_COLUMNS)
