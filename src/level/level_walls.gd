class_name LevelWalls
extends RefCounted
## The walls behind an episode's levels (milestone AB2): their textures
## ([method BackdropPictures.walls]: wallNN in the episode's folder, or the
## player's own backgrounds folder), and which pixels of a level's tiles
## the sky and the wall take the place of ([method holes]). The episodes'
## rules are in [Keen1Walls] and [Keen2Walls]; this one has only the sky.
##
## [GameScreen] uses it where an episode has one: Keen 1 and Keen 2. A level
## without a texture keeps its own wall, as in the original.

var _textures: BackdropPictures
var _tiles: Array[Image] = []


## The texture of the wall behind level [param number], or null.
func texture(number: int) -> Texture2D:
	return _textures.picture(number) if _textures != null else null


## The holes in [param level]'s tiles: for the sky where [param sky_color]
## is not transparent, and for the wall when [param wall] (the level has a
## texture). Null when nothing is left out.
func holes(_level: LevelData, sky_color: Color, _wall: bool) -> BackdropHoles:
	return BackdropHoles.create(sky_color) if sky_color.a > 0.0 else null


## The cells of [param level] whose sky colour is not the sky, for
## [param holes]: drawn with that colour kept.
func sky_kept_cells(_level: LevelData, _holes: BackdropHoles) -> Dictionary[Vector2i, bool]:
	return {}


## Whether [param level] uses tile [param tile] in its playable area.
static func uses_tile(level: LevelData, tile: int) -> bool:
	var area := level.playable_rect()
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			if level.tile_at(Vector2i(x, y)) == tile:
				return true
	return false


## The colour of tile [param tile] (a plain one), or transparent when there
## is no such tile.
func _color_of(tile: int) -> Color:
	if tile < 0 or tile >= _tiles.size():
		return Color.TRANSPARENT
	return BackdropPictures.color_of(_tiles[tile])
