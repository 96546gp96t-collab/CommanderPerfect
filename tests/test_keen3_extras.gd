extends "res://tests/test_case.gd"
## Tests for milestone C9: the pictures behind Keen 3's levels
## ([Keen3BackdropPictures]) come from Keen 3's own folder or the player's,
## never Keen 1's, and only show behind a level whose plain background is
## the sky. Smooth motion: the map's view blends between its last two
## corners but not across a jump, and Keen 3's moving things are drawn in
## between ticks by the shared [ActorLayer]. With the player's Keen 3 files:
## which of the real levels have sky.

const Fixtures := preload("res://tests/keen3_fixtures.gd")
const TEST_DIRECTORY := "user://test_keen3_extras"
## The levels of version 1.00 whose plain background is the sky.
const SKY_LEVELS: PackedInt32Array = [1, 2, 3, 4, 5, 6, 7, 8, 11, 13, 14, 15]
const SKY := Keen3BackdropPictures.SKY_TILE
## The EGA color of Keen 3's sky.
const LIGHT_CYAN := 11
## The plain dark gray inside the bases (a [constant Fixtures.WALLPAPER]).
const INSIDE := Fixtures.WALLPAPER
const SKY_COLOR := Color(0.33, 1.0, 1.0)
const INSIDE_COLOR := Color(0.33, 0.33, 0.33)
const PATTERN_COLOR := Color(1.0, 0.33, 1.0)
## A patterned tile with nothing to touch (the pink wallpaper of level 8).
const PATTERN := Fixtures.AIR
const LEGEND := {"s": SKY, "i": INSIDE, "-": PATTERN, "#": Fixtures.WALL}
## Mostly a patterned building, with some sky beside it (as level 8).
const BUILDING_LEVEL: PackedStringArray = [
	"s------s",
	"s------s",
	"########",
]
## Sky above a base whose plain dark gray is larger (as level 10).
const BASE_LEVEL: PackedStringArray = [
	"ssssssss",
	"########",
	"iiiiiiii",
	"iiiiiiii",
	"iiiiiiii",
	"########",
]
## A cave without sky.
const CAVE_LEVEL: PackedStringArray = [
	"i------i",
	"########",
]
const PICTURE_SIZE := Vector2i(8, 4)
const MAP_AREA := Rect2(0, 0, 1600, 1200)
const VIEW := Vector2(320, 200)
const MAP_STEP := Vector2(2, 0)
const TELEPORT_CORNER := Vector2(900, 700)
const HALF := 0.5
const ACTOR_STEP := Vector2(4, 2)


func test_a_level_whose_plain_background_is_the_sky_suits_a_picture() -> void:
	var properties := Fixtures.level_properties()
	var tiles := _tiles()
	var building := _level(BUILDING_LEVEL)
	assert_equal(Keen2BackdropPictures.most_used_tile(building), PATTERN, "mostly pattern")
	assert_true(Keen3BackdropPictures.suits(building, properties, tiles), "sky beside it")


func test_a_level_whose_plain_background_is_inside_a_base_does_not() -> void:
	var properties := Fixtures.level_properties()
	var tiles := _tiles()
	var base := _level(BASE_LEVEL)
	assert_equal(BackdropPictures.background_tile(base, properties, tiles), INSIDE, "plain")
	assert_true(not Keen3BackdropPictures.suits(base, properties, tiles), "the base")
	assert_true(Keen2BackdropPictures.suits(base, properties, tiles), "Keen 2's rule would")
	var cave := _level(CAVE_LEVEL)
	assert_true(not Keen3BackdropPictures.suits(cave, properties, tiles), "no sky")


func test_keen_3_pictures_come_only_from_keen_3s_folder() -> void:
	var levels: Dictionary[int, LevelData] = {
		1: _level(BUILDING_LEVEL), 2: _level(BASE_LEVEL), 3: _level(CAVE_LEVEL)
	}
	var pictures := Keen3BackdropPictures.for_levels(
		null, Keen3BackdropPictures.FOLDER_KEEN_3, levels, Fixtures.level_properties(), _tiles()
	)
	assert_true(pictures.shows_level(1), "level 1 has sky")
	assert_true(not pictures.shows_level(2) and not pictures.shows_level(3), "2 and 3 not")
	var own := pictures.picture(1)
	var keen_1 := BackdropPictures.create(null).picture(1)
	assert_true(keen_1 != null, "Keen 1 keeps its picture of level 1")
	assert_true(
		own == null or own.get_size() != keen_1.get_size(),
		"Keen 1's picture of level 1 is not used"
	)
	assert_true(pictures.picture(2) == null, "no picture behind a base level")


func test_every_level_with_sky_has_its_own_picture() -> void:
	for number in range(Keen3Files.FIRST_LEVEL, Keen3Files.LAST_LEVEL + 1):
		var path := Keen3BackdropPictures.FOLDER_KEEN_3.path_join(
			BackdropPictures.picture_name(number) + ".webp"
		)
		var expected := SKY_LEVELS.has(number)
		assert_equal(ResourceLoader.exists(path), expected, "a picture for level %d" % number)


func test_the_players_own_picture_shows_only_behind_a_level_with_sky() -> void:
	var folder := ProjectSettings.globalize_path(TEST_DIRECTORY)
	var pictures_folder := folder.path_join(BackdropPictures.PLAYER_FOLDER)
	DirAccess.make_dir_recursive_absolute(pictures_folder)
	var image := Image.create_empty(PICTURE_SIZE.x, PICTURE_SIZE.y, false, Image.FORMAT_RGB8)
	image.fill(SKY_COLOR)
	for number in [1, 2]:
		var file_name := BackdropPictures.picture_name(number) + ".png"
		image.save_png(pictures_folder.path_join(file_name))
	var files := GameFiles.new()
	files.directory = folder
	var levels: Dictionary[int, LevelData] = {1: _level(BUILDING_LEVEL), 2: _level(BASE_LEVEL)}
	var pictures := Keen3BackdropPictures.for_levels(
		files, Keen3BackdropPictures.FOLDER_KEEN_3, levels, Fixtures.level_properties(), _tiles()
	)
	var shown := pictures.picture(1)
	assert_true(shown != null, "the player's picture behind level 1")
	if shown != null:
		assert_equal(Vector2i(shown.get_size()), PICTURE_SIZE, "its size")
	assert_true(pictures.picture(2) == null, "none behind the base, file or not")
	_remove_folder(folder)


func test_the_map_view_blends_between_ticks_but_not_across_a_jump() -> void:
	var scroll := Keen3MapScroll.at_corner(MAP_AREA, VIEW, Vector2.ZERO)
	var keen_at := Vector2(Keen3MapScroll.FREE_RIGHT, Keen3MapScroll.FREE_TOP)
	scroll.begin_tick()
	scroll.follow(keen_at + MAP_STEP, MAP_STEP)
	var middle := VIEW / 2.0
	assert_equal(scroll.center(1.0), middle + MAP_STEP, "the view moved along")
	assert_equal(scroll.center(HALF), middle + MAP_STEP * HALF, "half way between ticks")
	scroll.begin_tick()
	scroll.jump_to(TELEPORT_CORNER)
	assert_equal(scroll.center(HALF), scroll.center(1.0), "a teleporter's jump is not blended")


func test_keen_3s_moving_things_are_drawn_between_ticks() -> void:
	var layer := ActorLayer.new()
	layer.set_textures(GraphicsTextures.create(EgaGraphics.new()))
	var start := Fixtures.cell_top_left(Vector2i(2, 2))
	var actors: Array[Actor] = [
		Keen3Messie.at_cell(Vector2i(2, 2), Vector2i.RIGHT),
		Keen3Platform.sideways(start),
		Keen3SoundWave.sent(start, 1),
	]
	layer.show_actors(actors)
	for actor in actors:
		actor.position += ACTOR_STEP
	layer.show_actors(actors)
	layer.place(HALF, true)
	var sprites := layer.get_children()
	assert_equal(sprites.size(), actors.size(), "a sprite each")
	for index in sprites.size():
		var expected := actors[index].position - ACTOR_STEP * HALF
		assert_equal((sprites[index] as Sprite2D).position, expected, "half way %d" % index)
	layer.free()


func test_only_the_real_levels_with_sky_suit_a_picture() -> void:
	var files := Keen3Files.locate()
	var data := Keen3GameData.load_from(files) if files != null else null
	if data == null:
		return
	var tiles := data.graphics.tiles
	var sky_color := BackdropPictures.color_of(tiles[SKY])
	assert_equal(sky_color, EgaPalette.color(LIGHT_CYAN), "the sky is light cyan")
	var pictures := Keen3BackdropPictures.for_game(files, data.properties, tiles)
	var suited := PackedInt32Array()
	for number in range(Keen3Files.FIRST_LEVEL, Keen3Files.LAST_LEVEL + 1):
		if pictures.shows_level(number):
			suited.append(number)
	assert_equal(suited, SKY_LEVELS, "the levels whose plain background is the sky")


## A level of [constant LEGEND] characters with Keen 3's border around it.
static func _level(rows: PackedStringArray) -> LevelData:
	var border := LevelData.BORDER_CELLS
	var level := LevelData.new()
	level.width = rows[0].length() + border * 2
	level.height = rows.size() + border * 2
	level.tiles.resize(level.width * level.height)
	level.tiles.fill(Fixtures.BORDER)
	level.infos.resize(level.width * level.height)
	for y in rows.size():
		for x in rows[y].length():
			level.tiles[(y + border) * level.width + x + border] = LEGEND[rows[y][x]]
	return level


## A picture for every tile: the sky and the inside are plain, the rest a
## pattern.
static func _tiles() -> Array[Image]:
	var tiles: Array[Image] = []
	for tile in Fixtures.LEVEL_TILE_COUNT:
		var image := Image.create(
			EgaGraphics.TILE_SIZE, EgaGraphics.TILE_SIZE, false, Image.FORMAT_RGBA8
		)
		match tile:
			SKY:
				image.fill(SKY_COLOR)
			INSIDE:
				image.fill(INSIDE_COLOR)
			_:
				image.fill(PATTERN_COLOR)
				image.set_pixel(0, 0, INSIDE_COLOR)
		tiles.append(image)
	return tiles


## Removes the player's folder made by a test, with its pictures.
static func _remove_folder(path: String) -> void:
	var pictures_folder := path.path_join(BackdropPictures.PLAYER_FOLDER)
	for file_name in DirAccess.get_files_at(pictures_folder):
		DirAccess.remove_absolute(pictures_folder.path_join(file_name))
	DirAccess.remove_absolute(pictures_folder)
	DirAccess.remove_absolute(path)
