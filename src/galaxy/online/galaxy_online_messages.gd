class_name GalaxyOnlineMessages
extends RefCounted
## The Galaxy engine's own online messages besides [GalaxySnapshot]
## (milestone D12): what the host's screen shows, and a tile that changed.
## Keen 1-3's messages ([OnlineMessages]) stay as they were; these kinds are
## appended at the end of [enum OnlineProtocol.Message]. As there, every
## reader checks each part, because it comes from the network, and returns
## an empty array for a message that is not a sane one of its kind.

## What the host's screen shows. WAITING: no map (the title loop, the high
## scores, a menu); MAP: a map is played (a level or the world map);
## ENDING: the end pages, which each player reads at his own pace.
enum Scene { WAITING, MAP, ENDING }

## Numbers per changed tile: the plane, x, y, the tile.
const TILE_FIELDS := 4
## A Galaxy map is at most a few hundred tiles a side; the episode has at
## most 100 maps.
const MAX_CELL := 1024
const MAX_MAP := 99
const MAX_TILE := 65535


static func scene(scene_id: int, kind: Scene, number: int, tiles: PackedInt32Array) -> Array:
	return [OnlineProtocol.Message.GALAXY_SCENE, scene_id, kind, number, tiles]


## [scene id, kind, map number, tiles] or empty.
static func read_scene(message: Array) -> Array:
	if message.size() != 5 or not _all_ints(message.slice(1, 4)):
		return []
	if message[2] < 0 or message[2] >= Scene.size():
		return []
	if message[3] < 0 or message[3] > MAX_MAP or not message[4] is PackedInt32Array:
		return []
	var tiles: PackedInt32Array = message[4]
	if tiles.size() % TILE_FIELDS != 0:
		return []
	for start in range(0, tiles.size(), TILE_FIELDS):
		if not is_sane_tile(tiles[start], tiles[start + 1], tiles[start + 2], tiles[start + 3]):
			return []
	return [message[1], message[2], message[3], tiles]


static func tile(scene_id: int, layer: int, cell: Vector2i, tile_number: int) -> Array:
	return [OnlineProtocol.Message.GALAXY_TILE, scene_id, layer, cell.x, cell.y, tile_number]


## [scene id, plane, cell, tile] or empty.
static func read_tile(message: Array) -> Array:
	if message.size() != 6 or not _all_ints(message.slice(1)):
		return []
	if not is_sane_tile(message[2], message[3], message[4], message[5]):
		return []
	return [message[1], message[2], Vector2i(message[3], message[4]), message[5]]


## The tiles of [param map] that differ from [param original], in all
## three planes: plane, x, y and the tile for each.
static func changed_tiles(map: GalaxyMap, original: GalaxyMap) -> PackedInt32Array:
	var tiles := PackedInt32Array()
	if map == null or original == null:
		return tiles
	if map.width != original.width or map.height != original.height:
		return tiles
	for layer in mini(map.planes.size(), original.planes.size()):
		var now := map.planes[layer]
		var before := original.planes[layer]
		for index in mini(now.size(), before.size()):
			if now[index] != before[index]:
				tiles.append_array([layer, index % map.width, index / map.width, now[index]])
	return tiles


## Puts [param tiles] ([method changed_tiles]) into [param map].
static func apply_tiles(map: GalaxyMap, tiles: PackedInt32Array) -> void:
	for start in range(0, tiles.size(), TILE_FIELDS):
		var layer := tiles[start]
		var x := tiles[start + 1]
		var y := tiles[start + 2]
		if layer < map.planes.size() and x < map.width and y < map.height:
			map.planes[layer][y * map.width + x] = tiles[start + 3]


static func is_sane_tile(layer: int, x: int, y: int, tile_number: int) -> bool:
	return (
		layer >= 0
		and layer < GalaxyMap.PLANE_COUNT
		and x >= 0
		and y >= 0
		and x < MAX_CELL
		and y < MAX_CELL
		and tile_number >= 0
		and tile_number <= MAX_TILE
	)


static func _all_ints(values: Array) -> bool:
	return values.all(func(value: Variant) -> bool: return value is int)
