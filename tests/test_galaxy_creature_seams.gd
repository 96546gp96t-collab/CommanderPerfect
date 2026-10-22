extends "res://tests/test_case.gd"
## Tests for what milestone E4 added to the Galaxy engine for Keen 5's
## creatures, each neutral for Keen 4 by its default: the sleep margin as a
## field of the world (Keen 4's 4 tiles, Keen 5's 6), the white flash of
## the object layer, the bouncing pieces ([GalaxyShrapnel]) and moving
## along path arrows ([GalaxyPathArrows]). Made-up levels; no game files.

const Fixtures := preload("res://tests/galaxy_keen_fixtures.gd")
const Waking := preload("res://tests/test_galaxy_wide_waking.gd")

const TILE := 256
const VIEW_END := 40
const KEEN_5_MARGIN := 6
const ARROW_RIGHT := 92
const ARROW_DOWN_RIGHT := 96
const ARROW_UP := 91
## A piece's rows: it falls and bounces (as Keen 5's).
const PIECE_ROWS: PackedStringArray = [
	"piece STUN_1 STUN_1 think -- 0 0 0 fall - shrapnel -",
]


func test_the_sleep_margin_defaults_to_keen_4s() -> void:
	var world := Waking._world()
	assert_equal(world.sleep_margin, GalaxyWorld.SLEEP_MARGIN, "Keen 4's margin by default")
	assert_equal(GalaxyWorld.SLEEP_MARGIN, 4, "4 tiles")
	var kept := _awake(world, VIEW_END + 4)
	var gone := _awake(world, VIEW_END + 5)
	Waking._frames(world, 1)
	assert_true(GalaxyWorld.is_awake(kept), "4 tiles beyond: awake")
	assert_true(not GalaxyWorld.is_awake(gone), "5 beyond: asleep")


func test_keen_5s_sleep_margin_is_6_tiles() -> void:
	var world := Waking._world()
	world.sleep_margin = KEEN_5_MARGIN
	var kept := _awake(world, VIEW_END + 6)
	var gone := _awake(world, VIEW_END + 7)
	var shot := _awake(world, VIEW_END + 7)
	shot.activity = GalaxyObject.Activity.ON_SCREEN_ONLY
	Waking._frames(world, 1)
	assert_true(GalaxyWorld.is_awake(kept), "6 tiles beyond: awake")
	assert_true(not GalaxyWorld.is_awake(gone), "7 beyond: asleep")
	assert_true(shot.removed, "an object living on the screen only is gone there")


func test_an_object_flashes_white_and_back() -> void:
	var world := Waking._world()
	var still := _awake(world, 30)
	var layer := GalaxyObjectLayer.new()
	var tint := CanvasItemMaterial.new()
	layer.tint(still, tint)
	layer.show_objects(world.objects)
	var item: GalaxyObjectLayer.Item = layer._shown[still]
	assert_equal(item.node.material, tint, "its own material")
	still.flash_white = true
	layer.show_objects(world.objects)
	var white := item.node.material as ShaderMaterial
	assert_true(white != null and white.shader.code.contains("vec4(1.0, 1.0, 1.0"), "white")
	still.flash_white = false
	layer.show_objects(world.objects)
	assert_equal(item.node.material, tint, "its own again")
	layer.tint(still, null)
	layer.show_objects(world.objects)
	assert_equal(item.node.material, null, "plain, as every Keen 4 object always")
	layer.free()


func test_a_piece_bounces_off_a_floor_with_half_its_energy_until_spent() -> void:
	var world := (
		Fixtures
		. world(
			[
				"....................",
				"....................",
				"....................",
				"....................",
				"..................K.",
				"####################",
			]
		)
	)
	var piece := GalaxyShrapnel.new()
	piece.velocity = Vector2i(0, 70)
	piece.direction = Vector2i.ZERO
	piece.enter(world, Vector2i(5 * TILE, 2 * TILE), PIECE_ROWS, Keen4Sprites.all(), &"piece")
	var bounces: Array[int] = []
	for frame in 200:
		var falling := piece.velocity.y > 0
		Fixtures.run(world, 1, Fixtures.nothing)
		if piece.removed:
			break
		if falling and piece.velocity.y < 0:
			bounces.append(piece.velocity.y)
	assert_true(bounces.size() >= 2, "it bounces")
	assert_true(-bounces[1] < -bounces[0], "lower every time")
	assert_true(piece.removed, "spent, it is gone")
	assert_equal(piece.velocity.x, 0, "straight down, straight up")


func test_a_piece_turns_back_at_a_wall_at_half_speed() -> void:
	var piece := GalaxyShrapnel.new()
	piece.velocity = Vector2i(30, 0)
	piece.left_hit = 1
	piece._react_shrapnel()
	assert_equal(piece.velocity.x, -15, "back at half speed")


func test_moving_along_arrows() -> void:
	var world := Waking._world()
	var mover := GalaxyObject.new()
	world.add(mover)
	mover.position = Vector2i(30 * TILE, 5 * TILE)
	var path := GalaxyPathArrows.start_at(world, Vector2i(30, 5), 1)
	assert_equal(world.info_at(30, 5), ARROW_RIGHT, "it writes its arrow")
	world.set_info(Vector2i(31, 5), ARROW_DOWN_RIGHT)
	world.set_info(Vector2i(32, 6), ARROW_UP)
	world.set_info(Vector2i(32, 5), ARROW_UP)
	world.tics = 2
	var moves: Array[Vector2i] = []
	for frame in 12:
		mover.step = Vector2i.ZERO
		path.advance(mover, 32)
		mover.position += mover.step
		moves.append(mover.step)
	assert_equal(moves[0], Vector2i(64, 0), "right, 32 a tic")
	assert_equal(mover.position, Vector2i(32 * TILE, 5 * TILE), "right, down-right, up")
	assert_equal(GalaxyPathArrows.arrow_of(ARROW_UP), 0, "91 is up")
	assert_equal(GalaxyPathArrows.arrow_of(0), -1, "0 is no arrow")
	assert_equal(path.arrow, 0, "following the up arrow now")
	mover.step = Vector2i(1, 0)
	path.advance(mover, 32)
	assert_equal(mover.step, Vector2i(1, 0), "moved already this frame: nothing more")


func test_a_piece_looks_ahead_by_its_offset() -> void:
	var world := Waking._world()
	var mover := GalaxyObject.new()
	world.add(mover)
	mover.position = Vector2i(30 * TILE + 0x40, 5 * TILE + 0x40)
	var path := GalaxyPathArrows.start_at(world, Vector2i(30, 5), 1)
	world.set_info(Vector2i(31, 5), ARROW_UP)
	world.tics = 8
	mover.step = Vector2i.ZERO
	path.advance(mover, 32, 0x40)
	assert_equal(mover.step, Vector2i(256, 0), "a whole tile to the next")
	assert_equal(path.arrow, 0, "where it reads the up arrow, 0x40 further")


## An object at column [param column], awake.
static func _awake(world: GalaxyWorld, column: int) -> GalaxyObject:
	var still := Waking._still(world, column)
	still.activity = GalaxyObject.Activity.ACTIVE
	return still
