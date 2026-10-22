extends "res://tests/test_case.gd"
## Checks Keen 5's machinery with the player's real files (milestone E5):
## every fuse level (4, 6, 8, 10, 13) ends when Keen pogoes onto each of
## its fuses (counted 1-4 from info 41), as a fuse's (14); map 12 has no
## fuse tile, its QED is destroyed by a mine's piece and the level ends as
## the QED's; the door to Korath III (level 11) brings the lightning; the
## fuse messages read the player's texts; every platform keeps moving (no
## GoPlat leaves its arrows), Keen rides one of each kind, and every level
## runs with its platforms in god mode. Skipped without the files.

const LEVELS: PackedInt32Array = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]
## The fuse levels and their fuses (files).
const FUSES := {4: 2, 6: 3, 8: 1, 10: 4, 13: 1}
const QED_MAP := 12
const QED_FUSES := 4
## The door to Korath III (files: level 11, its two tiles at (7, 33) and
## (8, 33), target 0x0000).
const KORATH_DOOR_MAP := 11
const KORATH_DOOR := Vector2i(7, 33)
const FRAME_TICS := 2
const RUN_FRAMES := 3000
## Keen comes down on a fuse at this speed (breaking needs 48).
const POGO_SPEED := 60
const FALL_FRAMES := 30
const END_FRAMES := 40
const RIDE_FRAMES := 100
## The messages' text lengths (files): Korath III's, then the others'.
const KORATH_TEXT_LENGTH := 36
const FUSE_TEXT_LENGTH := 69

var _data: GalaxyData
var _rules: GalaxyGameRules


func _init() -> void:
	var files := Keen5Files.locate()
	if files == null:
		skip("no Keen 5 files in game_data/keen5")
		return
	_data = Keen5Episode.load_data(files)
	_rules = Keen5Episode.game_rules()


func test_every_fuse_level_ends_by_its_fuses() -> void:
	for number in FUSES:
		var session := _level(number, GalaxyDifficulty.DEFAULT)
		session.keen.god_mode = true
		var fuses := _fuse_cells(session.world)
		assert_equal(fuses.size(), FUSES[number], "level %d: its fuses" % number)
		assert_equal(session.fuses_remaining(), FUSES[number], "level %d: counted" % number)
		for cell in fuses:
			if not _is_fuse(session.world, cell):
				continue
			_pogo_onto(session, cell)
			for frame in FALL_FRAMES:
				_frame(session, frame)
				if not _is_fuse(session.world, cell):
					break
			assert_true(not _is_fuse(session.world, cell), "level %d: %s breaks" % [number, cell])
		assert_equal(session.fuses_remaining(), 0, "level %d: none left" % number)
		for frame in END_FRAMES:
			_frame(session, frame)
		assert_true(session.is_done(), "level %d ends" % number)
		assert_equal(session.result(), Keen5LevelSession.DONE_BY_FUSE, "level %d: 14" % number)


func test_map_12_ends_by_its_qed() -> void:
	var session := _level(QED_MAP, GalaxyDifficulty.DEFAULT)
	assert_equal(_fuse_cells(session.world), [] as Array[Vector2i], "no fuse tile in map 12")
	assert_equal(session.fuses_remaining(), QED_FUSES, "but four fuses counted")
	var qed: Keen5Qed = null
	for object in session.world.objects:
		if object is Keen5Qed:
			qed = object
	assert_true(qed != null, "the QED")
	if qed == null:
		return
	var corner_upper := session.world.fore_tile(0, 0)
	var corner_lower := session.world.fore_tile(4, 0)
	session.keen.god_mode = true
	session.keen.position = Vector2i(qed.box.left, qed.box.top - GalaxyUnits.PER_TILE)
	session.keen.reset_box()
	session.camera.centre_on(qed.box.middle, qed.box.bottom)
	var at := Vector2i(qed.box.middle, qed.box.top + GalaxyUnits.PER_TILE)
	var piece := Keen5Piece.throw(
		session.world, at, Vector2i.ZERO, Keen5Mine.ROWS, _rules.sprites, &"piece"
	)
	piece.reports_touches = true
	_frame(session, 0)
	assert_true(qed.removed, "a mine's piece destroys it")
	assert_equal(session.world.fore_tile(16, 11), corner_upper, "the broken machine")
	assert_equal(session.world.fore_tile(16, 13), corner_lower, "both halves")
	for frame in END_FRAMES:
		_frame(session, frame)
	assert_equal(session.result(), Keen5LevelSession.DONE_BY_QED, "the level ends as the QED's")


func test_the_door_to_korath_iii_brings_the_lightning() -> void:
	var session := _level(KORATH_DOOR_MAP, GalaxyDifficulty.DEFAULT)
	var keen := session.keen
	keen.god_mode = true
	var world := session.world
	assert_equal(world.info_at(KORATH_DOOR.x, KORATH_DOOR.y), Keen5Keen.KORATH_TARGET, "0x0000")
	keen.position = Vector2i(
		GalaxyUnits.from_tile(KORATH_DOOR.x), GalaxyUnits.from_tile(KORATH_DOOR.y + 2) - 497
	)
	keen.reset_box()
	session.camera.centre_on(keen.position.x, keen.box.bottom)
	var up := KeenInput.new()
	up.vertical = -1
	var struck := false
	for frame in 60:
		session.run_frame(up, FRAME_TICS, (frame + 1) * FRAME_TICS)
		struck = struck or world.objects.any(func(o: GalaxyObject) -> bool: return o is Keen5Flash)
		if not session.is_playing():
			break
	assert_true(struck, "the lightning")
	assert_true(session.is_done(), "the level ends")
	assert_equal(session.ending(), Keen5Keen.KORATH_ENDING, "for Korath III")
	assert_equal(session.result(), Keen5LevelSession.DONE, "done as 1")


func test_the_fuse_messages_read_the_players_texts() -> void:
	var messages := Keen5Messages.create(_data)
	var screens := messages.fuse(4)
	assert_equal(screens.size(), 2, "Keen talking, then his thumb up")
	assert_equal(messages.texts[0].length(), FUSE_TEXT_LENGTH, "the four machines")
	assert_true(messages.texts[0].contains("toast"), "toast")
	messages.fuse(13)
	assert_equal(messages.texts[0].length(), KORATH_TEXT_LENGTH, "Korath III's own")
	assert_true(messages.texts[0].contains("fuse"), "what that fuse was for")
	assert_equal(screens[0].get_size(), GalaxyWindow.SCREEN_SIZE, "a whole screen")
	# Only the picture at the window's right differs between the two.
	var differs := Rect2i()
	for y in screens[0].get_height():
		for x in screens[0].get_width():
			if screens[0].get_pixel(x, y) != screens[1].get_pixel(x, y):
				var pixel := Rect2i(x, y, 1, 1)
				differs = pixel if differs.size == Vector2i.ZERO else differs.merge(pixel)
	var window := Rect2i(Vector2i(7, 8) * 8, Vector2i(26, 8) * 8)
	assert_true(differs.size != Vector2i.ZERO, "the thumb up")
	assert_true(differs.position.x >= window.end.x - 0x30, "only the picture at the right")
	assert_true(window.encloses(differs), "inside the window")


func test_every_machinery_sprite_is_real() -> void:
	for name in Keen5Sprites.MACHINERY:
		assert_true(_data.graphics.sprite(Keen5Sprites.MACHINERY[name]) != null, "%s" % name)
	for table in [
		Keen5Platform.ROWS,
		Keen5GoPlat.ROWS,
		Keen5StillPlatform.ROWS,
		GalaxyFallingPlatform.ROWS,
		Keen5Flash.ROWS,
		Keen5LevelEnd.ROWS,
		Keen5Qed.ROWS,
	]:
		var actions := GalaxyAction.table_from(table, _rules.sprites)
		assert_equal(actions.size(), table.size(), "every row reads (%s)" % table[0])


func test_every_platform_keeps_moving() -> void:
	for number in LEVELS:
		var session := _level(number, GalaxyDifficulty.Level.HARD)
		var world := session.world
		for frame in RUN_FRAMES:
			world.tics = FRAME_TICS
			world.run_frame(FRAME_TICS, (frame + 1) * FRAME_TICS)
		for object in world.objects:
			var go := object as Keen5GoPlat
			if go != null:
				assert_true(not go.path.stuck, "level %d: a GoPlat keeps to its arrows" % number)


func test_keen_rides_one_platform_of_each_kind() -> void:
	var ridden := {}
	for number in LEVELS:
		var session := _level(number, GalaxyDifficulty.Level.EASY)
		session.keen.god_mode = true
		for object in session.world.objects:
			var platform := object as GalaxyPlatform
			if platform == null or platform is Keen5Slicestar:
				continue
			var kind := _kind_of(platform)
			if ridden.has(kind) or not _rides(session, platform):
				continue
			ridden[kind] = number
	for kind in ["red", "purple", "red go", "purple go", "falling", "standing", "sneak"]:
		assert_true(ridden.has(kind), "Keen rides a %s platform" % kind)


func test_every_level_runs_with_its_platforms() -> void:
	for number in LEVELS:
		var session := _level(number, GalaxyDifficulty.Level.HARD)
		session.keen.god_mode = true
		for frame in 600:
			var input := KeenInput.create(
				1 if (frame / 60) % 2 == 0 else -1, frame % 25 == 0, false
			)
			session.run_frame(input, FRAME_TICS, (frame + 1) * FRAME_TICS)
			if not session.is_playing():
				break
		assert_true(not session.is_lost(), "level %d: Keen lives in god mode" % number)


## Drops Keen of [param session] onto [param platform] and lets it carry
## him; returns whether he stayed on it.
func _rides(session: Keen5LevelSession, platform: GalaxyPlatform) -> bool:
	var keen := session.keen
	keen.set_action(keen.actions[&"fall_1"])
	keen.velocity = Vector2i.ZERO
	keen.position = Vector2i(platform.box.left, platform.box.top - 496 - 40)
	keen.reset_box()
	session.camera.centre_on(keen.position.x, keen.box.bottom)
	for frame in 20:
		_frame(session, frame)
		if keen.platform == platform:
			break
	if keen.platform != platform:
		return false
	for frame in RIDE_FRAMES:
		_frame(session, frame)
	return keen.platform == platform and keen.action.name == &"ride_platform"


static func _kind_of(platform: GalaxyPlatform) -> String:
	if platform is GalaxyFallingPlatform:
		return "falling"
	if platform is Keen5GoPlat:
		return "purple go" if (platform as Keen5GoPlat).look != 0 else "red go"
	if platform is Keen5Platform:
		return "purple" if (platform as Keen5Platform).purple else "red"
	if platform.action.name == &"stand":
		return "standing"
	return "sneak"


## The cells of [param world]'s fuse tiles (top 57), top to bottom.
static func _fuse_cells(world: GalaxyWorld) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in world.map.height:
		for x in world.map.width:
			if _is_fuse(world, Vector2i(x, y)):
				cells.append(Vector2i(x, y))
	return cells


static func _is_fuse(world: GalaxyWorld, cell: Vector2i) -> bool:
	var tile := world.fore_tile(cell.x, cell.y)
	return world.tile_info.fore(GalaxyTileInfo.Fore.TOP, tile) == Keen5Fuses.FUSE_TOP


## Keen of [param session] on the pogo, coming down fast just over the
## fuse at [param cell].
static func _pogo_onto(session: Keen5LevelSession, cell: Vector2i) -> void:
	var keen := session.keen
	keen.set_action(keen.actions[&"pogo_2"])
	keen.reset_box()
	var bottom := keen.box.bottom - keen.position.y
	var middle := keen.box.middle - keen.position.x
	keen.position = Vector2i(
		GalaxyUnits.from_tile(cell.x) + GalaxyUnits.PER_TILE / 2 - middle,
		GalaxyUnits.from_tile(cell.y) - 1 - bottom - 8
	)
	keen.reset_box()
	keen.jump_timer = 0
	keen.velocity = Vector2i(0, POGO_SPEED)
	session.camera.centre_on(keen.position.x, keen.box.bottom)


static func _frame(session: Keen5LevelSession, frame: int) -> void:
	if session.is_playing():
		session.run_frame(KeenInput.new(), FRAME_TICS, (frame + 1) * FRAME_TICS)


func _level(number: int, level: GalaxyDifficulty.Level) -> Keen5LevelSession:
	var map := _data.maps.load_map(number)
	return Keen5LevelSession.start_level(
		_data, _rules, map, Keen5Inventory.new_game(), 0, level, number
	)
