extends "res://tests/test_case.gd"
## Checks Keen's moves in hand-made mini levels (milestone D4) with
## Omnispeak's numbers and what the original showed in js-dos
## (docs/keen4/research.md §5, "Watched in D4"): the jump and the pogo,
## walking and slopes, dropping through a thin floor, poles, ledges and
## doors. The frames are the original's: 3 tics, then 2 each, so gravity
## acts on the first tic of every frame.

const Fixtures := preload("res://tests/galaxy_keen_fixtures.gd")

const UNITS := 16
const TILE := 256
## Seen in the original (D4): a held jump rises 67 pixels, a held pogo
## bounce 105, a pogo bounce without jump 41.
const HELD_JUMP_PIXELS := 67
const HELD_POGO_PIXELS := 105
const FREE_POGO_PIXELS := 41
## Walking: 24 units a tic, 48 a frame (Omni); on a slope down to the right
## 4 more a tic going down, 4 less going up.
const WALK_PER_FRAME := 48
const DOWNHILL_PER_FRAME := 56
const UPHILL_PER_FRAME := 40
## On a pole: climbing 8 a tic, sliding 24 (Omni).
const CLIMB_PER_FRAME := 16
const SLIDE_PER_FRAME := 48
const OPEN_SKY: PackedStringArray = [
	"..............",
	"..............",
	"..............",
	"..............",
	"..............",
	"..............",
	"..............",
	"..............",
	"....K.........",
	"##############",
]


func test_a_held_jump_rises_67_pixels() -> void:
	var world := Fixtures.world(OPEN_SKY)
	var keen := world.player() as GalaxyKeen
	var start := keen.position.y
	var highest := Fixtures.run(
		world, 60, func(_frame: int) -> KeenInput: return Fixtures.press(0, 0, true)
	)
	assert_equal((start - highest) / UNITS, HELD_JUMP_PIXELS, "a held jump, in pixels")
	assert_equal(keen.action.name, &"stand", "he lands")
	assert_equal(keen.position.y, start, "on the floor he left")


func test_a_short_jump_is_lower() -> void:
	var world := Fixtures.world(OPEN_SKY)
	var keen := world.player() as GalaxyKeen
	var start := keen.position.y
	var tap := func(frame: int) -> KeenInput: return Fixtures.press(0, 0, frame < 3)
	var highest := Fixtures.run(world, 60, tap)
	var pixels := (start - highest) / UNITS
	assert_true(
		pixels >= 30 and pixels <= 45, "a jump held 3 frames rises 30-45 pixels: %d" % pixels
	)
	assert_equal(keen.action.name, &"stand", "he lands")


func test_pogo_held_and_not_held() -> void:
	var world := Fixtures.world(OPEN_SKY)
	var keen := world.player() as GalaxyKeen
	var start := keen.position.y
	var pogo := func(_frame: int) -> KeenInput: return Fixtures.press(0, 0, false, true)
	var jump := func(_frame: int) -> KeenInput: return Fixtures.press(0, 0, true)
	# Pogo, then jump held: the first bounce comes from the ground, measure
	# the second.
	Fixtures.run(world, 1, pogo)
	Fixtures.run(world, 60, jump)
	assert_true(keen.action.name.begins_with("pogo"), "still on the pogo")
	var highest := Fixtures.run(world, 50, jump)
	assert_equal((start - highest) / UNITS, HELD_POGO_PIXELS, "a held bounce, in pixels")
	var free := Fixtures.world(OPEN_SKY)
	var free_keen := free.player() as GalaxyKeen
	Fixtures.run(free, 1, pogo)
	Fixtures.run(free, 60, Fixtures.nothing)
	var free_highest := Fixtures.run(free, 32, Fixtures.nothing)
	assert_equal((start - free_highest) / UNITS, FREE_POGO_PIXELS, "a bounce without jump")
	# Pogo again: he falls off and lands.
	Fixtures.run(free, 1, pogo)
	Fixtures.run(free, 60, Fixtures.nothing)
	assert_equal(free_keen.action.name, &"stand", "pogo again: he stops")


func test_walking_speed() -> void:
	var world := Fixtures.world(OPEN_SKY)
	var keen := world.player() as GalaxyKeen
	var right := func(_frame: int) -> KeenInput: return Fixtures.press(1)
	Fixtures.run(world, 5, right)
	var before := keen.position.x
	Fixtures.run(world, 10, right)
	assert_equal(keen.position.x - before, 10 * WALK_PER_FRAME, "24 units a tic")
	assert_true(keen.action.name.begins_with("run"), "running")
	Fixtures.run(world, 60, right)
	assert_equal(keen.action.name, &"stand", "a wall stops him")
	assert_equal(keen.box.right, (world.map.width - 2) * TILE - 1, "against the border")


func test_slopes_change_his_speed_and_height() -> void:
	var world := (
		Fixtures
		. world(
			[
				"..................",
				"..K...............",
				"#####23...........",
				"#######23.........",
				"#########=========",
			]
		)
	)
	var keen := world.player() as GalaxyKeen
	var downhill := PackedInt32Array()
	var on_slope := true
	for frame in 30:
		var before := keen.position.x
		Fixtures.run(world, 1, func(_frame: int) -> KeenInput: return Fixtures.press(1))
		if keen.top_hit in [2, 3] and keen.moved.y > 0:
			downhill.append(keen.position.x - before)
			var column := GalaxyUnits.to_pixel(keen.box.middle) & 15
			var row := GalaxyUnits.to_tile(keen.box.bottom + 1)
			var floor_top := row * TILE + GalaxyClip.slope_height(keen.top_hit, column)
			on_slope = on_slope and keen.box.bottom == floor_top - 1
	assert_true(downhill.size() >= 3, "he walked down the slope")
	assert_true(on_slope, "his feet follow the slope's height")
	assert_true(downhill.count(DOWNHILL_PER_FRAME) >= 3, "28 a tic going down: %s" % downhill)
	var uphill := PackedInt32Array()
	for frame in 30:
		var before := keen.position.x
		Fixtures.run(world, 1, func(_frame: int) -> KeenInput: return Fixtures.press(-1))
		if keen.top_hit in [2, 3]:
			uphill.append(before - keen.position.x)
	assert_true(uphill.count(UPHILL_PER_FRAME) >= 3, "20 a tic going up: %s" % uphill)


func test_looking_down_and_jumping_drops_through_a_thin_floor() -> void:
	var world := (
		Fixtures
		. world(
			[
				"..........",
				"....K.....",
				"==========",
				"..........",
				"..........",
				"##########",
			]
		)
	)
	var keen := world.player() as GalaxyKeen
	var start := keen.position.y
	Fixtures.run(world, 20, func(_frame: int) -> KeenInput: return Fixtures.press(0, 1))
	assert_equal(keen.action.name, &"look_down_3", "looking down")
	Fixtures.run(world, 1, func(_frame: int) -> KeenInput: return Fixtures.press(0, 1, true))
	Fixtures.run(world, 40, Fixtures.nothing)
	assert_equal(keen.position.y, start + 3 * TILE, "he fell through to the floor below")
	var solid := Fixtures.world(["..........", "....K.....", "##########"])
	var solid_keen := solid.player() as GalaxyKeen
	var solid_start := solid_keen.position.y
	Fixtures.run(solid, 20, func(_frame: int) -> KeenInput: return Fixtures.press(0, 1))
	Fixtures.run(solid, 1, func(_frame: int) -> KeenInput: return Fixtures.press(0, 1, true))
	Fixtures.run(solid, 20, Fixtures.nothing)
	assert_equal(solid_keen.position.y, solid_start, "not through a solid floor")


func test_poles() -> void:
	var world := (
		Fixtures
		. world(
			[
				"..........",
				"....|.....",
				"....|.....",
				"....|.....",
				"....|.....",
				"....P.....",
				"####o#####",
				"....|.....",
				"....|.....",
				"....|.....",
				"##########",
			]
		)
	)
	var keen := world.player() as GalaxyKeen
	var up := func(_frame: int) -> KeenInput: return Fixtures.press(0, -1)
	Fixtures.run(world, 1, up)
	assert_equal(keen.action.name, &"pole", "up grabs the pole")
	assert_equal(keen.clip, GalaxyObject.Clip.NONE, "on a pole nothing clips him")
	assert_equal(keen.position.x, (6 - 1) * TILE + 128, "on the pole's column")
	Fixtures.run(world, 4, up)
	var before := keen.position.y
	Fixtures.run(world, 4, up)
	assert_equal(before - keen.position.y, 4 * CLIMB_PER_FRAME, "climbing 8 a tic")
	Fixtures.run(world, 60, up)
	before = keen.position.y
	Fixtures.run(world, 4, up)
	assert_equal(keen.position.y, before, "he stops at the pole's top")
	# The stop comes after the move that took his head over the pole's top.
	assert_equal(keen.box.tile_top, 2, "with his head just above its top tile")
	var down := func(_frame: int) -> KeenInput: return Fixtures.press(0, 1)
	Fixtures.run(world, 2, down)
	before = keen.position.y
	Fixtures.run(world, 4, down)
	assert_equal(keen.position.y - before, 4 * SLIDE_PER_FRAME, "sliding 24 a tic")
	# Jump off (sliding only looks at the buttons every 8 tics: hold still
	# first): −20 for 10 tics, and no grabbing for a while.
	Fixtures.run(world, 6, Fixtures.nothing)
	Fixtures.run(world, 1, func(_frame: int) -> KeenInput: return Fixtures.press(1, 0, true))
	assert_equal(keen.action.name, &"jump_1", "jumping off")
	assert_equal(keen.velocity, Vector2i(8, -20), "sideways 8, up 20")
	assert_equal(keen.clip, GalaxyObject.Clip.NORMAL, "clipped again")
	Fixtures.run(world, 3, up)
	assert_true(keen.action.name.begins_with("jump"), "no grabbing the pole at once")


func test_sliding_down_to_the_floor() -> void:
	var world := (
		Fixtures
		. world(
			[
				"..........",
				"....P.....",
				"####o#####",
				"....|.....",
				"....|.....",
				"##########",
			]
		)
	)
	var keen := world.player() as GalaxyKeen
	Fixtures.run(world, 60, func(_frame: int) -> KeenInput: return Fixtures.press(0, 1))
	assert_true(keen.action.name.begins_with("look_down"), "at the bottom he stands, looking down")
	assert_equal(keen.box.bottom, 7 * TILE - 1, "on the floor under the pole")


func test_hanging_on_a_ledge_and_pulling_up() -> void:
	var world := (
		Fixtures
		. world(
			[
				"............",
				"............",
				"######......",
				"######......",
				"######......",
				"######......",
				"######.K....",
				"############",
			]
		)
	)
	var keen := world.player() as GalaxyKeen
	var climb := func(frame: int) -> KeenInput: return Fixtures.press(-1, 0, frame < 20)
	var hung := false
	for frame in 60:
		Fixtures.run(world, 1, func(_f: int) -> KeenInput: return climb.call(frame))
		if keen.action.name.begins_with("hang"):
			hung = true
			break
	assert_true(hung, "falling past the wall's top with left held, he hangs")
	assert_equal(keen.clip, GalaxyObject.Clip.NONE, "hanging is not clipped")
	Fixtures.run(world, 10, Fixtures.nothing)
	assert_equal(keen.action.name, &"hang_2", "he keeps hanging")
	Fixtures.run(world, 1, func(_frame: int) -> KeenInput: return Fixtures.press(0, -1))
	assert_equal(keen.action.name, &"pull_1", "up pulls him up")
	Fixtures.run(world, 40, Fixtures.nothing)
	assert_equal(keen.action.name, &"stand", "onto the ledge")
	assert_equal(keen.box.bottom, 4 * TILE - 1, "standing on the wall's top")


func test_dropping_from_a_ledge() -> void:
	var world := (
		Fixtures
		. world(
			[
				"............",
				"............",
				"######......",
				"######......",
				"######......",
				"######......",
				"######.K....",
				"############",
			]
		)
	)
	var keen := world.player() as GalaxyKeen
	for frame in 60:
		Fixtures.run(world, 1, func(_f: int) -> KeenInput: return Fixtures.press(-1, 0, frame < 20))
		if keen.action.name.begins_with("hang"):
			break
	Fixtures.run(world, 10, Fixtures.nothing)
	Fixtures.run(world, 1, func(_frame: int) -> KeenInput: return Fixtures.press(0, 1))
	Fixtures.run(world, 40, Fixtures.nothing)
	assert_equal(keen.action.name, &"stand", "down lets go: he lands below")
	assert_equal(keen.box.bottom, 9 * TILE - 1, "on the floor")


func test_doors_take_him_to_their_target() -> void:
	var rows: PackedStringArray = [
		"....................",
		"..dd................",
		"..........K.........",
		"####################",
		"....................",
		"....................",
		"####################",
	]
	var map := Fixtures.level(rows)
	# The door's target: x in the high byte, y in the low one (map cells).
	Fixtures.put_info(map, Vector2i(2, 1), (15 << 8) | 7)
	var world := GalaxyWorld.create(map, Fixtures.tile_info(), Fixtures.sprite_infos())
	world.camera = Fixtures.camera_for(map)
	var keen := GalaxyKeen.spawn(world, Vector2i(14, 4), 1, Keen4Sprites.all())
	# Walk under the door first.
	for frame in 60:
		if keen.box.tile_middle == 5:
			break
		Fixtures.run(world, 1, func(_frame: int) -> KeenInput: return Fixtures.press(-1))
	Fixtures.run(world, 1, Fixtures.nothing)
	Fixtures.run(world, 1, func(_frame: int) -> KeenInput: return Fixtures.press(0, -1))
	assert_true(keen.action.name in [&"slide", &"enter_door_1"], "up at a door: to its spot")
	Fixtures.run(world, 40, Fixtures.nothing)
	assert_equal(keen.position, Vector2i(15 * TILE, 7 * TILE - TILE + 15), "at the target")
	assert_equal(keen.action.name, &"stand", "standing there")
	assert_true(keen.safe_tics > 0, "safe for a while after a door")
