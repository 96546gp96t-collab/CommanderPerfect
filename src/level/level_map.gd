class_name LevelMap
extends TileMapLayer
## Draws the tile layer of a level with the tiles from [LevelTileSet].
##
## Only the playable area is drawn. The border around it is never visible in
## the original, and leaving it empty means that a level narrower than a
## widescreen view gets black bars instead of border tiles.


## Replaces the current contents with [param level]. Assign [member tile_set]
## first. Tile numbers that the tile set does not have are left empty.
func show_level(level: LevelData) -> void:
	clear()
	var source := tile_set.get_source(LevelTileSet.SOURCE_ID) as TileSetAtlasSource
	var playable := level.playable_rect()
	for y in range(playable.position.y, playable.end.y):
		for x in range(playable.position.x, playable.end.x):
			var cell := Vector2i(x, y)
			var atlas_coords := LevelTileSet.atlas_coords_of(level.tile_at(cell))
			if source.has_tile(atlas_coords):
				set_cell(cell, LevelTileSet.SOURCE_ID, atlas_coords)


## The playable area in pixels.
static func playable_pixels(level: LevelData) -> Rect2i:
	var playable := level.playable_rect()
	return Rect2i(playable.position * EgaGraphics.TILE_SIZE, playable.size * EgaGraphics.TILE_SIZE)
