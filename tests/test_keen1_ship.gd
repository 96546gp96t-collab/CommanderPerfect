extends "res://tests/test_case.gd"
## Plays the two ship levels ([ShipLevels]) with the real tiles of Keen 1:
## Keen stands on the ground, the back of the ship takes him in and the
## hatch out again, he can walk away at both sides, and inside every place
## can be reached. Skipped when the game data is not available.

## Enough ticks to walk across either ship level and into the ship.
const WALK_TICKS := 900
const SETTLE_TICKS := 60
## Holding jump this long gives the highest jump.
const JUMP_TICKS := 30
## A cell right of the ship outside, in the playable area.
const BEYOND_DOOR := Vector2i(30, 7)

var _properties: TileProperties


func run_all() -> void:
	var files := GameFiles.locate()
	if files == null:
		skip("no Keen 1 game data found")
		return
	var graphics := EgaGraphics.load_from(files)
	_properties = TileProperties.load_from(files, graphics.tiles.size())
	super.run_all()


func test_keen_stands_on_the_ground_outside() -> void:
	var session := _session(ShipLevels.OUTSIDE_LEVEL, LevelData.PLAYER_START_INFO)
	assert_equal(session.keen.state, KeenBody.State.STANDING, "on the ground")
	assert_true(not session.keen.is_dead, "alive")


func test_back_of_the_ship_takes_keen_inside() -> void:
	var session := _session(ShipLevels.OUTSIDE_LEVEL, LevelData.PLAYER_START_INFO)
	var exit_x := INF
	for tick in WALK_TICKS:
		session.step(KeenInput.create(1))
		if session.keen.state == KeenBody.State.EXITING:
			exit_x = minf(exit_x, session.keen.position.x)
		if session.outcome != LevelSession.Outcome.PLAYING:
			break
	assert_equal(session.outcome, LevelSession.Outcome.COMPLETED, "walks in as through a door")
	var ship_x := (ShipLevels.OUTSIDE_SHIP.x + LevelData.BORDER_CELLS) * EgaGraphics.TILE_SIZE
	assert_true(exit_x < ship_x + EgaGraphics.TILE_SIZE, "at the back of the ship")


func test_keen_walks_away_at_both_sides() -> void:
	var left := _session(ShipLevels.OUTSIDE_LEVEL, LevelData.PLAYER_START_INFO)
	_run(left, KeenInput.create(-1))
	assert_equal(left.outcome, LevelSession.Outcome.WALKED_AWAY, "at the left")
	var right := _session(ShipLevels.OUTSIDE_LEVEL, LevelData.PLAYER_START_INFO, null, BEYOND_DOOR)
	_run(right, KeenInput.create(1))
	assert_equal(right.outcome, LevelSession.Outcome.WALKED_AWAY, "at the right")


func test_keen_can_jump_over_the_way_in() -> void:
	var session := _session(ShipLevels.OUTSIDE_LEVEL, ShipLevels.DOOR_START_INFO)
	for tick in WALK_TICKS:
		session.step(KeenInput.create(1, tick < JUMP_TICKS))
		if session.outcome != LevelSession.Outcome.PLAYING:
			break
	assert_equal(session.outcome, LevelSession.Outcome.WALKED_AWAY, "past the ship")


func test_hatch_inside_takes_keen_out() -> void:
	var session := _session(ShipLevels.INSIDE_LEVEL, LevelData.PLAYER_START_INFO)
	assert_equal(session.keen.state, KeenBody.State.STANDING, "on the floor of the cabin")
	_run(session, KeenInput.create(-1))
	assert_equal(session.outcome, LevelSession.Outcome.WALKED_AWAY, "out through the hatch")


func test_keen_walks_and_jumps_in_the_cabin() -> void:
	var session := _session(ShipLevels.INSIDE_LEVEL, LevelData.PLAYER_START_INFO)
	var sounds: Array[Sound.Id] = []
	session.sound_played.connect(func(sound: Sound.Id) -> void: sounds.append(sound))
	for tick in SETTLE_TICKS:
		session.step(KeenInput.create(0))
	assert_true(sounds.is_empty(), "standing still is quiet")
	var frames := {}
	for tick in SETTLE_TICKS:
		session.step(KeenInput.create(1))
		frames[session.keen.sprite_index()] = true
	assert_true(frames.size() > 1, "walking is animated")
	assert_true(sounds.has(Sound.Id.KEEN_WALK), "with footsteps")
	var floor_y := session.keen.position.y
	var highest := floor_y
	for tick in JUMP_TICKS:
		session.step(KeenInput.create(0, true))
		highest = minf(highest, session.keen.position.y)
	assert_true(highest < floor_y - EgaGraphics.TILE_SIZE, "he jumps")


func test_cabin_has_a_wall_at_the_nose() -> void:
	var session := _session(ShipLevels.INSIDE_LEVEL, LevelData.PLAYER_START_INFO)
	_run(session, KeenInput.create(1))
	assert_equal(session.outcome, LevelSession.Outcome.PLAYING, "stays inside")
	var nose := (ShipLevels.INSIDE_SIZE.x - 2 + LevelData.BORDER_CELLS) * EgaGraphics.TILE_SIZE
	assert_true(session.keen.hitbox().end.x <= nose, "stopped by the wall")


func test_cabin_roof_stops_a_jump() -> void:
	var session := _session(ShipLevels.INSIDE_LEVEL, LevelData.PLAYER_START_INFO)
	var top := INF
	for tick in JUMP_TICKS * 2:
		session.step(KeenInput.create(0, true))
		top = minf(top, session.keen.hitbox().position.y)
	var roof := (ShipLevels.INSIDE_CEILING_ROWS + LevelData.BORDER_CELLS) * EgaGraphics.TILE_SIZE
	assert_true(top >= roof, "under the roof")


func test_every_place_inside_can_be_reached() -> void:
	var game := GameProgress.new()
	game.inventory.ship_parts.fill(true)
	var session := _session(ShipLevels.INSIDE_LEVEL, LevelData.PLAYER_START_INFO, game)
	var repair := ShipRepair.create(game, session.level)
	assert_equal(repair.places.size(), Inventory.ShipPart.size(), "four places")
	for tick in WALK_TICKS:
		session.step(KeenInput.create(1))
		repair.step(session)
	assert_true(game.all_parts_installed(), "all parts went in")
	assert_equal(game.inventory.score, 0, "and gave no points")


## Ship level [param number] with Keen at the cell with [param start_info],
## or at playable cell [param at] when given.
func _session(
	number: int, start_info: int, game: GameProgress = null, at := Vector2i(-1, -1)
) -> LevelSession:
	var progress := game if game != null else GameProgress.new()
	var level := ShipLevels.build(number, progress.installed_parts)
	var cell := level.find_info(start_info)
	if at.x >= 0:
		cell = at + Vector2i.ONE * LevelData.BORDER_CELLS
	var start := Vector2(cell * EgaGraphics.TILE_SIZE)
	var session := LevelSession.create(level, _properties, progress.inventory, start, number)
	ShipVisit.new().set_up(session, number, progress)
	for tick in SETTLE_TICKS:
		session.step(KeenInput.create(0))
	return session


func _run(session: LevelSession, input: KeenInput) -> void:
	for tick in WALK_TICKS:
		session.step(input)
		if session.outcome != LevelSession.Outcome.PLAYING:
			return
