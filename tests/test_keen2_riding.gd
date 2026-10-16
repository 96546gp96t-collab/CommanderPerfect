extends "res://tests/test_case.gd"
## Tests for Keen 2's carriers in small hand-made levels, without Keen 2's
## files (tests/keen2_fixtures.gd): the Scrub crawling along floors, walls
## and ceilings, the moving platform, and Keen standing and riding on both
## ([Keen2Carrier], [Keen2RidingCollision], [Keen2LevelSession]).

const Fixtures := preload("res://tests/keen2_fixtures.gd")
const SETTLE_TICKS := 60
## Long enough for a Scrub to crawl once round a small room or block.
const ROUND_TICKS := 600

## Keen starts on the left, standing on the floor in row 14.
const FIELD := Fixtures.FIELD
## A room in columns 11-16, rows 9-13; a block in columns 22-24, rows 4-6.
const ROOM_AND_BLOCK: PackedStringArray = [
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"......................###.....",
	"......................###.....",
	"......................###.....",
	"..............................",
	"..........########............",
	"..........#......#............",
	"..........#......#............",
	"..........#......#............",
	"..........#......#............",
	"..........#......#............",
	"##############################",
]
## A ledge that is only solid on top, in columns 10-14 of row 10.
const LEDGE: PackedStringArray = [
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
	"..........=====...............",
	"..............................",
	"..............................",
	"..............................",
	"##############################",
]
## A platform lane in row 8 between walls at columns 5 and 20, with an exit
## door where Keen passes when he rides the platform.
const LANE: PackedStringArray = [
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	".....#........E.....#.........",
	".....#........E.....#.........",
	".....#..............#.........",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"##############################",
]
const KEEN_CELL := Vector2i(2, 12)
const FLOOR_ROW := 14
const PLATFORM_CELL := Vector2i(8, 8)
## Keen drops onto the platform from here as it sets off to the right.
const RIDER_CELL := Vector2i(9, 5)


func test_scrub_crawls_round_a_room() -> void:
	var session := _session(ROOM_AND_BLOCK, KEEN_CELL)
	var scrub := _add_scrub(session, Fixtures.on_floor(Keen2Scrub.BODY_BOX, 14, FLOOR_ROW))
	var seen := _watch_scrub(session, scrub)
	var crawls := [
		Keen2Scrub.Crawl.LEFT, Keen2Scrub.Crawl.UP, Keen2Scrub.Crawl.RIGHT, Keen2Scrub.Crawl.DOWN
	]
	assert_equal(seen.crawls.slice(0, 5), crawls + [Keen2Scrub.Crawl.LEFT], "inside corners")
	assert_true(not seen.fell, "never let go")
	assert_true(seen.tops.has(Fixtures.row_top(9)), "upside down along the ceiling")
	var room := Rect2(
		Fixtures.cell_top_left(Vector2i(11, 9)), Vector2(6, 5) * EgaGraphics.TILE_SIZE
	)
	assert_true(room.encloses(seen.inside), "in the room")


func test_scrub_crawls_round_a_block() -> void:
	var session := _session(ROOM_AND_BLOCK, KEEN_CELL)
	session.view_rects = [Rect2(Vector2.ZERO, Vector2(2000, 2000))]
	var scrub := _add_scrub(session, Fixtures.on_floor(Keen2Scrub.BODY_BOX, 23, 4))
	var seen := _watch_scrub(session, scrub)
	var crawls := [
		Keen2Scrub.Crawl.LEFT, Keen2Scrub.Crawl.DOWN, Keen2Scrub.Crawl.RIGHT, Keen2Scrub.Crawl.UP
	]
	assert_equal(seen.crawls.slice(0, 5), crawls + [Keen2Scrub.Crawl.LEFT], "outside corners")
	assert_true(not seen.fell, "never let go")
	var around := Rect2(
		Fixtures.cell_top_left(Vector2i(21, 3)), Vector2(5, 5) * EgaGraphics.TILE_SIZE
	)
	assert_true(around.encloses(seen.inside), "close round the block")


func test_scrub_falls_off_a_thin_ledge() -> void:
	var session := _session(LEDGE, KEEN_CELL)
	var scrub := _add_scrub(session, Fixtures.on_floor(Keen2Scrub.BODY_BOX, 12, 10))
	assert_true(not scrub.is_falling, "on the ledge")
	_run_until(session, func() -> bool: return scrub.is_falling, ROUND_TICKS)
	assert_true(scrub.is_falling, "let go at the end of the ledge")
	_run_until(session, func() -> bool: return not scrub.is_falling, ROUND_TICKS)
	assert_equal(scrub.hitbox().end.y, Fixtures.row_top(FLOOR_ROW), "landed on the floor")
	assert_equal(scrub.crawl, Keen2Scrub.Crawl.LEFT, "crawls left again")


func test_keen_rides_a_scrub() -> void:
	var session := Fixtures.begin_session(FIELD, Vector2i(10, 9))
	session.view_rects = [Rect2(-1000, -1000, 1, 1)]
	var scrub := _add_scrub(session, Fixtures.on_floor(Keen2Scrub.BODY_BOX, 10, FLOOR_ROW))
	scrub.is_active = false
	var keen := session.keen
	_run(session, KeenInput.create(0), SETTLE_TICKS)
	assert_equal(keen.hitbox().end.y, scrub.top(), "landed on it")
	assert_equal(keen.state, KeenBody.State.STANDING, "stands")
	assert_true(session.is_riding(keen), "rides")
	scrub.is_active = true
	var keen_x := keen.position.x
	var scrub_x := scrub.position.x
	_run(session, KeenInput.create(0), 20)
	assert_equal(keen.position.x - keen_x, scrub.position.x - scrub_x, "carried along")
	assert_true(scrub.position.x < scrub_x, "the Scrub crawled")
	assert_true(session.is_riding(keen) and not keen.is_dead, "still riding, harmless")


func test_scrub_pushes_keen() -> void:
	var session := _session(FIELD, KEEN_CELL)
	var scrub := _add_scrub(session, Fixtures.on_floor(Keen2Scrub.BODY_BOX, 8, FLOOR_ROW))
	var keen := session.keen
	var furthest := 0.0
	var overlapped := false
	for tick in 120:
		session.step(KeenInput.create(1))
		furthest = maxf(furthest, keen.hitbox().end.x)
		overlapped = overlapped or keen.hitbox().intersects(scrub.hitbox())
	assert_true(not overlapped, "never walked into it")
	assert_true(keen.hitbox().end.x < furthest, "pushed back")
	assert_true(not keen.is_dead and not session.is_riding(keen), "harmless, not riding")


func test_platform_carries_keen_and_waits_at_a_wall() -> void:
	var session := Fixtures.begin_session(LANE, RIDER_CELL, _platform_info())
	var platform := session.enemies()[0] as Keen2Platform
	var keen := session.keen
	var landed := false
	var flipped_at := -1
	var resumed_at := -1
	for tick in 600:
		var before := keen.position.x
		session.step(KeenInput.create(0))
		if not landed and session.is_riding(keen):
			landed = true
			continue
		if landed:
			assert_equal(keen.position.x - before, platform.last_move.x, "moves with it")
		if flipped_at < 0 and platform.facing < 0:
			flipped_at = tick
		elif flipped_at >= 0 and resumed_at < 0 and platform.last_move.x != 0.0:
			resumed_at = tick
	assert_true(landed, "landed on it")
	assert_equal(resumed_at - flipped_at - 1, Keen2Platform.WAIT_TICKS, "waits 51 ticks")
	assert_true(session.is_riding(keen), "still riding")


func test_platform_is_always_active() -> void:
	var session := _session(FIELD, KEEN_CELL)
	var platform := Keen2Platform.create(Fixtures.cell_top_left(Vector2i(26, 3)))
	session.add_actor(platform)
	var x := platform.position.x
	_run(session, KeenInput.create(0), 10)
	assert_true(not session.is_in_view(platform.hitbox()), "out of view")
	assert_true(platform.position.x != x, "moves all the same")


func test_no_exit_while_riding() -> void:
	var session := Fixtures.begin_session(LANE, RIDER_CELL, _platform_info())
	var keen := session.keen
	var touched_exit := false
	for tick in 600:
		session.step(KeenInput.create(0))
		for cell in LevelCollision.cells_under(keen.hitbox()):
			touched_exit = (
				touched_exit or session.properties.is_exit(session.collision.tile_at(cell))
			)
	assert_true(touched_exit, "rode past the exit")
	assert_true(keen.state != KeenBody.State.EXITING, "did not walk out")
	assert_equal(session.outcome, LevelSession.Outcome.PLAYING, "still playing")


func test_platform_stops_shots() -> void:
	var session := _session(FIELD, KEEN_CELL)
	session.inventory.charges = 1
	var platform := Keen2Platform.create(Fixtures.cell_top_left(Vector2i(8, 13)))
	session.add_actor(platform)
	_run(session, KeenInput.create(0, false, false, true), 1)
	var shot := _keen_shot(session)
	_run(session, KeenInput.create(0), 30)
	assert_true(shot.is_splashing or shot.removed, "stopped")
	assert_true(shot.position.x < platform.hitbox().end.x, "at the platform")
	assert_true(not platform.is_dead, "unharmed")


func test_one_shot_kills_a_scrub() -> void:
	var session := _session(FIELD, KEEN_CELL)
	var sounds: Array[Sound.Id] = []
	session.sound_played.connect(func(sound: Sound.Id) -> void: sounds.append(sound))
	session.inventory.charges = 1
	var scrub := _add_scrub(session, Fixtures.on_floor(Keen2Scrub.BODY_BOX, 8, FLOOR_ROW))
	var y := scrub.position.y
	_run(session, KeenInput.create(0, false, false, true), 1)
	for tick in 60:
		session.step(KeenInput.create(0))
		if scrub.is_dead:
			break
	assert_true(scrub.is_dead, "dead")
	assert_equal(sounds.count(Sound.Id.SHOT_HIT), 2, "SHOTHIT for the hit and the death")
	session.step(KeenInput.create(0))
	assert_true(scrub.position.y < y, "pops up")
	assert_equal(scrub.sprite_index(), Keen2Scrub.SPRITE_SHOT, "frame 110")
	_run(session, KeenInput.create(0), 30)
	assert_equal(scrub.sprite_index(), Keen2Scrub.SPRITE_DEAD, "frame 111")
	var feet_on_top := Rect2(scrub.hitbox().position - Vector2(0, 23), Vector2(8, 23))
	assert_true(not scrub.carries(feet_on_top), "a dead Scrub carries nobody")


## Runs [param scrub] for a while and notes where it went: the crawl
## directions in order, whether it fell, the tops it had, and the area it
## covered.
func _watch_scrub(session: LevelSession, scrub: Keen2Scrub) -> Dictionary:
	var seen := {"crawls": [scrub.crawl], "fell": false, "tops": {}, "inside": scrub.hitbox()}
	var crawling := not scrub.is_falling
	for tick in ROUND_TICKS:
		session.step(KeenInput.create(0))
		if scrub.is_falling:
			seen.fell = seen.fell or crawling
			continue
		crawling = true
		if scrub.crawl != seen.crawls.back():
			seen.crawls.append(scrub.crawl)
		seen.tops[scrub.hitbox().position.y] = true
		seen.inside = seen.inside.merge(scrub.hitbox())
	return seen


func _platform_info() -> Dictionary[Vector2i, int]:
	return {PLATFORM_CELL: Keen2LevelSession.INFO_PLATFORM}


func _add_scrub(session: LevelSession, start: Vector2) -> Keen2Scrub:
	var scrub := Keen2Scrub.create(start)
	session.add_actor(scrub)
	scrub.settle(session)
	scrub.is_active = true
	session.step(KeenInput.create(0))
	return scrub


## A session with Keen standing on the floor at [param keen_cell].
func _session(rows: PackedStringArray, keen_cell: Vector2i) -> Keen2LevelSession:
	var session := Fixtures.begin_session(rows, keen_cell)
	_run(session, KeenInput.create(0), SETTLE_TICKS)
	return session


## The first shot in [param session].
func _keen_shot(session: LevelSession) -> Keen2Shot:
	for actor in session.actors:
		if actor is Keen2Shot:
			return actor
	return null


func _run(session: LevelSession, input: KeenInput, ticks: int) -> void:
	for tick in ticks:
		session.step(input)


## Runs until [param done] returns true, at most [param ticks] ticks.
func _run_until(session: LevelSession, done: Callable, ticks: int) -> void:
	for tick in ticks:
		if done.call():
			return
		session.step(KeenInput.create(0))
