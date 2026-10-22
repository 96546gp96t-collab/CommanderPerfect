extends "res://tests/test_case.gd"
## Checks Keen 5's status window and the boxes between its levels with the
## player's files (milestone E6; [Keen5StatusWindow], [GalaxyGameBoxes]
## with Keen 5's rules): the labels (KEYCARD, VITALIN; no RESCUED, no
## wetsuit), KEYCARD printed from (80, 91) beside its black square at
## (135, 90) that shows the card (8×8 tile 40 at (136, 91)) only while Keen
## has it, the "press a key" tiles from (120, 140); Keen counting down
## (the seventh picture from the end), "One moment", the death box's texts
## and no "Game Over!" box. Skipped without the files.

const KEYCARD_TILE := 40
const FIRST_KEY_TILE := 72
const CELL := 8
const PICTURE_FROM_END := 7

var _data: GalaxyData
var _rules: GalaxyGameRules


func _init() -> void:
	var files := Keen5Files.locate()
	if files == null:
		skip("no Keen 5 files in game_data/keen5")
		return
	_data = Keen5Episode.load_data(files)
	_rules = Keen5Episode.game_rules()


func test_the_labels_are_keen_5s() -> void:
	var window := Keen5StatusWindow.create_keen5(_data, _rules)
	assert_equal(window.label(GalaxyStatusWindow.Text.LOCATION), "LOCATION", "location")
	assert_equal(window.label(GalaxyStatusWindow.Text.MIDDLE), "KEYCARD", "the keycard's row")
	assert_equal(window.label(GalaxyStatusWindow.Text.LIVES), "KEENS", "lives")
	assert_equal(window.label(GalaxyStatusWindow.Text.DROPS), "VITALIN", "the drops")
	assert_equal(window.key_tiles_at, Keen5StatusWindow.KEY_TILES_AT, "the key tiles' place")


func test_the_keycard_square_shows_the_card_only_while_keen_has_it() -> void:
	var window := Keen5StatusWindow.create_keen5(_data, _rules)
	var carried := Keen5Inventory.new_game()
	var progress := Keen5Progress.new()
	var without := window.window(1, carried, progress, GalaxyDifficulty.DEFAULT)
	var square := Keen5StatusWindow.KEYCARD_BOX
	for y in range(square.position.y, square.end.y):
		for x in range(square.position.x, square.end.x):
			assert_equal(
				without.get_pixel(x, y), GalaxyStatusWindow.BLACK, "black at %d,%d" % [x, y]
			)
	carried.keycard = true
	var with_card := window.window(1, carried, progress, GalaxyDifficulty.DEFAULT)
	var card := _rgba(_data.graphics.tile8(KEYCARD_TILE))
	assert_true(_same(with_card, Keen5StatusWindow.KEYCARD_TILE_AT, card), "tile 40 at (136, 91)")
	assert_equal(
		with_card.get_pixel(square.position.x, square.position.y),
		GalaxyStatusWindow.BLACK,
		"the square's edge stays black"
	)


func test_keycard_is_printed_from_80_91() -> void:
	var window := Keen5StatusWindow.create_keen5(_data, _rules)
	var picture := window.window(1, Keen5Inventory.new_game(), Keen5Progress.new(), 1)
	var at := Keen5StatusWindow.KEYCARD_LABEL_AT
	var font := _data.graphics.font(_rules.menu_font)
	var text := font.render("KEYCARD", GalaxyStatusWindow.DARK_GREY)
	var dark := 0
	for y in text.get_height():
		for x in text.get_width():
			if text.get_pixel(x, y).a > 0:
				assert_equal(
					picture.get_pixel(at.x + x, at.y + y), GalaxyStatusWindow.DARK_GREY, "the label"
				)
				dark += 1
	assert_true(dark > 0, "it has pixels")


func test_the_key_tiles_and_no_wetsuit_bar() -> void:
	var window := Keen5StatusWindow.create_keen5(_data, _rules)
	var picture := window.window(1, Keen5Inventory.new_game(), Keen5Progress.new(), 1)
	var first := _rgba(_data.graphics.tile8(FIRST_KEY_TILE))
	assert_true(_same(picture, Keen5StatusWindow.KEY_TILES_AT, first), "tile 72 at (120, 140)")
	var keen_4_bar := Vector2i(81, 145)
	assert_equal(picture.get_pixelv(keen_4_bar), GalaxyStatusWindow.GREY, "no white wetsuit bar")


func test_the_boxes_between_the_levels() -> void:
	var boxes := GalaxyGameBoxes.create(_data, _rules)
	var screens := boxes.entering(1)
	assert_equal(screens.size(), 6, "the box and five fingers")
	var countdown := _rgba(
		_data.graphics.picture(_data.graphics.ranges.picture_count - PICTURE_FROM_END)
	)
	var cells := GalaxyWindow.SCREEN_SIZE / CELL
	var corner := (cells - GalaxyGameBoxes.WINDOW_CELLS) / 2 * CELL
	assert_true(_same(screens[0], corner, countdown), "Keen counting down at the box's left")
	assert_equal(boxes.game_text(_rules.one_moment_text), "One moment", "One moment")
	assert_equal(
		boxes.game_text(_rules.try_again_intro_text), "You didn't make it past", "after a death"
	)
	assert_equal(boxes.game_text(_rules.try_again_text), "Try Again", "Try Again")
	assert_equal(boxes.game_text(_rules.exit_text), "Exit to Armageddon", "the exit")
	assert_true(boxes.game_over() == null, "no Game Over! box (a scene in E7)")


## Whether [param picture] holds [param part] at [param at], pixel for pixel
## where [param part] is not see-through.
static func _same(picture: Image, at: Vector2i, part: Image) -> bool:
	for y in part.get_height():
		for x in part.get_width():
			var pixel := part.get_pixel(x, y)
			if pixel.a > 0 and picture.get_pixel(at.x + x, at.y + y) != pixel:
				return false
	return true


static func _rgba(image: Image) -> Image:
	var copy := image.duplicate() as Image
	copy.convert(Image.FORMAT_RGBA8)
	return copy
