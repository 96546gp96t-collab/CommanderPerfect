extends "res://tests/test_case.gd"
## Tests for the end of the game: the ship's flights, the steps of the
## ending, and reading its texts and picture. Uses made-up data, so no game
## files are needed.

const ENOUGH_TICKS := 5000


func test_flight_to_earth_follows_its_script() -> void:
	var flight := ShipFlight.to_earth()
	var start := flight.position
	var marks := {}
	var stopped_scrolling := false
	var ticks := 0
	while not flight.is_finished() and ticks < ENOUGH_TICKS:
		flight.step()
		ticks += 1
		marks[flight.mark] = true
		stopped_scrolling = stopped_scrolling or not flight.scrolling
	assert_true(flight.is_finished(), "lands")
	assert_true(flight.position.x > start.x and flight.position.y > start.y, "down to the right")
	assert_true(marks.has(ShipFlight.SPRITE_QUESTION), "wonders")
	assert_true(marks.has(ShipFlight.SPRITE_EXCLAMATION), "finds it")
	assert_true(stopped_scrolling, "the view stops for a while")
	assert_equal(flight.fade, 1.0, "faded to black")


func test_flight_to_mothership_heads_left() -> void:
	var flight := ShipFlight.to_mothership()
	var start := flight.position
	for tick in ENOUGH_TICKS:
		flight.step()
	assert_true(flight.is_finished(), "arrives")
	assert_true(flight.position.x < start.x, "flew left")
	assert_equal(flight.sprite, ShipFlight.SPRITE_LEFT, "faces left")


func test_ending_goes_through_every_stage() -> void:
	var ending := EndingSequence.create(_texts(), "~THE END\r\n".to_ascii_buffer())
	var stages := {ending.stage: true}
	var remember_stage := func() -> void: stages[ending.stage] = true
	ending.changed.connect(remember_stage)
	assert_equal(ending.map_number(), GameFiles.WORLD_MAP_LEVEL, "starts on the world map")
	assert_equal(ending.window_lines(), _texts().returns_to_ship, "the repair message")
	_press(ending)
	assert_equal(ending.map_number(), GameFiles.ENDING_LEVEL, "flies through space")
	_step(ending, ENOUGH_TICKS)
	assert_equal(ending.stage, EndingSequence.Stage.AT_HOME, "at home")
	assert_equal(ending.map_number(), 0, "the picture, no map")
	for message in _texts().home_messages.size():
		assert_equal(ending.window_lines(), _texts().home_messages[message], "message %d" % message)
		_press(ending)
	assert_equal(ending.stage, EndingSequence.Stage.FLIGHT_TO_MOTHERSHIP, "up again")
	_step(ending, ENOUGH_TICKS)
	assert_equal(ending.stage, EndingSequence.Stage.END_TEXT, "the end text")
	assert_true(ending.window_lines()[0].ends_with("THE END"), "shows the text")
	_press(ending)
	assert_true(ending.is_finished(), "finished")
	assert_equal(stages.size(), EndingSequence.Stage.size(), "every stage")
	# The connection holds a reference to the sequence; break the cycle.
	ending.changed.disconnect(remember_stage)


func test_held_button_does_not_skip_a_message() -> void:
	var ending := EndingSequence.create(_texts(), PackedByteArray())
	_step(ending, 10, true)
	assert_equal(ending.stage, EndingSequence.Stage.AT_SHIP, "still at the ship")


func test_bedroom_light_goes_on_and_off() -> void:
	var ending := EndingSequence.create(_texts(), PackedByteArray())
	ending.stage = EndingSequence.Stage.AT_HOME
	var bitmaps := PackedStringArray()
	for message in EndingTexts.HOME_MESSAGE_COUNT:
		ending.home_message = message
		bitmaps.append(ending.window_bitmap())
	assert_equal(
		bitmaps,
		PackedStringArray(["", "", "WINDON", "WINDON", "WINDON", "WINDOFF", "WINDOFF"]),
		"light"
	)


func test_end_text_scrolls() -> void:
	var data := ("line\u001f\r\n".repeat(EndingSequence.TEXT_LINES + 5)).to_ascii_buffer()
	var ending := EndingSequence.create(_texts(), data)
	ending.stage = EndingSequence.Stage.END_TEXT
	_step(ending, 100, false, 1)
	assert_equal(ending.text_offset, 5, "down to the last page")
	_step(ending, 100, false, -1)
	assert_equal(ending.text_offset, 0, "back to the top")


func test_text_document_layout() -> void:
	var text := (
		"~Centered\u001f\r\nA paragraph that runs\r\non into the next line.\r\n\r\n"
		+ " \u0097\u0098  Hand   made\u001f\r\nIgnored\u001a after the end"
	)
	var data := PackedByteArray()
	for character in text:
		data.append(character.unicode_at(0))
	var lines := TextDocument.layout(data, 20)
	var expected := PackedStringArray(
		[
			"      Centered",
			"A paragraph that",
			"runs on into the",
			"next line.",
			"",
			" \u0097\u0098  Hand   made",
			"Ignored",
		]
	)
	assert_equal(lines, expected, "lines")


func test_finale_image_is_decoded() -> void:
	var plane_size := 8192
	var data := PackedByteArray()
	data.resize(4)
	data.encode_u32(0, plane_size * 4)
	# Plane 0 (blue) all set: 64 runs of 128 bytes 0xFF; the other planes empty.
	for run in plane_size / 128:
		data.append_array([125, 0xFF])
	for run in plane_size * 3 / 128:
		data.append_array([125, 0x00])
	var image := FinaleImage.decode(data)
	assert_true(image != null, "decoded")
	if image == null:
		return
	assert_equal(image.get_size(), FinaleImage.SIZE, "size")
	assert_equal(image.get_pixel(319, 199), EgaPalette.color(1), "blue everywhere")


func test_finale_image_rejects_short_data() -> void:
	var data := PackedByteArray([0, 0x80, 0, 0, 0x81, 1, 2])
	assert_equal(FinaleImage.decode(data), null, "too short")


func test_ending_texts_are_found() -> void:
	var image := PackedByteArray([1, 2, 3, 0])
	for record in [
		"Your ship is missing\nthese parts:\n\n",
		"  GO GET THEM!\n",
		"",
		"Keen returns\n",
		"to his ship.\n",
		"FINALE.CK1",
	]:
		image.append_array(record.to_ascii_buffer())
		image.append(0)
	for message in EndingTexts.HOME_MESSAGE_COUNT:
		image.append_array(("Message %d\n" % message).to_ascii_buffer())
		image.append(0)
		image.append_array("goes on".to_ascii_buffer())
		image.append(0)
	image.append_array("TO BE CONTINUED....".to_ascii_buffer())
	image.append(0)
	var texts := EndingTexts.find_in_image(image)
	assert_true(texts != null, "found")
	if texts == null:
		return
	assert_equal(
		texts.missing_parts,
		PackedStringArray(["Your ship is missing", "these parts:", "", "  GO GET THEM!"]),
		"missing parts"
	)
	assert_equal(
		texts.returns_to_ship, PackedStringArray(["Keen returns", "to his ship."]), "repair"
	)
	assert_equal(texts.home_messages.size(), EndingTexts.HOME_MESSAGE_COUNT, "home messages")
	assert_equal(texts.home_messages[6], PackedStringArray(["Message 6", "goes on"]), "last one")


func test_all_ship_parts() -> void:
	var inventory := Inventory.new()
	assert_true(not inventory.has_all_ship_parts(), "none at the start")
	for part in Inventory.ShipPart.values():
		inventory.add_ship_part(part)
	assert_true(inventory.has_all_ship_parts(), "all four")


func _texts() -> EndingTexts:
	var texts := EndingTexts.new()
	texts.returns_to_ship = PackedStringArray(["Keen returns", "to his ship."])
	for message in EndingTexts.HOME_MESSAGE_COUNT:
		texts.home_messages.append(PackedStringArray(["Message %d" % message]))
	return texts


## Presses and releases a button.
func _press(ending: EndingSequence) -> void:
	ending.step(false)
	ending.step(true)
	ending.step(false)


func _step(ending: EndingSequence, ticks: int, confirm_held := false, vertical := 0) -> void:
	for tick in ticks:
		ending.step(confirm_held, vertical)
