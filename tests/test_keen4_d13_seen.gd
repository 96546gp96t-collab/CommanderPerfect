extends "res://tests/test_case.gd"
## Pins the numbers that milestone D13 (part B) measured in the original
## (js-dos, the user's v1.0; docs/keen4/research.md, "Watched in D13:
## estimates"): Keen's idle animations, the pull up a ledge, the gem door,
## the falling platform and how long "Game Over!" stays. Each was an
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
## The timer is the sixth word of an action row (GalaxyAction.table_from).
const TIMER_COLUMN := 5
const Fixtures := preload("res://tests/galaxy_keen_fixtures.gd")
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
