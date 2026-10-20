extends "res://tests/test_case.gd"
## Checks playing Keen 4 with the player's real files (milestone D4): which
## maps are played, that Keen stands still at every start, the jump with
## Keen's real sprites (67 pixels, seen in the original), the door near the
## start of level 1 and its target, the wall at level 1's right border, the
## items the info plane places, and the score box. Skipped without the files.

const UNITS := 16
const TILE := 256
## The maps Keen walks in (D4); the world map (0) and the Well of Wishes
## (17) follow in D7 and D6.
const PLAYED_MAPS: PackedInt32Array = [
	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 18, 19
]
const NOT_PLAYED_MAPS: PackedInt32Array = [0, 17]
const HELD_JUMP_PIXELS := 67
## Level 1 (files, v1.0): the house door at (66-67, 15) leads to (74, 48).
const LEVEL_1_DOOR_RIGHT := 67
const LEVEL_1_DOOR_TARGET := Vector2i(74, 48)
## Keen arrives one tile above the target, 15 units into his row (Omni).
const DOOR_ARRIVAL := -TILE + 15

var _data: GalaxyData


func _init() -> void:
	var files := Keen4Files.locate()
	if files == null:
		skip("no Keen 4 files in game_data/keen4")
		return
	_data = Keen4Episode.load_data(files)


func test_keen_is_played_where_he_stands() -> void:
	for number in PLAYED_MAPS:
		var session := _level(number)
		assert_true(session != null, "map %d is played" % number)
		if session == null:
			continue
		var start := session.keen.position
		_run(session, 40, KeenInput.new())
		assert_equal(
			session.keen.position, start, "Keen stands still at the start of map %d" % number
		)
		assert_equal(session.keen.action.name, &"stand", "standing in map %d" % number)
		assert_true(session.is_playing(), "map %d goes on" % number)
	for number in NOT_PLAYED_MAPS:
		assert_true(_level(number) == null, "map %d is not played yet" % number)


func test_a_held_jump_with_the_real_sprites() -> void:
	var session := _level(1)
	var keen := session.keen
	var start := keen.position.y
	var highest := start
	var jump := KeenInput.create(0, true)
	for frame in 50:
		_run(session, 1, jump)
		highest = mini(highest, keen.position.y)
	assert_equal((start - highest) / UNITS, HELD_JUMP_PIXELS, "67 pixels, as in the original")


func test_the_door_in_level_1() -> void:
	var session := _level(1)
	var keen := session.keen
	var left := KeenInput.create(-1)
	for frame in 400:
		if keen.box.tile_middle == LEVEL_1_DOOR_RIGHT:
			break
		_run(session, 1, left)
	assert_equal(keen.box.tile_middle, LEVEL_1_DOOR_RIGHT, "walked to the door")
	_run(session, 1, KeenInput.new())
	var up := KeenInput.new()
	up.vertical = -1
	_run(session, 2, up)
	_run(session, 40, KeenInput.new())
	var target := LEVEL_1_DOOR_TARGET * TILE + Vector2i(0, DOOR_ARRIVAL)
	assert_equal(keen.position, target, "at the door's target")
	assert_equal(keen.action.name, &"stand", "standing")
	var view := session.camera.view_pixels()
	var on_screen := Vector2i(target.x / UNITS, target.y / UNITS) - view
	assert_true(
		Rect2i(Vector2i.ZERO, GalaxyCamera.VIEW_PIXELS).has_point(on_screen), "the view is on him"
	)


func test_the_border_stops_him_in_level_1() -> void:
	# Level 1 starts by its right border, which is a wall there (files).
	var session := _level(1)
	_run(session, 60, KeenInput.create(1))
	assert_true(session.is_playing(), "the level goes on")
	assert_equal(session.keen.box.right, 110 * TILE - 1, "against the border's wall")


func test_items_from_the_info_plane() -> void:
	for number in PLAYED_MAPS:
		var map := _data.maps.load_map(number)
		var expected := 0
		for value in map.planes[GalaxyMap.Layer.INFO]:
			if (
				value >= Keen4LevelSession.FIRST_ITEM_INFO
				and value <= Keen4LevelSession.LAST_ITEM_INFO
			):
				expected += 1
		var session := Keen4LevelSession.start(_data, map, Keen4Inventory.new_game())
		var items := session.world.objects.filter(
			func(o: GalaxyObject) -> bool: return o is GalaxyItem
		)
		assert_equal(items.size(), expected, "the items of map %d" % number)
	var level_1 := _data.maps.load_map(1)
	var low := Keen4Inventory.new_game()
	low.shots = 0
	var with_low := Keen4LevelSession.start(_data, level_1, low)
	var normal := Keen4LevelSession.start(_data, _data.maps.load_map(1), Keen4Inventory.new_game())
	var stunners := level_1.planes[GalaxyMap.Layer.INFO].count(Keen4LevelSession.LOW_STUNNER_INFO)
	assert_equal(
		with_low.world.objects.size() - normal.world.objects.size(),
		stunners,
		"info 34 places a stunner only with fewer than 5 charges"
	)


func test_the_score_box_shows_the_numbers() -> void:
	var box := GalaxyScoreBox.new()
	box.use_graphics(_data.graphics, Keen4Sprites.OBJECTS[&"SCOREBOX"])
	var picture := box.picture_for(1234567, 3, 105)
	var digits := {
		Vector2i(8 + 8 * 8, 4): "7",
		Vector2i(8 + 2 * 8, 4): "1",
		Vector2i(8, 4): " ",
		Vector2i(24 + 8, 20): "3",
		Vector2i(24, 20): " ",
		Vector2i(64, 20): "9",
		Vector2i(72, 20): "9",
	}
	for at: Vector2i in digits:
		var character: String = digits[at]
		var tile := GalaxyScoreBox.BLANK_TILE
		if character != " ":
			tile = GalaxyScoreBox.ZERO_TILE + character.to_int()
		var expected := _data.graphics.tile8(tile)
		var same := true
		for y in 8:
			for x in 8:
				same = same and picture.get_pixel(at.x + x, at.y + y) == expected.get_pixel(x, y)
		assert_true(same, "'%s' at %s" % [character, at])
	assert_equal(box.position, Vector2(4, 4), "4 pixels from the view's corner")
	box.free()


func _level(number: int) -> Keen4LevelSession:
	return Keen4LevelSession.start(_data, _data.maps.load_map(number), Keen4Inventory.new_game())


## Runs [param frames] frames with [param input] held (3 tics first, then 2).
func _run(session: Keen4LevelSession, frames: int, input: KeenInput) -> void:
	for frame in frames:
		var tics := (
			GalaxyClock.LEVEL_START_TICS if session.world.tic == 0 else GalaxyClock.NORMAL_TICS
		)
		session.run_frame(input, tics, session.world.tic + tics)
