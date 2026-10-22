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
## The same tiles with only the wall's holes ([method build_with_holes]),
## for the cells where the sky's colour is not the sky.
const SKY_KEPT_SOURCE_ID := 1
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
	var texture: Texture2D
	if backdrop_color.a > 0.0:
		texture = textures.backdrop_tile_atlas(ATLAS_COLUMNS, PADDING, backdrop_color)
	else:
		texture = textures.tile_atlas(ATLAS_COLUMNS, PADDING)
	var tile_set := _tile_set()
	tile_set.add_source(_source(texture, graphics.tiles.size()), SOURCE_ID)
	MaskedTiles.mark(tile_set, graphics, backdrop_color)
	return tile_set


## The tiles of [param graphics] (from [param textures]) with the holes of
## [param holes] left out, for the sky and the wall behind the level
## (milestone AB2). With a sky it has a second source,
## [constant SKY_KEPT_SOURCE_ID], whose tiles keep the sky's colour.
static func build_with_holes(
	graphics: EgaGraphics, textures: GraphicsTextures, holes: BackdropHoles
) -> TileSet:
	var count := graphics.tiles.size()
	var tile_set := _tile_set()
	var atlas := textures.holes_tile_atlas(ATLAS_COLUMNS, PADDING, holes)
	tile_set.add_source(_source(atlas, count), SOURCE_ID)
	if holes.has_sky():
		var kept := textures.holes_tile_atlas(ATLAS_COLUMNS, PADDING, holes, true)
		tile_set.add_source(_source(kept, count), SKY_KEPT_SOURCE_ID)
	MaskedTiles.mark(tile_set, graphics, holes.sky_color)
	return tile_set


## The wall's shape on the tiles of [param textures] that have some wall,
## for [LevelWall]; the others are left out.
static func build_wall_masks(textures: GraphicsTextures, holes: BackdropHoles) -> TileSet:
	var source := _source(textures.wall_mask_atlas(ATLAS_COLUMNS, PADDING, holes), 0)
	var kinds := textures.hole_kinds(holes)
	for tile_number in kinds.size():
		if BackdropHoles.has_wall_in(kinds[tile_number]):
			source.create_tile(atlas_coords_of(tile_number))
	var tile_set := _tile_set()
	tile_set.add_source(source, SOURCE_ID)
	return tile_set


## The tile number at atlas cell [param coords].
static func tile_at(coords: Vector2i) -> int:
	return coords.y * ATLAS_COLUMNS + coords.x


static func _tile_set() -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(EgaGraphics.TILE_SIZE, EgaGraphics.TILE_SIZE)
	return tile_set


## An atlas source of [param texture] (laid out as [method
## GraphicsTextures.tile_atlas]) with its first [param count] tiles.
static func _source(texture: Texture2D, count: int) -> TileSetAtlasSource:
	var source := TileSetAtlasSource.new()
	# Our own border instead of the one Godot can add, which would be made
	# from the larger images inside scaled textures.
	source.use_texture_padding = false
	source.texture = texture
	source.margins = Vector2i(PADDING, PADDING)
	source.separation = Vector2i(2 * PADDING, 2 * PADDING)
	source.texture_region_size = Vector2i(EgaGraphics.TILE_SIZE, EgaGraphics.TILE_SIZE)
	for tile_number in count:
		source.create_tile(atlas_coords_of(tile_number))
	return source


## Atlas cell of a tile number; matches [method EgaGraphics.create_tile_atlas].
static func atlas_coords_of(tile_number: int) -> Vector2i:
	return Vector2i(tile_number % ATLAS_COLUMNS, tile_number / ATLAS_COLUMNS)
