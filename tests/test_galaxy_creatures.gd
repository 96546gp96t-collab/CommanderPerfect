extends "res://tests/test_case.gd"
## Checks what the Galaxy creatures share (milestone D5), in hand-made mini
## levels: the stun (the hop, at most −48, and the stars: three frames of
## 10 tics), the second sprite and the draw offset on the object layer, a
## hidden object, the enemy shot that is gone at a wall, and Keen pushed
## out by a creature, landing on it and riding it (Omni CK_StunCreature,
## CK_BasicDrawFunc4, CK_PhysPushXY, CK_PhysPushY, CK_KeenRidePlatform);
## and (D13) a creature that starts another object's action in its think
## loses its own step of that frame (the original's shared step).

const Fixtures := preload("res://tests/galaxy_keen_fixtures.gd")
const Creatures := preload("res://tests/keen4_creature_fixtures.gd")

const TILE := 256
const FIELD: PackedStringArray = [
	"....................",
	"....................",
	"....................",
	"K...................",
	"####################",
]

var _keep: Array = []


func test_the_stun_hop_and_its_limit() -> void:
	var world := Creatures.world(FIELD, 22, [Vector2i(10, 3)])
	var slug := Creatures.first(world, Keen4Slug) as Keen4Slug
	var shot := Creatures.shoot(world, slug, _keep)
	slug.velocity.y = -40
	slug.stun(shot, &"stunned_1")
	assert_equal(slug.velocity.y, GalaxyCreature.STUN_HOP_LIMIT, "at most -48 up")
	assert_true(shot.spent, "the shot stops")
	assert_true(slug.stunned, "it counts as stunned")
	var lick := Creatures.world(FIELD, 14, [Vector2i(10, 3)])
	var other := Creatures.first(lick, Keen4Lick) as Keen4Lick
	other.velocity.y = 0
	other.stun(Creatures.shoot(lick, other, _keep), &"stunned_1")
	assert_equal(other.velocity.y, GalaxyCreature.STUN_HOP, "-24 from standing")


func test_the_stars_turn_every_10_tics() -> void:
	var world := Creatures.world(FIELD, 22, [Vector2i(10, 3)])
	var slug := Creatures.first(world, Keen4Slug) as Keen4Slug
	slug.stun(Creatures.shoot(world, slug, _keep), &"stunned_1")
	var frames: Array[int] = []
	for frame in 30:
		Creatures.wait(world, 1)
		if not slug.overlays.is_empty():
			var sprite := slug.overlays[0].sprite
			if frames.is_empty() or frames.back() != sprite:
				frames.append(sprite)
	assert_true(frames.size() >= 4, "the stars change (%s)" % [frames])
	assert_equal(frames.slice(0, 3), [40, 41, 42] as Array[int], "three frames in turn")
	assert_equal(slug.overlays[0].priority, GalaxyCreature.STAR_PRIORITY, "in front")


func test_the_layer_draws_overlays_offsets_and_hides() -> void:
	var world := Creatures.world(FIELD, 22, [Vector2i(10, 3)])
	var layer := GalaxyObjectLayer.new()
	var slug := Creatures.first(world, Keen4Slug) as Keen4Slug
	layer.show_objects(world.objects)
	var before := layer.items().size()
	var stars := GalaxyObject.Overlay.new()
	stars.sprite = 40
	slug.overlays.append(stars)
	slug.draw_offset = Vector2i(0, -64)
	layer.show_objects(world.objects)
	assert_equal(layer.items().size(), before + 1, "the stars are a second sprite")
	var drawn := layer.items().filter(
		func(item: GalaxyObjectLayer.Item) -> bool: return item.sprite == slug.sprite
	)
	assert_equal(drawn[0].position, slug.position + Vector2i(0, -64), "drawn at its offset")
	slug.overlays.clear()
	slug.hidden = true
	layer.show_objects(world.objects)
	assert_equal(layer.items().size(), before, "the stars go")
	assert_true(not drawn[0].node.visible, "a hidden object is not drawn")
	layer.free()


func test_a_slug_leaving_its_slime_keeps_its_place() -> void:
	var world := Creatures.world(FIELD, 22, [Vector2i(10, 3)])
	var slug := Creatures.first(world, Keen4Slug) as Keen4Slug
	Creatures.wait(world, 1)
	slug.direction.x = -1
	slug.action = slug.actions[&"sliming"]
	slug.action_timer = slug.action.timer - 1
	var x := slug.position.x
	var before := world.objects.size()
	Creatures.wait(world, 1)
	assert_equal(world.objects.size(), before + 1, "the slime is left")
	assert_true(slug.action == slug.actions[&"crawl_1"], "it crawls on")
	assert_equal(slug.position.x, x, "the slime's start took its step back (seen in D13)")


func test_an_enemy_shot_ends_at_a_wall() -> void:
	var rows: PackedStringArray = [
		"....................",
		"K.........#.........",
		"####################",
	]
	var world := Creatures.world(rows, 0, [])
	var shot := GalaxyEnemyShot.fire(
		world,
		Vector2i(6 * TILE, 3 * TILE),
		Vector2i.RIGHT,
		Keen4DartGun.DART_ROWS,
		Keen4Sprites.all(),
		&"side_1"
	)
	assert_equal(shot.activity, GalaxyObject.Activity.ON_SCREEN_ONLY, "only on the screen")
	var gone := Creatures.run_until(world, func() -> bool: return shot.removed, 30)
	assert_true(gone < 30, "gone at the wall")
	assert_true(shot.position.x < 13 * TILE, "before the wall")


func test_keen_is_pushed_out_sideways() -> void:
	var world := Creatures.world(FIELD, 12, [Vector2i(3, 3)])
	var ball := Creatures.first(world, Keen4Bounder) as Keen4Bounder
	var keen := world.player() as GalaxyKeen
	ball.moved = Vector2i(-48, 0)
	keen.moved = Vector2i.ZERO
	ball.box.left = keen.box.right - 40
	ball.box.right = ball.box.left + 240
	ball.box.top = keen.box.top
	ball.box.bottom = keen.box.bottom
	var start := keen.position.x
	keen.push_out(ball)
	assert_equal(keen.position.x, start - 40, "out of its way, to the left")
	assert_equal(keen.left_hit, 1, "as if against a wall")


func test_keen_lands_on_a_carrier_and_rides_it() -> void:
	var world := Creatures.world(FIELD, 0, [])
	var keen := world.player() as GalaxyKeen
	var carrier := GalaxyCreature.new()
	carrier.direction = Vector2i.ZERO
	carrier.enter(
		world, keen.position + Vector2i(0, 448), Keen4Bounder.ROWS, Keen4Sprites.all(), &"stunned_2"
	)
	carrier.box.top = keen.box.bottom - 32
	keen.moved = Vector2i(0, 64)
	carrier.moved = Vector2i.ZERO
	keen.land_on(carrier)
	assert_true(keen.platform == carrier, "he rides it")
	assert_equal(keen.top_hit, GalaxyObject.ON_PLATFORM, "standing on a platform")
	carrier.moved = Vector2i(32, 0)
	var x := keen.position.x
	keen.moved = Vector2i.ZERO
	keen._ride_platform()
	assert_equal(
		keen.position.x & ~GalaxyKeenBody.RIDE_X_BITS,
		(x + 32) & ~GalaxyKeenBody.RIDE_X_BITS,
		"and moves with it"
	)
	keen.moved = Vector2i(0, -40)
	keen._ride_platform()
	assert_true(keen.platform == null, "jumping, he leaves it")
