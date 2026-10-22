class_name GalaxyTileAnimator
extends RefCounted
## Runs the animated tiles of a Galaxy map, as TILEINFO says: after a tile's
## animation time (in tics) the tile becomes tile + its animation offset,
## and so on around its loop. Background and foreground tiles alike.
##
## As in the original (Omni `id_rf.c:RF_MarkTileGraphics`,
## `RFL_AnimateTiles`), every tile number that a map starts with gets one
## [Cycle], shared by all cells that start with it, so they move in step.
## A cycle counts its time down by the tics of each logic frame; when it
## reaches 0 or less it moves on one tile (at most one per frame) and adds
## the new tile's time. A tile with an offset but no time (a gem holder, a
## bridge) does not move by itself.
##
## The animator only keeps the time; [GalaxyLevelMap] draws the tiles that
## [method advance] reports and writes them into the map.


## One loop of tiles running on the map.
class Cycle:
	extends RefCounted
	var layer := GalaxyMap.Layer.BACKGROUND
	## The tile the map started with; it names the cycle.
	var start_tile := 0
	## The tile shown now.
	var tile := 0
	## Tics until the next tile; 0 or less moves on.
	var time_left := 0
	## The cells (x, y) that show this cycle.
	var cells: Array[Vector2i] = []


## The longest loop followed when listing a cycle's tiles (Omni
## RF_MAX_ANIM_LOOP is 20; a broken table must not hang the game).
const MAX_LOOP := 64

var _tile_info: GalaxyTileInfo
var _cycles: Array[Cycle] = []
## Cycles by layer and start tile ([method _key]).
var _by_start: Dictionary[int, Cycle] = {}
## The cycle each animated cell belongs to, by layer and cell index.
var _by_cell: Dictionary[int, Cycle] = {}
var _width := 0


## The animated tiles of the background and foreground planes of
## [param map].
static func for_map(map: GalaxyMap, tile_info: GalaxyTileInfo) -> GalaxyTileAnimator:
	var animator := GalaxyTileAnimator.new()
	animator._tile_info = tile_info
	animator._width = map.width
	for layer: GalaxyMap.Layer in [GalaxyMap.Layer.BACKGROUND, GalaxyMap.Layer.FOREGROUND]:
		for y in map.height:
			for x in map.width:
				animator.track(layer, Vector2i(x, y), map.tile(layer, x, y))
	return animator


## Whether [param tile] of [param layer] moves by itself.
static func is_animated(tile_info: GalaxyTileInfo, layer: GalaxyMap.Layer, tile: int) -> bool:
	return _offset(tile_info, layer, tile) != 0 and _time(tile_info, layer, tile) != 0


## Every tile that [param tile] of [param layer] turns into, [param tile]
## first; just [param tile] when it does not move.
static func loop_of(
	tile_info: GalaxyTileInfo, layer: GalaxyMap.Layer, tile: int
) -> PackedInt32Array:
	var tiles := PackedInt32Array([tile])
	if not is_animated(tile_info, layer, tile):
		return tiles
	var next := tile + _offset(tile_info, layer, tile)
	while next != tile and not tiles.has(next) and tiles.size() < MAX_LOOP:
		tiles.append(next)
		if _offset(tile_info, layer, next) == 0:
			break
		next += _offset(tile_info, layer, next)
	return tiles


## The cycles running now.
func cycles() -> Array[Cycle]:
	return _cycles


## Lets [param tics] tics pass; returns the cycles whose tile changed.
func advance(tics: int) -> Array[Cycle]:
	var changed: Array[Cycle] = []
	for cycle in _cycles:
		cycle.time_left -= tics
		if cycle.time_left > 0:
			continue
		cycle.tile += _offset(_tile_info, cycle.layer, cycle.tile)
		cycle.time_left += _time(_tile_info, cycle.layer, cycle.tile)
		if not cycle.cells.is_empty():
			changed.append(cycle)
	return changed


## Puts [param cell] of [param layer], which now shows [param tile], into
## the cycle that starts with that tile (made when there is none yet), or
## out of any cycle when the tile does not move.
func track(layer: GalaxyMap.Layer, cell: Vector2i, tile: int) -> void:
	forget(layer, cell)
	if not is_animated(_tile_info, layer, tile):
		return
	var key := _key(layer, tile)
	var cycle: Cycle = _by_start.get(key)
	if cycle == null:
		cycle = Cycle.new()
		cycle.layer = layer
		cycle.start_tile = tile
		cycle.tile = tile
		cycle.time_left = _time(_tile_info, layer, tile)
		_by_start[key] = cycle
		_cycles.append(cycle)
	cycle.cells.append(cell)
	_by_cell[_cell_key(layer, cell)] = cycle


## Takes [param cell] of [param layer] out of its cycle.
func forget(layer: GalaxyMap.Layer, cell: Vector2i) -> void:
	var key := _cell_key(layer, cell)
	var cycle: Cycle = _by_cell.get(key)
	if cycle != null:
		cycle.cells.erase(cell)
		_by_cell.erase(key)


func _key(layer: GalaxyMap.Layer, tile: int) -> int:
	return (tile << 1) | layer


func _cell_key(layer: GalaxyMap.Layer, cell: Vector2i) -> int:
	return ((cell.y * _width + cell.x) << 1) | layer


static func _offset(tile_info: GalaxyTileInfo, layer: GalaxyMap.Layer, tile: int) -> int:
	if layer == GalaxyMap.Layer.BACKGROUND:
		return tile_info.next_back_tile(tile) - tile
	return tile_info.next_fore_tile(tile) - tile


static func _time(tile_info: GalaxyTileInfo, layer: GalaxyMap.Layer, tile: int) -> int:
	if layer == GalaxyMap.Layer.BACKGROUND:
		return tile_info.back(GalaxyTileInfo.Back.ANIMATION_TIME, tile)
	return tile_info.fore(GalaxyTileInfo.Fore.ANIMATION_TIME, tile)
