class_name LevelTileSet
extends RefCounted
## Turns the decoded 16x16 tiles into a Godot TileSet for [LevelMap].
##
## All tiles go into one atlas texture, so a level is drawn from a single
## texture. Tile number n sits at atlas cell [method atlas_coords_of] n, which
## lets a tile number from a level file be used directly.

const SOURCE_ID := 0
const ATLAS_COLUMNS := 16


## Returns a TileSet that holds every tile of [param graphics].
static func build(graphics: EgaGraphics) -> TileSet:
	var tile_size := Vector2i(EgaGraphics.TILE_SIZE, EgaGraphics.TILE_SIZE)
	var source := TileSetAtlasSource.new()
	source.texture = ImageTexture.create_from_image(graphics.create_tile_atlas(ATLAS_COLUMNS))
	source.texture_region_size = tile_size
	for tile_number in graphics.tiles.size():
		source.create_tile(atlas_coords_of(tile_number))

	var tile_set := TileSet.new()
	tile_set.tile_size = tile_size
	tile_set.add_source(source, SOURCE_ID)
	return tile_set


## Atlas cell of a tile number; matches [method EgaGraphics.create_tile_atlas].
static func atlas_coords_of(tile_number: int) -> Vector2i:
	return Vector2i(tile_number % ATLAS_COLUMNS, tile_number / ATLAS_COLUMNS)
