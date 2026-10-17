class_name Keen2BackdropPictures
extends BackdropPictures
## The pictures behind Keen 2's levels ([BackdropPictures] with Keen 2's own
## folder), but only for the levels where they look right.
##
## A picture shows through the level's plain background tile, and through
## that tile's color wherever another tile has it. Most of Keen 2's levels
## have a patterned background (the gray diamonds, tile 143) and only a few
## plain tiles, whose color also sits in the pattern's dots: the picture
## would shine through those dots all over the level. So a level gets its
## picture only when its plain background tile is also the tile it uses most
## (in version 1.31: level 12).

## The levels whose plain background is their main background.
var _levels: Dictionary[int, bool] = {}


## The pictures in [param folder] (and the player's own folder in
## [param files]) for the levels in [param levels] (number to [LevelData])
## that suit them.
static func for_levels(
	files: GameFiles,
	folder: String,
	levels: Dictionary[int, LevelData],
	properties: TileProperties,
	tiles: Array[Image]
) -> Keen2BackdropPictures:
	var pictures := Keen2BackdropPictures.new()
	pictures._files = files
	pictures._folder = folder
	for number in levels:
		if suits(levels[number], properties, tiles):
			pictures._levels[number] = true
	return pictures


## Whether [param level]'s plain background tile is also its most used tile.
static func suits(level: LevelData, properties: TileProperties, tiles: Array[Image]) -> bool:
	var plain := background_tile(level, properties, tiles)
	return plain >= 0 and plain == most_used_tile(level)


## The tile [param level] uses most inside its playable area.
static func most_used_tile(level: LevelData) -> int:
	var counts: Dictionary[int, int] = {}
	var area := level.playable_rect()
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			var tile := level.tile_at(Vector2i(x, y))
			counts[tile] = counts.get(tile, 0) + 1
	var most := -1
	for tile in counts:
		if most < 0 or counts[tile] > counts[most]:
			most = tile
	return most


## Whether level [param number] may show a picture.
func shows_level(number: int) -> bool:
	return _levels.has(number)


func picture(number: int) -> Texture2D:
	return super(number) if shows_level(number) else null
