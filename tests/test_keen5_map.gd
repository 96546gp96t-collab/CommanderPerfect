extends "res://tests/test_case.gd"
## Checks Keen 5's world map in hand-made maps (milestone E6;
## [Keen5MapSession], [Keen5MapKeen], [Keen5MapRide]): the done levels'
## waving flags and gates, the teleporter (the walk onto it, the flashing
## tile, the jump, the walk out, objects waking at the target, nothing else
## moving meanwhile), both halves of an elevator (the door closing from the
## template, the unseen flight, the door opening, the walk out), the
## shafts by Keen's row and the fuse levels, and the arrival on Korath III
## (Omni numbers; docs/keen5/research.md §8).

const MapFixtures := preload("res://tests/keen5_map_fixtures.gd")

const TILE := 256
## A field with a teleporter (T) above the map Keen (M).
const TELEPORT_FIELD_WIDTH := 20
const TELEPORT_FIELD_HEIGHT := 40
const TELEPORTER_CELL := Vector2i(7, 5)
const TELEPORT_KEEN := Vector2i(5, 7)
const TELEPORT_TARGET := Vector2i(7, 35)
const FAR_FLAG_HOLDER := Vector2i(10, 37)
const NEAR_FLAG_HOLDER := Vector2i(12, 9)
const FLAG_LEVEL := 5
const NEAR_FLAG_LEVEL := 6
## An elevator (< >) above the map Keen.
const ELEVATOR_WIDTH := 24
const ELEVATOR_HEIGHT := 48
const ELEVATOR_LEFT := Vector2i(10, 6)
const ELEVATOR_TARGET := Vector2i(14, 42)
## A map as large as the Omegamatic for the shafts.
const SHAFT_WIDTH := 30
const SHAFT_HEIGHT := 104
## Frames of 2 tics.
const UP_FRAMES := 40
const MOST_RIDE_FRAMES := 200
const WALK_IN_STEP := 4
const TELEPORT_OUT_STEP := 6
const TELEPORT_OUT_UNITS := 270
const FLIGHT_STEP := 128
const FLIGHT_SIDEWAYS_STEP := 24
const DOOR_FRAMES := 4
const WALK_OUT_UNITS := 256


func test_done_levels_get_waving_flags_and_their_gates_open() -> void:
	var level := MapFixtures.map(_field(TELEPORT_FIELD_WIDTH, TELEPORT_FIELD_HEIGHT, TELEPORT_KEEN))
	var gate := Vector2i(4, 4)
	MapFixtures.set_fore(level, gate, MapFixtures.Fixtures.SOLID)
	MapFixtures.set_info(level, gate, 0xD000 | FLAG_LEVEL)
	MapFixtures.set_info(level, NEAR_FLAG_HOLDER, 0xF000 | FLAG_LEVEL)
	MapFixtures.set_info(level, Vector2i(3, 4), 0xC000 | FLAG_LEVEL)
	var progress := Keen5Progress.new()
	progress.mark_done(FLAG_LEVEL)
	progress.last_finished = FLAG_LEVEL
	var on_map := MapFixtures.session(level, progress)
	assert_true(on_map.keen is Keen5MapKeen, "Keen 5's map Keen")
	assert_equal(on_map.flags.size(), 1, "one flag")
	var flag := on_map.flags[0]
	var expected := NEAR_FLAG_HOLDER * TILE + Keen5Episode.MAP_FLAG_OFFSET
	assert_equal(flag.position, expected, "at (-0x50, -0x1E0) from its holder")
	assert_true(not flag.is_thrown(), "waving, also for the level just finished (no thrown flag)")
	assert_equal(on_map.world.fore_tile(gate.x, gate.y), 0, "the gate is gone")
	assert_equal(on_map.world.info_at(3, 4), 0, "no entrance any more")
	var sprites := Keen5Sprites.all()
	var waving := [sprites[&"FLAG_WAVE_1"], sprites[&"FLAG_WAVE_2"]]
	waving.append_array([sprites[&"FLAG_WAVE_3"], sprites[&"FLAG_WAVE_4"]])
	MapFixtures.hold(on_map, 12)
	assert_true(flag.sprite in waving, "FLAGFLAP1-4")


func test_he_enters_a_level_on_its_entrance() -> void:
	var level := MapFixtures.map(_field(TELEPORT_FIELD_WIDTH, TELEPORT_FIELD_HEIGHT, TELEPORT_KEEN))
	MapFixtures.set_info(level, TELEPORT_KEEN + Vector2i(2, 3), 0xC000 | FLAG_LEVEL)
	var on_map := MapFixtures.session(level)
	MapFixtures.hold(on_map, 1, MapFixtures.jump())
	assert_equal(on_map.entered(), FLAG_LEVEL, "jump on 0xC005 enters level 5")


func test_a_teleporter_takes_him_to_its_target() -> void:
	var on_map := _teleport_map()
	var keen := on_map.keen as Keen5MapKeen
	var flag_near := on_map.flags[0]
	var flag_far := on_map.flags[1]
	assert_equal(flag_far.activity, GalaxyObject.Activity.INACTIVE, "the far flag sleeps")
	_walk_up_until_a_ride(on_map)
	assert_true(on_map.rides(), "the teleporter takes him")
	var bolts: Dictionary[int, bool] = {}
	var flag_timer := flag_near.action_timer
	var last := keen.position
	for frame in MOST_RIDE_FRAMES:
		MapFixtures.hold(on_map, 1)
		if on_map.ride == null or on_map.ride.phase != Keen5MapRide.Phase.WALK_IN:
			break
		var moved := (keen.position - last).abs()
		assert_true(moved.x <= WALK_IN_STEP and moved.y <= WALK_IN_STEP, "2 units a tic")
		last = keen.position
		bolts[on_map.world.fore_tile(TELEPORTER_CELL.x, TELEPORTER_CELL.y)] = true
	assert_equal(
		bolts.keys(),
		[Keen5MapRide.BOLT_TILE, Keen5MapRide.BOLT_TILE + 1],
		"the tile flashes 0xA7F and 0xA80"
	)
	assert_equal(keen.position, TELEPORT_TARGET * TILE, "at the target")
	assert_equal(keen.facing, Keen5MapKeen.SOUTH, "facing south")
	assert_equal(
		on_map.world.fore_tile(TELEPORTER_CELL.x, TELEPORTER_CELL.y),
		Keen5MapRide.TELEPORTER_TILE,
		"the teleporter is itself again (0x427)"
	)
	assert_equal(flag_far.activity, GalaxyObject.Activity.ACTIVE, "objects at the target wake")
	assert_equal(flag_near.action_timer, flag_timer, "nothing else moved meanwhile")
	var start_y := keen.position.y
	MapFixtures.hold(on_map, 1)
	assert_equal(keen.position.y - start_y, TELEPORT_OUT_STEP, "out south, 3 units a tic")
	for frame in MOST_RIDE_FRAMES:
		if not on_map.rides():
			break
		MapFixtures.hold(on_map, 1)
	assert_equal(keen.position.y - start_y, TELEPORT_OUT_UNITS, "for 90 tics")
	assert_equal(
		on_map.world.fore_tile(TELEPORT_TARGET.x, TELEPORT_TARGET.y), 0, "the target is cleared"
	)
	MapFixtures.hold(on_map, 6, MapFixtures.stick(Vector2i.RIGHT))
	assert_true(keen.position.x > TELEPORT_TARGET.x * TILE, "he walks on")


func test_an_elevator_closes_flies_and_opens() -> void:
	var on_map := _elevator_map(Vector2i(0, 0))
	var keen := on_map.keen as Keen5MapKeen
	_walk_up_until_a_ride(on_map)
	assert_equal(keen.ride, Keen5MapKeen.Ride.LEFT_ELEVATOR, "the left half")
	_run_phase(on_map, Keen5MapRide.Phase.WALK_IN)
	assert_equal(keen.position, ELEVATOR_LEFT * TILE, "on the tile")
	var door := ELEVATOR_LEFT - Vector2i(0, 1)
	assert_equal(_door_at(on_map, door), 5, "the door: the open picture first")
	MapFixtures.hold(on_map, DOOR_FRAMES)
	assert_equal(_door_at(on_map, door), 4, "the next one 8 tics later")
	_run_phase(on_map, Keen5MapRide.Phase.DOOR_CLOSING)
	assert_equal(_door_at(on_map, door), 0, "closed")
	assert_true(keen.is_flying(), "he flies")
	assert_equal(keen.sprite, GalaxyObject.NO_SPRITE, "unseen")
	var before := keen.position
	MapFixtures.hold(on_map, 1)
	assert_equal(
		keen.position - before, Vector2i(FLIGHT_SIDEWAYS_STEP, FLIGHT_STEP), "12 and 64 a tic"
	)
	for frame in MOST_RIDE_FRAMES:
		if on_map.rides():
			break
		MapFixtures.hold(on_map, 1)
	assert_equal(on_map.ride.phase, Keen5MapRide.Phase.DOOR_OPENING, "arrived: the door opens")
	var target_door := ELEVATOR_TARGET - Vector2i(0, 2)
	assert_equal(_door_at(on_map, target_door), 0, "from the closed picture")
	assert_equal(
		keen.position, ELEVATOR_TARGET * TILE - Vector2i(0, TILE), "a tile up, in the door"
	)
	assert_equal(keen.sprite, Keen5Sprites.MAP[&"MAP_S_STAND"], "seen again, facing south")
	_run_phase(on_map, Keen5MapRide.Phase.DOOR_OPENING)
	assert_equal(_door_at(on_map, target_door), 5, "open")
	for frame in MOST_RIDE_FRAMES:
		if not on_map.rides():
			break
		MapFixtures.hold(on_map, 1)
	assert_equal(keen.position, ELEVATOR_TARGET * TILE, "he walked out, 32 steps of 8")
	assert_equal(keen.clip, GalaxyObject.Clip.NORMAL, "clipped again")


func test_the_right_half_closes_the_door_to_its_left() -> void:
	var on_map := _elevator_map(Vector2i(1, 0))
	var keen := on_map.keen as Keen5MapKeen
	_walk_up_until_a_ride(on_map)
	assert_equal(keen.ride, Keen5MapKeen.Ride.RIGHT_ELEVATOR, "the right half")
	_run_phase(on_map, Keen5MapRide.Phase.WALK_IN)
	_run_phase(on_map, Keen5MapRide.Phase.DOOR_CLOSING)
	assert_equal(_door_at(on_map, ELEVATOR_LEFT - Vector2i(0, 1)), 0, "the same door closed")


func test_the_shafts_open_by_keens_row() -> void:
	var places := [
		Keen5MapSession.BOTTOM_DOOR,
		Keen5MapSession.MIDDLE_DOWN_DOOR,
		Keen5MapSession.MIDDLE_UP_DOOR,
		Keen5MapSession.TOP_DOOR,
	]
	# -1: as in the map, 0 closed, 5 open; by Keen's row, fuses broken or not.
	var cases := [
		[90, false, [-1, -1, -1, -1]],
		[75, false, [-1, -1, -1, -1]],
		[74, false, [0, 5, -1, -1]],
		[60, true, [0, 5, 5, -1]],
		[40, true, [0, 5, 5, -1]],
		[39, true, [0, 5, -1, -1]],
		[38, true, [0, 5, -1, 5]],
		[101, false, [0, 5, -1, 5]],
		[101, true, [0, 5, 5, 5]],
	]
	for case: Array in cases:
		var row: int = case[0]
		var progress := Keen5Progress.new()
		if case[1]:
			for level in Keen5Progress.SHAFT_FUSE_LEVELS:
				progress.mark_done(level)
		var level := MapFixtures.map(_field(SHAFT_WIDTH, SHAFT_HEIGHT, Vector2i(3, row - 2)))
		var on_map := MapFixtures.session(level, progress)
		var seen := []
		for place: Vector2i in places:
			seen.append(_door_at(on_map, place))
		assert_equal(seen, case[2], "row %d, fuses %s" % [row, case[1]])


func test_three_fuse_levels_do_not_open_the_upper_shaft() -> void:
	var progress := Keen5Progress.new()
	for level in [4, 6, 8]:
		progress.mark_done(level)
	var level := MapFixtures.map(_field(SHAFT_WIDTH, SHAFT_HEIGHT, Vector2i(3, 58)))
	var on_map := MapFixtures.session(level, progress)
	assert_equal(_door_at(on_map, Keen5MapSession.MIDDLE_UP_DOOR), -1, "still closed")
	progress.mark_done(10, Keen5Progress.DONE_BY_FUSE)
	on_map = MapFixtures.session(
		MapFixtures.map(_field(SHAFT_WIDTH, SHAFT_HEIGHT, Vector2i(3, 58))), progress
	)
	assert_equal(_door_at(on_map, Keen5MapSession.MIDDLE_UP_DOOR), 5, "the fourth opens it")


func test_he_steps_out_onto_korath_iii_at_info_26() -> void:
	var korath := Vector2i(15, 30)
	var rows := _field(TELEPORT_FIELD_WIDTH, TELEPORT_FIELD_HEIGHT, TELEPORT_KEEN)
	var level := MapFixtures.map(rows)
	MapFixtures.set_info(level, korath, Keen5MapSession.KORATH_INFO)
	var progress := Keen5Progress.new()
	progress.korath_arrival = true
	var on_map := MapFixtures.session(level, progress)
	assert_equal(on_map.keen.position, korath * TILE, "on info 26, not on info 3")
	assert_equal(on_map.keen.sprite, Keen5Sprites.MAP[&"MAP_W_STAND"], "facing west")
	progress.map_shown()
	assert_true(not progress.korath_arrival, "only once")
	on_map = MapFixtures.session(MapFixtures.map(rows), progress)
	assert_equal(on_map.keen.position, (TELEPORT_KEEN + Vector2i(2, 2)) * TILE, "on info 3 again")


## A field of [param width] × [param height] with the map Keen at
## [param keen] (rows coordinates).
static func _field(width: int, height: int, keen: Vector2i) -> PackedStringArray:
	var rows := PackedStringArray()
	for y in height:
		var row := ".".repeat(width)
		if y == keen.y:
			row = row.substr(0, keen.x) + MapFixtures.MAP_KEEN + row.substr(keen.x + 1)
		rows.append(row)
	return rows


func _teleport_map() -> Keen5MapSession:
	var level := MapFixtures.map(_field(TELEPORT_FIELD_WIDTH, TELEPORT_FIELD_HEIGHT, TELEPORT_KEEN))
	MapFixtures.set_fore(level, TELEPORTER_CELL, MapFixtures.TELEPORTER)
	MapFixtures.set_info(level, TELEPORTER_CELL, MapFixtures.target_word(TELEPORT_TARGET))
	MapFixtures.set_info(level, FAR_FLAG_HOLDER, 0xF000 | FLAG_LEVEL)
	MapFixtures.set_info(level, NEAR_FLAG_HOLDER, 0xF000 | NEAR_FLAG_LEVEL)
	var progress := Keen5Progress.new()
	progress.mark_done(FLAG_LEVEL)
	progress.mark_done(NEAR_FLAG_LEVEL)
	return MapFixtures.session(level, progress)


## An elevator above the map Keen, who walks into the half at
## [param half] (0, 0) left or (1, 0) right.
func _elevator_map(half: Vector2i) -> Keen5MapSession:
	var keen := ELEVATOR_LEFT + half + Vector2i(0, 3) - Vector2i(2, 2)
	var level := MapFixtures.map(_field(ELEVATOR_WIDTH, ELEVATOR_HEIGHT, keen))
	MapFixtures.set_fore(level, ELEVATOR_LEFT, MapFixtures.ELEVATOR_LEFT)
	MapFixtures.set_fore(level, ELEVATOR_LEFT + Vector2i(1, 0), MapFixtures.ELEVATOR_RIGHT)
	var word := MapFixtures.target_word(ELEVATOR_TARGET - Vector2i(0, 1))
	MapFixtures.set_info(level, ELEVATOR_LEFT, word)
	MapFixtures.set_info(level, ELEVATOR_LEFT + Vector2i(1, 0), word)
	return MapFixtures.session(level)


func _walk_up_until_a_ride(on_map: Keen5MapSession) -> void:
	for frame in UP_FRAMES:
		MapFixtures.hold(on_map, 1, MapFixtures.stick(Vector2i.UP))
		if on_map.rides():
			return


## Runs frames while the ride is in [param phase].
func _run_phase(on_map: Keen5MapSession, phase: Keen5MapRide.Phase) -> void:
	for frame in MOST_RIDE_FRAMES:
		if on_map.ride == null or on_map.ride.phase != phase:
			return
		MapFixtures.hold(on_map, 1)


## Which door picture stands at [param corner]: 0-5, or -1 for none.
static func _door_at(on_map: Keen5MapSession, corner: Vector2i) -> int:
	var tile := on_map.world.fore_tile(corner.x, corner.y)
	for picture in MapFixtures.DOOR_PICTURES:
		if tile == MapFixtures.door_tile(picture, Vector2i.ZERO):
			return picture
	return -1
