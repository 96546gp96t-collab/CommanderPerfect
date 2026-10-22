extends "res://tests/test_case.gd"
## Checks Keen 5's platforms in hand-made mini levels (milestone E5): the
## info values place each kind (the standing platform's difficulty
## reversed), the red and purple axis platforms turn at B-blocks (the
## purple one looking a column further right going up or down, never
## animating), the GoPlats follow the path arrows at 12 a tic (the purple
## one reading them 0x40 further), a switch turns an arrow round, the sneak
## platform slides away from a jumping Keen and back, and Keen surfs on a
## platform (Omni numbers; docs/keen5/research.md §6, §7).

const Fixtures := preload("res://tests/keen5_machine_fixtures.gd")
const Keen := preload("res://tests/galaxy_keen_fixtures.gd")

const TILE := 256
const B_BLOCK := GalaxyPlatform.TURN_POINT
## A platform's move in one frame (12 a tic, 2 tics).
const FRAME_MOVE := 24
## The path arrows (Omni 0x5B-0x62): up, right, down, left.
const ARROW_UP := 91
const ARROW_RIGHT := 92
const ARROW_DOWN := 93
const ARROW_LEFT := 94
## Open space with Keen on a ledge at the top left.
const SPACE: PackedStringArray = [
	"....................",
	"K...................",
	"##..................",
	"....................",
	"....................",
	"....................",
	"....................",
	"....................",
	"....................",
	"....................",
	"....................",
]
const EASY := GalaxyDifficulty.Level.EASY
const NORMAL := GalaxyDifficulty.Level.NORMAL
const HARD := GalaxyDifficulty.Level.HARD


func test_the_info_values_place_each_kind() -> void:
	var kinds := {
		27: Keen5Platform,
		30: Keen5Platform,
		84: Keen5Platform,
		87: Keen5Platform,
		32: GalaxyFallingPlatform,
		36: Keen5GoPlat,
		39: Keen5GoPlat,
		80: Keen5GoPlat,
		83: Keen5GoPlat,
		40: Keen5StillPlatform,
		35: Keen5StillPlatform,
	}
	for value in kinds:
		var world := Fixtures.world(SPACE, value, [Vector2i(8, 5)])
		var platform := Fixtures.first(world, kinds[value]) as GalaxyPlatform
		assert_true(platform != null, "info %d places a %s" % [value, kinds[value]])
		if platform == null:
			continue
		var corner := Vector2i(10, 7) * TILE
		var purple: bool = value >= Keen5Platforms.PURPLE_GO
		var expected: Vector2i = corner + (Vector2i(0x40, 0x40) if purple else Vector2i.ZERO)
		assert_equal(platform.position, expected, "info %d: its place" % value)
		assert_equal(platform.priority, 0, "info %d: behind everything" % value)
	for value in [27, 84]:
		var world := Fixtures.world(SPACE, value, [Vector2i(8, 5)])
		var platform := Fixtures.first(world, Keen5Platform) as Keen5Platform
		assert_equal(platform.direction, Vector2i.UP, "info %d goes up" % value)
		assert_equal(platform.activity, GalaxyObject.Activity.ALWAYS, "always awake")
	var red := Fixtures.first(Fixtures.world(SPACE, 27, [Vector2i(8, 5)]), Keen5Platform)
	assert_equal(red.sprite, Keen5Sprites.MACHINERY[&"PLATFORM"], "red")
	var purple := Fixtures.first(Fixtures.world(SPACE, 84, [Vector2i(8, 5)]), Keen5Platform)
	assert_equal(purple.sprite, Keen5Sprites.MACHINERY[&"PURPLEPLAT1"], "purple")


func test_the_standing_platform_has_its_difficulty_reversed() -> void:
	var placed := {
		33: [true, false, false],
		34: [true, true, false],
		35: [true, true, true],
	}
	for value in placed:
		for level in [EASY, NORMAL, HARD]:
			var world := Fixtures.world(SPACE, value, [Vector2i(8, 5)], level)
			var platform := Fixtures.first(world, Keen5StillPlatform) as Keen5StillPlatform
			assert_equal(
				platform != null, placed[value][level], "info %d on difficulty %d" % [value, level]
			)
	var world := Fixtures.world(SPACE, 35, [Vector2i(8, 5)])
	var standing := Fixtures.first(world, Keen5StillPlatform) as Keen5StillPlatform
	var at := standing.position
	Fixtures.wait(world, 100)
	assert_equal(standing.position, at, "it never moves")
	assert_equal(standing.activity, GalaxyObject.Activity.ACTIVE, "it sleeps far from the view")


func test_a_red_platform_moves_12_a_tic_and_turns_at_b_blocks() -> void:
	var world := Fixtures.world(SPACE, 28, [Vector2i(4, 5)])
	Keen.put_info(world.map, Vector2i(10, 5), B_BLOCK)
	var platform := Fixtures.first(world, Keen5Platform) as Keen5Platform
	Fixtures.wait(world, 1)
	var x := platform.position.x
	Fixtures.wait(world, 1)
	assert_equal(platform.position.x - x, FRAME_MOVE, "12 a tic, 2 tics a frame")
	var rightmost := 0
	for frame in 80:
		Fixtures.wait(world, 1)
		rightmost = maxi(rightmost, platform.box.right)
	assert_true(rightmost < (10 + 2) * TILE, "it turns before the B-block")
	assert_true(rightmost >= (10 + 2) * TILE - FRAME_MOVE, "within a frame of it")


func test_a_purple_platform_looks_a_column_further_going_up() -> void:
	# Its box starts 12 pixels left of its place, in the column before:
	# the B-block that turns it is in its own column, one right of that.
	var world := Fixtures.world(SPACE, 84, [Vector2i(8, 7)])
	var platform := Fixtures.first(world, Keen5Platform) as Keen5Platform
	assert_equal(platform.box.tile_left, 9, "its box starts in the column before")
	Keen.put_info(world.map, Vector2i(7, 3), B_BLOCK)
	Keen.put_info(world.map, Vector2i(8, 3), B_BLOCK)
	var top := platform.box.top
	for frame in 60:
		Fixtures.wait(world, 1)
		top = mini(top, platform.box.top)
	assert_true(top >= (3 + 3) * TILE, "it turns under the B-block of its own column")
	assert_equal(platform.direction.y, 1, "and comes down")
	var only_left := Fixtures.world(SPACE, 84, [Vector2i(8, 7)])
	Keen.put_info(only_left.map, Vector2i(7, 3), B_BLOCK)
	var going := Fixtures.first(only_left, Keen5Platform) as Keen5Platform
	for frame in 60:
		Fixtures.wait(only_left, 1)
	assert_true(going.box.top < (3 + 2) * TILE, "a B-block in the box's left column is passed")


func test_the_purple_platforms_never_animate() -> void:
	for value in [84, 80]:
		var world := Fixtures.world(SPACE, value, [Vector2i(8, 5)])
		Keen.put_info(world.map, Vector2i(8, 1), B_BLOCK)
		Keen.put_info(world.map, Vector2i(9, 1), B_BLOCK)
		Keen.put_info(world.map, Vector2i(8, 9), B_BLOCK)
		Keen.put_info(world.map, Vector2i(9, 9), B_BLOCK)
		# The GoPlat goes up and down between two arrows.
		_line(world, Vector2i(8, 4), Vector2i.UP, 1, ARROW_DOWN)
		var platform := Fixtures.first(world, GalaxyPlatform) as GalaxyPlatform
		var shown := {}
		for frame in 200:
			Fixtures.wait(world, 1)
			shown[platform.sprite] = true
		assert_equal(
			shown.keys(), [Keen5Sprites.MACHINERY[&"PURPLEPLAT1"]], "info %d: one picture" % value
		)


func test_a_goplat_follows_the_arrows() -> void:
	# A square: right from (4, 5) to (8, 5), down to (8, 8), left to
	# (4, 8), up to (4, 5).
	var world := Fixtures.world(SPACE, 37, [Vector2i(4, 5)])
	_line(world, Vector2i(5, 5), Vector2i.RIGHT, 3, ARROW_RIGHT)
	_line(world, Vector2i(8, 5), Vector2i.DOWN, 3, ARROW_DOWN)
	_line(world, Vector2i(8, 8), Vector2i.LEFT, 4, ARROW_LEFT)
	_line(world, Vector2i(4, 8), Vector2i.UP, 3, ARROW_UP)
	var platform := Fixtures.first(world, Keen5GoPlat) as Keen5GoPlat
	assert_equal(world.info_at(6, 7), ARROW_RIGHT, "its start arrow is in its tile")
	assert_equal(platform.activity, GalaxyObject.Activity.ALWAYS, "always awake")
	assert_equal(platform.clip, GalaxyObject.Clip.NONE, "never clipped")
	var start := platform.position
	Fixtures.wait(world, 1)
	assert_equal(platform.position - start, Vector2i(36, 0), "12 a tic (3 tics first)")
	var lowest := platform.position
	var highest := platform.position
	var last := platform.position
	var even := true
	for frame in 400:
		Fixtures.wait(world, 1)
		var moved := platform.position - last
		last = platform.position
		even = even and absi(moved.x) + absi(moved.y) == FRAME_MOVE
		lowest = lowest.min(platform.position)
		highest = highest.max(platform.position)
	assert_true(even, "24 a frame, round the corners too")
	assert_true(not platform.path.stuck, "it keeps to its path")
	assert_equal(lowest, Vector2i(6, 7) * TILE, "the square's top left")
	var corner := Vector2i(10, 10) * TILE
	assert_true(highest.x <= corner.x and highest.x > corner.x - FRAME_MOVE, "its right side")
	assert_true(highest.y <= corner.y and highest.y > corner.y - FRAME_MOVE, "its bottom")


func test_a_purple_goplat_reads_the_arrows_of_its_tile() -> void:
	var world := Fixtures.world(SPACE, 81, [Vector2i(4, 5)])
	_line(world, Vector2i(5, 5), Vector2i.RIGHT, 2, ARROW_RIGHT)
	_line(world, Vector2i(7, 5), Vector2i.DOWN, 3, ARROW_DOWN)
	_line(world, Vector2i(7, 8), Vector2i.DOWN, 1, ARROW_UP)
	var platform := Fixtures.first(world, Keen5GoPlat) as Keen5GoPlat
	assert_equal(platform.position, Vector2i(6, 7) * TILE + Vector2i(0x40, 0x40), "its place")
	for frame in 120:
		Fixtures.wait(world, 1)
	assert_true(not platform.path.stuck, "it found every arrow")
	assert_equal(platform.position.x, 9 * TILE + 0x40, "down the column of the arrow")


func test_a_switch_turns_an_arrow_round() -> void:
	var rows: PackedStringArray = [
		"....................",
		"....................",
		"..S.................",
		"..K.................",
		"####################",
	]
	var world := Fixtures.world(rows, 0, [])
	var target := Vector2i(15, 2)
	world.set_info(Vector2i(4, 4), (target.x << 8) | target.y)
	var turned := {91: 93, 92: 94, 93: 91, 94: 92, 95: 97, 96: 98, 97: 95, 98: 96}
	for arrow in turned:
		world.set_info(target, arrow)
		_press_switch(world)
		assert_equal(world.info_at(target.x, target.y), turned[arrow], "arrow %d turns" % arrow)
	world.set_info(target, 0)
	_press_switch(world)
	assert_equal(world.info_at(target.x, target.y), B_BLOCK, "elsewhere a B-block comes")
	_press_switch(world)
	assert_equal(world.info_at(target.x, target.y), 0, "and goes")


func test_a_turned_arrow_sends_the_goplat_back() -> void:
	var world := Fixtures.world(SPACE, 37, [Vector2i(4, 5)])
	_line(world, Vector2i(5, 5), Vector2i.RIGHT, 3, ARROW_RIGHT)
	var keen := Fixtures.keen(world)
	Keen.put_info(world.map, Vector2i(7, 5), keen._switched_info(ARROW_RIGHT))
	var platform := Fixtures.first(world, Keen5GoPlat) as Keen5GoPlat
	var rightmost := 0
	var went_left := false
	for frame in 80:
		Fixtures.wait(world, 1)
		rightmost = maxi(rightmost, platform.position.x)
		went_left = went_left or platform.path.arrow == 3
	assert_true(
		rightmost <= 9 * TILE and rightmost > 9 * TILE - FRAME_MOVE,
		"it turned at the switched arrow"
	)
	assert_true(went_left, "and went back")
	assert_true(not platform.path.stuck, "on its arrows")


func test_the_sneak_platform_slides_away_from_a_jump() -> void:
	var rows: PackedStringArray = [
		"....................",
		"....................",
		"....................",
		"K...................",
		"#####...............",
	]
	var world := Fixtures.world(rows, 40, [Vector2i(5, 3)])
	var platform := Fixtures.first(world, Keen5StillPlatform) as Keen5StillPlatform
	var home := platform.position
	Fixtures.wait(world, 30)
	assert_equal(platform.position, home, "it waits")
	assert_equal(platform.activity, GalaxyObject.Activity.ALWAYS, "always awake")
	Keen.run(world, 1, func(_frame: int) -> KeenInput: return Keen.press(0, 0, true))
	Fixtures.wait(world, 1)
	assert_equal(platform.action.name, &"sneak", "a jump at it sends it away")
	assert_equal(platform.direction.x, 1, "the way he faces")
	var x := platform.position.x
	Fixtures.wait(world, 1)
	assert_equal(platform.position.x - x, 64, "32 a tic")
	Fixtures.wait(world, 30)
	assert_equal(platform.action.name, &"back", "after 48 tics it comes back")
	x = platform.position.x
	Fixtures.wait(world, 1)
	assert_equal(platform.position.x - x, -32, "16 a tic")
	Fixtures.wait(world, 60)
	assert_equal(platform.action.name, &"wait", "and waits again")
	assert_equal(platform.position.x, home.x, "where it was")


func test_the_sneak_platform_ignores_a_far_jump() -> void:
	var rows: PackedStringArray = [
		"....................",
		"....................",
		"....................",
		"K...................",
		"#####...............",
	]
	var world := Fixtures.world(rows, 40, [Vector2i(14, 3)])
	var platform := Fixtures.first(world, Keen5StillPlatform) as Keen5StillPlatform
	Keen.run(world, 1, func(_frame: int) -> KeenInput: return Keen.press(0, 0, true))
	Fixtures.wait(world, 1)
	assert_equal(platform.action.name, &"wait", "more than 4 tiles away it waits")


func test_keen_surfs_on_a_platform() -> void:
	var world := Fixtures.world(SPACE, 28, [Vector2i(3, 4)])
	Keen.put_info(world.map, Vector2i(14, 4), B_BLOCK)
	var platform := Fixtures.first(world, Keen5Platform) as Keen5Platform
	var keen := Fixtures.keen(world)
	keen.position = Vector2i(platform.box.left, platform.box.top - 496 - 40)
	keen.reset_box()
	keen.set_action(keen.actions[&"fall_1"])
	for frame in 30:
		Fixtures.wait(world, 1)
		if keen.platform == platform:
			break
	assert_true(keen.platform == platform, "he lands on it")
	Fixtures.wait(world, 3)
	assert_equal(keen.action.name, &"ride_platform", "he surfs")
	assert_equal(keen.sprite, Keen5Sprites.KEEN[&"ON_PLATFORM"], "KEENONPLAT")
	var keen_x := keen.position.x
	var platform_x := platform.position.x
	Fixtures.wait(world, 10)
	assert_true(
		absi((keen.position.x - keen_x) - (platform.position.x - platform_x)) <= 0x1F,
		"he moves with it"
	)
	assert_equal(keen.idle_tics, 0, "riding is never boring")
	Keen.run(world, 1, func(_frame: int) -> KeenInput: return Keen.press(1))
	assert_equal(keen.action.name, &"run_1", "the buttons work as standing")


## Puts [param arrow] in [param count] cells from [param from] (a cell of
## the rows) on, [param step] apart.
func _line(world: GalaxyWorld, from: Vector2i, step: Vector2i, count: int, arrow: int) -> void:
	for index in count:
		Keen.put_info(world.map, from + step * index, arrow)


## Presses up until the switch has been pressed (he walks to it first).
func _press_switch(world: GalaxyWorld) -> void:
	var keen := Fixtures.keen(world)
	var up := func(_frame: int) -> KeenInput: return Keen.press(0, -1)
	for frame in 40:
		Keen.run(world, 1, up)
		if keen.action.name == &"press_switch_2":
			break
	Keen.run(world, 8, Keen.nothing)
