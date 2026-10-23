extends "res://tests/test_case.gd"
## Plays Keen 5's world map (map 0, the Omegamatic) from the player's files
## (milestone E6; [Keen5MapSession]): Keen's start, the doors of the shafts
## at their fixed places (checked against the map: the template's
## pictures, and the elevators' info words point at them), the shafts by
## Keen's row and the fuse levels, every elevator ride and the teleporter
## on Korath III, the arrival on Korath III, the done levels' flags and
## gates, every level's entrance, and the yellow filler drawn as space.
## Skipped without the files.

const TILE := 256
const FRAME_TICS := 2
const FIRST_FRAME_TICS := 3
## Where Keen starts (info 3, files) and where he steps out onto Korath III
## (info 26).
const START := Vector2i(28, 95)
const KORATH := Vector2i(37, 107)
## The elevator halves and teleporter (files) and where each ride ends.
const BOTTOM_ELEVATOR := Vector2i(24, 77)
const MIDDLE_DOWN := Vector2i(22, 56)
const MIDDLE_UP := Vector2i(26, 56)
const TOP_ELEVATOR := Vector2i(24, 31)
const TELEPORTER := Vector2i(44, 106)
const TELEPORT_TARGET := Vector2i(20, 30)
## A done level's flag holder and gate (files: level 1's).
const LEVEL_1_FLAG := Vector2i(29, 88)
const LEVEL_1_GATE := Vector2i(24, 85)
## The levels whose entrance has a gate in front (files).
const GATED_LEVELS: PackedInt32Array = [1, 2, 3, 5, 7, 9, 11, 13]
const LEVELS := 13
const MOST_FRAMES := 400
const WALK_FRAMES := 60

var _data: GalaxyData
var _rules: GalaxyGameRules
var _closed: Array[int] = []
var _open: Array[int] = []


func _init() -> void:
	var files := Keen5Files.locate()
	if files == null:
		skip("no Keen 5 files in game_data/keen5")
		return
	_data = Keen5Episode.load_data(files)
	_rules = Keen5Episode.game_rules()
	var map := _data.maps.load_map(Keen5Episode.WORLD_MAP)
	_closed = _picture(map, Keen5MapSession.CLOSED_DOOR)
	_open = _picture(map, Keen5MapSession.OPEN_DOOR)


func test_the_doors_stand_where_the_original_puts_them() -> void:
	var map := _data.maps.load_map(Keen5Episode.WORLD_MAP)
	assert_equal(_picture(map, Keen5MapSession.BOTTOM_DOOR), _open, "the bottom door is open")
	for door in [
		Keen5MapSession.MIDDLE_DOWN_DOOR, Keen5MapSession.MIDDLE_UP_DOOR, Keen5MapSession.TOP_DOOR
	]:
		assert_equal(_picture(map, door), _closed, "%s is closed in the file" % door)
	var misc := _data.tile_info
	assert_equal(misc.misc_kind(_open[2]), Keen5MapKeen.LEFT_ELEVATOR_TILE, "open: misc 33")
	assert_equal(misc.misc_kind(_open[3]), Keen5MapKeen.RIGHT_ELEVATOR_TILE, "and 34")
	# Each elevator's word names the door it goes to: the row below it.
	var rides := {
		BOTTOM_ELEVATOR: Keen5MapSession.MIDDLE_DOWN_DOOR,
		MIDDLE_DOWN: Keen5MapSession.BOTTOM_DOOR,
		MIDDLE_UP: Keen5MapSession.TOP_DOOR,
		TOP_ELEVATOR: Keen5MapSession.MIDDLE_UP_DOOR,
	}
	for from: Vector2i in rides:
		var word := map.tile(GalaxyMap.Layer.INFO, from.x, from.y)
		var target := Keen5MapRide._target_cell(word, 1)
		assert_equal(target - Vector2i(0, 2), rides[from], "the elevator at %s" % from)
	var teleporter := map.tile(GalaxyMap.Layer.INFO, TELEPORTER.x, TELEPORTER.y)
	assert_equal(Keen5MapRide._target_cell(teleporter, 0), TELEPORT_TARGET, "the teleporter")


func test_a_new_game_starts_at_the_bottom() -> void:
	var on_map := _session(Keen5Progress.new())
	assert_equal(on_map.keen.position, START * TILE, "on info 3")
	assert_equal(on_map.keen.sprite, Keen5Sprites.MAP[&"MAP_W_STAND"], "facing west")
	assert_equal(_door(on_map, Keen5MapSession.BOTTOM_DOOR), _open, "the way up is open")
	assert_equal(_door(on_map, Keen5MapSession.MIDDLE_DOWN_DOOR), _closed, "the middle closed")
	assert_true(on_map.flags.is_empty(), "no flags")


func test_the_shafts_by_where_keen_is() -> void:
	var progress := Keen5Progress.new()
	progress.map_position = (MIDDLE_DOWN + Vector2i(0, 1)) * TILE
	var on_map := _session(progress)
	assert_equal(_door(on_map, Keen5MapSession.BOTTOM_DOOR), _closed, "in the middle: closed")
	assert_equal(_door(on_map, Keen5MapSession.MIDDLE_DOWN_DOOR), _open, "the way down open")
	assert_equal(_door(on_map, Keen5MapSession.MIDDLE_UP_DOOR), _closed, "the way up closed")
	for level in [4, 6, 8]:
		progress.mark_done(level)
	progress.mark_done(10, Keen5Progress.DONE_BY_FUSE)
	on_map = _session(progress)
	assert_equal(_door(on_map, Keen5MapSession.MIDDLE_UP_DOOR), _open, "four fuses: open")
	progress.map_position = (TOP_ELEVATOR + Vector2i(0, 1)) * TILE
	on_map = _session(progress)
	assert_equal(_door(on_map, Keen5MapSession.TOP_DOOR), _open, "at the top: open")
	assert_equal(_door(on_map, Keen5MapSession.MIDDLE_UP_DOOR), _closed, "below: closed")


func test_every_elevator_ride() -> void:
	var progress := Keen5Progress.new()
	for level in Keen5Progress.SHAFT_FUSE_LEVELS:
		progress.mark_done(level)
	progress.mark_done(2)
	var rides := [
		[BOTTOM_ELEVATOR, MIDDLE_DOWN + Vector2i(0, 1)],
		[MIDDLE_DOWN, BOTTOM_ELEVATOR + Vector2i(0, 1)],
		[MIDDLE_UP, TOP_ELEVATOR + Vector2i(0, 1)],
		[TOP_ELEVATOR, MIDDLE_UP + Vector2i(0, 1)],
	]
	for ride: Array in rides:
		var from: Vector2i = ride[0]
		progress.map_position = (from + Vector2i(0, 2)) * TILE
		var on_map := _session(progress)
		var keen := on_map.keen as Keen5MapKeen
		var flew := false
		for frame in MOST_FRAMES:
			_hold(on_map, 1, _stick(Vector2i.UP) if frame < WALK_FRAMES else KeenInput.new())
			flew = flew or keen.is_flying()
			if flew and not on_map.rides() and not keen.is_flying():
				break
		assert_true(flew, "from %s he flies" % from)
		assert_equal(keen.position, (ride[1] as Vector2i) * TILE, "from %s to %s" % ride)
		var door: Vector2i = (ride[1] as Vector2i) - Vector2i(0, 2)
		assert_equal(_door(on_map, door), _open, "the door there is open")


func test_the_teleporter_on_korath_iii() -> void:
	var progress := Keen5Progress.new()
	progress.map_position = (TELEPORTER + Vector2i(0, 2)) * TILE
	var on_map := _session(progress)
	var keen := on_map.keen
	for frame in MOST_FRAMES:
		_hold(on_map, 1, _stick(Vector2i.UP) if frame < WALK_FRAMES else KeenInput.new())
		if keen.position.x == TELEPORT_TARGET.x * TILE and not on_map.rides():
			break
	var out := Keen5MapRide.TELEPORT_OUT_SPEED * Keen5MapRide.TELEPORT_OUT_TICS
	assert_equal(keen.position, TELEPORT_TARGET * TILE + Vector2i(0, out), "at the top")
	assert_equal(
		on_map.world.fore_tile(TELEPORTER.x, TELEPORTER.y),
		Keen5MapRide.TELEPORTER_TILE,
		"the teleporter is itself again"
	)


func test_he_steps_out_onto_korath_iii() -> void:
	var progress := Keen5Progress.new()
	progress.map_position = START * TILE
	progress.korath_arrival = true
	var on_map := _session(progress)
	assert_equal(on_map.keen.position, KORATH * TILE, "on info 26")
	assert_equal(on_map.keen.sprite, Keen5Sprites.MAP[&"MAP_W_STAND"], "facing west")
	assert_equal(_door(on_map, Keen5MapSession.TOP_DOOR), _open, "the top door opens")
	assert_equal(_door(on_map, Keen5MapSession.BOTTOM_DOOR), _closed, "the bottom one closes")


func test_done_levels_wave_their_flags_and_open_their_gates() -> void:
	var progress := Keen5Progress.new()
	for level in range(1, LEVELS + 1):
		progress.mark_done(level)
	progress.last_finished = 1
	var on_map := _session(progress)
	assert_equal(on_map.flags.size(), LEVELS, "a flag for each level")
	var holders := _cells_with(0xF000 | 1)
	assert_equal(holders, [LEVEL_1_FLAG], "level 1's holder")
	var expected := LEVEL_1_FLAG * TILE + Keen5Episode.MAP_FLAG_OFFSET
	var found := false
	for flag in on_map.flags:
		found = found or flag.position == expected
		assert_true(not flag.is_thrown(), "waving")
	assert_true(found, "at (-0x50, -0x1E0)")
	for level in GATED_LEVELS:
		for cell in _cells_with(0xD000 | level):
			assert_equal(on_map.world.fore_tile(cell.x, cell.y), 0, "level %d's gate" % level)
	assert_equal(on_map.world.fore_tile(LEVEL_1_GATE.x, LEVEL_1_GATE.y), 0, "level 1's gate")


func test_every_level_is_entered_from_its_entrance() -> void:
	for level in range(1, LEVELS + 1):
		var cells := _cells_with(GalaxyMapKeen.ENTRY_BASE + level)
		assert_true(not cells.is_empty(), "level %d has an entrance" % level)
		var progress := Keen5Progress.new()
		progress.map_position = cells[0] * TILE
		var on_map := _session(progress)
		_hold(on_map, 1, _jump())
		assert_equal(on_map.entered(), level, "level %d" % level)


func test_the_yellow_filler_is_drawn_as_space() -> void:
	var on_map := _session(Keen5Progress.new())
	var filler := 0
	var korath := 0
	for y in on_map.map.height:
		for x in on_map.map.width:
			if on_map.map.tile(GalaxyMap.Layer.BACKGROUND, x, y) == Keen5MapSession.FILLER_TILE:
				if y <= Keen5MapSession.KORATH_ROW:
					filler += 1
				else:
					korath += 1
	assert_equal(filler, 0, "none around the station")
	assert_true(korath > 0, "Korath III's yellow stays")


func _session(progress: Keen5Progress) -> Keen5MapSession:
	var map := _data.maps.load_map(Keen5Episode.WORLD_MAP)
	var on_map := Keen5MapSession.start_map(_data, _rules, map, progress, 0)
	on_map.run_frame(KeenInput.new(), FIRST_FRAME_TICS, FIRST_FRAME_TICS)
	on_map.set_meta(&"tic", FIRST_FRAME_TICS)
	return on_map


static func _hold(on_map: Keen5MapSession, frames: int, held: KeenInput) -> void:
	var tic: int = on_map.get_meta(&"tic", 0)
	for frame in frames:
		tic += FRAME_TICS
		on_map.run_frame(held, FRAME_TICS, tic)
	on_map.set_meta(&"tic", tic)


static func _stick(way: Vector2i) -> KeenInput:
	var input := KeenInput.new()
	input.direction = way.x
	input.vertical = way.y
	return input


static func _jump() -> KeenInput:
	var input := KeenInput.new()
	input.jump = true
	return input


## The four tiles of the door at [param corner] in [param map].
static func _picture(map: GalaxyMap, corner: Vector2i) -> Array[int]:
	var tiles: Array[int] = []
	for y in 2:
		for x in 2:
			tiles.append(map.tile(GalaxyMap.Layer.FOREGROUND, corner.x + x, corner.y + y))
	return tiles


static func _door(on_map: Keen5MapSession, corner: Vector2i) -> Array[int]:
	var tiles: Array[int] = []
	for y in 2:
		for x in 2:
			tiles.append(on_map.world.fore_tile(corner.x + x, corner.y + y))
	return tiles


## The cells of the world map whose info word is [param word].
func _cells_with(word: int) -> Array[Vector2i]:
	var map := _data.maps.load_map(Keen5Episode.WORLD_MAP)
	var cells: Array[Vector2i] = []
	for y in map.height:
		for x in map.width:
			if map.tile(GalaxyMap.Layer.INFO, x, y) == word:
				cells.append(Vector2i(x, y))
	return cells
