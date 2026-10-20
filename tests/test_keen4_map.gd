extends "res://tests/test_case.gd"
## Checks Keen 4's world map in hand-made maps (milestone D7): the map Keen
## walking and waving, entering levels, the done levels' marks and flags,
## the water, the Foot's flight and Miragia (Omni numbers and what the
## original showed; docs/keen4/research.md §8).

const MapFixtures := preload("res://tests/keen4_map_fixtures.gd")

const TILE := 256
const FIELD: PackedStringArray = [
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..........M...................",
	"..............................",
	"..............................",
	"..............................",
]
## A map large enough for the flight to the pyramid.
const FLIGHT_ROWS := 58
const FLIGHT_COLUMNS := 40
const WATER_FIELD: PackedStringArray = [
	"..........",
	"....M.....",
	"..........",
	"....n.....",
	"..........",
	"..........",
	"....s.....",
	"..........",
	"..........",
]
## The cell under Keen's place (his box covers it; his own cell holds
## his info value).
const BELOW_KEEN := Vector2i(10, 5)
const LEVEL := 5
## A frame is 2 tics.
const FRAME_STEP := 48
## 360 tics standing before he waves (Omni; seen in the original).
const STILL_FRAMES := 170
const WAVE_FRAMES := 12


func test_he_walks_24_a_tic_on_each_axis() -> void:
	var on_map := MapFixtures.session(FIELD)
	var keen := on_map.keen
	assert_true(keen is Keen4MapKeen, "the map Keen")
	MapFixtures.hold(on_map, 1, MapFixtures.stick(Vector2i.RIGHT))
	var x := keen.position.x
	MapFixtures.hold(on_map, 4, MapFixtures.stick(Vector2i.RIGHT))
	assert_equal(keen.position.x - x, 4 * FRAME_STEP, "48 units a frame of 2 tics (seen: 3 px)")
	var at := keen.position
	MapFixtures.hold(on_map, 4, MapFixtures.stick(Vector2i(1, 1)))
	var moved := keen.position - at
	assert_true(moved.x > 3 * FRAME_STEP and moved.y >= 2 * FRAME_STEP, "diagonally on both axes")
	assert_equal(keen.facing, 3, "facing south-east")


func test_his_walking_pictures_and_waving() -> void:
	var on_map := MapFixtures.session(FIELD)
	var keen := on_map.keen
	var sprites := Keen4Sprites.all()
	assert_equal(keen.sprite, sprites[&"MAP_W_STAND"], "standing, facing west")
	var seen := PackedInt32Array()
	for frame in 8:
		MapFixtures.hold(on_map, 1, MapFixtures.stick(Vector2i.LEFT))
		if seen.is_empty() or seen[-1] != keen.sprite:
			seen.append(keen.sprite)
	var cycle := PackedInt32Array(
		[sprites[&"MAP_W_STAND"], sprites[&"MAP_W_WALK_1"], sprites[&"MAP_W_STAND"]]
	)
	assert_true(_contains_run(seen, cycle), "walking 2, standing, walking 1, standing")
	MapFixtures.hold(on_map, STILL_FRAMES)
	assert_equal(keen.sprite, sprites[&"MAP_W_STAND"], "standing still")
	MapFixtures.hold(on_map, WAVE_FRAMES)
	assert_true(
		keen.sprite in [sprites[&"MAP_WAVE_1"], sprites[&"MAP_WAVE_2"]], "after 360 tics he waves"
	)


func test_he_enters_a_level_only_with_a_button_on_its_entrance() -> void:
	var level := MapFixtures.map(FIELD)
	MapFixtures.Fixtures.put_info(level, BELOW_KEEN, GalaxyMapKeen.ENTRY_BASE + LEVEL)
	var on_map := MapFixtures.session_of(level, Keen4Progress.new())
	MapFixtures.hold(on_map, 3)
	assert_equal(on_map.entered(), 0, "not without a button")
	MapFixtures.hold(on_map, 1, MapFixtures.jump())
	assert_equal(on_map.entered(), LEVEL, "jump on 0xC005 enters level 5")
	assert_equal(on_map.keen.map_position, on_map.keen.position, "where he stood")


func test_other_info_words_and_done_levels_are_no_entrance() -> void:
	for word in [0xC013, 0xD005, 0xF005, LEVEL]:
		var level := MapFixtures.map(FIELD)
		MapFixtures.Fixtures.put_info(level, BELOW_KEEN, word)
		var on_map := MapFixtures.session_of(level, Keen4Progress.new())
		MapFixtures.hold(on_map, 1, MapFixtures.jump())
		assert_equal(on_map.entered(), 0, "0x%04X is no entrance" % word)
	var level := MapFixtures.map(FIELD)
	MapFixtures.Fixtures.put_info(level, BELOW_KEEN, GalaxyMapKeen.ENTRY_BASE + LEVEL)
	var done := Keen4Progress.new()
	done.mark_done(LEVEL)
	var on_map := MapFixtures.session_of(level, done)
	MapFixtures.hold(on_map, 1, MapFixtures.jump())
	assert_equal(on_map.entered(), 0, "a done level cannot be entered again")


func test_done_levels_clear_their_words_fences_and_put_flags() -> void:
	var level := MapFixtures.map(FIELD)
	var fence := Vector2i(3, 1)
	MapFixtures.put_fore(level, fence, MapFixtures.Fixtures.SOLID)
	MapFixtures.Fixtures.put_info(level, fence, 0xD003)
	MapFixtures.Fixtures.put_info(level, Vector2i(5, 1), 0xF003)
	MapFixtures.Fixtures.put_info(level, Vector2i(7, 1), 0xF004)
	MapFixtures.Fixtures.put_info(level, Vector2i(9, 1), 0xF006)
	MapFixtures.Fixtures.put_info(level, Vector2i(11, 1), 0xC003)
	var progress := Keen4Progress.new()
	progress.mark_done(3)
	progress.mark_done(4)
	progress.last_finished = 4
	var on_map := MapFixtures.session_of(level, progress)
	var at := fence + Vector2i(2, 2)
	assert_equal(level.tile(GalaxyMap.Layer.FOREGROUND, at.x, at.y), 0, "0xD0: the fence is gone")
	assert_equal(level.tile(GalaxyMap.Layer.INFO, at.x, at.y), 0, "its word cleared")
	assert_equal(level.tile(GalaxyMap.Layer.INFO, 13, 3), 0, "the entrance of a done level too")
	assert_equal(
		level.tile(GalaxyMap.Layer.INFO, 11, 3), 0xF006, "an undone level keeps its holder"
	)
	assert_equal(on_map.flags.size(), 2, "a flag for each done level")
	var waving := on_map.flags[0]
	assert_true(not waving.is_thrown(), "level 3's flag waves")
	var corner := Vector2i(7 * TILE, 3 * TILE)
	assert_equal(waving.position, corner + Keen4MapSession.FLAG_OFFSET, "at its holder (Omni)")
	assert_true(on_map.flags[1].is_thrown(), "the level just finished: thrown")


func test_a_thrown_flag_flies_an_arc_and_lands_in_its_holder() -> void:
	var from := Vector2i(10 * TILE, 10 * TILE)
	var to := Vector2i(4 * TILE, 2 * TILE)
	var path := GalaxyMapFlag.arc(from, to)
	assert_equal(path.size(), 30, "30 points (Omni)")
	assert_equal(path[0], from, "from where it is thrown")
	assert_equal(path[24].x, to.x, "sideways there in 24 points")
	assert_true(path[12].y < from.y - 10 * 0x30, "up in an arc")
	var level := MapFixtures.map(FIELD)
	MapFixtures.Fixtures.put_info(level, Vector2i(3, 1), 0xF002)
	var progress := Keen4Progress.new()
	progress.mark_done(2)
	progress.last_finished = 2
	var on_map := MapFixtures.session_of(level, progress)
	var flag := on_map.flags[0]
	var start := on_map.keen.position + GalaxyMapFlag.THROW_START
	assert_true(flag.position == start or flag.is_thrown(), "it leaves Keen")
	MapFixtures.hold(on_map, 40)
	assert_true(not flag.is_thrown(), "landed after about 50 tics (Omni)")
	var holder := Vector2i(5 * TILE, 3 * TILE) + Keen4MapSession.THROW_OFFSET
	assert_equal(flag.position, holder + Vector2i(0, GalaxyMapFlag.LANDING_DROP), "in its holder")


func test_water_without_the_wetsuit_pushes_him_back() -> void:
	var on_map := MapFixtures.session(WATER_FIELD)
	var asked := false
	for frame in 30:
		MapFixtures.hold(on_map, 1, MapFixtures.stick(Vector2i.DOWN))
		if on_map.take_conversation() == Keen4MapKeen.CANT_SWIM:
			asked = true
	assert_true(asked, '"I can\'t swim!"')
	var box := on_map.keen.box
	var middle := GalaxyUnits.to_tile(box.top + (box.bottom - box.top) / 2)
	assert_true(middle < 3 + 2, "the middle of his box never stays on the water")
	assert_equal(on_map.keen.action.name, &"walk", "and walks on")


func test_with_the_wetsuit_he_swims_across() -> void:
	var progress := Keen4Progress.new()
	progress.wetsuit = true
	var on_map := MapFixtures.session(WATER_FIELD, progress)
	var swam := false
	var y := on_map.keen.position.y
	for frame in 40:
		MapFixtures.hold(on_map, 1, MapFixtures.stick(Vector2i.DOWN))
		if on_map.keen.action.name == &"swim":
			swam = true
		assert_true(on_map.take_conversation().is_empty(), "no message")
	assert_true(swam, "he swims")
	assert_true(on_map.keen.position.y > y + 4 * TILE, "across the water")
	assert_equal(on_map.keen.action.name, &"walk", "and walks out of it")


func test_swimming_speed_and_the_way_into_the_water() -> void:
	var progress := Keen4Progress.new()
	progress.wetsuit = true
	var on_map := MapFixtures.session(WATER_FIELD, progress)
	var keen := on_map.keen
	var frames := 0
	while keen.action.name != &"swim" and frames < 30:
		MapFixtures.hold(on_map, 1, MapFixtures.stick(Vector2i.DOWN))
		frames += 1
	assert_equal(keen.forced_tics, Keen4MapKeen.WATER_TICS, "18 tics on by himself (Omni)")
	assert_equal(keen.direction, Vector2i(0, 1), "into the water from its north side")
	var y := keen.position.y
	MapFixtures.hold(on_map, 2, KeenInput.new())
	assert_equal(keen.position.y - y, 2 * 2 * 16, "16 units a tic, without the stick")


func test_the_foot_flies_him_to_the_pyramid_or_back() -> void:
	var west := Keen4MapKeen.flight_target(Vector2i(0x1000, 0x2000))
	assert_equal(west, Vector3i(0x1E00, 0x3700, 280), "from the west to the pyramid (Omni)")
	var back := Keen4MapKeen.flight_target(Vector2i(0x3000, 0x2000))
	assert_equal(back, Vector3i(0x1000, 0x2F00, 140), "otherwise back (Omni)")
	var rows := PackedStringArray()
	for y in FLIGHT_ROWS:
		rows.append(".".repeat(FLIGHT_COLUMNS))
	rows[4] = rows[4].substr(0, 10) + "M" + rows[4].substr(11)
	var level := MapFixtures.map(rows)
	var progress := Keen4Progress.new()
	progress.foot_flight = true
	var on_map := MapFixtures.session_of(level, progress)
	var keen := on_map.keen
	assert_true(keen.is_flying(), "he flies")
	assert_equal(keen.priority, Keen4MapKeen.FLYING_PRIORITY, "in front of everything")
	MapFixtures.hold(on_map, 139)
	assert_true(not keen.is_flying(), "280 tics later he stands")
	var target := Vector2i(west.x, west.y)
	# The think runs twice in a frame in which the Foot's picture changes
	# (as the original's action loop does), so he lands a little short.
	assert_true((keen.position - target).length() < 3 * TILE, "near the flight's end")


func test_progress_round_trip() -> void:
	var progress := Keen4Progress.new()
	progress.rescue()
	progress.rescue()
	progress.wetsuit = true
	progress.mark_done(3)
	progress.mark_done(9)
	progress.map_position = Vector2i(0x3500, 0x2200)
	var copy := Keen4Progress.from_dictionary(progress.to_dictionary())
	assert_equal(copy.rescued, 2, "the rescues")
	assert_true(copy.wetsuit, "the wetsuit")
	assert_equal(copy.done_levels(), PackedInt32Array([3, 9]), "the levels done")
	assert_equal(copy.map_position, Vector2i(0x3500, 0x2200), "the place on the map")
	var empty := Keen4Progress.from_dictionary({})
	assert_equal(empty.done_levels().size(), 0, "a new game from nothing")


static func _contains_run(seen: PackedInt32Array, run: PackedInt32Array) -> bool:
	for start in seen.size() - run.size() + 1:
		if seen.slice(start, start + run.size()) == run:
			return true
	return false
