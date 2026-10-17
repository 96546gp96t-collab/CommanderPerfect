extends "res://tests/test_case.gd"
## Tests for two players in Keen 2 (milestone B9) in small hand-made levels:
## the second Keen plays with his own buttons and is a Keen 2 Keen (he can
## be stunned and press switches), and on the world map either player
## steers the one Keen.

const Fixtures := preload("res://tests/keen2_fixtures.gd")
const SETTLE_TICKS := 60
const WALK_TICKS := 30
const MAX_TICKS := 300
const FLOOR_ROW := 14
const PLAYER_1_CELL := Vector2i(2, 12)
const PLAYER_2_CELL := Vector2i(8, 12)
## A lever in column 2; the floor has a gap from column 5 for its bridge.
const LEVER_LEVEL: PackedStringArray = [
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
	"..d...........................",
	"#####----------#####..........",
]
const LEVER_CELL := Vector2i(2, 13)
const BRIDGE_INFO := 0x0103
const FAR_CELL := Vector2i(17, 12)


func test_second_keen_plays_with_his_own_buttons() -> void:
	var session := Fixtures.begin_session(Fixtures.FIELD, PLAYER_1_CELL)
	var partner := session.add_player(Fixtures.cell_top_left(PLAYER_2_CELL))
	assert_true(partner is Keen2Body, "a Keen 2 Keen")
	assert_equal(session.keens.size(), 2, "two Keens")
	_run(session, [KeenInput.new(), KeenInput.new()], SETTLE_TICKS)
	var first := session.keen.position.x
	var second := partner.position.x
	_run(session, [KeenInput.create(0), KeenInput.create(1)], WALK_TICKS)
	assert_equal(session.keen.position.x, first, "player 1 stands still")
	assert_true(partner.position.x > second, "player 2 walks right")


func test_youth_stuns_player_2_only() -> void:
	var session := Fixtures.begin_session(Fixtures.FIELD, PLAYER_1_CELL)
	var partner := session.add_player(Fixtures.cell_top_left(PLAYER_2_CELL)) as Keen2Body
	_run(session, [KeenInput.new(), KeenInput.new()], SETTLE_TICKS)
	var start := Fixtures.on_floor(Keen2Youth.BODY_BOX, PLAYER_2_CELL.x + 3, FLOOR_ROW)
	var youth := Keen2Youth.create(start, -1)
	session.add_actor(youth)
	youth.settle(session)
	youth.is_active = true
	for tick in MAX_TICKS:
		if partner.is_stunned():
			break
		session.step_players([KeenInput.new(), KeenInput.new()])
	assert_true(partner.is_stunned(), "player 2 is stunned")
	assert_true(not (session.keen as Keen2Body).is_stunned(), "player 1 is not")


func test_player_2_presses_a_switch() -> void:
	var infos: Dictionary[Vector2i, int] = {LEVER_CELL: BRIDGE_INFO}
	var session := Fixtures.begin_session(LEVER_LEVEL, FAR_CELL, infos)
	session.add_player(Fixtures.cell_top_left(PLAYER_1_CELL))
	_run(session, [KeenInput.new(), KeenInput.new()], SETTLE_TICKS)
	var pogo := KeenInput.create(0, false, true)
	session.step_players([KeenInput.new(), pogo])
	var lever := LEVER_CELL + Vector2i.ONE * LevelData.BORDER_CELLS
	assert_equal(session.level.tile_at(lever), Fixtures.LEVER_UP, "the lever flips")


func test_either_player_steers_keen_on_the_map() -> void:
	var properties := Fixtures.create_properties()
	var start := Vector2i(PLAYER_1_CELL.x, FLOOR_ROW - 1)
	var infos: Dictionary[Vector2i, int] = {start: LevelData.PLAYER_START_INFO}
	var map := Fixtures.create_level(Fixtures.FIELD, infos)
	var play := Keen2LevelPlay.create(null, properties)
	play.map_session = MapSession.create(map, properties, play.progress)
	play.state = Keen2LevelPlay.State.MAP
	var x := play.map_session.keen.position.x
	for tick in WALK_TICKS:
		play.step_players([KeenInput.new(), KeenInput.new(), KeenInput.create(1)])
	assert_true(play.map_session.keen.position.x > x, "player 2's keys walk him")


func _run(session: LevelSession, inputs: Array[KeenInput], ticks: int) -> void:
	for tick in ticks:
		session.step_players(inputs)
