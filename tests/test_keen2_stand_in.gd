extends "res://tests/test_case.gd"
## Plays Keen 2's levels with stand-in data: the Keen 1 shareware files,
## copied to a folder in the user folder under Keen 2's names (see
## tests/keen2_fixtures.gd). Checks the loading ([Keen2GameData]), the
## course of the levels ([Keen2LevelPlay]: exit, death, game over, the last
## level), and Keen 2's enemies spawned from Keen 1's info values, played
## for a while in every level. The game screen itself ([Keen2View]) needs a running scene tree,
## which the test runner does not have; it is checked with
## tools/scripted_play.gd (see docs/keen2/gameplay.md). The copy is removed
## afterwards. Skipped when the Keen 1 data is not there.

const Fixtures := preload("res://tests/keen2_fixtures.gd")
const TEST_DIRECTORY := "user://test_keen2_stand_in"
const TICKS := 120
## More than the dying animation takes, so that a bug cannot hang the tests.
const MAX_DEATH_TICKS := 1000
## How long the enemies of each level are played (with an invincible Keen).
const ENEMY_TICKS := 600

var _files: GameFiles
var _data: Keen2GameData


func run_all() -> void:
	var keen_1 := GameFiles.locate()
	if keen_1 == null:
		skip("no Keen 1 game data found")
		return
	var folder := ProjectSettings.globalize_path(TEST_DIRECTORY)
	Fixtures.remove_folder(folder)
	Fixtures.copy_as_keen_2(keen_1.directory, folder)
	_files = Keen2Files.find_in([folder])
	if _files != null:
		_data = Keen2GameData.load_from(_files)
	super.run_all()
	Fixtures.remove_folder(folder)


func test_the_data_loads() -> void:
	assert_true(_data != null, "graphics, tile properties and sounds")
	if _data == null:
		return
	assert_true(_data.sounds != null, "the sounds of SOUNDS.CK2 as a fallback")
	assert_true(_data.finale != null, "FINALE.CK2")


func test_icons_match_keen_1() -> void:
	if _data == null:
		return
	assert_equal(Keen2Icons.raygun(_data.properties), StatusScreen.RAYGUN_TILE, "raygun")
	assert_equal(Keen2Icons.keycards(_data.properties), StatusScreen.KEYCARD_TILES, "keycards")


func test_level_1_plays() -> void:
	var play := _play()
	if play == null:
		return
	var started: Array[int] = []
	play.level_started.connect(func(number: int) -> void: started.append(number))
	assert_true(play.start(Keen2Files.FIRST_LEVEL), "level 1 starts")
	assert_equal(started, [1] as Array[int], "announced")
	assert_true(not play.session.enemies().is_empty(), "enemies from the info layer")
	var x := play.session.keen.position.x
	for tick in TICKS:
		play.step(KeenInput.create(1))
	assert_true(play.session.keen.position.x > x, "Keen walks right")
	assert_equal(play.level_number, Keen2Files.FIRST_LEVEL, "still level 1")


func test_enemies_spawn_and_play_in_every_level() -> void:
	var play := _play()
	if play == null:
		return
	var kinds := {}
	for number in range(Keen2Files.FIRST_LEVEL, Keen2Files.LAST_LEVEL + 1):
		play.start(number)
		play.session.set_invincible(true)
		play.inventory.charges = ENEMY_TICKS
		for enemy in play.session.enemies():
			kinds[enemy.get_script()] = true
		for tick in ENEMY_TICKS:
			var input := KeenInput.create(1 if (tick / 100) % 2 == 0 else -1, tick % 50 == 0)
			input.fire = tick % 30 == 0
			play.session.step(input)
		assert_equal(play.session.outcome, LevelSession.Outcome.PLAYING, "level %d" % number)
	var expected: Array[Script] = [
		Keen2Grunt, Keen2Youth, Keen2Elite, Keen2Scrub, Keen2GuardRobot, Keen2Platform
	]
	for kind in expected:
		assert_true(kinds.has(kind), "%s spawns somewhere" % kind.get_global_name())
	assert_equal(kinds.size(), expected.size(), "only Keen 2's enemies")


func test_exit_leads_to_the_next_level() -> void:
	var play := _play()
	if play == null:
		return
	play.start(3)
	var score := play.inventory.score
	play.session.outcome = LevelSession.Outcome.COMPLETED
	play.step(KeenInput.new())
	assert_equal(play.level_number, 4, "level 4")
	assert_equal(play.state, Keen2LevelPlay.State.PLAYING, "playing")
	assert_equal(play.inventory.score, score, "the score stays")


func test_last_level_finishes() -> void:
	var play := _play()
	if play == null:
		return
	var done := [false]
	play.finished.connect(func() -> void: done[0] = true)
	play.start(Keen2Files.LAST_LEVEL)
	play.session.outcome = LevelSession.Outcome.COMPLETED
	play.step(KeenInput.new())
	assert_true(done[0], "finished after level 16")
	assert_equal(play.state, Keen2LevelPlay.State.FINISHED, "nothing more to play")


func test_death_restarts_the_level() -> void:
	var play := _play()
	if play == null:
		return
	var lives_left: Array[int] = []
	play.life_lost.connect(func(lives: int) -> void: lives_left.append(lives))
	play.start(2)
	var first_session := play.session
	_die(play)
	assert_equal(lives_left, [Inventory.START_LIVES - 1] as Array[int], "one life less")
	assert_equal(play.level_number, 2, "the same level")
	assert_true(play.session != first_session, "a fresh attempt")


func test_last_life_ends_the_game() -> void:
	var play := _play()
	if play == null:
		return
	var over := [false]
	play.game_over.connect(func() -> void: over[0] = true)
	play.start(1)
	play.inventory.lives = 0
	_die(play)
	assert_true(over[0], "game over")
	assert_equal(play.state, Keen2LevelPlay.State.GAME_OVER, "stopped")


func _play() -> Keen2LevelPlay:
	if _data == null:
		return null
	return Keen2LevelPlay.create(_files, _data.properties)


## Kills Keen and runs the ticks until his attempt is over.
func _die(play: Keen2LevelPlay) -> void:
	var session := play.session
	session.keen.kill()
	for tick in MAX_DEATH_TICKS:
		if play.session != session or play.state != Keen2LevelPlay.State.PLAYING:
			return
		play.step(KeenInput.new())
