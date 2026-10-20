extends "res://tests/test_case.gd"
## Checks D6 with the player's real files: every info value in levels 1-17
## places something (only the world map's values are left for D7), the
## platforms, people and creatures under water of the real levels, the
## Well of Wishes played with the swimming Keen, every new sprite and action
## row, and the message boxes: which text each screen shows (chosen by the
## rescue count and the level) and the original's layout (seen in the
## original, D6: the same pixels). Skipped without the files.

const FIRST_LEVEL := 1
const LAST_LEVEL := 17
const WELL := 17
## Info values that place no object of their own (Omni, research.md §6):
## Keen 1 / 2 and swimming 42, the scroll blocks 25 / 26, the stunner for
## few charges 34 (an item), the turn point 31.
const NOT_OBJECTS: PackedInt32Array = [1, 2, 25, 26, 31, 34, 42]
const FIRST_ITEM := 57
const LAST_ITEM := 68
const FIRST_TARGET := 0x100
## What only the world map places: the map Keen and Miragia (D7); 75 only
## loads the moon's sprites (level 11).
const MAP_ONLY: PackedInt32Array = [3, 33]
const MOON_SPRITES := 75
## Level 17 on Hard (files, v1.0): one council member, the Dopefish (2 on
## every difficulty, 4 more from Normal, 3 more on Hard), 24 school fish,
## 13 mines; the sprites under water (1 + 4 + 12).
const WELL_COUNTS := {"council": 1, "dopefish": 9, "schoolfish": 24, "mines": 13, "sprites": 17}
## The message window (Omni US_CenterWindow(26, 8); seen in the original):
## its inside, and what is drawn of it with the frame (the frame tiles'
## outer row and column are see-through).
const WINDOW_INSIDE := Rect2i(56, 64, 208, 64)
const WINDOW_DRAWN := Rect2i(49, 57, 222, 78)
const RUN_FRAMES := 300

var _data: GalaxyData


func _init() -> void:
	var files := Keen4Files.locate()
	if files == null:
		skip("no Keen 4 files in game_data/keen4")
		return
	_data = Keen4Episode.load_data(files)


func test_every_info_value_places_something() -> void:
	var unknown: Array[String] = []
	var later: Array[String] = []
	for number in range(FIRST_LEVEL, LAST_LEVEL + 1):
		var map := _data.maps.load_map(number)
		for value in map.planes[GalaxyMap.Layer.INFO]:
			if value == 0 or value >= FIRST_TARGET or value in NOT_OBJECTS:
				continue
			if value >= FIRST_ITEM and value <= LAST_ITEM:
				continue
			if Keen4Creatures.PLACED.has(value):
				continue
			if value in Keen4Creatures.LATER:
				later.append("%d in level %d" % [value, number])
			else:
				unknown.append("%d in level %d" % [value, number])
	assert_equal(unknown, [] as Array[String], "every value in levels 1-17 is placed")
	assert_equal(later, ["%d in level 11" % MOON_SPRITES] as Array[String], "only the moon")
	for value in MAP_ONLY:
		assert_true(value in Keen4Creatures.LATER, "%d is left for the world map" % value)


func test_the_well_of_wishes_has_its_creatures() -> void:
	var session := _level(WELL, GalaxyDifficulty.Level.HARD)
	assert_true(session.swimmer != null and session.keen == null, "Keen swims in level 17")
	var counts := {
		"council": _count(session, Keen4Council),
		"dopefish": _count(session, Keen4Dopefish),
		"schoolfish": _count(session, Keen4Schoolfish) - _count(session, Keen4Dopefish),
		"mines": _count(session, Keen4Mine),
		"sprites": _count(session, Keen4WaterSprite),
	}
	assert_equal(counts, WELL_COUNTS, "level 17's creatures on Hard")
	var easy := _level(WELL, GalaxyDifficulty.Level.EASY)
	assert_equal(_count(easy, Keen4Dopefish), 2, "two Dopefish on Easy")


func test_the_well_is_swum() -> void:
	var session := _level(WELL, GalaxyDifficulty.DEFAULT)
	var keen := session.swimmer
	keen.god_mode = true
	var start := keen.position
	var view := session.camera.scroll
	_run(session, 150, KeenInput.new())
	assert_true(keen.position.y > start.y, "he sinks")
	assert_true(session.camera.scroll != view, "the view follows as on the world map")
	_run(session, RUN_FRAMES, KeenInput.create(1, false))
	assert_true(not session.is_lost(), "in god mode nothing eats him")


func test_levels_with_platforms_run() -> void:
	var platforms := 0
	for number in range(FIRST_LEVEL, LAST_LEVEL):
		var session := _level(number, GalaxyDifficulty.DEFAULT)
		platforms += _count(session, GalaxyPlatform)
		session.player.god_mode = true
		_run(session, RUN_FRAMES, KeenInput.new())
		assert_true(not session.is_lost(), "level %d runs with its platforms" % number)
	assert_true(platforms > 80, "many platforms in levels 1-16 (%d)" % platforms)


func test_council_members_people_and_the_wetsuit_are_where_they_should_be() -> void:
	var members := 0
	for number in [3, 4, 6, 10, 12, 13, 14, 16, WELL]:
		members += _count(_level(number, GalaxyDifficulty.DEFAULT), Keen4Council)
	assert_equal(members, 9, "nine council members, the janitor among them (files)")
	assert_equal(_count(_level(5, GalaxyDifficulty.DEFAULT), Keen4Lindsey), 1, "Lindsey in 5")
	assert_equal(_count(_level(7, GalaxyDifficulty.DEFAULT), Keen4Lindsey), 1, "and in 7")
	assert_equal(_count(_level(9, GalaxyDifficulty.DEFAULT), Keen4Wetsuit), 1, "the wetsuit")


func test_every_new_sprite_and_row_is_real() -> void:
	var count := _data.graphics.sprite_infos.size()
	var sprites := Keen4Sprites.all()
	for name in sprites:
		assert_true(sprites[name] >= 0 and sprites[name] < count, "%s is a sprite" % name)
	for table in [
		Keen4Platform.ROWS,
		GalaxyFallingPlatform.ROWS,
		Keen4Mine.ROWS,
		Keen4Council.ROWS,
		Keen4Lindsey.ROWS,
		Keen4Wetsuit.ROWS,
		Keen4Schoolfish.ROWS,
		Keen4Dopefish.DOPEFISH_ROWS,
		Keen4Bubble.ROWS,
		Keen4WaterSprite.ROWS,
		Keen4WaterSprite.SHOT_ROWS,
		Keen4SwimmingKeen.ROWS,
	]:
		var actions := GalaxyAction.table_from(table, sprites)
		assert_equal(actions.size(), table.size(), "every row reads (%s)" % table[0])


func test_the_council_messages_by_rescue_count_and_level() -> void:
	var messages := Keen4Messages.create(_data)
	var texts := _data.executable.messages(Keen4Episode.COUNCIL_MESSAGES)
	for before in Keen4Progress.COUNCIL_COUNT:
		var screens := messages.council(1, before)
		assert_equal(screens.size(), 3, "three screens")
		assert_equal(messages.texts[0], texts[Keen4Messages.THANKS], "the elder's thanks")
		var answer := texts[Keen4Messages.FIRST_ANSWER + before]
		assert_equal(messages.texts[1], answer, "Keen's answer %d" % before)
	messages.council(WELL, 0)
	assert_equal(messages.texts[0], texts[Keen4Messages.THANKS_UNDER_WATER], "bubbly in 17")
	var all_answers := {}
	for before in Keen4Progress.COUNCIL_COUNT:
		all_answers[texts[Keen4Messages.FIRST_ANSWER + before]] = true
	assert_equal(all_answers.size(), 8, "eight different answers")


func test_the_janitor_lindsey_and_the_wetsuit_boxes() -> void:
	var messages := Keen4Messages.create(_data)
	var janitor := _data.executable.messages(Keen4Episode.JANITOR_MESSAGES)
	assert_equal(messages.janitor().size(), 5, "the janitor's five boxes")
	assert_equal(
		messages.texts,
		PackedStringArray([janitor[0], janitor[1], janitor[2], janitor[3], ""]),
		"his three, Keen's, and Keen cross"
	)
	var texts := _data.executable.messages(Keen4Episode.COUNCIL_MESSAGES)
	messages.lindsey(7)
	assert_true(
		messages.texts[0].ends_with(texts[Keen4Messages.HINT_WETSUIT]), "level 7: the wetsuit"
	)
	messages.lindsey(5)
	assert_true(
		messages.texts[0].ends_with(texts[Keen4Messages.HINT_PYRAMID]), "level 5: the pyramid"
	)
	assert_equal(messages.wetsuit().size(), 2, "the wetsuit: Keen, then his thumb up")


func test_the_window_layout() -> void:
	var messages := Keen4Messages.create(_data)
	var screen := messages.council(1, 0)[0]
	assert_equal(screen.get_size(), GalaxyWindow.SCREEN_SIZE, "the original's screen")
	var used := screen.get_used_rect()
	assert_equal(used, WINDOW_DRAWN, "26 × 8 cells, framed, centred")
	var thumb := messages.council(1, 0)
	var talk := thumb[1].get_region(WINDOW_INSIDE)
	var up := thumb[2].get_region(WINDOW_INSIDE)
	assert_true(talk.get_data() != up.get_data(), "the third screen shows his thumb up")
	var left := Rect2i(WINDOW_INSIDE.position, Vector2i(WINDOW_INSIDE.size.x - 48, 64))
	assert_equal(
		thumb[1].get_region(left).get_data(),
		thumb[2].get_region(left).get_data(),
		"only his picture changes"
	)


func _level(number: int, level: GalaxyDifficulty.Level) -> Keen4LevelSession:
	var map := _data.maps.load_map(number)
	return Keen4LevelSession.start(_data, map, Keen4Inventory.new_game(), 0, level, number)


func _count(session: Keen4LevelSession, type: Script) -> int:
	return (
		session
		. world
		. objects
		. filter(func(object: GalaxyObject) -> bool: return is_instance_of(object, type))
		. size()
	)


func _run(session: Keen4LevelSession, frames: int, input: KeenInput) -> void:
	for frame in frames:
		var first := session.world.tic == 0
		var tics := GalaxyClock.LEVEL_START_TICS if first else GalaxyClock.NORMAL_TICS
		session.run_frame(input, tics, session.world.tic + tics)
