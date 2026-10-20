class_name Keen3BackdropPictures
extends BackdropPictures
## The pictures behind Keen 3's levels (milestone C9): [BackdropPictures]
## with Keen 3's own folder ([constant FOLDER_KEEN_3], or the player's
## game_data/keen3/backgrounds), never Keen 1's or Keen 2's, and only for
## the levels where they look right.
##
## A picture takes the place of the sky (tile 143, light cyan), and of the
## sky's color around everything drawn on it: [method backdrop_color] is
## the color the game screen leaves out of the tiles. Keen 3 has two kinds
## of plain background:
##   - the sky of the levels outside; its color only sits around clouds,
##     trees, signs and grass, so a picture shows where the sky was, also
##     in a level that is mostly a building or a cave (levels 8, 11, 13
##     and 15) or mostly a base under a field (levels 9 and 10)
##   - the dark gray inside walls (tile 195) of the bases and caves; its
##     color is also in the cave rock and the patterned walls, so a picture
##     would shine through 11-61% of what is drawn there. It never lets a
##     picture through, not even in a level where it is the plain
##     background (levels 9 and 10: it is used more than their sky).
## So a level gets its picture when it has sky, and the picture shows only
## through the sky. Keen 2's rule ([Keen2BackdropPictures]: the plain
## background must be the most used tile) does not fit Keen 3: it would
## give levels 9 and 10 their picture behind the bases' walls and none to
## levels 8, 11, 13 and 15. In version 1.00 the levels with sky are 1-11,
## 13, 14 and 15; 12 and 16 have none.

## Keen 3's own pictures behind the levels (Keen 1's and 2's are never used).
const FOLDER_KEEN_3 := "res://assets/backgrounds/keen3"
## The sky of Keen 3's levels: one light cyan color, nothing to touch.
const SKY_TILE := 143

## The levels that have sky.
var _levels: Dictionary[int, bool] = {}


## The pictures for Keen 3's levels 1-16 in [param files]: Keen 3's own
## folder and the player's, for the levels with sky. A level that cannot be
## read gets no picture.
static func for_game(
	files: GameFiles, properties: TileProperties, tiles: Array[Image]
) -> Keen3BackdropPictures:
	var levels: Dictionary[int, LevelData] = {}
	for number in range(Keen3Files.FIRST_LEVEL, Keen3Files.LAST_LEVEL + 1):
		var level := LevelData.parse(files.read(files.level_file(number)))
		if level != null:
			levels[number] = level
	return for_levels(files, FOLDER_KEEN_3, levels, properties, tiles)


## The pictures in [param folder] (and the player's own folder in
## [param files]) for the levels in [param levels] (number to [LevelData])
## that have sky.
static func for_levels(
	files: GameFiles,
	folder: String,
	levels: Dictionary[int, LevelData],
	properties: TileProperties,
	tiles: Array[Image]
) -> Keen3BackdropPictures:
	var pictures := Keen3BackdropPictures.new()
	pictures._files = files
	pictures._folder = folder
	for number in levels:
		if suits(levels[number], properties, tiles):
			pictures._levels[number] = true
	return pictures


## Whether [param level] has sky, so that a picture can show through it.
## [param properties] and [param tiles] are not needed for that; they are
## kept so that the rule reads as Keen 2's ([method
## Keen2BackdropPictures.suits]).
static func suits(level: LevelData, _properties: TileProperties, _tiles: Array[Image]) -> bool:
	var area := level.playable_rect()
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			if level.tile_at(Vector2i(x, y)) == SKY_TILE:
				return true
	return false


## The color that a picture takes the place of, in every Keen 3 level with
## a picture: the sky's, never the dark gray of a base.
static func backdrop_color(tiles: Array[Image]) -> Color:
	return color_of(tiles[SKY_TILE])


## Whether level [param number] may show a picture.
func shows_level(number: int) -> bool:
	return _levels.has(number)


func picture(number: int) -> Texture2D:
	return super(number) if shows_level(number) else null
