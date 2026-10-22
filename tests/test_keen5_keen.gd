extends "res://tests/test_case.gd"
## Checks Keen 5's own Keen in hand-made mini levels (milestone E3;
## [Keen5Keen], [Keen5SecurityDoor], [Keen5Inventory], [Keen5LevelSession];
## Omni `ck_keen.c`, `ck_obj.c`; docs/keen5/research.md §4-§5): the keycard
## taken with its own sound and no points; the security door that does
## nothing without the card and opens in three steps of 15 tics with it,
## Keen stepping in and coming out at the door's target; the exit door
## (0xB1B1) and the door to Korath III (0x0000) ending the level with Keen
## out of sight; the keycard and the gems lost after a level and a death;
## Keen 5's actions, items and sprites; Keen 5's rules for the shared game.
## No game files are needed.

const Fixtures := preload("res://tests/keen5_level_fixtures.gd")
const Keen := preload("res://tests/galaxy_keen_fixtures.gd")

const TILE := 256
## The door opens a step every 15 tics, three times; Keen steps in for 45
## tics, then the door's five pictures of 9 tics (Omni).
const STEP_TICS := 15
const STEPS := 3
const STEP_IN_TICS := 45
const DOOR_TICS := 45
const FRAME_TICS := 2
## Where a door takes him: x in the high byte, y in the low one; he arrives
## one tile above it, + 15 units (Omni).
const TARGET := Vector2i(15, 5)
const ARRIVAL_RISE := TILE - 15
## The Vitalin splash: four pictures of 8 tics (Omni).
const SPLASH_FRAMES := 4
const SPLASH_TICS := 8
const ITEM_COUNT := 13


func test_the_keycard_is_taken_with_its_sound_and_no_points() -> void:
	# As large as the view, so that the view lies inside it and the card
	# wakes up.
	var rows := PackedStringArray()
	for row in 13:
		rows.append(".".repeat(20))
	rows.append("........K" + ".".repeat(11))
	rows.append("#".repeat(20))
	var map := Keen.level(rows)
	var sounds: Array[StringName] = []
	var rules := Keen5Episode.game_rules()
	Keen.put_info(map, Vector2i(5, 13), Keen5Episode.KEYCARD_INFO)
	var carried := Keen5Inventory.new_game()
	var session := Keen5LevelSession.start_level(_data(), rules, map, carried)
	session.world.sound_player = func(name: StringName, _interrupt: bool) -> void:
		sounds.append(name)
	assert_true(session.keen is Keen5Keen, "Keen 5's Keen")
	var card := _item(session.world, Keen5Inventory.KEYCARD_ITEM)
	assert_true(card != null, "info 70 is the keycard (item 12)")
	assert_equal(card.sprite, Keen5Sprites.ITEM_FIRST_FRAMES[12], "its sprite")
	var left := KeenInput.create(-1, false, false)
	for frame in 40:
		session.run_frame(left, FRAME_TICS, (frame + 1) * FRAME_TICS)
	assert_true(carried.keycard, "taken")
	assert_equal(carried.score, 0, "no points")
	assert_true(sounds.has(&"got_keycard"), "its own sound")
	assert_equal(card.sprite, Keen5Sprites.ITEM_SHADOWS[12], "its shadow rises")


func test_a_security_door_without_the_keycard_does_nothing() -> void:
	var sounds: Array[StringName] = []
	var map := Fixtures.security_door_level()
	var world := Fixtures.world(map, sounds)
	var keen := world.player() as Keen5Keen
	Fixtures.walk_to(world, 5)
	var before := map.planes[GalaxyMap.Layer.FOREGROUND].duplicate()
	for frame in 30:
		Fixtures.press_up(world)
	assert_true(sounds.has(&"need_keycard"), "the sound that he needs the card")
	assert_true(keen.action.name.begins_with("look_up"), "he only looks up")
	Keen.run(world, 60, Keen.nothing)
	assert_equal(map.planes[GalaxyMap.Layer.FOREGROUND], before, "the door stays shut")
	assert_equal(world.state, GalaxyWorld.LevelState.PLAYING, "still playing")


func test_the_keycard_opens_a_security_door_in_three_steps() -> void:
	var sounds: Array[StringName] = []
	var map := Fixtures.security_door_level()
	Keen.put_info(map, Fixtures.DOOR_TARGET_CELL, (TARGET.x << 8) | TARGET.y)
	var world := Fixtures.world(map, sounds)
	var keen := world.player() as Keen5Keen
	(keen.inventory as Keen5Inventory).keycard = true
	Fixtures.walk_to(world, 5)
	for frame in 20:
		Fixtures.press_up(world)
		if keen.action.name == &"enter_security_door":
			break
	assert_equal(keen.action.name, &"enter_security_door", "he steps in")
	assert_true(not keen.has_keycard(), "the card is used")
	assert_true(sounds.has(&"open_security_door"), "the door's sound")
	assert_equal(keen.box.tile_middle - 2, Fixtures.DOOR_AT.x, "the door at his middle − 2")
	# The opener runs in the frame that placed it: its 15 tics count from
	# that frame's start.
	var opened_at := world.tic - FRAME_TICS
	while world.tic - opened_at < STEPS * STEP_TICS + FRAME_TICS:
		var elapsed := world.tic - opened_at
		var steps := mini(elapsed / STEP_TICS, STEPS)
		assert_equal(_door_shift(map), -steps * 4, "%d steps after %d tics" % [steps, elapsed])
		Keen.run(world, 1, Keen.nothing)
	assert_true(_openers(world) == 0, "the opener is gone after three steps")
	for frame in (STEP_IN_TICS + DOOR_TICS) / FRAME_TICS:
		Keen.run(world, 1, Keen.nothing)
	assert_equal(_door_shift(map), -STEPS * 4, "three steps only")
	assert_equal(
		keen.position, Vector2i(TARGET.x * TILE, TARGET.y * TILE - ARRIVAL_RISE), "through"
	)


func test_the_exit_door_ends_the_level() -> void:
	var map := Keen.level(Fixtures.DOOR_ROWS)
	Keen.put_info(map, Fixtures.DOOR_TARGET_CELL, Keen5Keen.EXIT_TARGET)
	var world := Fixtures.world(map)
	var keen := world.player() as Keen5Keen
	_enter_door(world)
	assert_equal(world.state, GalaxyWorld.LevelState.COMPLETED, "the level is done")
	assert_equal(world.ending, &"", "the plain end")
	assert_equal(keen.action.name, &"entered_door", "he is gone through it")
	assert_equal(keen.sprite, -1, "out of sight")


func test_the_door_to_korath_ends_the_level_its_way() -> void:
	var map := Keen.level(Fixtures.DOOR_ROWS)
	Keen.put_info(map, Fixtures.DOOR_TARGET_CELL, Keen5Keen.KORATH_TARGET)
	var world := Fixtures.world(map)
	_enter_door(world)
	assert_equal(world.state, GalaxyWorld.LevelState.COMPLETED, "the level is done")
	assert_equal(world.ending, Keen5Keen.KORATH_ENDING, "to Korath III")


func test_the_keycard_and_gems_are_lost_after_a_level_and_a_death() -> void:
	for dies in [false, true]:
		var map := Keen.level(Fixtures.DOOR_ROWS)
		Keen.put_info(map, Fixtures.DOOR_TARGET_CELL, Keen5Keen.EXIT_TARGET)
		var carried := Keen5Inventory.new_game()
		var session := Keen5LevelSession.start_level(
			_data(), Keen5Episode.game_rules(), map, carried
		)
		carried.keycard = true
		carried.gems = PackedInt32Array([1, 1, 0, 0])
		if dies:
			session.keen.kill()
		var held := func(frame: int) -> KeenInput:
			if dies or session.keen.box.tile_middle != 5:
				return Keen.press(0 if dies else -1)
			return Keen.press(0, -1 if frame % 2 == 0 else 0)
		for frame in 300:
			session.run_frame(held.call(frame), FRAME_TICS, (frame + 1) * FRAME_TICS)
			if not session.is_playing():
				break
		assert_true(session.is_lost() if dies else session.is_done(), "ended (%s)" % dies)
		assert_true(not carried.keycard, "the keycard is gone (death: %s)" % dies)
		assert_equal(carried.gems, PackedInt32Array([0, 0, 0, 0]), "the gems too (%s)" % dies)


func test_keen_5_has_its_own_actions_and_items() -> void:
	var map := Keen.level(Fixtures.DOOR_ROWS)
	var keen := Fixtures.world(map).player() as Keen5Keen
	assert_true(not keen.actions.has(&"moon_1"), "no moon")
	var step_in := keen.actions[&"enter_security_door"]
	assert_equal([step_in.timer, step_in.velocity.y], [STEP_IN_TICS, -64], "stepping in")
	assert_equal(step_in.next, keen.actions[&"enter_door_1"], "then the door's pictures")
	assert_equal(keen.actions[&"entered_door"].right_sprite, GalaxyAction.NO_SPRITE, "unseen")
	assert_equal(keen.item_sounds.size(), ITEM_COUNT, "13 item sounds")
	assert_equal(keen.item_sounds[Keen5Inventory.KEYCARD_ITEM], &"got_keycard", "the card's")
	var splash := keen.item_actions()[&"splash_1"]
	var frames := 0
	while splash != null:
		assert_equal(splash.timer, SPLASH_TICS, "8 tics each")
		frames += 1
		splash = splash.next
	assert_equal(frames, SPLASH_FRAMES, "four Vitalin splash pictures")
	assert_true(not keen.shows_moon, "misc 16 means nothing")


func test_every_sprite_name_of_keen_and_the_items_is_there() -> void:
	var sprites := Keen5Sprites.all()
	for name in GalaxyKeenActions.SPRITE_NAMES:
		if not name.begins_with("MOON"):
			assert_true(sprites.has(StringName(name)), "Keen's %s" % name)
	for item in ITEM_COUNT:
		assert_true(sprites.has(StringName("ITEM_%d" % item)), "item %d" % item)
		assert_true(sprites.has(StringName("SHADOW_%d" % item)), "shadow %d" % item)
	for name in [&"SPLASH_4", &"EXTRA_LIFE_SPLASH", &"SCOREBOX", &"STUN_1", &"STUN_HIT_2"]:
		assert_true(sprites.has(name), String(name))


func test_keen_5_rules_for_the_shared_game() -> void:
	var rules := Keen5Episode.game_rules()
	assert_equal(rules.next_level(13), 1, "13 is followed by 1")
	assert_equal(rules.next_level(12), 13, "12 by 13")
	assert_true(not rules.is_level(Keen5Episode.EMPTY_MAP), "map 14 does not exist")
	assert_equal(rules.column_block_info, -1, "no column blocks: 26 is Korath III's arrival")
	assert_equal(rules.row_block_info, 25, "rows at 25")
	assert_equal(rules.item_of_info(Keen5Episode.KEYCARD_INFO), 12, "70 is the keycard")
	assert_equal(rules.item_of_info(68), 11, "68 the stunner")
	assert_equal(rules.item_of_info(Keen5Episode.LOW_STUNNER_INFO), -1, "69 depends")
	assert_equal(rules.user_folder, "user://keen5", "Keen 5's own folder")
	assert_true(rules.sky_tiles.is_empty(), "no pictures behind the levels yet")
	assert_true(rules.missing_data_message().begins_with("Keen 5 data not found"), "message")


func test_a_new_game_carries_no_keycard() -> void:
	var carried := Keen5Inventory.new_game()
	assert_equal([carried.lives, carried.shots, carried.next_life_at], [3, 5, 20000], "new game")
	assert_true(not carried.keycard, "no keycard")
	assert_true(not carried.collect(Keen5Inventory.KEYCARD_ITEM), "no extra life")
	assert_true(carried.keycard, "the card")
	carried.collect(4)
	assert_equal(carried.score, 100, "the others as before")


## Up at the door of [param world]'s rows, then the door's whole way, until
## the level ends (as the level session stops then).
func _enter_door(world: GalaxyWorld) -> void:
	Fixtures.walk_to(world, 5)
	Fixtures.press_up(world)
	for frame in 60:
		if world.state != GalaxyWorld.LevelState.PLAYING:
			return
		Keen.run(world, 1, Keen.nothing)


## How far the door's tiles have stepped (all must agree).
static func _door_shift(map: GalaxyMap) -> int:
	var shifts: Dictionary[int, bool] = {}
	for y in Fixtures.DOOR_SIZE.y:
		for x in Fixtures.DOOR_SIZE.x:
			var cell := Fixtures.DOOR_AT + Vector2i(x, y)
			var first := (
				Fixtures.SECURITY_DOOR if x in Fixtures.MIDDLE_COLUMNS else Fixtures.SECURITY_FRAME
			)
			shifts[map.tile(GalaxyMap.Layer.FOREGROUND, cell.x, cell.y) - first] = true
	return shifts.keys()[0] if shifts.size() == 1 else 999


static func _openers(world: GalaxyWorld) -> int:
	var count := 0
	for object in world.objects:
		if object is Keen5SecurityDoor and not object.removed:
			count += 1
	return count


static func _item(world: GalaxyWorld, kind: int) -> GalaxyItem:
	for object in world.objects:
		var item := object as GalaxyItem
		if item != null and item.kind == kind:
			return item
	return null


## Data for a level in memory: the mini levels' tiles and sprite boxes.
static func _data() -> GalaxyData:
	var data := preload("res://tests/galaxy_game_fixtures.gd").data()
	data.tile_info = Fixtures.tile_info()
	return data
