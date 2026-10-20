extends "res://tests/test_case.gd"
## Checks Keen 4's moving things in hand-made mini levels (milestone D6):
## platforms in four directions turning at turn points (info 31) and the
## vertical one held between two, Keen riding them and falling onto one
## from a pole, the falling platform, switches that turn a turn point on
## and off, bridges, and the mines (Omni numbers; docs/keen4/research.md
## §6, §7, §9).

const Fixtures := preload("res://tests/galaxy_keen_fixtures.gd")
const Creatures := preload("res://tests/keen4_creature_fixtures.gd")

const TILE := 256
const TURN := GalaxyPlatform.TURN_POINT
## Info values (Omni): platforms up, right, down, left; the falling one.
const UP := 27
const RIGHT := 28
const DOWN := 29
const FALLING := 32
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


func test_the_info_values_place_platforms() -> void:
	for value in [UP, RIGHT, DOWN, 30]:
		var world := Creatures.world(SPACE, value, [Vector2i(8, 5)])
		var platform := Creatures.first(world, Keen4Platform) as Keen4Platform
		assert_true(platform != null, "info %d places a platform" % value)
		if platform == null:
			continue
		var heading: Vector2i = GalaxyPlatform.HEADINGS[value - UP]
		assert_equal(platform.direction, heading, "info %d goes %s" % [value, heading])
		assert_equal(platform.position, Vector2i(10, 7) * TILE, "at its tile's corner")
		assert_equal(platform.activity, GalaxyObject.Activity.ALWAYS, "always awake")
		assert_equal(platform.priority, 0, "behind everything")
	var falling := Creatures.world(SPACE, FALLING, [Vector2i(8, 5)])
	assert_true(Creatures.first(falling, GalaxyFallingPlatform) != null, "info 32 falls")
	var turn := Creatures.world(SPACE, TURN, [Vector2i(8, 5)])
	assert_equal(turn.objects.size(), 1, "a turn point places nothing")


func test_a_platform_moves_12_a_tic_and_turns_at_turn_points() -> void:
	var world := Creatures.world(SPACE, RIGHT, [Vector2i(4, 5)])
	Fixtures.put_info(world.map, Vector2i(9, 5), TURN)
	Fixtures.put_info(world.map, Vector2i(2, 5), TURN)
	var platform := Creatures.first(world, Keen4Platform) as Keen4Platform
	Creatures.wait(world, 1)
	var x := platform.position.x
	Creatures.wait(world, 1)
	assert_equal(platform.position.x - x, 24, "12 a tic, 2 tics a frame")
	var rightmost := 0
	var turned := false
	for frame in 60:
		Creatures.wait(world, 1)
		rightmost = maxi(rightmost, platform.box.right)
		if platform.direction.x == -1:
			turned = true
	assert_true(turned, "it turned")
	assert_equal(rightmost, (9 + 2) * TILE, "its edge stops on the turn point's tile")
	var leftmost := platform.box.left
	for frame in 80:
		Creatures.wait(world, 1)
		leftmost = mini(leftmost, platform.box.left)
	assert_equal(leftmost, (2 + 3) * TILE, "and on the left one's far edge")


func test_a_vertical_platform_turns_at_turn_points() -> void:
	var world := Creatures.world(SPACE, UP, [Vector2i(10, 7)])
	Fixtures.put_info(world.map, Vector2i(10, 3), TURN)
	var platform := Creatures.first(world, Keen4Platform) as Keen4Platform
	var top := platform.box.top
	for frame in 40:
		Creatures.wait(world, 1)
		top = mini(top, platform.box.top)
	assert_equal(top, (3 + 3) * TILE, "going up it turns under the turn point")
	assert_equal(platform.direction.y, 1, "and comes down")


func test_a_vertical_platform_between_two_turn_points_is_held() -> void:
	# Going up: a turn point ahead and another two tiles below that one.
	var up := Creatures.world(SPACE, UP, [Vector2i(10, 6)])
	Fixtures.put_info(up.map, Vector2i(10, 4), TURN)
	Fixtures.put_info(up.map, Vector2i(10, 6), TURN)
	var rising := Creatures.first(up, Keen4Platform) as Keen4Platform
	Creatures.wait(up, 30)
	var held := rising.position
	Creatures.wait(up, 20)
	assert_equal(rising.position, held, "going up it is held")
	assert_true(rising.box.top >= (4 + 3) * TILE, "under the turn point ahead")
	assert_equal(rising.direction.y, -1, "still heading up")
	# Going down: the second turn point two tiles above the one ahead.
	var down := Creatures.world(SPACE, DOWN, [Vector2i(10, 6)])
	Fixtures.put_info(down.map, Vector2i(10, 8), TURN)
	Fixtures.put_info(down.map, Vector2i(10, 6), TURN)
	var sinking := Creatures.first(down, Keen4Platform) as Keen4Platform
	Creatures.wait(down, 30)
	held = sinking.position
	Creatures.wait(down, 20)
	assert_equal(sinking.position, held, "going down it is held")
	assert_true(sinking.box.bottom < (8 + 2) * TILE, "above the turn point ahead")
	assert_equal(sinking.direction.y, 1, "still heading down")


func test_keen_rides_a_moving_platform() -> void:
	var world := Creatures.world(SPACE, RIGHT, [Vector2i(3, 4)])
	Fixtures.put_info(world.map, Vector2i(12, 4), TURN)
	var platform := Creatures.first(world, Keen4Platform) as Keen4Platform
	var keen := world.player() as GalaxyKeen
	_drop_onto(keen, platform)
	assert_true(keen.platform == platform, "he lands on it")
	Creatures.wait(world, 2)
	assert_equal(keen.box.bottom, platform.box.top - 16, "standing on top of it (Omni)")
	assert_equal(keen.top_hit, GalaxyObject.ON_PLATFORM, "on a platform")
	var keen_x := keen.position.x
	var platform_x := platform.position.x
	Creatures.wait(world, 10)
	assert_true(
		absi((keen.position.x - keen_x) - (platform.position.x - platform_x)) <= 0x1F,
		"he moves with it"
	)
	assert_true(keen.position.x > keen_x, "to the right")
	Fixtures.run(world, 1, func(_frame: int) -> KeenInput: return Fixtures.press(0, 0, true))
	Creatures.wait(world, 3)
	assert_true(keen.platform == null, "a jump takes him off")


func test_a_platform_takes_keen_off_a_pole() -> void:
	var rows: PackedStringArray = [
		"....|...............",
		"....|...............",
		"....|...............",
		"....|...............",
		"....|...............",
		"K...|...............",
		"#####...............",
	]
	var world := Creatures.world(rows, UP, [Vector2i(3, 5)])
	Fixtures.put_info(world.map, Vector2i(3, 0), TURN)
	var platform := Creatures.first(world, Keen4Platform) as Keen4Platform
	var keen := world.player() as GalaxyKeen
	keen.position = Vector2i(GalaxyKeen.POLE_X + 5 * TILE, 3 * TILE)
	keen.clip = GalaxyObject.Clip.NONE
	keen.set_action(keen.actions[&"pole"])
	for frame in 40:
		Creatures.wait(world, 1)
		if keen.platform == platform:
			break
	assert_true(keen.platform == platform, "it carries him off the pole")
	assert_equal(keen.clip, GalaxyObject.Clip.NORMAL, "clipped again")


func test_the_falling_platform_sinks_falls_and_comes_back() -> void:
	var world := Creatures.world(SPACE, FALLING, [Vector2i(3, 4)])
	Fixtures.put_info(world.map, Vector2i(3, 9), TURN)
	var platform := Creatures.first(world, GalaxyFallingPlatform) as GalaxyFallingPlatform
	var home := platform.position.y
	Creatures.wait(world, 20)
	assert_equal(platform.position.y, home, "without Keen it floats")
	var keen := world.player() as GalaxyKeen
	_drop_onto(keen, platform)
	assert_true(keen.platform == platform, "he lands on it")
	var sunk := platform.position.y
	Creatures.wait(world, 1)
	assert_equal(platform.position.y - sunk, 32, "it sinks 16 a tic under him")
	Creatures.wait(world, 4)
	assert_equal(platform.action.name, &"fall", "half a tile down it falls")
	Creatures.wait(world, 30)
	assert_equal(platform.box.bottom, (9 + 2) * TILE - 1, "it stops over the turn point")
	assert_true(keen.platform == platform, "with him on it")
	# He walks off: it rises 32 a tic to its place.
	keen.position.x += 2 * TILE
	keen.reset_box()
	Creatures.wait(world, 3)
	assert_equal(platform.action.name, &"rise", "without him it rises")
	var y := platform.position.y
	Creatures.wait(world, 1)
	assert_equal(y - platform.position.y, 64, "32 a tic")
	Creatures.wait(world, 60)
	assert_equal(platform.position.y, home, "back at its place")
	assert_equal(platform.action.name, &"float", "floating again")


func test_a_switch_turns_a_turn_point_on_and_off() -> void:
	var rows: PackedStringArray = [
		"....................",
		"....................",
		"..S.................",
		"..K.................",
		"####################",
	]
	var world := Creatures.world(rows, 0, [])
	var switch_cell := Vector2i(4, 4)
	var target := Vector2i(15, 2)
	world.set_info(switch_cell, (target.x << 8) | target.y)
	var keen := world.player() as GalaxyKeen
	var up := func(_frame: int) -> KeenInput: return Fixtures.press(0, -1)
	_press(world, up)
	assert_equal(world.info_at(target.x, target.y), TURN, "the switch adds the turn point")
	assert_equal(world.fore_tile(4, 4), Fixtures.PLATFORM_SWITCH + 1, "the switch flips")
	assert_equal(keen.position.x, 4 * TILE - 64, "he stood at its spot")
	Fixtures.run(world, 2, Fixtures.nothing)
	_press(world, up)
	assert_equal(world.info_at(target.x, target.y), 0, "and takes it away again")
	assert_equal(world.fore_tile(4, 4), Fixtures.PLATFORM_SWITCH, "the switch flips back")


func test_a_switched_turn_point_turns_the_platform() -> void:
	var world := Creatures.world(SPACE, RIGHT, [Vector2i(4, 5)])
	Fixtures.put_info(world.map, Vector2i(16, 5), TURN)
	var platform := Creatures.first(world, Keen4Platform) as Keen4Platform
	Creatures.wait(world, 4)
	world.set_info(Vector2i(10, 7), world.info_at(10, 7) ^ GalaxyKeen.TURN_POINT_TOGGLE)
	var rightmost := 0
	for frame in 50:
		Creatures.wait(world, 1)
		rightmost = maxi(rightmost, platform.box.right)
	assert_equal(rightmost, 10 * TILE, "it turns at the new turn point")


func test_a_bridge_switch_extends_the_bridge() -> void:
	var rows: PackedStringArray = [
		"....................",
		"....................",
		"..s.................",
		"..K.......bbbb......",
		"#########bbbbb######",
	]
	var world := Creatures.world(rows, 0, [])
	world.set_info(Vector2i(4, 4), (12 << 8) | 5)
	var up := func(_frame: int) -> KeenInput: return Fixtures.press(0, -1)
	_press(world, up)
	for x in range(12, 16):
		assert_equal(world.fore_tile(x, 5), Fixtures.BRIDGE + 1, "the bridge's top row %d" % x)
	for x in range(11, 16):
		assert_equal(world.fore_tile(x, 6), Fixtures.BRIDGE + 1, "its second row %d" % x)
	assert_equal(world.fore_tile(16, 6), Fixtures.SOLID, "up to the bridge's end")


func test_the_platform_jets() -> void:
	var directions := {UP: 2, RIGHT: 1, 30: 1}
	for value in directions:
		var world := Creatures.world(SPACE, value, [Vector2i(10, 5)])
		var platform := Creatures.first(world, Keen4Platform) as Keen4Platform
		Creatures.wait(world, 1)
		assert_equal(platform.overlays.size(), directions[value], "jets of info %d" % value)
	var down := Creatures.world(SPACE, DOWN, [Vector2i(10, 2)])
	var platform := Creatures.first(down, Keen4Platform) as Keen4Platform
	var counts := {}
	for frame in 8:
		Creatures.wait(down, 1)
		counts[platform.overlays.size()] = true
	assert_true(counts.has(0) and counts.has(2), "going down the jets flicker")


func test_a_mine_moves_like_a_platform_and_explodes() -> void:
	var world := Creatures.world(SPACE, 70, [Vector2i(4, 0)])
	var mine := Creatures.first(world, Keen4Mine) as Keen4Mine
	assert_true(mine != null, "info 70 places a mine going right")
	var x := mine.position.x
	Creatures.wait(world, 2)
	assert_equal(mine.position.x - x, 12 * 5, "12 a tic")
	var keen := world.player() as GalaxyKeen
	keen.position = mine.position
	keen.reset_box()
	Creatures.wait(world, 1)
	assert_equal(mine.action.name, &"explode_1", "it explodes at Keen")
	assert_true(keen.is_dying(), "and kills him")
	Creatures.wait(world, 40)
	assert_true(not world.objects.has(mine), "gone after 60 tics")


## Puts [param keen] falling just above [param carrier] and runs until he
## lands on it (at most 30 frames).
func _drop_onto(keen: GalaxyKeen, carrier: GalaxyObject) -> void:
	keen.position = Vector2i(carrier.box.left, carrier.box.top - 496 - 40)
	keen.reset_box()
	keen.set_action(keen.actions[&"fall_1"])
	for frame in 30:
		Creatures.wait(keen.world, 1)
		if keen.platform == carrier:
			return


## Presses up until the switch has been pressed (he walks to it first).
func _press(world: GalaxyWorld, up: Callable) -> void:
	var keen := world.player() as GalaxyKeen
	for frame in 40:
		Fixtures.run(world, 1, up)
		if keen.action.name == &"press_switch_2":
			break
	Fixtures.run(world, 6, Fixtures.nothing)
