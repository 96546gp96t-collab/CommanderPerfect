extends "res://tests/test_case.gd"
## Two players in Keen 5's levels with the player's real files (milestone
## E11; [Keen5LevelSession] with [method GalaxyLevelSession.add_player];
## docs/keen5/gameplay.md, "Two players"): player 2 is Keen 5's Keen too;
## the keycard is shared, so the card one takes opens the security door
## for the other (and is used up for both), and without it the door says
## no to either; in a fuse level each breaks a fuse and the level ends as a
## fuse's (14); either Keen leaving by the exit or the door to Korath III
## ends the level for both, either death ends the attempt and costs one
## life; the creatures go after the nearer Keen. Skipped without the files.

const KEYCARD_LEVEL := 2
const EXIT_LEVEL := 1
const FUSE_LEVEL := 4
const KORATH_DOOR_LEVEL := 11
const KORATH_DOOR := Vector2i(7, 33)
const TILE := 256
const STANDING_RISE := 241
const KORATH_RISE := 497
## Keen stands this far into the left of a door two tiles wide (Omni).
const DOOR_SPOT := 96
const FRAME_TICS := 2
const DOOR_FRAMES := 120
const TAKE_FRAMES := 60
const FALL_FRAMES := 30
const END_FRAMES := 80
## Keen comes down on a fuse at this speed (breaking needs 48).
const POGO_SPEED := 60
const FAR := 40 * TILE

var _data: GalaxyData
var _rules: GalaxyGameRules
var _tic := 0


func _init() -> void:
	var files := Keen5Files.locate()
	if files == null:
		skip("no Keen 5 files in game_data/keen5")
		return
	_data = Keen5Episode.load_data(files)
	_rules = Keen5Episode.game_rules()


func test_player_2_is_keen_5s_keen_with_the_shared_inventory() -> void:
	var session := _two_in(KEYCARD_LEVEL)
	assert_true(session.partner is Keen5Keen, "Keen 5's Keen")
	assert_true(session.partner.inventory == session.inventory, "one inventory")
	assert_true(session.world.players().has(session.partner), "a player of the world")


func test_the_keycard_one_takes_opens_the_door_for_the_other() -> void:
	var session := _two_in(KEYCARD_LEVEL)
	var carried := session.inventory as Keen5Inventory
	var doors := _door_cells(session.map, Keen5Keen.SECURITY_DOOR)
	assert_equal(doors.size(), 2, "the security door")
	_at_door(session.partner, session.camera_2, doors)
	var sounds: Array[StringName] = []
	session.world.sound_player = func(name: StringName, _interrupt := false) -> void:
		sounds.append(name)
	_up_and_through(session, false)
	assert_true(session.is_playing(), "no card: the door stays shut for player 2")
	assert_true(sounds.has(&"need_keycard"), "and says so")
	_take_keycard(session, session.player)
	assert_true(carried.keycard, "player 1 took the keycard")
	_at_door(session.partner, session.camera_2, doors)
	_up_and_through(session, false)
	assert_true(not carried.keycard, "used up, for both")
	assert_true(session.is_done(), "player 2 went through: the level is done")
	assert_equal(session.result(), Keen5LevelSession.DONE, "as 1")


func test_each_breaks_a_fuse_and_the_level_ends_as_a_fuses() -> void:
	var session := _two_in(FUSE_LEVEL)
	var fuses := _fuse_cells(session.world)
	assert_equal(fuses.size(), 2, "level 4 has two fuses")
	var keens: Array[GalaxyKeenBody] = [session.player, session.partner]
	var cameras: Array[GalaxyCamera] = [session.camera, session.camera_2]
	for index in fuses.size():
		_pogo_onto(keens[index], cameras[index], fuses[index])
		for frame in FALL_FRAMES:
			_frame(session)
			if not _is_fuse(session.world, fuses[index]):
				break
		assert_true(not _is_fuse(session.world, fuses[index]), "player %d's fuse" % (index + 1))
	assert_equal(session.fuses_remaining(), 0, "none left")
	for frame in END_FRAMES:
		_frame(session)
	assert_true(session.is_done(), "the level ends")
	assert_equal(session.result(), Keen5LevelSession.DONE_BY_FUSE, "as a fuse's: 14")


func test_player_2_at_the_exit_door_ends_the_level() -> void:
	var session := _two_in(EXIT_LEVEL)
	var exits: Array[Vector2i] = []
	for cell in _door_cells(session.map, GalaxyTileKinds.DOOR):
		if session.map.tile(GalaxyMap.Layer.INFO, cell.x, cell.y) == Keen5Keen.EXIT_TARGET:
			exits.append(cell)
	_at_door(session.partner, session.camera_2, exits)
	_up_and_through(session, false)
	assert_true(session.is_done(), "done for both")
	assert_equal(session.ending(), &"", "by the exit")


func test_player_2_through_the_door_to_korath_iii() -> void:
	var session := _two_in(KORATH_DOOR_LEVEL)
	_at_door(session.partner, session.camera_2, [KORATH_DOOR], true)
	_up_and_through(session, false)
	assert_true(session.is_done(), "the level ends")
	assert_true(session.left_for_korath(), "for Korath III")


func test_either_death_ends_the_attempt() -> void:
	var session := _two_in(EXIT_LEVEL)
	session.partner.god_mode = false
	session.partner.kill()
	for frame in 400:
		_frame(session)
		if not session.is_playing():
			break
	assert_true(session.is_lost(), "player 2's death ends it")


func test_creatures_go_after_the_nearer_keen() -> void:
	var session := _two_in(KEYCARD_LEVEL)
	var creature: Keen5Creature
	for object in session.world.objects:
		if object is Keen5Creature:
			creature = object
			break
	assert_true(creature != null, "a creature in level 2")
	if creature == null:
		return
	session.player.position = creature.position + Vector2i(FAR, 0)
	session.partner.position = creature.position + Vector2i(-TILE, 0)
	assert_true(creature._keen() == session.partner, "player 2 is nearer")
	session.partner.position = creature.position + Vector2i(-FAR * 2, 0)
	assert_true(creature._keen() == session.player, "now player 1")


## Level [param number] with player 2 joined, both in god mode.
func _two_in(number: int) -> Keen5LevelSession:
	var map := _data.maps.load_map(number)
	var session := Keen5LevelSession.start_level(
		_data, _rules, map, Keen5Inventory.new_game(), 0, GalaxyDifficulty.DEFAULT, number
	)
	session.add_player()
	session.player.god_mode = true
	session.partner.god_mode = true
	return session


func _frame(
	session: GalaxyLevelSession, input := KeenInput.new(), partner := KeenInput.new()
) -> void:
	_tic += FRAME_TICS
	if session.is_playing():
		session.run_frame(input, FRAME_TICS, _tic, partner)


## Lays the keycard where [param keen] stands (its own place is by a
## wall) and runs until he took it.
func _take_keycard(session: GalaxyLevelSession, keen: GalaxyKeenBody) -> void:
	for object in session.world.objects:
		var item := object as GalaxyItem
		if item == null or item.kind != Keen5Inventory.KEYCARD_ITEM:
			continue
		item.position = Vector2i(keen.box.left, keen.box.top)
		item.reset_box()
		session.camera.centre_on(keen.position.x, keen.box.bottom)
		for frame in TAKE_FRAMES:
			_frame(session)
			if (session.inventory as Keen5Inventory).keycard:
				return


## Puts [param keen] standing at the spot of the door [param cells], his
## view [param view] on him; the door to Korath III ([param korath]) has
## its tiles in the row of his head, not of his feet (files).
static func _at_door(
	keen: GalaxyKeenBody, view: GalaxyCamera, cells: Array[Vector2i], korath := false
) -> void:
	var door := cells[0]
	keen.position = Vector2i(door.x * TILE + DOOR_SPOT, (door.y + 1) * TILE - STANDING_RISE)
	if korath:
		keen.position = Vector2i(door.x * TILE, (door.y + 2) * TILE - KORATH_RISE)
	keen.direction.x = 1
	keen.start(keen.actions[&"stand"])
	keen.reset_box()
	view.centre_on(keen.position.x, keen.box.bottom)


## Up for a frame (player 1's, or player 2's when [param first] is false),
## then the door's way until the level ends or the time is up.
func _up_and_through(session: GalaxyLevelSession, first: bool) -> void:
	var up := KeenInput.new()
	up.vertical = -1
	for frame in DOOR_FRAMES:
		var held := up if frame < 2 else KeenInput.new()
		_frame(session, held if first else KeenInput.new(), KeenInput.new() if first else held)
		if not session.is_playing():
			return


## [param keen] on the pogo, coming down fast just over the fuse at
## [param cell], his view [param view] on him.
static func _pogo_onto(keen: GalaxyKeenBody, view: GalaxyCamera, cell: Vector2i) -> void:
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
	view.centre_on(keen.position.x, keen.box.bottom)


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
