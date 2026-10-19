extends "res://tests/test_case.gd"
## Tests for two players in Keen 3 on one keyboard (milestone C10), in
## small hand-made levels and maps (tests/keen3_fixtures.gd,
## tests/keen3_map_fixtures.gd, tests/keen3_machine_fixtures.gd): the second
## Keen is a Keen 3 Keen with his own buttons and his own ankh, his halo
## leaves with him, one death ends the attempt and one exit completes the
## level for both, he can shoot the machine; on the world map the keys of
## both steer the one Keen, also onto and off Messie and into a teleporter;
## the HUD and the status screen show each Keen's ankh; the game screen
## hands player 2 to the split screen in a level and lets every key steer
## the one Keen on the map. The split screen itself is Keen 1's
## (tests/test_split_screen.gd).

const Fixtures := preload("res://tests/keen3_fixtures.gd")
const Maps := preload("res://tests/keen3_map_fixtures.gd")
const Machine := preload("res://tests/keen3_machine_fixtures.gd")
const SETTLE_TICKS := 60
const WALK_TICKS := 30
const MAX_TICKS := 400
const NOBODY := 0
const RIGHT := 1
## Player 1 on the left, player 2 further right, both on the floor (row 14).
const FIELD: PackedStringArray = [
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..........A.....X......E......",
	"##############################",
]
const PLAYER_1_CELL := Vector2i(2, 12)
const PLAYER_2_CELL := Vector2i(8, 12)
const ANKH_CELL := Vector2i(10, 13)
const FIRE_CELL := Vector2i(16, 13)
const EXIT_CELL := Vector2i(23, 13)
## The map: Messie's loop and Keen's start, as in tests/test_keen3_messie.gd.
const MAP_SIZE := Vector2i(16, 12)
const LOOP := Rect2i(3, 3, 10, 6)
const MAP_START := Vector2i(8, 6)
const LANDING := Vector2i(5, 2)
const TELEPORT_TICKS := 80


## The split screen without its nodes (they need a running scene): it only
## puts player 2 into the session and reports two views.
class SplitStandIn:
	extends TwoPlayerView
	var started_at := Vector2.INF

	func start(session: LevelSession, at: Vector2, _view_center: Vector2, splits := true) -> void:
		_session = session
		_splits = splits
		started_at = at
		session.add_player(at)

	func stop() -> void:
		if _session != null and _session.keens.size() > 1:
			_session.remove_player(_session.keens[1])
		_session = null

	func view_rects() -> Array[Rect2]:
		return [Rect2(0, 0, 320, 200), Rect2(400, 0, 320, 200)]


func test_second_keen_is_a_keen_3_keen_with_his_own_buttons() -> void:
	var session := Fixtures.start_session(FIELD, PLAYER_1_CELL)
	var partner := session.add_player(Fixtures.cell_top_left(PLAYER_2_CELL))
	assert_true(partner is Keen3Body, "a Keen 3 Keen")
	assert_equal(session.keens.size(), 2, "two Keens")
	_run(session, [KeenInput.new(), KeenInput.new()], SETTLE_TICKS)
	var first := session.keen.position.x
	var second := partner.position.x
	_run(session, [KeenInput.new(), KeenInput.create(-1)], WALK_TICKS)
	assert_equal(session.keen.position.x, first, "player 1 stands still")
	assert_true(partner.position.x < second, "player 2 walks left")


func test_each_keen_has_his_own_ankh() -> void:
	var session := Fixtures.start_session(FIELD, PLAYER_1_CELL)
	var partner := session.add_player(Fixtures.cell_top_left(PLAYER_2_CELL)) as Keen3Body
	_run(session, [KeenInput.new(), KeenInput.create(RIGHT)], WALK_TICKS)
	assert_true(partner.is_protected(), "player 2 took the ankh")
	assert_true(not (session.keen as Keen3Body).is_protected(), "player 1 has none")
	var halo := _halo_of(session, partner)
	assert_true(halo != null, "a halo around player 2")
	assert_true(_halo_of(session, session.keen) == null, "none around player 1")
	var ankh := session.level.tile_at(ANKH_CELL + Vector2i.ONE * LevelData.BORDER_CELLS)
	assert_equal(ankh, Fixtures.ITEM_ROW, "the ankh is taken")


func test_player_2_leaving_takes_his_halo() -> void:
	var session := Fixtures.start_session(FIELD, PLAYER_1_CELL)
	var partner := session.add_player(Fixtures.cell_top_left(PLAYER_2_CELL)) as Keen3Body
	_run(session, [KeenInput.new(), KeenInput.create(RIGHT)], WALK_TICKS)
	var halo := _halo_of(session, partner)
	session.remove_player(partner)
	assert_equal(session.keens.size(), 1, "player 1 alone")
	assert_true(halo.removed, "his halo goes with him")
	session.remove_player(session.keen)
	assert_equal(session.keens.size(), 1, "player 1 stays")


func test_one_death_ends_the_attempt_for_both() -> void:
	var session := Fixtures.start_session(FIELD, PLAYER_1_CELL)
	var partner := session.add_player(Fixtures.cell_top_left(FIRE_CELL - Vector2i(2, 1)))
	_run_until_over(session, [KeenInput.new(), KeenInput.create(RIGHT)])
	assert_true(partner.is_dead, "player 2 ran into the fire")
	assert_true(not session.keen.is_dead, "player 1 lives")
	assert_equal(session.outcome, LevelSession.Outcome.DIED, "the attempt is over")


func test_player_2_at_the_exit_completes_the_level() -> void:
	var session := Fixtures.start_session(FIELD, PLAYER_1_CELL)
	session.add_player(Fixtures.cell_top_left(EXIT_CELL - Vector2i(2, 1)))
	_run_until_over(session, [KeenInput.new(), KeenInput.create(RIGHT)])
	assert_equal(session.outcome, LevelSession.Outcome.COMPLETED, "done for both")


func test_player_2_shoots_a_spark_of_the_machine() -> void:
	var session := Machine.session()
	var flashes := [0]
	session.border_flashed.connect(func() -> void: flashes[0] += 1)
	var spark := _spark_at(session, Vector2i(9, 6))
	var partner := session.add_player(Vector2.ZERO)
	var aim := partner.shot_position() - partner.position
	partner.position = Vector2(3 * EgaGraphics.TILE_SIZE, spark.position.y + 4) - aim
	var fire := KeenInput.create(NOBODY, false, false, true)
	session.step_players([KeenInput.new(), fire])
	_run(session, [KeenInput.new(), KeenInput.new()], WALK_TICKS)
	assert_true(spark.removed, "the spark is gone")
	assert_equal(session.inventory.score, 1000, "+1000 for both")
	assert_equal(flashes[0], 1, "the border flashes")


func test_either_player_steers_keen_on_the_map() -> void:
	var play := _play_on_map({})
	var x := play.map_session.keen.position.x
	for tick in WALK_TICKS:
		play.step_players([KeenInput.new(), KeenInput.new(), KeenInput.create(RIGHT)])
	assert_true(play.map_session.keen.position.x > x, "player 2's keys walk him")
	x = play.map_session.keen.position.x
	for tick in WALK_TICKS:
		play.step_players([KeenInput.new(), KeenInput.create(-1), KeenInput.new()])
	assert_true(play.map_session.keen.position.x < x, "and player 1's")


func test_player_2_keys_take_keen_onto_messie_and_off() -> void:
	var play := _play_on_map({LANDING: Keen3MapInfo.LANDING})
	var map := play.map_session
	map.keen.position = map.messie.position + Vector2(4, 26)
	var up := KeenInput.toward(Vector2i.UP)
	for tick in 3:
		play.step_players([KeenInput.new(), KeenInput.new(), up])
	assert_true(map.is_riding(), "on her back with player 2's keys")
	for tick in MAX_TICKS:
		var cell := Vector2i((map.messie.position / Maps.CELL).floor())
		if cell == Maps.map_cell(LANDING + Vector2i.DOWN):
			break
		play.step_players([KeenInput.new(), KeenInput.new(), KeenInput.new()])
	play.step_players([KeenInput.new(), KeenInput.new(), up])
	assert_true(not map.is_riding(), "off at the landing with player 2's keys")
	assert_true(not map.keen.hidden, "one Keen, visible again")


func test_player_2_keys_use_a_teleporter() -> void:
	var a := Vector2i(1, 9)
	var b := Vector2i(14, 9)
	var play := _play_on_map({a: 0x0F12, b: 0x0F21})
	play.map_session.keen.position = Maps.top_left(a)
	var none: Array[KeenInput] = [KeenInput.new(), KeenInput.new(), KeenInput.new()]
	play.step_players(none)
	var jump := KeenInput.create(NOBODY, true)
	play.step_players([KeenInput.new(), KeenInput.new(), jump])
	assert_true(play.map_session.is_teleporting(), "player 2's button")
	for tick in TELEPORT_TICKS:
		play.step_players(none)
	assert_equal(play.map_session.keen.position, Maps.top_left(b), "the one Keen went")


func test_hud_shows_the_ankh_of_each_keen() -> void:
	var hud := Keen3Hud.new()
	hud.show_ankh_time(true, 7)
	assert_equal(hud.ankh_text(0), "7", "one player: the time alone")
	hud.show_ankh_times(PackedInt32Array([-1, 4]))
	assert_equal(hud.ankh_text(1), "2:4", "player 2's, with his number")
	hud.show_ankh_times(PackedInt32Array([9, 4]))
	assert_equal(hud.ankh_text(0), "1:9", "player 1's, with his number")
	hud.free()


func test_status_screen_shows_the_ankh_of_each_keen() -> void:
	var window := Keen3Window.new()
	Keen3StatusScreen.fill(window, Keen3Inventory.new(), 3, PackedStringArray(), 8)
	var cells := {}
	for item: Dictionary in window._texts:
		cells[item.text] = item.cell
	assert_equal(cells.get("1:3"), Keen3StatusScreen.ANKH_TIME_CELL, "player 1's on row 8")
	assert_equal(cells.get("2:8"), Keen3StatusScreen.ANKH_TIME_CELL + Vector2i.DOWN, "2 under it")
	Keen3StatusScreen.fill(window, Keen3Inventory.new(), 3, PackedStringArray())
	cells.clear()
	for item: Dictionary in window._texts:
		cells[item.text] = item.cell
	assert_equal(cells.get("3"), Keen3StatusScreen.ANKH_TIME_CELL, "alone: as before")
	window.free()


func test_the_screen_hands_player_2_to_the_split_screen() -> void:
	var screen := _coop_screen()
	var split := screen._second_player as SplitStandIn
	screen._mode = GameScreen.Mode.LEVEL
	screen._session = Fixtures.start_session(FIELD, PLAYER_1_CELL)
	screen._toggle_second_player()
	assert_true(split.is_split_screen(), "player 2 on the split screen")
	assert_equal(screen._session.keens.size(), 2, "two Keens in the level")
	assert_equal(split.started_at, screen._session.keen.position, "where player 1 is")
	assert_true(screen._session.keens[1] is Keen3Body, "a Keen 3 Keen")
	assert_equal(screen._inputs().size(), 2, "a set of keys each")
	assert_equal(screen._view_rects(), split.view_rects(), "a view each, for waking enemies")
	screen._toggle_second_player()
	assert_equal(screen._session.keens.size(), 1, "player 2 left")
	assert_true(not split.is_active(), "no split screen")
	_free_screen(screen)


func test_on_the_map_the_screen_lets_every_key_steer_one_keen() -> void:
	var screen := _coop_screen()
	var split := screen._second_player as SplitStandIn
	screen._mode = GameScreen.Mode.MAP
	screen._toggle_second_player()
	assert_true(screen._two_players, "player 2 plays along")
	assert_true(not split.is_active(), "but not on the map")
	assert_equal(screen._inputs().size(), 3, "alone, player 1's and player 2's keys")
	screen._session = Fixtures.start_session(FIELD, PLAYER_1_CELL)
	screen._mode = GameScreen.Mode.LEVEL
	screen._add_second_keen()
	assert_equal(screen._session.keens.size(), 2, "in the next level he is there")
	_free_screen(screen)


## Messie's loop (as in tests/test_keen3_messie.gd), [param infos] and Keen
## inside the loop, played by a [Keen3LevelPlay] on the map.
func _play_on_map(infos: Dictionary) -> Keen3LevelPlay:
	var all := {}
	for x in range(LOOP.position.x, LOOP.end.x):
		all[Vector2i(x, LOOP.position.y)] = Keen3MapInfo.PATH
		all[Vector2i(x, LOOP.end.y - 1)] = Keen3MapInfo.PATH
	for y in range(LOOP.position.y, LOOP.end.y):
		all[Vector2i(LOOP.position.x, y)] = Keen3MapInfo.PATH
		all[Vector2i(LOOP.end.x - 1, y)] = Keen3MapInfo.PATH
	for corner in [LOOP.position, LOOP.end - Vector2i.ONE]:
		all.erase(corner)
	all.erase(Vector2i(LOOP.end.x - 1, LOOP.position.y))
	all.erase(Vector2i(LOOP.position.x, LOOP.end.y - 1))
	all.merge(infos, true)
	var typed: Dictionary[Vector2i, int] = {}
	typed.assign(all)
	var play := Keen3LevelPlay.create(null, Fixtures.level_properties())
	play.map_session = Maps.open_map(Maps.field_rows(MAP_SIZE), typed, MAP_START, play.progress)
	play.state = Keen3LevelPlay.State.MAP
	return play


func _run(session: LevelSession, inputs: Array[KeenInput], ticks: int) -> void:
	for tick in ticks:
		session.step_players(inputs)


func _run_until_over(session: LevelSession, inputs: Array[KeenInput]) -> void:
	for tick in MAX_TICKS:
		if session.outcome != LevelSession.Outcome.PLAYING:
			return
		session.step_players(inputs)


## Keen 3's game screen with what two players need, outside a scene.
static func _coop_screen() -> Keen3OnlineScreen:
	var screen := Keen3OnlineScreen.new()
	screen._second_player = SplitStandIn.new()
	screen._online = OnlinePlay.new()
	screen._camera = LevelCamera.new()
	screen._camera_anchor = Node2D.new()
	return screen


## Frees [param screen] and every node it holds outside a tree.
static func _free_screen(screen: Node) -> void:
	for property in screen.get_property_list():
		var value: Variant = screen.get(property.name)
		if value is Node and value != screen and is_instance_valid(value):
			if value.get_parent() == null:
				value.free()
	screen.free()


static func _halo_of(session: LevelSession, body: KeenBody) -> Keen3AnkhShield:
	for actor in session.actors:
		var shield := actor as Keen3AnkhShield
		if shield != null and shield.keen == body and not shield.removed:
			return shield
	return null


static func _spark_at(session: LevelSession, cell: Vector2i) -> Actor:
	for actor in session.actors:
		if actor is Keen3Spark and actor.position == Vector2(cell * EgaGraphics.TILE_SIZE):
			return actor
	return null
