extends "res://tests/test_case.gd"
## Keen 3's sounds, title and high score screens from the player's real
## files (milestone C8): the 45 named sounds of KEEN3.EXE (Keen 1's 41 and
## ANKH, MEEP, MORTIMER, FOOTSLAM with their priorities), every sound the
## game plays is found, map 90's title and high score screens with their
## bitmaps and no border on screen, the story for the menu, the high score
## texts and the font's second half for the red names. Skipped when the
## Keen 3 files are not there.

const NAMED_SOUNDS := 45
## Keen 3's own sounds and their priorities (research.md §2, Choco).
const OWN_PRIORITIES: Dictionary[String, int] = {
	"ANKH": 255, "MEEP": 200, "MORTIMER": 255, "FOOTSLAM": 250
}
const BITMAPS: PackedStringArray = ["TITLE", "F1HELP", "HIGHSCOR", "NAME", "SCORE", "GAMEOVER"]
const MAP_90_SIZE := Vector2i(126, 17)
const SCREEN_CELLS := Vector2i(20, 13)
const BORDER_TILE := 245
const FONT_CHARS := 256

var _files: GameFiles
var _data: Keen3GameData


func run_all() -> void:
	_files = Keen3Files.locate()
	if _files == null:
		skip("no Keen 3 game data found")
		return
	_data = Keen3GameData.load_from(_files)
	super.run_all()


func test_the_sound_block_has_45_named_sounds() -> void:
	var named := 0
	for key in _data.sounds.sounds:
		named += int(not key.begins_with("_"))
	assert_equal(named, NAMED_SOUNDS, "41 of Keen 1 and 4 of Keen 3")


func test_every_shared_sound_is_in_keen_3() -> void:
	for id: Sound.Id in Sound.FILE_NAMES:
		var entry := Keen2Sounds.find_entry(_data.sounds, Sound.FILE_NAMES[id])
		assert_true(entry != null and not entry.divisors.is_empty(), Sound.FILE_NAMES[id])


func test_keen_3_own_sounds_and_their_priorities() -> void:
	var sounds := Keen3Sounds.new()
	sounds.load_sounds(_data.sounds)
	for sound_name in OWN_PRIORITIES:
		assert_true(sounds.has_sound(sound_name), sound_name)
		assert_equal(sounds.priority_of(sound_name), OWN_PRIORITIES[sound_name], sound_name)
	assert_true(sounds.seconds(Keen3Sounds.MORTIMER) > 1.0, "MORTIMER lasts a while")
	assert_true(sounds.seconds_of("KEENSLEFT") > 0.0, "keensleft before the end text")
	sounds.free()


func test_map_90_has_the_title_and_high_score_screens() -> void:
	var map := LevelData.parse(_files.read(_files.level_file(Keen3Files.TITLE_LEVEL)))
	assert_true(map != null, "map 90")
	if map == null:
		return
	assert_equal(Vector2i(map.width, map.height), MAP_90_SIZE, "126x17")
	for area in [Keen3Screens.TITLE_SCREEN, Keen3Screens.HIGH_SCORE_SCREEN]:
		var screen := Backdrops.screen(map, area)
		var playable := screen.playable_rect()
		assert_equal(playable.size, SCREEN_CELLS, "20x13 cells")
		var border_cells := 0
		for y in range(playable.position.y, playable.end.y):
			for x in range(playable.position.x, playable.end.x):
				border_cells += int(screen.tile_at(Vector2i(x, y)) == BORDER_TILE)
		assert_equal(border_cells, 0, "no OH no! border on screen %s" % area)


func test_the_screens_bitmaps_and_red_font_are_there() -> void:
	for bitmap_name in BITMAPS:
		assert_true(_data.graphics.bitmap_index(bitmap_name) >= 0, bitmap_name)
	assert_true(_data.graphics.bitmap_index("SAVED") < 0, "no SAVED: no third column")
	assert_equal(_data.graphics.font_chars.size(), FONT_CHARS, "the font's second half")


func test_story_and_high_score_texts() -> void:
	assert_true(not _data.story.is_empty(), "the story")
	var lines := TextDocument.layout(_data.story, MenuController.TEXT_WIDTH)
	assert_true(lines.size() > MenuController.TEXT_LINES, "more than a page")
	assert_true(_data.story != _data.help, "the story, not the help text")
	assert_equal(_data.score_texts.default_names.size(), 3, "three names in a new table")
	assert_equal(_data.score_texts.place_names.size(), 7, "seven place words")
