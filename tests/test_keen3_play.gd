extends "res://tests/test_case.gd"
## Plays Keen 3's levels with the player's real files ([Keen3GameData],
## [Keen3LevelPlay]): every level starts, level 1 plays, the course of the
## game (exit and death back to the map, game over, level 16 wins), level 9's start, the two
## exits of levels 12, 13 and 15, what items leave in the real tile table,
## and that the border (tile 245) is never drawn. The game screen itself
## ([Keen3View]) needs a running scene tree, which the test runner does not
## have; it is checked with tools/scripted_play.gd (docs/keen3/gameplay.md).
## Skipped when the Keen 3 files are not there (Keen 3 is not shareware).

const TICKS := 120
const SHORT_WALK_TICKS := 30
## The deadly plant right of Keen's start in level 1.
const PLANT_COLUMN := 12
## More than the dying animation takes, so that a bug cannot hang the tests.
const MAX_DEATH_TICKS := 1000
const BORDER_TILE := 245
const LEVEL_9 := 9
const LEVEL_9_START := Vector2i(63, 17)
const LEVELS_WITH_TWO_EXITS: PackedInt32Array = [12, 13, 15]
## An exit is two cells high: two exit tiles per exit.
const TILES_PER_EXIT := 2
## The rows of item tiles in the tile table (research.md §4).
const FIRST_ITEM_ROW := 143
const LAST_ITEM_ROW := 208
const ITEM_ROW_TILES := 13
const ANKH_LEVELS: PackedInt32Array = [3, 10, 14]

var _files: GameFiles
var _data: Keen3GameData


func run_all() -> void:
	_files = Keen3Files.locate()
	if _files == null:
		skip("no Keen 3 game data found")
		return
	_data = Keen3GameData.load_from(_files)
	super.run_all()


func test_every_level_starts() -> void:
	var play := _play()
	if play == null:
		return
	for number in range(Keen3Files.FIRST_LEVEL, Keen3Files.LAST_LEVEL + 1):
		assert_true(play.start(number), "level %d starts" % number)
		assert_true(play.session.keen is Keen3Body, "Keen 3's Keen in level %d" % number)
		var playable := Rect2(LevelMap.playable_pixels(play.level))
		var box := play.session.keen.hitbox()
		assert_true(playable.encloses(box), "Keen inside level %d" % number)


func test_level_1_plays() -> void:
	var play := _play()
	if play == null:
		return
	assert_true(play.start(Keen3Files.FIRST_LEVEL), "level 1 starts")
	var keen := play.session.keen
	var x := keen.position.x
	for tick in SHORT_WALK_TICKS:
		play.step(KeenInput.create(1))
	assert_true(keen.position.x > x, "Keen walks right")
	assert_true(not keen.is_dead, "alive")
	assert_equal(play.level_number, Keen3Files.FIRST_LEVEL, "still level 1")
	assert_equal(play.inventory.lives, 4, "4 lives")
	assert_equal(play.inventory.charges, 5, "5 charges")
	# The green plant right of the start is deadly (seen in js-dos in C1).
	for tick in TICKS:
		play.step(KeenInput.create(1))
	assert_true(keen.is_dead, "the plant kills him")
	var plant_column := floori(keen.hitbox().end.x / EgaGraphics.TILE_SIZE)
	assert_equal(plant_column, PLANT_COLUMN, "at the plant")


func test_level_9_starts_at_the_later_start() -> void:
	var play := _play()
	if play == null or not play.start(LEVEL_9):
		return
	assert_equal(Keen3LevelPlay.start_cell(play.level), LEVEL_9_START, "(63,17)")
	var start := Vector2(LEVEL_9_START * EgaGraphics.TILE_SIZE)
	assert_true(play.session.keen.position.x == start.x, "Keen there")


func test_two_exits_in_levels_12_13_and_15() -> void:
	for number in range(Keen3Files.FIRST_LEVEL, Keen3Files.LAST_LEVEL + 1):
		var level := LevelData.parse(_files.read(_files.level_file(number)))
		var exits := 0
		for tile in level.tiles:
			if _data.properties.is_exit(tile):
				exits += 1
		var expected := 2 if number in LEVELS_WITH_TWO_EXITS else 1
		if number == Keen3Files.LAST_LEVEL:
			expected = 0
		assert_equal(exits, expected * TILES_PER_EXIT, "exits of level %d" % number)


func test_items_leave_an_empty_tile_of_their_row() -> void:
	var properties := _data.properties
	for row in range(FIRST_ITEM_ROW, LAST_ITEM_ROW + 1, ITEM_ROW_TILES):
		assert_equal(properties.behavior(row), 0, "row %d starts empty" % row)
		for tile in range(row + 1, row + ITEM_ROW_TILES):
			var behavior := properties.behavior(tile)
			assert_true(Keen3LevelSession.is_keen3_item_behavior(behavior), "%d is an item" % tile)
			assert_equal(
				Keen3LevelSession.row_background(tile), row, "tile %d leaves %d" % [tile, row]
			)


func test_ankhs_lie_in_levels_3_10_and_14() -> void:
	for number in ANKH_LEVELS:
		var level := LevelData.parse(_files.read(_files.level_file(number)))
		var found := Array(level.tiles).any(
			func(tile: int) -> bool: return _data.properties.behavior(tile) == Keen3Behavior.ANKH
		)
		assert_true(found, "an ankh in level %d" % number)


func test_ankh_is_reset_in_every_level() -> void:
	var play := _play()
	if play == null:
		return
	play.start(3)
	(play.session.keen as Keen3Body).add_ankh()
	play.start(3)
	assert_equal((play.session.keen as Keen3Body).ankh_ticks, 0, "a new attempt has none")


func test_the_border_is_never_drawn() -> void:
	var textures := GraphicsTextures.create(_data.graphics)
	var map := LevelMap.new()
	map.tile_set = LevelTileSet.build(_data.graphics, textures)
	for number in range(Keen3Files.FIRST_LEVEL, Keen3Files.LAST_LEVEL + 1):
		var level := LevelData.parse(_files.read(_files.level_file(number)))
		map.show_level(level, _data.properties)
		var playable := level.playable_rect()
		var border_tiles := 0
		var drawn_outside := 0
		for y in level.height:
			for x in level.width:
				var cell := Vector2i(x, y)
				if playable.has_point(cell):
					continue
				border_tiles += 1 if level.tile_at(cell) == BORDER_TILE else 0
				if (
					map.get_cell_source_id(cell) != -1
					or map.foreground().get_cell_source_id(cell) != -1
				):
					drawn_outside += 1
		assert_true(border_tiles > 0, "level %d has the border tile" % number)
		assert_equal(drawn_outside, 0, "nothing of the border drawn in level %d" % number)
		for view in [Vector2i(320, 200), Vector2i(426, 200), Vector2i(480, 200)]:
			_check_camera(level, view, number)
	map.free()


func test_exit_leads_to_the_map() -> void:
	var play := _play()
	if play == null:
		return
	play.start(3)
	play.inventory.keycards[0] = true
	play.session.outcome = LevelSession.Outcome.COMPLETED
	play.step(KeenInput.new())
	assert_equal(play.state, Keen3LevelPlay.State.MAP, "on the map")
	assert_equal(play.level_number, Keen3Files.WORLD_MAP_LEVEL, "map 80")
	assert_true(play.progress.is_completed(3), "level 3 is done")
	assert_true(not play.inventory.keycards.has(true), "the keycards are gone")


func test_level_16_done_wins() -> void:
	var play := _play()
	if play == null:
		return
	var done := [false]
	play.won.connect(func() -> void: done[0] = true)
	play.start(Keen3Files.LAST_LEVEL)
	play.session.outcome = LevelSession.Outcome.COMPLETED
	play.step(KeenInput.new())
	assert_true(done[0], "won after level 16")
	assert_equal(play.state, Keen3LevelPlay.State.WON, "nothing more to play")


func test_death_goes_back_to_the_map() -> void:
	var play := _play()
	if play == null:
		return
	var lives_left: Array[int] = []
	play.life_lost.connect(func(lives: int) -> void: lives_left.append(lives))
	play.start(2)
	_die(play)
	assert_equal(lives_left, [3] as Array[int], "one life less")
	assert_equal(play.state, Keen3LevelPlay.State.MAP, "back on the map")
	assert_true(not play.progress.is_completed(2), "level 2 is not done")


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
	assert_equal(play.state, Keen3LevelPlay.State.GAME_OVER, "stopped")


func test_hud_icons() -> void:
	assert_equal(Keen2Icons.raygun(_data.properties), 151, "the raygun of the first row")
	assert_equal(
		Keen2Icons.keycards(_data.properties), PackedInt32Array([152, 153, 154, 155]), "cards"
	)
	assert_equal(Keen2Icons.first_tile_with(_data.properties, Keen3Behavior.ANKH), 149, "ankh")


## The camera's scroll limits for [param view] never show more than the
## playable area, except black bars where the level is smaller than the
## view (nothing is drawn there).
func _check_camera(level: LevelData, view: Vector2i, number: int) -> void:
	var area := LevelMap.playable_pixels(level)
	var limits := LevelCamera.limits_for(area, view)
	for axis in [0, 1]:
		if area.size[axis] >= view[axis]:
			var inside := limits.position[axis] == area.position[axis]
			inside = inside and limits.end[axis] == area.end[axis]
			assert_true(
				inside, "level %d, view %s, axis %d: the playable area" % [number, view, axis]
			)


func _play() -> Keen3LevelPlay:
	if _data == null:
		return null
	return Keen3LevelPlay.create(_files, _data.properties)


## Kills Keen and runs the ticks until his attempt is over.
func _die(play: Keen3LevelPlay) -> void:
	var session := play.session
	session.keen.kill()
	for tick in MAX_DEATH_TICKS:
		if play.session != session or play.state != Keen3LevelPlay.State.PLAYING:
			return
		play.step(KeenInput.new())
