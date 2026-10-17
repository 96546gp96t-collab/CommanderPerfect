extends "res://tests/test_case.gd"
## Tests for milestone B8: the pictures behind Keen 2's levels
## ([Keen2BackdropPictures]) come from Keen 2's own folder, never Keen 1's,
## and only show behind a level whose plain background is its main one.
## Keen 1's [BackdropPictures] keeps its own folder. With the player's Keen 2
## files: which of the real levels suit a picture.

const Fixtures := preload("res://tests/keen2_fixtures.gd")
const KEEN_2_FOLDER := "res://assets/backgrounds/keen2"
## The levels of version 1.31 whose plain background is their main one.
const PICTURE_LEVELS: PackedInt32Array = [12]
const PLAIN_COLOR := Color(0.5, 0.5, 1.0)
const PATTERN_COLOR := Color(0.3, 0.3, 0.3)
## Mostly plain background, with a wall.
const PLAIN_LEVEL: PackedStringArray = [
	"..........",
	"..........",
	"##########",
]
## Mostly a patterned background, with a little plain background.
const PATTERN_LEVEL: PackedStringArray = [
	"--------..",
	"----------",
	"##########",
]


func test_a_level_with_a_plain_main_background_suits_a_picture() -> void:
	var properties := Fixtures.create_properties()
	var tiles := _tiles()
	var plain := Fixtures.create_level(PLAIN_LEVEL)
	var pattern := Fixtures.create_level(PATTERN_LEVEL)
	assert_true(Keen2BackdropPictures.suits(plain, properties, tiles), "plain background")
	assert_true(not Keen2BackdropPictures.suits(pattern, properties, tiles), "patterned")
	assert_equal(Keen2BackdropPictures.most_used_tile(pattern), Fixtures.GRAY, "most used")


func test_keen_2_pictures_come_only_from_keen_2s_folder() -> void:
	var properties := Fixtures.create_properties()
	var levels: Dictionary[int, LevelData] = {
		1: Fixtures.create_level(PLAIN_LEVEL), 2: Fixtures.create_level(PATTERN_LEVEL)
	}
	var pictures := Keen2BackdropPictures.for_levels(
		null, KEEN_2_FOLDER, levels, properties, _tiles()
	)
	assert_true(pictures.shows_level(1) and not pictures.shows_level(2), "only level 1")
	assert_true(pictures.picture(1) == null, "Keen 1's picture of level 1 is not used")
	assert_true(BackdropPictures.create(null).picture(1) != null, "Keen 1 keeps it")


func test_only_level_12_of_the_real_files_suits_a_picture() -> void:
	var files := Keen2Files.locate()
	var data := Keen2GameData.load_from(files) if files != null else null
	if data == null:
		return
	var suited := PackedInt32Array()
	for number in range(Keen2Files.FIRST_LEVEL, Keen2Files.LAST_LEVEL + 1):
		var level := LevelData.parse(files.read(files.level_file(number)))
		if Keen2BackdropPictures.suits(level, data.properties, data.graphics.tiles):
			suited.append(number)
	assert_equal(suited, PICTURE_LEVELS, "the levels with a plain main background")


## A picture for every tile: the air is one color, the gray background a
## pattern, the rest another color.
func _tiles() -> Array[Image]:
	var tiles: Array[Image] = []
	for tile in Fixtures.TILE_COUNT:
		var image := Image.create(
			EgaGraphics.TILE_SIZE, EgaGraphics.TILE_SIZE, false, Image.FORMAT_RGBA8
		)
		image.fill(PATTERN_COLOR if tile != Fixtures.AIR else PLAIN_COLOR)
		if tile == Fixtures.GRAY:
			image.set_pixel(0, 0, PLAIN_COLOR)
		tiles.append(image)
	return tiles
