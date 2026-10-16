extends "res://tests/test_case.gd"
## Tests for the extra levels: the ship as a level of its own (walking away
## at its sides, putting the parts back, the ending after the last one), the
## pogo level that can be played again, and the parts in the HUD. On small
## hand-made levels and maps (no game data needed); test_keen1_ship.gd plays
## the real ship levels.

const Fixtures := preload("res://tests/fixtures.gd")
const SETTLE_TICKS := 120
const WALK_TICKS := 240

## Keen starts on the left, standing on the floor in row 4.
const FIELD: PackedStringArray = [
	"....................",
	"....................",
	"....................",
	"....................",
	"....................",
	"####################",
]
const START_CELL := Vector2i(2, 3)
const FEET_ROW := 4
## An open map for the world map tests, with the ship next to the start.
const MAP: PackedStringArray = [
	"##########",
	"#........#",
	"#........#",
	"##########",
]
const MAP_START := Vector2i(2, 1)
const MAP_SHIP := Vector2i(4, 1)


func test_installed_parts_are_saved() -> void:
	var game := GameProgress.new()
	game.install_part(Inventory.ShipPart.BATTERY)
	var loaded := GameProgress.from_dict(game.to_dict())
	assert_equal(loaded.installed_parts, [false, true, false, false], "battery is in")
	var old := game.to_dict()
	old.erase("installed_parts")
	var from_old := GameProgress.from_dict(old)
	assert_true(from_old != null, "a game saved before the ship could be repaired")
	assert_true(not from_old.installed_parts.has(true), "has no parts in the ship")
	game.installed_parts.fill(true)
	assert_true(game.all_parts_installed(), "all in")


func test_pogo_level_stays_open_until_keen_has_the_pogo() -> void:
	var game := GameProgress.new()
	game.complete_level(GameProgress.POGO_LEVEL)
	game.complete_level(3)
	assert_true(game.can_enter(GameProgress.POGO_LEVEL, true), "pogo left behind")
	assert_true(not game.can_enter(GameProgress.POGO_LEVEL, false), "not without the extras")
	assert_true(not game.can_enter(3, true), "another completed level")
	assert_true(game.can_enter(4, false), "a level that is not done")
	game.inventory.has_pogo = true
	assert_true(not game.can_enter(GameProgress.POGO_LEVEL, true), "once Keen has the pogo")


func test_map_enters_the_pogo_level_again() -> void:
	var game := GameProgress.new()
	game.complete_level(GameProgress.POGO_LEVEL)
	var session := _map_session({MAP_SHIP: GameProgress.POGO_LEVEL}, game)
	session.extra_levels = true
	_walk_onto_and_use(session, MAP_SHIP)
	assert_equal(session.outcome, MapSession.Outcome.ENTER_LEVEL, "entered")
	assert_equal(session.chosen_level, GameProgress.POGO_LEVEL, "the pogo level")


func test_ship_on_the_map_is_a_level_with_the_extras() -> void:
	var session := _map_session({MAP_SHIP: MapInfo.SHIP})
	session.extra_levels = true
	var used := []
	session.ship_used.connect(func() -> void: used.append(true))
	_walk_onto_and_use(session, MAP_SHIP)
	assert_equal(session.outcome, MapSession.Outcome.ENTER_LEVEL, "enters the ship")
	assert_equal(session.chosen_level, ShipLevels.OUTSIDE_LEVEL, "the outside of the ship")
	assert_equal(session.progress.map_position, session.keen.position, "comes back here")
	assert_true(used.is_empty(), "no message of missing parts")


func test_ship_can_be_used_from_next_to_it() -> void:
	var session := _map_session({MAP_SHIP: MapInfo.SHIP})
	session.extra_levels = true
	session.keen.position = Vector2(_left_of(MAP_SHIP.x - 1), _left_of(MAP_START.y))
	assert_true(session.cell_under_keen() != _cell(MAP_SHIP.x, MAP_SHIP.y), "not on the ship")
	assert_true(session.is_near_ship(), "but next to it")
	session.step(KeenInput.toward(Vector2i.ZERO, true))
	assert_equal(session.chosen_level, ShipLevels.OUTSIDE_LEVEL, "enters the ship")
	var far := _map_session({MAP_SHIP: MapInfo.SHIP})
	far.extra_levels = true
	far.step(KeenInput.toward(Vector2i.ZERO, true))
	assert_true(not far.is_near_ship(), "two cells away is too far")
	assert_equal(far.outcome, MapSession.Outcome.PLAYING, "stays on the map")


func test_ship_on_the_map_shows_missing_parts_without_the_extras() -> void:
	var session := _map_session({MAP_SHIP: MapInfo.SHIP})
	var used := []
	session.ship_used.connect(func() -> void: used.append(true))
	_walk_onto_and_use(session, MAP_SHIP)
	assert_equal(session.outcome, MapSession.Outcome.PLAYING, "stays on the map")
	assert_equal(used.size(), 1, "as in the original")


func test_points_do_not_count_when_played_again() -> void:
	var session := _session_with_items("....o.g.............")
	session.scores_points = false
	_run(session, KeenInput.create(1), WALK_TICKS)
	assert_equal(session.inventory.score, 0, "no points for the lollipop")
	assert_equal(session.inventory.charges, Inventory.RAYGUN_CHARGES, "the raygun still counts")
	assert_equal(session.level.tile_at(_cell(4, FEET_ROW)), LevelSession.BACKGROUND_TILE, "gone")


func test_items_can_stay_where_they_are() -> void:
	var session := _session_with_items("....J...............")
	session.picks_up_items = false
	_run(session, KeenInput.create(1), WALK_TICKS)
	assert_true(not session.inventory.ship_parts.has(true), "not picked up")
	assert_equal(session.level.tile_at(_cell(4, FEET_ROW)), Fixtures.JOYSTICK, "still there")


func test_keen_walks_away_at_open_sides() -> void:
	var walled := _session(FIELD)
	_run(walled, KeenInput.create(-1), WALK_TICKS)
	assert_equal(walled.outcome, LevelSession.Outcome.PLAYING, "a wall as usual")
	var right := _session(FIELD)
	right.open_sides()
	_run(right, KeenInput.create(1), WALK_TICKS * 2)
	assert_equal(right.outcome, LevelSession.Outcome.WALKED_AWAY, "out at the right")
	var left := _session(FIELD)
	left.open_sides()
	_run(left, KeenInput.create(-1), WALK_TICKS)
	assert_equal(left.outcome, LevelSession.Outcome.WALKED_AWAY, "out at the left")
	assert_true(left.keen.hitbox().end.x <= _left_of(0), "out of sight")
	assert_true(not left.keen.is_dead, "on the ground that goes on")


func test_found_part_goes_into_its_place() -> void:
	var game := GameProgress.new()
	game.inventory.ship_parts[Inventory.ShipPart.JOYSTICK] = true
	var session := _ship_session(game, Inventory.ShipPart.JOYSTICK)
	var repair := ShipRepair.create(game, session.level)
	var installed: Array[int] = []
	repair.part_installed.connect(func(part: int) -> void: installed.append(part))
	var sounds: Array[Sound.Id] = []
	session.sound_played.connect(func(sound: Sound.Id) -> void: sounds.append(sound))
	_run_with(session, repair, KeenInput.create(1), WALK_TICKS)
	assert_equal(installed, [Inventory.ShipPart.JOYSTICK], "the joystick goes in, once")
	assert_true(game.installed_parts[Inventory.ShipPart.JOYSTICK], "kept in the game")
	var place := _cell(6, FEET_ROW)
	assert_equal(
		session.level.tile_at(place), ShipLevels.PART_TILES[Inventory.ShipPart.JOYSTICK], "shown"
	)
	assert_true(sounds.has(Sound.Id.GOT_PART), "with a sound")
	assert_true(not repair.is_ready_to_fly(), "three more to go")


func test_part_that_is_not_found_is_missing() -> void:
	var game := GameProgress.new()
	var session := _ship_session(game, Inventory.ShipPart.BATTERY)
	var repair := ShipRepair.create(game, session.level)
	var missing: Array[int] = []
	repair.part_missing.connect(func(part: int) -> void: missing.append(part))
	_run_with(session, repair, KeenInput.create(1), WALK_TICKS)
	assert_equal(missing, [Inventory.ShipPart.BATTERY], "said once, while Keen walks past")
	assert_true(not game.installed_parts.has(true), "nothing goes in")


func test_ship_flies_a_moment_after_the_last_part() -> void:
	var game := GameProgress.new()
	game.inventory.ship_parts.fill(true)
	game.installed_parts = [true, true, false, true]
	var session := _ship_session(game, Inventory.ShipPart.VACUUM)
	var repair := ShipRepair.create(game, session.level)
	var ticks := 0
	while not game.all_parts_installed() and ticks < WALK_TICKS:
		_run_with(session, repair, KeenInput.create(1), 1)
		ticks += 1
	assert_true(game.all_parts_installed(), "the last part is in")
	assert_true(not repair.is_ready_to_fly(), "not at once")
	_run_with(session, repair, KeenInput.create(0), ShipRepair.FLY_DELAY_TICKS)
	assert_true(repair.is_ready_to_fly(), "a moment later")


func test_ship_levels_are_built_with_their_places() -> void:
	var outside := ShipLevels.build(ShipLevels.OUTSIDE_LEVEL)
	assert_true(outside.find_info(LevelData.PLAYER_START_INFO).x >= 0, "start outside")
	assert_true(outside.find_info(ShipLevels.DOOR_START_INFO).x >= 0, "start at the door")
	assert_equal(ShipLevels.smoke_sources(ShipLevels.OUTSIDE_LEVEL).size(), 2, "smoke")
	var empty := ShipLevels.build(ShipLevels.INSIDE_LEVEL)
	var repaired := ShipLevels.build(ShipLevels.INSIDE_LEVEL, [false, false, true, false])
	for part in Inventory.ShipPart.size():
		var place := empty.find_info(ShipLevels.FIRST_PLACE_INFO + part)
		assert_true(place.x >= 0, "a place for part %d" % part)
		var expected := (
			ShipLevels.PART_TILES[part] if part == 2 else ShipLevels.EMPTY_PLACE_TILES[part]
		)
		assert_equal(repaired.tile_at(place), expected, "part %d shown" % part)
		assert_equal(empty.tile_at(place), ShipLevels.EMPTY_PLACE_TILES[part], "empty %d" % part)
	assert_true(ShipLevels.smoke_sources(ShipLevels.INSIDE_LEVEL).is_empty(), "no smoke inside")
	assert_equal(ShipLevels.picture_level(ShipLevels.OUTSIDE_LEVEL), 1, "Mars behind it")
	assert_equal(ShipLevels.title(ShipLevels.INSIDE_LEVEL), "Inside the ship", "title")
	assert_equal(ShipLevels.title(3), "Level 3", "other titles as before")


func test_hud_shows_the_found_parts() -> void:
	var parts: Array[bool] = [true, false, false, true]
	var tiles := Hud.part_tiles(parts)
	assert_equal(tiles.size(), 2, "two found")
	assert_equal(tiles[0], StatusScreen.SHIP_PART_TILES[0], "the joystick")
	assert_equal(tiles[1], StatusScreen.SHIP_PART_TILES[3], "the whiskey")


func test_extra_levels_setting_is_remembered() -> void:
	var path := "user://test_ship_settings.cfg"
	var settings := UserSettings.new()
	settings.path = path
	assert_true(settings.extra_levels, "on by default")
	settings.extra_levels = false
	settings.save()
	assert_true(not UserSettings.load_from(path).extra_levels, "stays off")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## A map with the ship or an entrance; Keen starts at [constant MAP_START].
func _map_session(infos: Dictionary, game: GameProgress = null) -> MapSession:
	var level := Fixtures.create_level(MAP)
	level.infos[_index(level, MAP_START)] = LevelData.PLAYER_START_INFO
	for cell: Vector2i in infos:
		level.infos[_index(level, cell)] = infos[cell]
	var progress := game if game != null else GameProgress.new()
	return MapSession.create(level, Fixtures.create_properties(), progress)


func _walk_onto_and_use(session: MapSession, cell: Vector2i) -> void:
	for tick in WALK_TICKS:
		if session.cell_under_keen() == _cell(cell.x, cell.y):
			break
		session.step(KeenInput.toward(Vector2i.RIGHT))
	session.step(KeenInput.toward(Vector2i.ZERO, true))


func _session_with_items(items: String) -> LevelSession:
	var rows := FIELD.duplicate()
	rows[FEET_ROW] = items + rows[FEET_ROW].substr(items.length())
	return _session(rows)


## A session with Keen standing at [constant START_CELL].
func _session(rows: PackedStringArray, game: GameProgress = null) -> LevelSession:
	var inventory := game.inventory if game != null else Inventory.new()
	var start := Vector2((START_CELL + _border()) * EgaGraphics.TILE_SIZE)
	var session := LevelSession.create(
		Fixtures.create_level(rows), Fixtures.create_properties(), inventory, start
	)
	_run(session, KeenInput.create(0), SETTLE_TICKS)
	return session


## A ship inside with the place of [param part] in column 6, in Keen's way.
func _ship_session(game: GameProgress, part: Inventory.ShipPart) -> LevelSession:
	var session := _session(FIELD, game)
	session.picks_up_items = false
	var place := _cell(6, FEET_ROW)
	session.level.infos[place.y * session.level.width + place.x] = (
		ShipLevels.FIRST_PLACE_INFO + part
	)
	session.set_tile(place, ShipLevels.EMPTY_PLACE_TILES[part])
	return session


func _run(session: LevelSession, input: KeenInput, ticks: int) -> void:
	for tick in ticks:
		session.step(input)


func _run_with(session: LevelSession, repair: ShipRepair, input: KeenInput, ticks: int) -> void:
	for tick in ticks:
		session.step(input)
		repair.step(session)


func _index(level: LevelData, cell: Vector2i) -> int:
	var map_cell := _cell(cell.x, cell.y)
	return map_cell.y * level.width + map_cell.x


## A cell of the rows, in level coordinates (with the border).
func _cell(x: int, y: int) -> Vector2i:
	return Vector2i(x, y) + _border()


func _border() -> Vector2i:
	return Vector2i(LevelData.BORDER_CELLS, LevelData.BORDER_CELLS)


func _left_of(column: int) -> float:
	return (column + LevelData.BORDER_CELLS) * EgaGraphics.TILE_SIZE
