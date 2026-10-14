class_name MapCollision
extends LevelCollision
## Collisions on the world map: the tiles of the map, plus the entrances of
## levels that block the way until they are done (see [MapInfo]).

var progress: GameProgress


static func create_for_map(
	level_data: LevelData, tile_properties: TileProperties, game: GameProgress
) -> MapCollision:
	var collision := MapCollision.new()
	collision.level = level_data
	collision.properties = tile_properties
	collision.progress = game
	return collision


func is_solid(cell: Vector2i, edge: Edge) -> bool:
	if is_blocked(cell):
		return true
	return super.is_solid(cell, edge)


## Whether [param cell] is the entrance of a level that blocks the way.
func is_blocked(cell: Vector2i) -> bool:
	if not level.playable_rect().has_point(cell):
		return false
	var info := level.info_at(cell)
	return MapInfo.is_blocking(info) and not progress.is_completed(MapInfo.level_of(info))
