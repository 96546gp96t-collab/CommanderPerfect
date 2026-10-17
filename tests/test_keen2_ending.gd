extends "res://tests/test_case.gd"
## Tests for milestone B6 without Keen 2's files: the cities
## ([Keen2Progress]), the status screen ([Keen2StatusScreen]), the ending
## ([Keen2Ending], [Keen2Flight]) and the texts of the status screen and the
## ending in a hand-made KEEN2.EXE image. The world map with real map files is
## in tests/test_keen2_stand_in.gd and tests/test_keen2_data.gd.

const IMAGE_SIZE := 0x1A600
const FILLER := 0x01
const CITY_NAMES: PackedStringArray = ["A", "B", "C", "D", "E", "F", "G", "H"]
## A short end text block: two lines and the end mark.
const END_TEXT := "First line of the end text\r\nSecond line\r\n\u001a"
## Far more ticks than a flight takes.
const MAX_TICKS := 2000


func test_a_city_is_saved_when_its_level_is_done() -> void:
	var progress := Keen2Progress.new()
	assert_true(progress.inventory is Keen2Inventory, "Keen 2's inventory")
	assert_equal(progress.saved_city_count(), 0, "none at the start")
	progress.complete_level(1)
	assert_equal(progress.saved_city_count(), 0, "level 1 is no city")
	progress.complete_level(Keen2Progress.CITY_LEVELS[2])
	assert_equal(progress.saved_cities()[2], true, "the third city")
	assert_equal(progress.saved_city_count(), 1, "one")
	assert_true(not progress.all_cities_saved(), "not all")
	for number in Keen2Progress.CITY_LEVELS:
		progress.complete_level(number)
	assert_true(progress.all_cities_saved(), "all eight")
	assert_true(Keen2Progress.is_city(16) and not Keen2Progress.is_city(5), "is_city")


func test_status_screen_shows_cities_keycards_and_lives() -> void:
	var progress := Keen2Progress.new()
	progress.inventory.score = 1234
	progress.inventory.charges = 7
	progress.inventory.keycards[TileProperties.KeyColor.RED] = true
	progress.complete_level(Keen2Progress.CITY_LEVELS[0])
	progress.complete_level(Keen2Progress.CITY_LEVELS[3])
	var window := GameWindow.new()
	Keen2StatusScreen.fill(window, progress, PackedStringArray(), CITY_NAMES)
	assert_true(window.visible, "open")
	var texts := _texts(window)
	assert_true(texts.has("1234") and texts.has("7"), "score and charges")
	assert_true(texts.has("A") and texts.has("D"), "the saved cities")
	assert_true(not texts.has("B"), "not the others")
	assert_true(texts.has("     PLEASE PRESS A KEY"), "the labels, also without the EXE")
	var tiles: Array = window._tile_items.map(func(item: Dictionary) -> int: return item.tile)
	assert_true(tiles.has(Keen2StatusScreen.KEYCARD_TILES[1]), "the red keycard")
	assert_true(not tiles.has(Keen2StatusScreen.KEYCARD_TILES[0]), "not the yellow one")
	assert_true(tiles.has(Keen2StatusScreen.RAYGUN_TILE), "the raygun")
	assert_equal(window._sprite_items.size(), Inventory.START_LIVES, "a Keen per life")
	window.free()


func test_status_screen_uses_the_lines_of_the_exe() -> void:
	var lines := PackedStringArray()
	for row in Keen2StatusScreen.SIZE.y:
		lines.append("line %d" % row)
	var window := GameWindow.new()
	Keen2StatusScreen.fill(window, Keen2Progress.new(), lines, PackedStringArray())
	var texts := _texts(window)
	assert_true(texts.has("line 0") and texts.has("line 11"), "the box from the EXE")
	window.free()


func test_flight_waits_then_flies_its_legs() -> void:
	var flight := Keen2Flight.home(Vector2(100, 50))
	for tick in Keen2Flight.WAIT_TICKS:
		flight.step()
	assert_equal(flight.position, Vector2(100, 50), "waits first")
	flight.step()
	assert_equal(flight.position, Vector2(100, 50) + Keen2Flight.HOME_LEGS[0][1], "first leg")
	_fly(flight)
	assert_true(flight.is_finished(), "lands")
	var expected := Vector2(100, 50)
	for leg in Keen2Flight.HOME_LEGS:
		expected += leg[1] * leg[0]
	assert_true(flight.position.is_equal_approx(expected), "every leg flown")
	assert_equal(Keen2Flight.mothership().sprite, Keen2Flight.MOTHERSHIP_SPRITE, "mothership")


func test_ending_runs_through_its_stages() -> void:
	var ending := Keen2Ending.create(_ending_texts(), END_TEXT.to_ascii_buffer(), Vector2.ZERO)
	assert_equal(ending.stage, Keen2Ending.Stage.SHIP_HOME, "Keen's ship first")
	assert_true(ending.shows_space(), "on map 81")
	assert_equal(ending.window_lines(), PackedStringArray(["text 0"]), "with its text")
	_fly_stage(ending)
	assert_equal(ending.stage, Keen2Ending.Stage.SHIP_HOME, "the text keeps it waiting")
	ending.confirm()
	ending.step(false)
	assert_equal(ending.stage, Keen2Ending.Stage.MOTHERSHIP, "then the mothership")
	ending.step(true)
	ending.step(false)
	assert_true(ending.window_lines().is_empty(), "a button closes the text")
	_fly_stage(ending)
	assert_equal(ending.stage, Keen2Ending.Stage.AT_HOME, "home")
	assert_true(ending.shows_picture() and not ending.shows_space(), "the picture")
	for page in Keen2Ending.HOME_PAGES.size():
		assert_equal(ending.window_lines()[0], "text %d" % (page + 2), "page %d" % page)
		ending.confirm()
	assert_equal(ending.stage, Keen2Ending.Stage.END_TEXT, "the end text")
	assert_true(ending.window_lines()[0].begins_with("First line"), "its first line")
	ending.confirm()
	assert_true(ending.is_finished(), "done")


func test_ending_without_texts_still_ends() -> void:
	var none: Array[PackedStringArray] = []
	var ending := Keen2Ending.create(none, PackedByteArray(), Vector2.ZERO)
	assert_true(ending.window_lines().is_empty(), "no text")
	for tick in MAX_TICKS * 2:
		ending.step(false)
	assert_true(ending.is_finished(), "the flights end, no pages, no end text")


func test_ship_starts_at_its_tile() -> void:
	var space := LevelData.new()
	space.width = 10
	space.height = 10
	space.tiles.resize(100)
	space.infos.resize(100)
	space.set_tile(Vector2i(6, 5), Keen2Ending.SHIP_START_TILE)
	assert_equal(Keen2Ending.ship_start_in(space), Vector2(96, 80), "at tile 593")


func test_ending_and_status_texts_are_read_from_the_exe() -> void:
	var image := _image_with_texts()
	var executable := Keen2Executable.from_image(image)
	var first := executable.ending_text(Keen2Executable.EndingText.SHIP_HOME)
	assert_equal(first, PackedStringArray(["Line one", "last line"]), "the unfinished last line")
	var second := executable.ending_text(Keen2Executable.EndingText.MOTHERSHIP)
	assert_equal(second.size(), 2, "ends before finale.ck2")
	assert_equal(second[0], "Ship", "its first line")
	var lines := executable.status_box_lines()
	assert_equal(lines.size(), Keen2Executable.STATUS_BOX_LINES, "twelve lines")
	assert_equal(lines[0], "  SCORE  ", "spaces kept, line feed dropped")
	assert_true(Keen2Executable.from_image(_filler()).status_box_lines().is_empty(), "missing")
	var filler := Keen2Executable.from_image(_filler())
	assert_true(filler.ending_text(Keen2Executable.EndingText.HOME_1).is_empty(), "missing")


## The texts "text 0" ... "text 6", in the order of the ending's texts.
func _ending_texts() -> Array[PackedStringArray]:
	var texts: Array[PackedStringArray] = []
	for which in Keen2Executable.EndingText.size():
		texts.append(PackedStringArray(["text %d" % which]))
	return texts


## Steps a flight stage until its ship is there.
func _fly_stage(ending: Keen2Ending) -> void:
	var stage := ending.stage
	for tick in MAX_TICKS:
		if ending.flight.is_finished() or ending.stage != stage:
			break
		ending.step(false)
	ending.step(false)


func _fly(flight: Keen2Flight) -> void:
	for tick in MAX_TICKS:
		if flight.is_finished():
			return
		flight.step()


func _texts(window: GameWindow) -> PackedStringArray:
	var texts := PackedStringArray()
	for item: Dictionary in window._texts:
		texts.append(item.text)
	return texts


func _image_with_texts() -> PackedByteArray:
	var image := _filler()
	var parts := Keen2Executable.ENDING_TEXT_OFFSETS
	_put_records(image, parts[0], ["Line one\n", "last line"])
	# The second part runs right up to the record "finale.ck2".
	var gap := Keen2Executable.FINALE_NAME_OFFSET - parts[1] - "Ship\n".length() - 1
	_put_records(image, parts[1], ["Ship\n", "y".repeat(gap - 2) + "\n", "finale.ck2"])
	var box: PackedStringArray = ["  SCORE  \n"]
	for row in Keen2Executable.STATUS_BOX_LINES - 2:
		box.append(" \n")
	box.append("  PRESS A KEY  ")
	_put_records(image, Keen2Executable.STATUS_BOX_OFFSET, box)
	return image


## Writes [param records] from [param start], each followed by a zero byte,
## with a zero byte before the first.
func _put_records(image: PackedByteArray, start: int, records: PackedStringArray) -> void:
	image[start - 1] = 0
	var position := start
	for record in records:
		var bytes := record.to_ascii_buffer()
		bytes.append(0)
		for offset in bytes.size():
			image[position + offset] = bytes[offset]
		position += bytes.size()


func _filler() -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(IMAGE_SIZE)
	bytes.fill(FILLER)
	return bytes
