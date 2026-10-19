class_name Keen3BackdropPictures
extends BackdropPictures
## The pictures behind Keen 3's levels (milestone C9): [BackdropPictures]
## with Keen 3's own folder ([constant FOLDER_KEEN_3], or the player's
## game_data/keen3/backgrounds), never Keen 1's or Keen 2's, and only for
## the levels where they look right.
##
## The picture takes the place of the level's plain background tile
## ([method BackdropPictures.background_tile]), and of that tile's color
## around everything drawn on it. Keen 3 has two kinds of plain background:
##   - the sky (tile 143, light cyan) of the levels outside; its color only
##     sits around clouds, trees, signs and grass, so a picture shows where
##     the sky was, also in a level that is mostly a building or a cave
##     (levels 8, 11, 13 and 15)
##   - the dark gray inside walls (tile 195) of the bases and caves
##     (levels 9, 10, 12 and 16); its color is also in the cave rock and the
##     patterned walls, so a picture would shine through 11-61% of what is
##     drawn there. Level 10 has some sky above its base, but the base is
##     larger: its plain background is the dark gray.
## So a level gets its picture only when its plain background is the sky.
## Keen 2's rule ([Keen2BackdropPictures]: the plain background must be the
## most used tile) does not fit Keen 3: it would give level 10 its picture
## behind the base's walls and none to levels 8, 11, 13 and 15. In version
## 1.00 the levels with sky are 1-8, 11, 13, 14 and 15.

## Keen 3's own pictures behind the levels (Keen 1's and 2's are never used).
const FOLDER_KEEN_3 := "res://assets/backgrounds/keen3"
## The sky of Keen 3's levels: one light cyan color, nothing to touch.
const SKY_TILE := 143

## The levels whose plain background is the sky.
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
## whose plain background is the sky.
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


## Whether [param level]'s plain background is the sky.
static func suits(level: LevelData, properties: TileProperties, tiles: Array[Image]) -> bool:
	return background_tile(level, properties, tiles) == SKY_TILE


## Whether level [param number] may show a picture.
func shows_level(number: int) -> bool:
	return _levels.has(number)


func picture(number: int) -> Texture2D:
	return super(number) if shows_level(number) else null
