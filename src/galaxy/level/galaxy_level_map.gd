class_name GalaxyLevelMap
extends Node2D
## Draws the tiles of a Galaxy map on three [TileMapLayer]s:
##   - the background tiles, behind everything;
##   - the foreground tiles, over the background and behind the sprites;
##   - the foreground tiles whose TILEINFO misc has bit 0x80, in front of
##     the sprites (a door frame, the grass Keen walks behind). Only that
##     bit decides; nothing is guessed (docs/keen4/architecture.md).
## The original draws its sprites of priority 0-2 between the second and
## the third, and those of priority 3 over all of them (Omni
## `id_rf.c:RFL_DrawSpriteList`); [GalaxyObjectLayer] uses [constant
## FRONT_Z] for that.
##
## Every change of a tile goes through [method set_tile] (later: doors,
## items, switches, bridges, Miragia), which writes the map, draws the cell
## and keeps the animation right. Animated tiles run on the logic frames'
## tics ([method animate], [GalaxyTileAnimator]). The whole map is drawn,
## its 2-tile border too: the camera never shows it in 4:3, and in
## widescreen the view is covered beyond the scroll area ([GalaxyCamera]).

## Asked when [method set_tile] puts a tile that is not in the atlas of
## [param layer]: give the layer a new atlas with [method wanted_tiles].
signal tiles_missing(layer: GalaxyMap.Layer)

## The z index of the in-front foreground tiles: sprites of priority 0-2
## are drawn below it, priority 3 above it ([GalaxyObjectLayer]).
const FRONT_Z := 4
## Foreground tile 0 is nothing (file-formats.md).
const EMPTY_FORE_TILE := 0

var map: GalaxyMap
var tile_info: GalaxyTileInfo
var animator: GalaxyTileAnimator
var _back := TileMapLayer.new()
var _fore := TileMapLayer.new()
var _front := TileMapLayer.new()
var _back_atlas: GalaxyTileAtlas
var _fore_atlas: GalaxyTileAtlas
## Tiles put by [method set_tile] that the map did not start with.
var _extra_tiles: Dictionary[GalaxyMap.Layer, PackedInt32Array] = {
	GalaxyMap.Layer.BACKGROUND: PackedInt32Array(),
	GalaxyMap.Layer.FOREGROUND: PackedInt32Array(),
}


func _init() -> void:
	_back.name = "Background"
	_fore.name = "Foreground"
	_front.name = "InFront"
	_front.z_index = FRONT_Z
	for layer in [_back, _fore, _front]:
		add_child(layer)


## The tiles of [param layer] that [param map] can show: its own and every
## tile of their animation loops, each once.
static func tiles_of(
	map: GalaxyMap, tile_info: GalaxyTileInfo, layer: GalaxyMap.Layer
) -> PackedInt32Array:
	var seen: Dictionary[int, bool] = {}
	for tile in map.planes[layer]:
		if seen.has(tile):
			continue
		for step in GalaxyTileAnimator.loop_of(tile_info, layer, tile):
			seen[step] = true
	var tiles := PackedInt32Array(seen.keys())
	tiles.sort()
	return tiles


## Shows [param new_map] with the tiles of [param back_atlas] and
## [param fore_atlas] (made from [method tiles_of]).
func show_map(
	new_map: GalaxyMap,
	info: GalaxyTileInfo,
	back_atlas: GalaxyTileAtlas,
	fore_atlas: GalaxyTileAtlas
) -> void:
	map = new_map
	tile_info = info
	for layer: GalaxyMap.Layer in _extra_tiles:
		_extra_tiles[layer] = PackedInt32Array()
	animator = GalaxyTileAnimator.for_map(map, tile_info)
	use_atlases(back_atlas, fore_atlas)


## Draws the map with other atlases (other graphics, or more tiles), the
## same tile numbers.
func use_atlases(back_atlas: GalaxyTileAtlas, fore_atlas: GalaxyTileAtlas) -> void:
	_back_atlas = back_atlas
	_fore_atlas = fore_atlas
	_back.tile_set = back_atlas.tile_set
	_fore.tile_set = fore_atlas.tile_set
	_front.tile_set = fore_atlas.tile_set
	redraw()


## Draws every cell again.
func redraw() -> void:
	for layer in [_back, _fore, _front]:
		layer.clear()
	if map == null:
		return
	for y in map.height:
		for x in map.width:
			var cell := Vector2i(x, y)
			_draw_back(cell, map.tile(GalaxyMap.Layer.BACKGROUND, x, y))
			_draw_fore(cell, map.tile(GalaxyMap.Layer.FOREGROUND, x, y))


## The tiles [param layer] needs now: [method tiles_of] and those that
## [method set_tile] put since.
func wanted_tiles(layer: GalaxyMap.Layer) -> PackedInt32Array:
	var tiles := tiles_of(map, tile_info, layer)
	for tile in _extra_tiles[layer]:
		for step in GalaxyTileAnimator.loop_of(tile_info, layer, tile):
			if not tiles.has(step):
				tiles.append(step)
	tiles.sort()
	return tiles


## Lets [param tics] tics pass for the animated tiles.
func animate(tics: int) -> void:
	if animator == null:
		return
	for cycle in animator.advance(tics):
		for cell in cycle.cells:
			_write(cycle.layer, cell, cycle.tile)


## Puts [param tile] in [param cell] of [param layer] (background or
## foreground): in the map, on the screen, and in the animation.
func set_tile(layer: GalaxyMap.Layer, cell: Vector2i, tile: int) -> void:
	if map == null or layer == GalaxyMap.Layer.INFO:
		return
	animator.track(layer, cell, tile)
	var atlas := _back_atlas if layer == GalaxyMap.Layer.BACKGROUND else _fore_atlas
	var missing := false
	for step in GalaxyTileAnimator.loop_of(tile_info, layer, tile):
		if not atlas.has(step) and not _is_empty(layer, step):
			missing = true
			if not _extra_tiles[layer].has(step):
				_extra_tiles[layer].append(step)
	_write(layer, cell, tile)
	if missing:
		tiles_missing.emit(layer)


## The tile drawn in [param cell] of the in-front layer, or -1 (for tests
## and screenshots: what is drawn in front of Keen).
func front_tile_at(cell: Vector2i) -> int:
	return _tile_on(_front, _fore_atlas, cell)


## The tile drawn in [param cell] of the foreground layer behind the
## sprites, or -1.
func fore_tile_at(cell: Vector2i) -> int:
	return _tile_on(_fore, _fore_atlas, cell)


## The tile drawn in [param cell] of the background layer, or -1.
func back_tile_at(cell: Vector2i) -> int:
	return _tile_on(_back, _back_atlas, cell)


func _write(layer: GalaxyMap.Layer, cell: Vector2i, tile: int) -> void:
	map.planes[layer][cell.y * map.width + cell.x] = tile
	if layer == GalaxyMap.Layer.BACKGROUND:
		_draw_back(cell, tile)
	else:
		_draw_fore(cell, tile)


func _draw_back(cell: Vector2i, tile: int) -> void:
	_put(_back, _back_atlas, cell, tile)


func _draw_fore(cell: Vector2i, tile: int) -> void:
	_fore.erase_cell(cell)
	_front.erase_cell(cell)
	if tile != EMPTY_FORE_TILE:
		_put(_front if tile_info.is_in_front(tile) else _fore, _fore_atlas, cell, tile)


func _put(layer: TileMapLayer, atlas: GalaxyTileAtlas, cell: Vector2i, tile: int) -> void:
	if atlas != null and atlas.has(tile):
		layer.set_cell(cell, GalaxyTileAtlas.SOURCE_ID, atlas.coords_of(tile))
	else:
		layer.erase_cell(cell)


func _is_empty(layer: GalaxyMap.Layer, tile: int) -> bool:
	return layer == GalaxyMap.Layer.FOREGROUND and tile == EMPTY_FORE_TILE


static func _tile_on(layer: TileMapLayer, atlas: GalaxyTileAtlas, cell: Vector2i) -> int:
	if atlas == null or layer.get_cell_source_id(cell) < 0:
		return -1
	return atlas.tile_at(layer.get_cell_atlas_coords(cell))
