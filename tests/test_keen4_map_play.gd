extends "res://tests/test_case.gd"
## Checks Keen 4's world map and the screens between the levels with the
## player's own files (milestone D7; skipped without them): the 18
## entrances of map 0, the flags and fences of done levels, Miragia, the
## texts found by their lengths, the boxes and the status window. (The
## view's flow needs a running scene tree; the screenshots check it.)

const MapFixtures := preload("res://tests/keen4_map_fixtures.gd")

const ENTRANCES := 18
const FLAG_HOLDERS := 17
const FENCES: Array[Vector2i] = [
	Vector2i(52, 30), Vector2i(53, 30), Vector2i(48, 22), Vector2i(49, 22)
]
const MIRAGIA := Vector2i(13, 19)
const STATUS_LABELS := 14

var _data: GalaxyData


func _init() -> void:
	var files := Keen4Files.locate()
	if files == null:
		skip("no Keen 4 files in game_data/keen4")
		return
	_data = Keen4Episode.load_data(files)


func test_map_0_has_the_18_entrances_and_each_one_enters() -> void:
	var map := _data.maps.load_map(Keen4Episode.WORLD_MAP)
	var first: Dictionary[int, Vector2i] = {}
	for y in map.height:
		for x in map.width:
			var level := map.tile(GalaxyMap.Layer.INFO, x, y) - GalaxyMapKeen.ENTRY_BASE
			if level >= 1 and level <= ENTRANCES and not first.has(level):
				first[level] = Vector2i(x, y)
	assert_equal(first.size(), ENTRANCES, "0xC001-0xC012 (files, v1.0)")
	var entered := 0
	for level: int in first:
		var on_map := Keen4MapSession.start(_data, _data.maps.load_map(0), Keen4Progress.new())
		on_map.keen.position = first[level] * MapFixtures.TILE
		on_map.keen.reset_box()
		on_map.run_frame(MapFixtures.jump(), 2, 5)
		if on_map.entered() == level:
			entered += 1
	assert_equal(entered, ENTRANCES, "jump on each entrance enters its level")


func test_done_levels_put_flags_and_open_the_fences() -> void:
	var progress := Keen4Progress.new()
	for level in range(1, 19):
		progress.mark_done(level)
	progress.last_finished = 1
	var on_map := Keen4MapSession.start(_data, _data.maps.load_map(0), progress)
	assert_equal(on_map.flags.size(), FLAG_HOLDERS, "17 flags (0xF001-0xF011)")
	var thrown := on_map.flags.filter(func(flag: GalaxyMapFlag) -> bool: return flag.is_thrown())
	assert_equal(thrown.size(), 1, "level 1's flag is thrown")
	for cell in FENCES:
		assert_equal(on_map.map.tile(GalaxyMap.Layer.FOREGROUND, cell.x, cell.y), 0, "fence gone")
	var left := 0
	for y in on_map.map.height:
		for x in on_map.map.width:
			var level := on_map.map.tile(GalaxyMap.Layer.INFO, x, y) - GalaxyMapKeen.ENTRY_BASE
			if level >= 1 and level <= ENTRANCES:
				left += 1
				assert_equal(level, 18, "only the Megarocket stays open")
	assert_true(left > 0, "the Megarocket can be entered again (seen)")


func test_miragia_appears_on_the_real_map() -> void:
	var on_map := Keen4MapSession.start(_data, _data.maps.load_map(0), Keen4Progress.new())
	assert_equal(on_map.miragia.cell, MIRAGIA, "info 33")
	MapFixtures.hold(on_map, 151)
	assert_equal(on_map.miragia.column, 8, "after 300 tics the first block")
	var map := on_map.map
	var template := Vector2i(8, Keen4Miragia.TEMPLATE_ROW)
	var same := true
	for y in Keen4Miragia.SIZE.y:
		for x in Keen4Miragia.SIZE.x:
			for layer in [GalaxyMap.Layer.BACKGROUND, GalaxyMap.Layer.FOREGROUND]:
				var copy := map.tile(layer, MIRAGIA.x + x, MIRAGIA.y + y)
				same = same and copy == map.tile(layer, template.x + x, template.y + y)
	assert_true(same, "copied from the template on row 60")


func test_the_texts_found_by_their_lengths() -> void:
	var labels := _data.executable.texts(Keen4Episode.STATUS_TEXTS)
	assert_equal(labels.size(), STATUS_LABELS, "the status window's 14 labels")
	for index in labels.size():
		assert_equal(labels[index].length(), Keen4Episode.STATUS_LENGTHS[index], "label length")
	var game := _data.executable.texts(Keen4Episode.GAME_TEXTS)
	assert_equal(game.size(), Keen4Episode.GAME_LENGTHS.size(), "the game texts")


func test_the_boxes() -> void:
	var boxes := Keen4GameBoxes.create(_data)
	var entering := boxes.entering(1)
	assert_equal(entering.size(), 6, "the whole picture and five fingers")
	assert_true(entering[0].get_data() != entering[5].get_data(), "the fingers count down")
	assert_equal(entering[0].get_size(), GalaxyWindow.SCREEN_SIZE, "a whole screen")
	var first := boxes.try_again(14, 0, 0)
	var second := boxes.try_again(14, 1, 0)
	assert_true(first.get_data() != second.get_data(), "the frame shows the choice")
	var blink := boxes.try_again(14, 0, 16)
	assert_true(first.get_data() != blink.get_data(), "and blinks every 16 tics")
	for picture: Image in [boxes.one_moment(), boxes.cant_swim(), boxes.game_over()]:
		assert_true(not picture.is_invisible(), "drawn")


func test_the_status_window_contents() -> void:
	var status := Keen4StatusWindow.create(_data)
	var inventory := Keen4Inventory.new_game()
	var progress := Keen4Progress.new()
	var plain := status.window(0, inventory, progress, GalaxyDifficulty.Level.NORMAL)
	var at := Keen4StatusWindow.WINDOW_AT
	assert_equal(plain.get_pixelv(at + Vector2i(20, 20)), Keen4StatusWindow.GREY, "grey inside")
	assert_equal(plain.get_pixel(81, 39), Keen4StatusWindow.WHITE, "the location bar")
	progress.rescued = 3
	progress.wetsuit = true
	inventory.score = 12345
	var later := status.window(9, inventory, progress, GalaxyDifficulty.Level.HARD)
	for bar: Rect2i in [
		Keen4StatusWindow.RESCUED_BAR,
		Keen4StatusWindow.SCORE_BAR,
		Keen4StatusWindow.WETSUIT_BAR,
		Keen4StatusWindow.DIFFICULTY_BAR,
		Keen4StatusWindow.NAME_BAR,
	]:
		assert_true(_differs(plain, later, bar), "the bar at %s shows the new state" % bar)
	assert_equal(status.label(Keen4StatusWindow.Text.LOCATION).length(), 8, "its labels")
	assert_true(status.arm() != null and status.strap() != null, "the arm and the strap")


static func _differs(one: Image, other: Image, rect: Rect2i) -> bool:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if one.get_pixel(x, y) != other.get_pixel(x, y):
				return true
	return false
