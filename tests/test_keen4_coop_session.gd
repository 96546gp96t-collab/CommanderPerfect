extends "res://tests/test_case.gd"
## Tests for player 2 in a Keen 4 level session (milestone D12), in
## hand-made mini levels (tests/galaxy_keen_fixtures.gd; nothing from the
## game files): he joins where player 1 is, facing the same way, with the
## shared inventory, god mode and easy jumps and a view of his own that
## follows him; under water he swims; either Keen walking out completes the
## level, either death loses it after the dying Keen's flight left his own
## view, while one Keen dies the other cannot walk out; he can leave again.

const Fixtures := preload("res://tests/galaxy_keen_fixtures.gd")

const TILE := 256
const FRAME_TICS := 2
const MAX_FRAMES := 400
const LONG_ROWS := 90
const FIELD: PackedStringArray = [
	"....................",
	"....................",
	"....................",
	".........K..........",
	"####################",
]
const WATER: PackedStringArray = [
	"....................",
	"....................",
	"....................",
	"....................",
	"....................",
	"....................",
]


func test_player_2_joins_where_player_1_is() -> void:
	var session := _session(FIELD)
	session.keen.direction.x = -1
	session.keen.god_mode = true
	session.keen.easy_jumps = true
	_run(session, 3, KeenInput.new(), KeenInput.new())
	var partner := session.add_player()
	assert_true(partner is GalaxyKeen, "a walking Keen")
	assert_true(session.partner == partner and session.world.partner == partner, "the partner")
	assert_true(session.world.objects[1] == partner, "the second object")
	assert_equal(partner.position, session.keen.position, "on player 1's spot")
	assert_equal(partner.direction.x, -1, "facing the same way")
	assert_true(partner.inventory == session.inventory, "the shared inventory")
	assert_true(partner.god_mode, "god mode goes with him")
	assert_true((partner as GalaxyKeen).easy_jumps, "and the difficulty's jumps")
	assert_true(session.camera_2 != null and session.camera_2 != session.camera, "his own view")
	assert_equal(session.camera_2.scroll, session.camera.scroll, "starting where player 1's is")
	assert_true(session.add_player() == partner, "a second F7 adds nobody")
	assert_equal(session.world.players().size(), 2, "two Keens")


func test_each_view_follows_its_own_keen() -> void:
	var session := _session(_long_rows(4))
	var partner := session.add_player()
	var scroll := session.camera.scroll
	_run(session, 120, KeenInput.new(), KeenInput.create(1))
	assert_true(partner.position.x > session.keen.position.x + 20 * TILE, "player 2 walked far")
	assert_equal(session.camera.scroll.x, scroll.x, "player 1's view stays")
	assert_true(session.camera_2.scroll.x > scroll.x + 10 * TILE, "player 2's follows him")
	assert_true(session.is_playing(), "still playing")


func test_without_player_2_input_he_stands_still() -> void:
	var session := _session(FIELD)
	var partner := session.add_player()
	_run(session, 5, KeenInput.new(), KeenInput.new())
	var x := partner.position.x
	for frame in 30:
		session.run_frame(KeenInput.create(1), FRAME_TICS, session.world.tic + FRAME_TICS)
	assert_equal(partner.position.x, x, "no input given: he stands")
	assert_true(session.keen.position.x > x, "player 1 walked")


func test_player_2_walking_out_completes_the_level() -> void:
	var session := _session(FIELD)
	session.add_player()
	var frames := _run_until_over(session, KeenInput.new(), KeenInput.create(-1))
	assert_true(frames < MAX_FRAMES, "it ends")
	assert_true(session.is_done(), "done for both")
	assert_true(not session.keen.is_dying(), "player 1 stood still")


func test_player_2_dying_loses_the_level_after_his_flight() -> void:
	var rows := _long_rows(4)
	rows[3] = rows[3].substr(0, 70) + "X" + rows[3].substr(71)
	var session := _session(rows)
	var partner := session.add_player()
	session.inventory.gems[0] = 1
	var frames := 0
	while not partner.is_dying() and frames < MAX_FRAMES:
		_run(session, 1, KeenInput.new(), KeenInput.create(1))
		frames += 1
	assert_true(partner.is_dying(), "player 2 runs into the deadly tile")
	assert_true(session.is_playing(), "his flight is still in his view")
	_run_until_over(session, KeenInput.new(), KeenInput.new())
	assert_true(session.is_lost(), "then the attempt is lost for both")
	assert_equal(session.inventory.gems[0], 0, "gems are lost")


func test_player_1_dying_loses_it_too() -> void:
	var rows: PackedStringArray = FIELD.duplicate()
	rows[3] = ".......X.K.........."
	var session := _session(rows)
	session.add_player()
	_run_until_over(session, KeenInput.create(-1), KeenInput.new())
	assert_true(session.is_lost(), "player 1's death ends the attempt")


func test_no_way_out_while_the_other_keen_dies() -> void:
	# Keen 1-3 (docs/two-players.md): while one Keen is dying the other
	# cannot walk out; the attempt is lost.
	var rows: PackedStringArray = FIELD.duplicate()
	rows[3] = "...K.....X.........."
	var session := _session(rows)
	session.keen.position.x = 11 * TILE
	session.keen.reset_box()
	var partner := session.add_player()
	partner.position.x = 3 * TILE
	partner.reset_box()
	var walk_in := 0
	while not session.keen.is_dying() and walk_in < MAX_FRAMES:
		_run(session, 1, KeenInput.create(-1), KeenInput.new())
		walk_in += 1
	assert_true(session.keen.is_dying(), "player 1 dies")
	_run_until_over(session, KeenInput.new(), KeenInput.create(-1))
	assert_true(session.is_lost(), "player 2 walked out meanwhile: still lost")


func test_player_2_leaves_again() -> void:
	var session := _session(FIELD)
	var partner := session.add_player()
	session.remove_player()
	assert_true(session.partner == null and session.camera_2 == null, "gone")
	assert_true(session.world.partner == null, "out of the world")
	assert_true(not session.world.objects.has(partner), "no object")
	_run(session, 10, KeenInput.create(1), KeenInput.new())
	assert_true(session.is_playing(), "player 1 plays on alone")


func test_under_water_player_2_swims() -> void:
	var session := _water_session()
	var partner := session.add_player()
	assert_true(partner is Keen4SwimmingKeen, "a swimmer")
	assert_equal(partner.position, session.swimmer.position, "where player 1 swims")
	var x := partner.position.x
	_run(session, 30, KeenInput.new(), KeenInput.create(1))
	assert_true(partner.position.x > x, "he swims on his own")
	assert_true(session.camera_2 != null, "with his own view")


func _session(rows: PackedStringArray) -> Keen4LevelSession:
	var session := Keen4LevelSession.new()
	session.world = Fixtures.world(rows)
	var map := session.world.map
	# The border's left and right columns open: Keen can leave there.
	for y in map.height - 2:
		for x in [0, 1, map.width - 2, map.width - 1]:
			map.planes[GalaxyMap.Layer.FOREGROUND][y * map.width + x] = Fixtures.EMPTY
	session.map = map
	session.keen = session.world.player() as GalaxyKeen
	session.camera = Fixtures.camera_for(map)
	session.world.camera = session.camera
	session.camera.centre_on(session.keen.position.x, session.keen.box.bottom)
	session.inventory = session.keen.inventory
	return session


func _water_session() -> Keen4LevelSession:
	var session := Keen4LevelSession.new()
	var map := Fixtures.level(WATER)
	var world := GalaxyWorld.create(map, Fixtures.tile_info(), Fixtures.sprite_infos())
	world.camera = Fixtures.camera_for(map)
	session.world = world
	session.map = map
	session.camera = world.camera
	session.swimmer = Keen4SwimmingKeen.spawn(world, Vector2i(6, 4), Keen4Sprites.all())
	session.inventory = Keen4Inventory.new_game()
	session.swimmer.inventory = session.inventory
	return session


## Rows wider than two views, with player 1 at the left on row [param height] − 1.
static func _long_rows(height: int) -> PackedStringArray:
	var rows: PackedStringArray = []
	for y in height:
		rows.append(("...K" if y == height - 1 else "....") + ".".repeat(LONG_ROWS - 4))
	rows.append("#".repeat(LONG_ROWS))
	return rows


static func _run(session: Keen4LevelSession, frames: int, one: KeenInput, two: KeenInput) -> void:
	for frame in frames:
		var tic := session.world.tic + FRAME_TICS
		session.run_frame(one, FRAME_TICS, tic, two)


static func _run_until_over(session: Keen4LevelSession, one: KeenInput, two: KeenInput) -> int:
	for frame in MAX_FRAMES:
		if not session.is_playing():
			return frame
		_run(session, 1, one, two)
	return MAX_FRAMES
