extends "res://tests/test_case.gd"
## Pins the numbers that milestone D13 (part B) measured in the original
## (js-dos, the user's v1.0; docs/keen4/research.md, "Watched in D13:
## estimates"): Keen's idle animations, the pull up a ledge, the gem door,
## the falling platform, how long "Game Over!" stays, the turn of a
## platform or mine sideways, the creatures under water, the slug, the
## Wormmouth, the cloud, the inchworms, the dart guns, the fireball and
## the wetsuit's box. Each was an
## Omnispeak number or an estimate before; a change here must come from a
## new measurement.

## Seen: bored after 300 tics of looking up, the book 700 tics after the
## boredom began (the boredom's own 360 tics count), look up after 200.
const IDLE_LOOK := 200
const IDLE_BORED := 300
const IDLE_READ := 700
## Seen: the pictures of the boredom (90, 10, 90, 10, 90, 70 tics), the
## book (four of 16), reading (300, 16, 16) and stowing it (three of 12).
const BORED_TICS := [90, 10, 90, 10, 90, 70]
const OPEN_BOOK_TICS := [16, 16, 16, 16]
const READ_TICS := [300, 16, 16]
const STOW_BOOK_TICS := [12, 12, 12]
## Seen: four climbing pictures of 10 tics each (40 tics in all), and
## facing either way Keen ends one step (128 units) from the ledge's edge
## sideways from where he hung (Omnispeak: two steps facing right).
const PULL_TICS := [10, 10, 10, 10]
const PULL_SIDEWAYS := 128
const TILE := 256
## The ledge's top row in the fixture's map (it adds a border).
const LEDGE_TOP := 4
## The ledge test's frames: falling to the ledge, hanging, then the pull.
const FALL_FRAMES := 60
const HELD_FRAMES := 20
const PULL_FRAMES := 40
const HANG_FRAMES := 10
## Seen: the door's tiles move on three times, 10 tics apart, the first
## when Keen stands again 28 tics after he began walking to the holder.
const DOOR_STEP_TICS := 10
## Seen: the platform's track after Keen lands (the original's frames,
## +8 / +18 / +26 / +30 / +34 tics: 8, 15, 30, 41, 48 pixels down) is
## 16 a tic for half a tile, then gravity high; it rises 32 a tic.
const SINK_SPEED := 16
const SINK_DEPTH := 0x80
const RISE_SPEED := -32
## Seen: "Game Over!" was up 4,758 ms.
const GAME_OVER_TICS := 333
## Seen: a mine (and so a platform: the same move) turning sideways goes
## back by what it would have gone past the turn point's edge.
const BOUNCE := 2
const FRAME_MOVE := 24
const TILE_MASK := 0xFF
## Seen (level 17): the Dopefish's three burp pictures of 60 tics and the
## level lost 180 tics after Keen is swallowed; a sprite aims 40 tics,
## shoots 40 + 30, its shot flies 64 a tic; a mine explodes in two
## pictures of 30 tics.
const DOPEFISH_BURP_TICS := [60, 60, 60]
const SWALLOWED_TICS := 180
const SPRITE_TICS := [40, 40, 30]
const SPRITE_SHOT_SPEED := 64
const MINE_BOOM_TICS := [30, 30]
## Seen: the slug crawls 64 every 8 tics, squirts 60 tics, the slime kills
## 300 tics and fades 60; the Wormmouth peeks 20, 8, 20, 8, 20, 8, 20, 8.
const SLUG_CRAWL := [8, 64]
const SLUG_SQUIRT_TICS := 60
const SLIME_TICS := [300, 60]
const PEEK_TICS := [20, 8, 20, 8, 20, 8, 20, 8]
## Seen: the cloud flashes eight times 10 tics and once 48; its bolt is
## lethal 48 tics (six pictures of 8).
const STRIKE_TICS := [10, 10, 10, 10, 10, 10, 10, 10, 48]
const BOLT_TICS := [8, 8, 8, 8, 8, 8]
## Seen: an inchworm moves 128 every 30 tics; the dart guns all fire every
## 150 tics, the darts 64 a tic; the Berkeloid throws in 36 + 36 tics and
## the fireball burns 6, then 8 × 12 tics.
const INCH_STEP := [30, 128]
const DART_GUN_TICS := 150
const DART_SPEED := 64
const THROW_HALF_TICS := 36
const BURN_TICS := [6, 12, 12, 12, 12, 12, 12, 12, 12]
## Seen: the wetsuit's box comes after the game stood still for its sound.
const WETSUIT_SOUND_TICS := 73
## The velocity is the seventh and eighth word of an action row.
const VELOCITY_COLUMN := 6
## The timer is the sixth word of an action row (GalaxyAction.table_from).
const TIMER_COLUMN := 5
const Fixtures := preload("res://tests/galaxy_keen_fixtures.gd")
const Creatures := preload("res://tests/keen4_creature_fixtures.gd")
## Open space for a platform (info 28 goes right).
const RIGHT_PLATFORM := 28
const SPACE: PackedStringArray = [
	"....................",
	"K...................",
	"##..................",
	"....................",
	"....................",
	"....................",
	"....................",
	"....................",
]
## A wall whose top is a ledge, Keen beside it (left or right of it).
const LEDGE_ON_THE_LEFT: PackedStringArray = [
	"............",
	"............",
	"######......",
	"######......",
	"######......",
	"######......",
	"######.K....",
	"############",
]
const LEDGE_ON_THE_RIGHT: PackedStringArray = [
	"............",
	"............",
	"......######",
	"......######",
	"......######",
	"......######",
	"....K.######",
	"############",
]


func test_idle_waits() -> void:
	assert_equal(GalaxyKeen.IDLE_LOOK_TICS, IDLE_LOOK, "looking up")
	assert_equal(GalaxyKeen.IDLE_BORED_TICS, IDLE_BORED, "bored")
	assert_equal(GalaxyKeen.IDLE_READ_TICS, IDLE_READ, "the book")


func test_idle_pictures() -> void:
	assert_equal(_timers(GalaxyKeenActions.ROWS, "bored_", 6), BORED_TICS, "bored")
	assert_equal(_timers(GalaxyKeenActions.ROWS, "open_book_", 4), OPEN_BOOK_TICS, "the book")
	assert_equal(_timers(GalaxyKeenActions.ROWS, "read_", 3), READ_TICS, "reading")
	assert_equal(_timers(GalaxyKeenActions.ROWS, "stow_book_", 3), STOW_BOOK_TICS, "stowing")


func test_pulling_up() -> void:
	assert_equal(_timers(GalaxyKeenActions.ROWS, "pull_", 4), PULL_TICS, "the pull")


func test_pulling_up_ends_one_step_from_the_edge() -> void:
	for side: int in [-1, 1]:
		var world := Fixtures.world(LEDGE_ON_THE_LEFT if side == -1 else LEDGE_ON_THE_RIGHT)
		var keen := world.player() as GalaxyKeen
		var hung_at := 0
		for frame in FALL_FRAMES:
			Fixtures.run(
				world,
				1,
				func(_f: int) -> KeenInput: return Fixtures.press(side, 0, frame < HELD_FRAMES)
			)
			if keen.action.name.begins_with("hang"):
				hung_at = keen.position.x
				break
		assert_true(hung_at != 0, "he hangs (side %d)" % side)
		Fixtures.run(world, HANG_FRAMES, Fixtures.nothing)
		Fixtures.run(world, 1, func(_frame: int) -> KeenInput: return Fixtures.press(0, -1))
		Fixtures.run(world, PULL_FRAMES, Fixtures.nothing)
		assert_equal(keen.action.name, &"stand", "on the ledge (side %d)" % side)
		assert_equal(
			keen.position.x - hung_at, side * PULL_SIDEWAYS, "one step on (side %d)" % side
		)
		assert_equal(keen.box.bottom, LEDGE_TOP * TILE - 1, "on the wall's top (side %d)" % side)


func test_gem_door() -> void:
	assert_equal(
		_timers(GalaxyGemDoor.ROWS, "open_", 3),
		[DOOR_STEP_TICS, DOOR_STEP_TICS, DOOR_STEP_TICS],
		"three steps"
	)


func test_falling_platform() -> void:
	assert_equal(GalaxyFallingPlatform.SINK_SPEED, SINK_SPEED, "sinking")
	assert_equal(GalaxyFallingPlatform.SINK_DEPTH, SINK_DEPTH, "how far it sinks")
	var rise := _row(GalaxyFallingPlatform.ROWS, "rise").split(" ")
	assert_equal(int(rise[rise.size() - 5]), RISE_SPEED, "rising")


func test_game_over() -> void:
	assert_equal(Keen4View.GAME_OVER_TICS, GAME_OVER_TICS, "the box's time")


func test_a_platform_bounces_off_a_turn_point() -> void:
	var world := Creatures.world(SPACE, RIGHT_PLATFORM, [Vector2i(4, 5)])
	Fixtures.put_info(world.map, Vector2i(9, 5), GalaxyPlatform.TURN_POINT)
	var platform := Creatures.first(world, Keen4Platform) as Keen4Platform
	var before := platform.box.right
	for frame in 60:
		before = platform.box.right
		Creatures.wait(world, 1)
		if platform.direction.x == -1:
			break
	assert_equal(platform.direction.x, -1, "it turned")
	var reach := before + FRAME_MOVE
	var past := reach & TILE_MASK
	assert_true(past > 0, "the move would go past the edge")
	assert_equal(platform.box.right, reach - BOUNCE * past, "back by what went past")
	assert_equal(GalaxyPlatform.BOUNCE, BOUNCE, "the rule's constant")


func test_under_water() -> void:
	assert_equal(_timers(Keen4Dopefish.DOPEFISH_ROWS, "burp_", 3), DOPEFISH_BURP_TICS, "burps")
	var eaten := _row(Keen4SwimmingKeen.ROWS, "eaten_2").split(" ")
	assert_equal(int(eaten[TIMER_COLUMN]), SWALLOWED_TICS, "lost after being swallowed")
	var sprite := [
		int(_row(Keen4WaterSprite.ROWS, "aim").split(" ")[TIMER_COLUMN]),
		int(_row(Keen4WaterSprite.ROWS, "shoot_1").split(" ")[TIMER_COLUMN]),
		int(_row(Keen4WaterSprite.ROWS, "shoot_2").split(" ")[TIMER_COLUMN]),
	]
	assert_equal(sprite, SPRITE_TICS, "the sprite aims and shoots")
	var shot := _row(Keen4WaterSprite.SHOT_ROWS, "fly_1").split(" ")
	assert_equal(int(shot[VELOCITY_COLUMN]), SPRITE_SHOT_SPEED, "its shot")
	assert_equal(_timers(Keen4Mine.ROWS, "explode_", 2), MINE_BOOM_TICS, "a mine explodes")


func test_land_creatures() -> void:
	var crawl := _row(Keen4Slug.ROWS, "crawl_1").split(" ")
	assert_equal([int(crawl[TIMER_COLUMN]), int(crawl[VELOCITY_COLUMN])], SLUG_CRAWL, "slug")
	var squirt := _row(Keen4Slug.ROWS, "sliming").split(" ")
	assert_equal(int(squirt[TIMER_COLUMN]), SLUG_SQUIRT_TICS, "the squirt")
	assert_equal(_timers(Keen4Slug.ROWS, "slime_", 2), SLIME_TICS, "the slime")
	assert_equal(_timers(Keen4Wormmouth.ROWS, "peek_", 8), PEEK_TICS, "the Wormmouth peeks")
	assert_equal(_timers(Keen4Cloud.ROWS, "strike_", 9), STRIKE_TICS, "the cloud strikes")
	assert_equal(_timers(Keen4Cloud.ROWS, "bolt_", 6), BOLT_TICS, "its bolt")
	var creep := _row(Keen4Inchworm.ROWS, "creep_1").split(" ")
	assert_equal([int(creep[TIMER_COLUMN]), int(creep[VELOCITY_COLUMN])], INCH_STEP, "inchworm")
	var gun := _row(Keen4DartGun.ROWS, "gun").split(" ")
	assert_equal(int(gun[TIMER_COLUMN]), DART_GUN_TICS, "the dart guns")
	var dart := _row(Keen4DartGun.DART_ROWS, "side_1").split(" ")
	assert_equal(int(dart[VELOCITY_COLUMN]), DART_SPEED, "a dart")
	var throw := 0
	for n in range(1, 7):
		throw += int(_row(Keen4Berkeloid.ROWS, "throw_%d" % n).split(" ")[TIMER_COLUMN])
	assert_equal(throw, THROW_HALF_TICS, "the Berkeloid's throw")
	assert_equal(_timers(Keen4Berkeloid.ROWS, "burn_", 9), BURN_TICS, "the fireball burns")


func test_the_wetsuit_box_waits_for_the_sound() -> void:
	assert_equal(Keen4View.WETSUIT_SOUND_TICS, WETSUIT_SOUND_TICS, "the wait")


## The timers of the actions [param prefix]1 … [param prefix][param count].
static func _timers(rows: PackedStringArray, prefix: String, count: int) -> Array:
	var timers := []
	for n in range(1, count + 1):
		timers.append(int(_row(rows, "%s%d" % [prefix, n]).split(" ")[TIMER_COLUMN]))
	return timers


static func _row(rows: PackedStringArray, name: String) -> String:
	for row in rows:
		if row.begins_with(name + " "):
			return row
	return ""
