extends "res://tests/test_case.gd"
## Tests for milestone D11 part B: the pictures behind Keen 4's levels
## (painted by tools/make_keen4_backgrounds.py). Exactly the levels whose
## top row has sky have a picture in assets/backgrounds/keen4, and no other
## map has one. With the player's files (never in the repository) also the
## whole way: the screen's [GalaxyBackdropPictures] finds a picture for
## those levels and for no other map.

## The levels with sky in their top row (docs/keen4/gameplay.md, "Pictures
## behind the levels"), the same as in test_keen4_level.gd.
const SKY_LEVELS: PackedInt32Array = [5, 7, 8, 9, 10, 11, 12, 13, 14, 16]
## Maps 0 (the world map) to 19 (the high scores).
const MAP_COUNT := 20
## The widescreen view's shape: every picture is at least this wide for its
## height, so it covers the view.
const WIDESCREEN := 16.0 / 9.0

var _data: GalaxyData


func _init() -> void:
	# Not skipped without the files: the pictures themselves are ours.
	var files := Keen4Files.locate()
	if files != null:
		_data = Keen4Episode.load_data(files)


func test_exactly_the_levels_with_sky_have_a_picture() -> void:
	for number in MAP_COUNT:
		var expected := SKY_LEVELS.has(number)
		assert_equal(_has_own_picture(number), expected, "a picture for map %d" % number)


func test_the_folder_holds_only_the_pictures_of_those_levels() -> void:
	var expected := PackedStringArray()
	for number in SKY_LEVELS:
		expected.append(BackdropPictures.picture_name(number) + ".webp")
	var found := PackedStringArray()
	for file_name in DirAccess.get_files_at(Keen4Episode.BACKDROP_FOLDER):
		if file_name.get_extension() in BackdropPictures.EXTENSIONS:
			found.append(file_name)
	found.sort()
	assert_equal(found, expected, "the pictures in %s" % Keen4Episode.BACKDROP_FOLDER)


func test_every_picture_is_wide_enough_for_widescreen() -> void:
	for number in SKY_LEVELS:
		var picture := _pictures().picture(number)
		assert_true(picture != null, "level %d's picture loads" % number)
		if picture != null:
			var size := picture.get_size()
			assert_true(
				size.x >= size.y * WIDESCREEN, "level %d's picture is 16:9 or wider" % number
			)


func test_the_screen_finds_a_picture_for_exactly_those_levels() -> void:
	if _data == null:
		return  # Needs the player's maps (game_data/keen4).
	var pictures := _pictures()
	var shown := PackedInt32Array()
	for number in MAP_COUNT:
		if pictures.picture_for(_data.maps.load_map(number)) != null:
			shown.append(number)
	assert_equal(shown, SKY_LEVELS, "the levels that show a picture")


func _pictures() -> GalaxyBackdropPictures:
	return GalaxyBackdropPictures.for_episode(
		null,
		Keen4Episode.BACKDROP_FOLDER,
		Keen4Episode.SKY_TILES,
		Keen4Episode.FIRST_LEVEL,
		Keen4Episode.LAST_LEVEL
	)


func _has_own_picture(number: int) -> bool:
	for extension in BackdropPictures.EXTENSIONS:
		var path := Keen4Episode.BACKDROP_FOLDER.path_join(
			BackdropPictures.picture_name(number) + "." + extension
		)
		if ResourceLoader.exists(path):
			return true
	return false
