class_name LevelMap
extends TileMapLayer
## Draws the tile layer of a level with the tiles from [LevelTileSet].
##
## Only the playable area is drawn. The border around it is never visible in
## the original, and leaving it empty means that a level narrower than a
## widescreen view gets black bars instead of border tiles.
##
## With [TileProperties], foreground tiles go to a second layer that is drawn
## in front of Keen, and animated tiles cycle through their frames.

## Seconds per animation frame of animated tiles.
const ANIMATION_FRAME_TIME := 0.1
## Drawn above Keen and the other sprites, which have z index 0.
const FOREGROUND_Z_INDEX := 1

var _foreground := TileMapLayer.new()
var _properties: TileProperties
## Animated cells and the tile the level puts there.
var _animated_cells: Dictionary[Vector2i, int] = {}
var _animation_time := 0.0
var _animation_step := 0


func _init() -> void:
	_foreground.name = "Foreground"
	_foreground.z_index = FOREGROUND_Z_INDEX
	add_child(_foreground)


func _process(delta: float) -> void:
	animate(delta)


## Replaces the current contents with [param level]. Assign [member tile_set]
## first. Tile numbers that the tile set does not have are left empty.
## Without [param properties] every tile is drawn behind Keen and nothing
## is animated.
func show_level(level: LevelData, properties: TileProperties = null) -> void:
	clear()
	_foreground.clear()
	_foreground.tile_set = tile_set
	_properties = properties
	_animated_cells.clear()
	_animation_time = 0.0
	_animation_step = 0

	var playable := level.playable_rect()
	for y in range(playable.position.y, playable.end.y):
		for x in range(playable.position.x, playable.end.x):
			var cell := Vector2i(x, y)
			var tile := level.tile_at(cell)
			if properties != null and properties.is_animated(tile):
				_animated_cells[cell] = tile
			_draw_tile(cell, tile)


## Draws the level with [param new_tile_set] from now on (other graphics,
## the same tile numbers), keeping every cell.
func use_tile_set(new_tile_set: TileSet) -> void:
	tile_set = new_tile_set
	_foreground.tile_set = new_tile_set


## Changes the tile in [param cell], for example when Keen picks up an item.
func set_tile(cell: Vector2i, tile: int) -> void:
	if _properties != null and _properties.is_animated(tile):
		_animated_cells[cell] = tile
	else:
		_animated_cells.erase(cell)
	_draw_tile(cell, tile)


## The layer with the tiles that are drawn in front of Keen.
func foreground() -> TileMapLayer:
	return _foreground


## Advances the tile animations by [param seconds].
func animate(seconds: float) -> void:
	if _animated_cells.is_empty():
		return
	_animation_time += seconds
	var step := floori(_animation_time / ANIMATION_FRAME_TIME)
	if step == _animation_step:
		return
	_animation_step = step
	for cell in _animated_cells:
		_draw_tile(cell, _properties.animated_tile(_animated_cells[cell], step))


func _draw_tile(cell: Vector2i, tile: int) -> void:
	var in_front := _properties != null and _properties.is_foreground(tile)
	var layer: TileMapLayer = _foreground if in_front else self
	var other: TileMapLayer = self if in_front else _foreground
	other.erase_cell(cell)
	var source := tile_set.get_source(LevelTileSet.SOURCE_ID) as TileSetAtlasSource
	var atlas_coords := LevelTileSet.atlas_coords_of(tile)
	if source.has_tile(atlas_coords):
		layer.set_cell(cell, LevelTileSet.SOURCE_ID, atlas_coords)
	else:
		layer.erase_cell(cell)


## The playable area in pixels.
static func playable_pixels(level: LevelData) -> Rect2i:
	var playable := level.playable_rect()
	return Rect2i(playable.position * EgaGraphics.TILE_SIZE, playable.size * EgaGraphics.TILE_SIZE)
