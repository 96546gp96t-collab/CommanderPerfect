extends "res://tests/test_case.gd"
## Plays Keen 2's levels with stand-in data: the Keen 1 shareware files,
## copied to a folder in the user folder under Keen 2's names (see
## tests/keen2_fixtures.gd). Checks the loading ([Keen2GameData]), the
## course of the game ([Keen2LevelPlay]: the world map, entering a level,
## exit and death back to the map, done levels, game over, all cities saved),
## and Keen 2's enemies spawned from Keen 1's info values (the
## shareware levels have no info 7, so no sparks), played for a while in
## every level with the pogo button pressed now and then (Keen 1's levels
## have no Keen 2 switches), and the Earth exploding on Keen 1's map 81. The
## game screen itself ([Keen2View]) needs a running scene tree, which the
## test runner does not have; it is checked with tools/scripted_play.gd (see
## docs/keen2/gameplay.md). The copy is removed afterwards. Skipped when the
## Keen 1 data is not there.

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
			input.pogo = tick % 40 < 2
			play.session.step(input)
		assert_equal(play.session.outcome, LevelSession.Outcome.PLAYING, "level %d" % number)
		assert_true(not play.session.tantalus_fired, "no Tantalus Ray in level %d" % number)
	var expected: Array[Script] = [
		Keen2Grunt, Keen2Youth, Keen2Elite, Keen2Scrub, Keen2GuardRobot, Keen2Platform
	]
	for kind in expected:
		assert_true(kinds.has(kind), "%s spawns somewhere" % kind.get_global_name())
	assert_equal(kinds.size(), expected.size(), "only Keen 2's enemies")


func test_a_new_game_starts_on_the_map() -> void:
	var play := _play()
	if play == null:
		return
	var started := [0]
	play.map_started.connect(func() -> void: started[0] += 1)
	assert_true(play.start_map(), "map 80 loads")
	assert_equal(started[0], 1, "announced")
	assert_equal(play.state, Keen2LevelPlay.State.MAP, "on the map")
	assert_equal(play.level_number, Keen2Files.WORLD_MAP_LEVEL, "map 80")
	var start := play.level.find_info(LevelData.PLAYER_START_INFO)
	assert_equal(play.map_session.cell_under_keen(), start, "Keen at the start")


func test_an_entrance_on_the_map_starts_its_level() -> void:
	var play := _play()
	if play == null:
		return
	play.start_map()
	_stand_on_entrance(play, 2)
	play.step(KeenInput.create(0, true))
	assert_equal(play.state, Keen2LevelPlay.State.PLAYING, "in a level")
	assert_equal(play.level_number, 2, "level 2")
	assert_true(play.map_session == null, "off the map")


func test_exit_leads_back_to_the_map() -> void:
	var play := _play()
	if play == null:
		return
	play.start_map()
	_stand_on_entrance(play, 3)
	var entrance := play.map_session.keen.position
	play.step(KeenInput.create(0, true))
	var score := play.inventory.score
	play.session.outcome = LevelSession.Outcome.COMPLETED
	play.step(KeenInput.new())
	assert_equal(play.state, Keen2LevelPlay.State.MAP, "on the map")
	assert_true(play.progress.is_completed(3), "level 3 is done")
	assert_equal(play.map_session.keen.position, entrance, "where he went in")
	assert_equal(play.inventory.score, score, "the score stays")
	var cell := play.level.find_info(3)
	assert_true(play.level.tile_at(cell) in [MapSession.DONE_TILE, 78], "a done sign")
	play.step(KeenInput.new())
	play.step(KeenInput.create(0, true))
	assert_equal(play.state, Keen2LevelPlay.State.MAP, "a done level is not entered again")


func test_death_leads_back_to_the_map() -> void:
	var play := _play()
	if play == null:
		return
	var lives_left: Array[int] = []
	play.life_lost.connect(func(lives: int) -> void: lives_left.append(lives))
	play.start(2)
	_die(play)
	assert_equal(lives_left, [Inventory.START_LIVES - 1] as Array[int], "one life less")
	assert_equal(play.state, Keen2LevelPlay.State.MAP, "on the map")
	assert_true(not play.progress.is_completed(2), "not done")


func test_the_last_city_wins_the_game() -> void:
	var play := _play()
	if play == null:
		return
	var won := [0]
	play.won.connect(func() -> void: won[0] += 1)
	for number in Keen2Progress.CITY_LEVELS.slice(1):
		play.progress.complete_level(number)
	play.start(Keen2Progress.CITY_LEVELS[0])
	play.session.outcome = LevelSession.Outcome.COMPLETED
	play.step(KeenInput.new())
	assert_equal(won[0], 1, "won once")
	assert_equal(play.state, Keen2LevelPlay.State.WON, "the ending")
	assert_true(play.progress.all_cities_saved(), "eight cities")


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


func test_the_earth_explodes_on_map_81() -> void:
	if _files == null:
		return
	var space := LevelData.parse(_files.read(_files.level_file(Keen2Files.SPACE_LEVEL)))
	assert_true(space != null, "map 81")
	if space == null:
		return
	var scene := Keen2EarthExplosion.create(space)
	for tick in MAX_DEATH_TICKS:
		if scene.finished:
			break
		scene.step()
	assert_true(scene.finished, "the scene ends")
	var earth := Keen2EarthExplosion.EARTH_CELL
	assert_equal(space.tile_at(earth), Keen2EarthExplosion.WRECKED_EARTH, "the Earth is wrecked")


func _play() -> Keen2LevelPlay:
	if _data == null:
		return null
	return Keen2LevelPlay.create(_files, _data.properties)


## Puts Keen on the map on the entrance of level [param number].
func _stand_on_entrance(play: Keen2LevelPlay, number: int) -> void:
	var cell := play.level.find_info(number)
	var keen := play.map_session.keen
	keen.position = Vector2(cell * EgaGraphics.TILE_SIZE) + Vector2.ONE * 4.0
	play.step(KeenInput.new())


## Kills Keen and runs the ticks until his attempt is over.
func _die(play: Keen2LevelPlay) -> void:
	var session := play.session
	session.keen.kill()
	for tick in MAX_DEATH_TICKS:
		if play.session != session or play.state != Keen2LevelPlay.State.PLAYING:
			return
		play.step(KeenInput.new())
