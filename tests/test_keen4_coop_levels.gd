extends "res://tests/test_case.gd"
## Tests for two Keens in Keen 4's real levels (milestone D12), with the
## player's files: in every level 1-17 player 2 joins where player 1 is
## (a swimmer in the Well of Wishes), both run around in god mode for a
## while with their own buttons and nothing breaks; the two views follow
## their own Keen; playing alone stays deterministic (the same frames give
## the same level whether or not a partner joined and left before any frame
## ran). Skipped without the files.

const FIRST_LEVEL := 1
const LAST_LEVEL := 17
const WELL := 17
const RUN_FRAMES := 300
const FRAME_TICS := 2
const SEED := 17

var _data: GalaxyData


func _init() -> void:
	var files := Keen4Files.locate()
	if files == null:
		skip("no Keen 4 files in game_data/keen4")
		return
	_data = Keen4Episode.load_data(files)


func test_every_level_plays_with_two_keens() -> void:
	for number in range(FIRST_LEVEL, LAST_LEVEL + 1):
		var session := _level(number)
		var partner := session.add_player()
		var swims := number == WELL
		assert_true(
			(partner is Keen4SwimmingKeen) == swims, "level %d: walking or swimming" % number
		)
		assert_equal(partner.position, session.player.position, "level %d: on his spot" % number)
		session.player.god_mode = true
		partner.god_mode = true
		for frame in RUN_FRAMES:
			var one := KeenInput.create(-1 if frame % 120 < 60 else 1, frame % 50 == 0)
			var two := KeenInput.create(1 if frame % 90 < 45 else -1, frame % 40 == 0)
			two.vertical = -1 if frame % 70 < 10 else 0
			session.run_frame(one, FRAME_TICS, session.world.tic + FRAME_TICS, two)
			if not session.is_playing():
				break
		assert_true(not session.is_lost(), "level %d: nobody died in god mode" % number)
		assert_equal(session.world.players().size(), 2, "level %d: both still there" % number)


func test_the_views_follow_their_own_keen_in_level_1() -> void:
	var session := _level(FIRST_LEVEL)
	var partner := session.add_player()
	session.player.god_mode = true
	partner.god_mode = true
	var scroll := session.camera.scroll
	for frame in 150:
		session.run_frame(
			KeenInput.new(), FRAME_TICS, session.world.tic + FRAME_TICS, KeenInput.create(-1)
		)
	# Level 1 starts at its right end.
	assert_true(partner.position.x < session.player.position.x, "player 2 went left")
	assert_true(session.camera_2.scroll.x < scroll.x, "his view went with him")
	assert_equal(session.camera.scroll.x, scroll.x, "player 1's stayed")


func test_the_well_has_two_swimmers() -> void:
	var session := _level(WELL)
	var partner := session.add_player()
	assert_true(partner is Keen4SwimmingKeen, "player 2 swims")
	assert_true(session.swimmer != partner, "beside player 1")


func test_alone_a_level_runs_as_before() -> void:
	var alone := _level(4)
	var joined := _level(4)
	joined.add_player()
	joined.remove_player()
	for frame in RUN_FRAMES:
		var input := KeenInput.create(1 if frame % 100 < 70 else -1, frame % 30 == 0)
		alone.run_frame(input, FRAME_TICS, alone.world.tic + FRAME_TICS)
		joined.run_frame(input, FRAME_TICS, joined.world.tic + FRAME_TICS)
	assert_equal(joined.player.position, alone.player.position, "Keen on the same spot")
	assert_equal(joined.world.random_index, alone.world.random_index, "the same random numbers")
	assert_equal(joined.world.objects.size(), alone.world.objects.size(), "the same objects")
	assert_equal(joined.inventory.score, alone.inventory.score, "the same score")


func _level(number: int) -> Keen4LevelSession:
	var map := _data.maps.load_map(number)
	return Keen4LevelSession.start(
		_data, map, Keen4Inventory.new_game(), SEED, GalaxyDifficulty.DEFAULT, number
	)
