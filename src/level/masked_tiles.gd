class_name MaskedTiles
extends RefCounted
## Which tiles of a [LevelTileSet] have a mask, and the material that draws
## them through it.
##
## A masked tile (behavior -2, used by Keen 2 and 3) is drawn behind the
## sprites like any tile, and in front of them only where its mask, the next
## tile, is black ([method EgaGraphics.has_tile_mask]). [LevelMap] draws
## those parts with [method material_of] on a layer in front of the sprites.
## A masked tile whose next tile is not a mask stays a plain foreground tile.
##
## The tile set carries this itself (a custom data layer and metadata), so
## every game that builds its tiles with [method LevelTileSet.build] gets it.

## The custom data layer that marks a tile with a mask.
const HAS_MASK_LAYER := "has_mask"
## The metadata of the tile set that holds the material.
const MATERIAL_META := &"masked_tiles_material"
## Below this brightness a background color counts as black (see the shader).
const DARK_LUMINANCE := 0.5
const SHADER := preload("res://src/graphics/masked_tiles.gdshader")


## Marks the tiles of [param tile_set] (made from [param graphics], with
## [param backdrop_color] left out of its tiles when it is not transparent)
## that have a mask, and gives the tile set the material that draws them.
static func mark(tile_set: TileSet, graphics: EgaGraphics, backdrop_color: Color) -> void:
	tile_set.add_custom_data_layer()
	var layer := tile_set.get_custom_data_layers_count() - 1
	tile_set.set_custom_data_layer_name(layer, HAS_MASK_LAYER)
	tile_set.set_custom_data_layer_type(layer, TYPE_BOOL)
	var source := tile_set.get_source(LevelTileSet.SOURCE_ID) as TileSetAtlasSource
	for tile in graphics.tiles.size():
		if graphics.has_tile_mask(tile):
			source.get_tile_data(LevelTileSet.atlas_coords_of(tile), 0).set_custom_data(
				HAS_MASK_LAYER, true
			)
	tile_set.set_meta(MATERIAL_META, _material(graphics.tiles.size(), backdrop_color))


## Whether [param tile] of [param tile_set] has a mask. False for tile sets
## that were not marked and for tiles they do not have.
static func has_mask(tile_set: TileSet, tile: int) -> bool:
	if tile_set == null or not tile_set.has_meta(MATERIAL_META):
		return false
	var source := tile_set.get_source(LevelTileSet.SOURCE_ID) as TileSetAtlasSource
	var coords := LevelTileSet.atlas_coords_of(tile)
	if tile < 0 or not source.has_tile(coords):
		return false
	return source.get_tile_data(coords, 0).get_custom_data(HAS_MASK_LAYER)


## The material that draws only the masked parts of the tiles of
## [param tile_set], or null when it was not marked.
static func material_of(tile_set: TileSet) -> ShaderMaterial:
	if tile_set == null or not tile_set.has_meta(MATERIAL_META):
		return null
	return tile_set.get_meta(MATERIAL_META)


static func _material(tile_count: int, backdrop_color: Color) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("columns", float(LevelTileSet.ATLAS_COLUMNS))
	material.set_shader_parameter(
		"rows", float(ceili(tile_count / float(LevelTileSet.ATLAS_COLUMNS)))
	)
	material.set_shader_parameter(
		"holes_drawn", backdrop_color.a > 0.0 and backdrop_color.get_luminance() < DARK_LUMINANCE
	)
	return material
