class_name LevelWall
extends TileMapLayer
## The wall behind a level (milestone AB2): a layer just behind the tiles
## of [LevelMap], with the same cells, that draws on each the wall's shape
## of its tile ([method BackdropHoles.mask]) filled with a texture that
## repeats and is fixed to the level ([code]level_wall.gdshader[/code]). It
## moves 1:1 with the tiles, as the back wall of Keen 2's rooms (the
## lattice) does in the original.
##
## It is part of the level's own canvas, so Keen 2's darkness (a
## [CanvasModulate]) dims it with the level, and the second view of a split
## screen, which looks at the same canvas, shows it too.

## Just behind the tiles (z index 0) and the sprites.
const Z_INDEX := -1
const SHADER := preload("res://src/graphics/level_wall.gdshader")


func _init() -> void:
	name = "Wall"
	z_index = Z_INDEX
	# One mask pixel per game pixel, never blurred, whatever the graphics.
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	material = ShaderMaterial.new()
	(material as ShaderMaterial).shader = SHADER
	visible = false


## Draws [param texture] through the masks of [param masks] (a tile set from
## [method LevelTileSet.build_wall_masks]); null for either shows no wall.
## The cells are drawn again with [method draw_tile].
func set_up(masks: TileSet, texture: Texture2D) -> void:
	clear()
	tile_set = masks
	(material as ShaderMaterial).set_shader_parameter("wall_texture", texture)
	visible = masks != null and texture != null


## Whether a wall is drawn.
func is_showing() -> bool:
	return visible


## Puts the wall of [param tile] into [param cell]; nothing where that tile
## has no wall.
func draw_tile(cell: Vector2i, tile: int) -> void:
	if not visible:
		return
	var source := tile_set.get_source(LevelTileSet.SOURCE_ID) as TileSetAtlasSource
	var coords := LevelTileSet.atlas_coords_of(tile)
	if tile >= 0 and source.has_tile(coords):
		set_cell(cell, LevelTileSet.SOURCE_ID, coords)
	else:
		erase_cell(cell)
