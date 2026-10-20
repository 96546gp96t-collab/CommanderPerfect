extends "res://tests/test_case.gd"
## Tests for Keen 3's status screen ([Keen3StatusScreen] in a
## [Keen3Window]) and the other windows of the map, without Keen 3's files:
## the box where the original has it (x 40-279, y 48-151), the numbers,
## the little Keens, the pistol, the ankh and the keycards at the places
## measured in js-dos, the labels in the font's second half, the ship's
## prompt from KEEN3.EXE, and "Keens Left" with at most six Keens.

const Fixtures := preload("res://tests/keen3_fixtures.gd")
const SHIFT := Vector2(0, 4)


func test_the_box_is_where_the_original_has_it() -> void:
	var window := _filled(Keen3Inventory.new())
	window.view_size = Vector2i(320, 200)
	var inside := window._inside_origin()
	assert_equal(inside, Vector2(48, 56), "the inside from (48, 56)")
	var outer := Rect2(inside - Vector2(8, 8), Vector2(Keen3StatusScreen.SIZE + Vector2i(2, 2)) * 8)
	assert_equal(outer, Rect2(40, 48, 240, 104), "x 40-279, y 48-151")
	window.free()


func test_score_and_next_extra_keen() -> void:
	var inventory := Keen3Inventory.new()
	inventory.score = 12345
	var window := _filled(inventory)
	var cells := _text_cells(window)
	assert_equal(cells["12345"], Vector2i(5, 1), "the score ends before column 10")
	assert_equal(cells["20000"], Vector2i(21, 1), "the next extra Keen before column 26")
	window.free()


func test_a_little_keen_per_life_at_most_nine() -> void:
	var inventory := Keen3Inventory.new()
	var window := _filled(inventory)
	assert_equal(window._sprite_items.size(), 4, "four lives")
	inventory.lives = 12
	window.free()
	window = _filled(inventory)
	assert_equal(window._sprite_items.size(), 9, "at most nine")
	for life in window._sprite_items.size():
		var item: Dictionary = window._sprite_items[life]
		assert_equal(item.sprite, 0, "Keen standing")
		assert_equal(item.cell, Vector2i(1 + life * 2, 3), "two columns apart from column 1")
	window.free()


func test_pistol_ankh_and_keycards_sit_half_a_row_lower() -> void:
	var inventory := Keen3Inventory.new()
	inventory.keycards[0] = true
	inventory.keycards[2] = true
	var window := _filled(inventory, 7)
	var tiles := {}
	for item: Dictionary in window._shifted_tiles:
		assert_equal(item.offset, SHIFT, "4 px below the row")
		tiles[item.tile] = item.cell
	# Found pixel for pixel in a status screen of the original (js-dos, C6).
	var expected := {216: Vector2i(21, 3), 214: Vector2i(3, 7), 217: Vector2i(13, 7)}
	expected[219] = Vector2i(21, 7)
	assert_equal(tiles, expected, "pistol, ankh, yellow and green keycards")
	var cells := _text_cells(window)
	assert_equal(cells["5"], Vector2i(24, 4), "the charges")
	assert_equal(cells["7"], Vector2i(7, 8), "the ankh time")
	window.free()


func test_labels_in_the_second_half_of_the_font() -> void:
	# The shape of the real box: four full lines, one-space lines between.
	var lines := PackedStringArray()
	for row in Keen3StatusScreen.LINE_COUNT:
		lines.append(("Row %d" % row).rpad(28) if row in [0, 2, 6, 10] else " ")
	var window := _filled(Keen3Inventory.new(), 0, lines)
	var labels := {}
	for item: Dictionary in window._texts:
		if item.text.unicode_at(0) >= Keen3Window.LABEL_FONT_OFFSET:
			labels[item.cell.y] = item
	assert_equal(labels.size(), Keen3StatusScreen.LINE_COUNT, "every line")
	assert_equal(labels[0].cell, Vector2i.ZERO, "a full line from column 0")
	assert_equal(labels[0].text, Keen3Window.label_text(lines[0]), "red on gray")
	var dividers := {1: 12, 3: 19, 4: 19, 5: 19, 7: 11, 8: 11, 9: 11}
	for row: int in dividers:
		assert_equal(labels[row].cell, Vector2i(dividers[row], row), "divider in row %d" % row)
	window.free()
	var plain := _filled(Keen3Inventory.new())
	for item: Dictionary in plain._texts:
		assert_true(item.text.unicode_at(0) < Keen3Window.LABEL_FONT_OFFSET, "no labels")
	plain.free()


func test_label_text() -> void:
	assert_equal(Keen3Window.label_text("A ").unicode_at(0), 0x41 + 0x80, "A in red on gray")
	assert_equal(Keen3Window.label_text("A ").unicode_at(1), 0x20 + 0x80, "a gray bar")


func test_ship_prompt_from_the_executable() -> void:
	var executable := Keen3Executable.from_image(Fixtures.image())
	assert_equal(executable.ship_prompt(), Fixtures.SHIP_PROMPT, "the two records after the ship")
	var image := Fixtures.image()
	var at := Fixtures._records(Fixtures.SHIP_PROMPT_RECORDS)
	var start := _find(image, at)
	image[start] = "x".unicode_at(0)
	executable = Keen3Executable.from_image(image)
	assert_equal(executable.ship_prompt(), "", "no line feed first: not found")


func test_keens_left_shows_at_most_six() -> void:
	assert_equal(Keen3SceneScreen.MAX_LIVES_SHOWN, 6, "Choco: six")


func test_a_new_game_is_won_with_level_16() -> void:
	var game := Keen3Progress.new()
	assert_true(game.inventory is Keen3Inventory, "Keen 3's inventory")
	for number in range(1, 16):
		game.complete_level(number)
	assert_true(not game.is_won(), "levels 1-15 are not enough")
	game.complete_level(16)
	assert_true(game.is_won(), "level 16 is")


func _filled(inventory: Inventory, ankh_seconds := 0, lines := PackedStringArray()) -> Keen3Window:
	var window := Keen3Window.new()
	Keen3StatusScreen.fill(window, inventory, ankh_seconds, lines)
	return window


static func _text_cells(window: Keen3Window) -> Dictionary:
	var cells := {}
	for item: Dictionary in window._texts:
		cells[item.text] = item.cell
	return cells


static func _find(data: PackedByteArray, part: PackedByteArray) -> int:
	for start in data.size() - part.size():
		if data.slice(start, start + part.size()) == part:
			return start
	return -1
