extends "res://tests/test_case.gd"
## Checks Keen 5's levels with the player's real files (milestone E3;
## [Keen5LevelSession], [Keen5Keen]; docs/keen5/gameplay.md): Keen starts
## in every map whose info plane places him, every level runs, the
## keycards lie where the security doors need them, every security door
## opens with the keycard to the level's end (its tiles step back three
## times into an open door), every plain exit door ends its level, and
## the fuse levels have no exit (their fuses come in E5). Every sprite the
## game asks for is in the files. Skipped without the files.

const LEVELS: PackedInt32Array = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]
const HIGH_SCORE_MAP := 15
const WORLD_MAP := 0
const MISSING_MAP := 14
## The levels with a keycard and a security door (files: one each).
const KEYCARD_LEVELS: PackedInt32Array = [2, 3, 5, 7, 9, 11, 13]
## The levels whose exit is a plain door (files).
const PLAIN_EXIT_LEVELS: Array[int] = [1]
## The fuse levels end by their fuses (E5), not by a door (files).
const FUSE_LEVELS: PackedInt32Array = [4, 6, 8, 10, 12]
const TILE := 256
const STANDING_RISE := 241
## Keen stands this far into the left of a door two tiles wide (Omni).
const DOOR_SPOT := 96
const DOOR_TILE_STEPS := 12
const NORMAL_DOOR := GalaxyTileKinds.DOOR
const RUN_FRAMES := 300
const DOOR_FRAMES := 120
const FRAME_TICS := 2

var _data: GalaxyData
var _rules: GalaxyGameRules


func _init() -> void:
	var files := Keen5Files.locate()
	if files == null:
		skip("no Keen 5 files in game_data/keen5")
		return
	_data = Keen5Episode.load_data(files)
	_rules = Keen5Episode.game_rules()


func test_keen_starts_in_every_map_that_places_him() -> void:
	for number in range(0, Keen5Episode.LAST_MAP + 1):
		if number == MISSING_MAP:
			assert_true(not _data.maps.has_map(number), "map 14 is missing")
			continue
		var map := _data.maps.load_map(number)
		var start := GalaxyStart.find(map, _rules)
		var session := _start(number)
		if number == WORLD_MAP:
			assert_true(start.is_world_map() and session == null, "the world map is no level")
			continue
		assert_true(session != null, "Keen stands in map %d" % number)
		assert_true(session.keen is Keen5Keen, "Keen 5's Keen in map %d" % number)
		assert_equal(session.keen.position, start.position, "at his start in map %d" % number)


func test_every_level_runs() -> void:
	for number in LEVELS + PackedInt32Array([HIGH_SCORE_MAP]):
		var session := _start(number)
		session.keen.god_mode = true
		for frame in RUN_FRAMES:
			var input := KeenInput.create(
				1 if (frame / 40) % 2 == 0 else -1, frame % 30 == 0, false
			)
			session.run_frame(input, FRAME_TICS, (frame + 1) * FRAME_TICS)
			if not session.is_playing():
				break
		assert_true(not session.is_lost(), "map %d runs in god mode" % number)


func test_every_keycard_level_has_one_keycard() -> void:
	for number in LEVELS:
		var cards := 0
		for object in _start(number).world.objects:
			var item := object as GalaxyItem
			if item != null and item.kind == Keen5Inventory.KEYCARD_ITEM:
				cards += 1
		assert_equal(cards, 1 if KEYCARD_LEVELS.has(number) else 0, "keycards in %d" % number)


func test_every_security_door_opens_to_the_end_of_its_level() -> void:
	for number in KEYCARD_LEVELS:
		var session := _start(number)
		var doors := _door_cells(session.map, Keen5Keen.SECURITY_DOOR)
		assert_equal(doors.size(), 2, "one security door, two tiles wide, in %d" % number)
		var carried := session.inventory as Keen5Inventory
		_at_door(session, doors)
		_up_and_through(session)
		assert_true(session.is_playing(), "no card: still in level %d" % number)
		var before := session.map.planes[GalaxyMap.Layer.FOREGROUND].duplicate()
		carried.keycard = true
		_at_door(session, doors)
		_up_and_through(session)
		assert_true(session.is_done(), "through the security door: level %d done" % number)
		assert_equal(session.ending(), &"", "by the exit (0xB1B1) in %d" % number)
		var left := doors[0]
		var block := Vector2i(left.x - 1, left.y - 3)
		var stepped := true
		for y in 4:
			for x in 4:
				var cell := block + Vector2i(x, y)
				var was: int = before[cell.y * session.map.width + cell.x]
				stepped = (
					stepped
					and (
						session.map.tile(GalaxyMap.Layer.FOREGROUND, cell.x, cell.y)
						== was - DOOR_TILE_STEPS
					)
				)
		assert_true(stepped, "the door's 4 × 4 tiles stepped back 3 × 4 in %d" % number)
		for cell in doors:
			var tile := session.map.tile(GalaxyMap.Layer.FOREGROUND, cell.x, cell.y)
			assert_equal(
				_data.tile_info.misc_kind(tile), NORMAL_DOOR, "open: a door in %d" % number
			)


func test_every_plain_exit_door_ends_its_level() -> void:
	var with_exit: Array[int] = []
	for number in LEVELS:
		var session := _start(number)
		var exits: Array[Vector2i] = []
		for cell in _door_cells(session.map, NORMAL_DOOR):
			if session.map.tile(GalaxyMap.Layer.INFO, cell.x, cell.y) == Keen5Keen.EXIT_TARGET:
				exits.append(cell)
		if exits.is_empty():
			continue
		assert_true(not KEYCARD_LEVELS.has(number), "level %d has both exits" % number)
		_at_door(session, exits)
		_up_and_through(session)
		assert_true(session.is_done(), "through the exit door: level %d done" % number)
		with_exit.append(number)
	assert_equal(with_exit, PLAIN_EXIT_LEVELS, "the levels with a plain exit door")


func test_the_fuse_levels_have_no_exit_door() -> void:
	for number in FUSE_LEVELS:
		var map := _data.maps.load_map(number)
		assert_true(
			not map.planes[GalaxyMap.Layer.INFO].has(Keen5Keen.EXIT_TARGET),
			"level %d ends by its fuses" % number
		)


func test_every_sprite_the_game_asks_for_is_in_the_files() -> void:
	var count := _data.graphics.sprite_infos.size()
	for name in _rules.sprites:
		var sprite := _rules.sprites[name]
		assert_true(sprite >= 0 and sprite < count, "%s: sprite %d" % [name, sprite])
		assert_true(_data.graphics.sprite(sprite) != null, "%s is drawn" % name)
	assert_true(_rules.map_keen_sprite < count, "Keen on the map")


func _start(number: int) -> Keen5LevelSession:
	var map := _data.maps.load_map(number)
	return Keen5LevelSession.start_level(
		_data, _rules, map, Keen5Inventory.new_game(), 0, GalaxyDifficulty.DEFAULT, number
	)


## The cells of [param map] whose foreground tile is of misc [param kind],
## left to right.
func _door_cells(map: GalaxyMap, kind: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in map.height:
		for x in map.width:
			var tile := map.tile(GalaxyMap.Layer.FOREGROUND, x, y)
			if _data.tile_info.fore(GalaxyTileInfo.Fore.MISC, tile) == kind:
				cells.append(Vector2i(x, y))
	return cells


## Puts Keen standing at the spot of the door [param cells] (two tiles
## wide, his head in their row), the view on him.
static func _at_door(session: GalaxyLevelSession, cells: Array[Vector2i]) -> void:
	var keen := session.keen
	var door := cells[0]
	keen.position = Vector2i(door.x * TILE + DOOR_SPOT, (door.y + 1) * TILE - STANDING_RISE)
	keen.direction.x = 1
	keen.start(keen.actions[&"stand"])
	keen.reset_box()
	session.camera.centre_on(keen.position.x, keen.box.bottom)


## Up for a frame, then the door's way until the level ends or the time is
## up.
static func _up_and_through(session: GalaxyLevelSession) -> void:
	var up := KeenInput.new()
	up.vertical = -1
	for frame in DOOR_FRAMES:
		session.run_frame(
			up if frame < 2 else KeenInput.new(), FRAME_TICS, (frame + 1) * FRAME_TICS
		)
		if not session.is_playing():
			return
