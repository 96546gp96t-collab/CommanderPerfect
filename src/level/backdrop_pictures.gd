class_name BackdropPictures
extends RefCounted
## Finds the pictures that can be shown behind a level instead of its own
## plain background (an extra; see docs/graphics.md). One picture per level,
## named after it: level01.png for level 1 (or .webp, .jpg).
##
## The pictures that come with the game are in assets/backgrounds/. A
## player can add or replace one without building the game: a picture of
## the same name in a folder "backgrounds" in his own game folder (next to
## the game files, such as game_data/keen1/backgrounds/) wins.
##
## Which tiles the picture shows through is decided by [method background_tile]:
## the plain background of the level, and the same color around everything
## drawn on it ([method GraphicsTextures.backdrop_tile_atlas]).

const FOLDER := "res://assets/backgrounds"
const PLAYER_FOLDER := "backgrounds"
const EXTENSIONS: Array[String] = ["png", "webp", "jpg"]

var _files: GameFiles
var _cache: Dictionary[int, Texture2D] = {}
var _missing: Dictionary[int, bool] = {}


static func create(files: GameFiles) -> BackdropPictures:
	var pictures := BackdropPictures.new()
	pictures._files = files
	return pictures


## The file name, without extension, of the picture for level [param number].
static func picture_name(number: int) -> String:
	return "level%02d" % number


## The picture for level [param number], or null when there is none.
func picture(number: int) -> Texture2D:
	if _cache.has(number):
		return _cache[number]
	if _missing.has(number):
		return null
	var image := _player_image(number)
	if image == null:
		image = _own_image(number)
	if image == null:
		_missing[number] = true
		return null
	# The picture is drawn much smaller than it is; mipmaps keep it calm.
	image.generate_mipmaps()
	_cache[number] = ImageTexture.create_from_image(image)
	return _cache[number]


## The plain background tile of [param level]: the tile that is used most
## and is nothing but one color, with nothing to stand on or touch. -1 when
## the level has none.
static func background_tile(
	level: LevelData, properties: TileProperties, tiles: Array[Image]
) -> int:
	var counts: Dictionary[int, int] = {}
	var area := level.playable_rect()
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			var tile := level.tile_at(Vector2i(x, y))
			counts[tile] = counts.get(tile, 0) + 1
	var best := -1
	for tile in counts:
		if best >= 0 and counts[tile] <= counts[best]:
			continue
		if tile >= 0 and tile < tiles.size() and _is_plain(tile, properties, tiles[tile]):
			best = tile
	return best


## The one color of [param image] (a tile), for the background around things.
static func color_of(image: Image) -> Color:
	return image.get_pixel(0, 0)


static func _is_plain(tile: int, properties: TileProperties, image: Image) -> bool:
	if properties.behavior(tile) != TileProperties.Behavior.NONE or properties.is_animated(tile):
		return false
	if (
		properties.blocks_top(tile)
		or properties.blocks_right(tile)
		or properties.blocks_bottom(tile)
		or properties.blocks_left(tile)
	):
		return false
	var color := color_of(image)
	for y in image.get_height():
		for x in image.get_width():
			if not image.get_pixel(x, y).is_equal_approx(color):
				return false
	return true


func _player_image(number: int) -> Image:
	if _files == null:
		return null
	var folder := _files.directory.path_join(PLAYER_FOLDER)
	for extension in EXTENSIONS:
		var path := folder.path_join(picture_name(number) + "." + extension)
		if FileAccess.file_exists(path):
			var image := Image.load_from_file(path)
			if image != null and not image.is_empty():
				return image
			push_error("%s could not be read as a picture." % path)
	return null


func _own_image(number: int) -> Image:
	for extension in EXTENSIONS:
		var path := FOLDER.path_join(picture_name(number) + "." + extension)
		if ResourceLoader.exists(path):
			var texture := load(path) as Texture2D
			if texture != null:
				var image := texture.get_image()
				if image != null:
					image.decompress()
					return image
	return null
