extends "res://tests/test_case.gd"
## Checks more of Keen 4's creatures in hand-made mini levels (milestone
## D5): the Berkeloid and its fireball, the Lick, the Mimrock, the Bounder
## (riding and steering it, the stunned Bounder as a platform), Smirky,
## the inchworms and the Foot, and the dart guns (Omni numbers;
## docs/keen4/research.md §7).

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


func test_berkeloid_throws_fire_that_burns() -> void:
	var world := Creatures.world(FIELD, 5, [Vector2i(12, 3)])
	var berk := Creatures.first(world, Keen4Berkeloid) as Keen4Berkeloid
	assert_equal(berk.position.y, (3 + 2) * TILE - Keen4Berkeloid.RISE, "two tiles up")
	var lowest := 0
	for frame in 3000:
		Creatures.wait(world, 1)
		lowest = mini(lowest, berk.draw_offset.y)
		if _fireball(world) != null:
			break
	assert_true(lowest < 0 and lowest >= Keen4Berkeloid.BOB_TOP, "its picture bobs up to a tile")
	var ball := _fireball(world)
	assert_true(ball != null, "it throws fireballs")
	assert_equal(absi(ball.velocity.x), 48, "48 sideways")
	var burning := Creatures.run_until(
		world, func() -> bool: return ball.action.name.begins_with("burn"), 200
	)
	assert_true(burning < 200, "on the ground it burns")
	var keen := world.player() as GalaxyKeen
	var shot := Creatures.shoot(world, berk, _keep)
	Creatures.wait(world, 2)
	assert_true(shot.spent and not berk.stunned, "the stunner does nothing to it")
	berk.position = keen.position
	berk.reset_box()
	Creatures.wait(world, 1)
	assert_true(keen.is_dying(), "touching it kills Keen")


func test_lick_hops_and_burns_only_in_front() -> void:
	var world := Creatures.world(FIELD, 14, [Vector2i(14, 3)])
	var lick := Creatures.first(world, Keen4Lick) as Keen4Lick
	var start := lick.position.x
	Creatures.wait(world, 60)
	assert_true(lick.position.x < start, "it hops to Keen")
	var keen := world.player() as GalaxyKeen
	var flamed := Creatures.run_until(
		world, func() -> bool: return lick.action.name.begins_with("flame"), 600
	)
	assert_true(flamed < 600, "close to Keen it breathes fire")
	Creatures.wait(world, 4)
	assert_true(keen.is_dying(), "the flame kills Keen in front of it")
	var calm := Creatures.world(FIELD, 14, [Vector2i(14, 3)])
	var other := Creatures.first(calm, Keen4Lick) as Keen4Lick
	var victim := calm.player() as GalaxyKeen
	other.direction.x = 1
	other.position = victim.position + Vector2i(64, 0)
	other.reset_box()
	other.set_action(other.actions[&"flame_1"])
	Creatures.wait(calm, 1)
	assert_true(not victim.is_dying(), "Keen behind it is safe")
	Creatures.shoot(calm, other, _keep)
	Creatures.wait(calm, 2)
	assert_true(other.stunned, "a shot stuns it")


func test_mimrock_sneaks_and_leaps() -> void:
	var world := Creatures.world(FIELD, 19, [Vector2i(10, 3)])
	var rock := Creatures.first(world, Keen4Mimrock) as Keen4Mimrock
	var keen := world.player() as GalaxyKeen
	keen.direction.x = 1
	var keep: Array = []
	var shot := Creatures.shoot(world, rock, keep)
	Creatures.wait(world, 2)
	assert_true(not rock.stunned and not shot.spent, "sitting it is just a rock")
	var start := rock.position.x
	Creatures.wait(world, 30)
	assert_equal(rock.position.x, start, "Keen looks at it: it sits")
	keen.direction.x = -1
	var sneaking := Creatures.run_until(
		world, func() -> bool: return rock.action.name.begins_with("sneak"), 60
	)
	assert_true(sneaking < 60, "Keen looks away: it sneaks after him")
	var leapt := Creatures.run_until(
		world, func() -> bool: return rock.action.name.begins_with("leap"), 300
	)
	assert_true(leapt < 300, "close behind him it leaps")
	var killed := Creatures.run_until(world, func() -> bool: return keen.is_dying(), 100)
	assert_true(killed < 100, "the leap kills Keen")


func test_bounder_bounces_carries_and_steers() -> void:
	var rows: PackedStringArray = [
		"........................",
		"........................",
		"........................",
		"........................",
		"........................",
		"........................",
		"........................",
		"........................",
		"K.......................",
		"########################",
	]
	var world := Creatures.world(rows, 12, [Vector2i(10, 8)])
	var ball := Creatures.first(world, Keen4Bounder) as Keen4Bounder
	var speeds: Array[int] = []
	for frame in 120:
		Creatures.wait(world, 1)
		if ball.velocity.y == Keen4Bounder.BOUNCE_SPEED:
			speeds.append(ball.velocity.x)
	assert_true(not speeds.is_empty(), "it bounces at -50")
	var keen := world.player() as GalaxyKeen
	keen.position = Vector2i(ball.box.left - 64, ball.box.top - 3 * TILE)
	keen.reset_box()
	keen.set_action(keen.actions[&"fall_1"])
	keen.velocity = Vector2i.ZERO
	var landed := 0
	while keen.platform != ball and landed < 200:
		# The player keeps him over the ball as he falls.
		keen.position.x = ball.box.left - 64
		Creatures.wait(world, 1)
		landed += 1
	assert_true(landed < 200, "Keen lands on it and rides it")
	assert_true(not keen.is_dying(), "it never hurts him")
	keen.position.x = ball.box.right - 100
	keen.reset_box()
	var steered := Creatures.run_until(world, func() -> bool: return ball.direction.x == 1, 120)
	assert_true(steered < 120, "standing on its right side steers it right")
	assert_equal(absi(ball.velocity.x), Keen4Bounder.SIDEWAYS_SPEED, "24 sideways")


func test_stunned_bounder_is_a_platform() -> void:
	var world := Creatures.world(FIELD, 12, [Vector2i(10, 3)])
	var ball := Creatures.first(world, Keen4Bounder) as Keen4Bounder
	Creatures.wait(world, 30)
	Creatures.shoot(world, ball, _keep)
	Creatures.run_until(world, func() -> bool: return ball.stunned, 10)
	var resting := Creatures.run_until(
		world, func() -> bool: return ball.action.name == &"stunned_2", 200
	)
	assert_true(resting < 200, "stunned, it lands and stays")
	assert_true(ball.overlays.size() == 1, "with stars")
	var keen := world.player() as GalaxyKeen
	keen.position = Vector2i(ball.box.left - 64, ball.box.top - 2 * TILE)
	keen.reset_box()
	keen.set_action(keen.actions[&"fall_1"])
	keen.velocity = Vector2i.ZERO
	var landed := Creatures.run_until(world, func() -> bool: return keen.platform == ball, 100)
	assert_true(landed < 100, "Keen stands on it")
	assert_true(keen.box.bottom <= ball.box.top, "on top of it")


func test_smirky_eats_items_and_teleports() -> void:
	var rows: PackedStringArray = [
		"....................",
		"..........$.........",
		"....................",
		"....................",
		"K...................",
		"####################",
	]
	var world := Creatures.world(rows, 18, [Vector2i(10, 4)])
	var smirky := Creatures.first(world, Keen4Smirky) as Keen4Smirky
	var keen := world.player() as GalaxyKeen
	var sprites := Keen4Sprites.all()
	var item := GalaxyItem.place(world, Vector2i(18, 6), 4, sprites, keen.item_actions())
	var ate := Creatures.run_until(
		world, func() -> bool: return world.fore_tile(12, 3) == Fixtures.EMPTY, 400
	)
	assert_true(ate < 400, "it jumps for the item tile above it and eats it")
	assert_equal(keen.inventory.score, 0, "Keen gets nothing")
	var gone := Creatures.run_until(world, func() -> bool: return item.taken, 3000)
	assert_true(gone < 3000, "it gets to the item lying as a sprite and eats it")
	assert_true(not keen.is_dying(), "it never hurts Keen")
	Creatures.shoot(world, smirky, _keep)
	Creatures.wait(world, 2)
	assert_true(smirky.stunned or smirky.removed, "a shot stuns it (unless it is gone)")


func test_smirky_teleports_to_an_item_or_leaves() -> void:
	var world := Creatures.world(FIELD, 18, [Vector2i(10, 3)])
	var smirky := Creatures.first(world, Keen4Smirky) as Keen4Smirky
	var keen := world.player() as GalaxyKeen
	var item := GalaxyItem.place(world, Vector2i(18, 4), 4, Keen4Sprites.all(), keen.item_actions())
	smirky.misses = Keen4Smirky.MISSES_TO_TELEPORT
	Creatures.run_until(world, func() -> bool: return smirky.action.name == &"appear_1", 300)
	assert_equal(smirky.position.x, item.position.x + Keen4Smirky.ITEM_OFFSET, "next to the item")
	item.taken = true
	world.remove(item)
	smirky.misses = Keen4Smirky.MISSES_TO_TELEPORT
	var left := Creatures.run_until(world, func() -> bool: return smirky.removed, 600)
	assert_true(left < 600, "with no item left it is gone")


func test_eleven_worms_make_the_foot() -> void:
	var world := Creatures.world(FIELD, 11, [Vector2i(10, 3)])
	var sprites := Keen4Sprites.all()
	for worm in 11:
		Keen4Inchworm.spawn(world, Vector2i(12, 5), sprites)
	assert_equal(Creatures.count(world, Keen4Inchworm), 12, "twelve worms (one from info 11)")
	Creatures.wait(world, 2)
	var foot := Creatures.first(world, Keen4Inchworm) as Keen4Inchworm
	for object in world.objects:
		var worm := object as Keen4Inchworm
		if worm != null and worm.is_foot:
			foot = worm
	assert_true(foot.is_foot, "touching 11 others, a worm becomes the Foot")
	var worms := world.objects.filter(
		func(object: GalaxyObject) -> bool: return object is Keen4Inchworm and object.is_worm()
	)
	assert_true(worms.is_empty(), "the other worms are gone")
	var keen := world.player() as GalaxyKeen
	keen.position = foot.position - Vector2i(0, TILE / 2)
	keen.reset_box()
	Creatures.wait(world, 1)
	assert_equal(world.state, GalaxyWorld.LevelState.COMPLETED, "the Foot ends the level")
	assert_equal(world.ending, Keen4Inchworm.FOOT_ENDING, "carried off by the Foot")


func test_few_worms_stay_worms_and_harmless() -> void:
	var world := Creatures.world(FIELD, 11, [Vector2i(10, 3)])
	Keen4Inchworm.spawn(world, Vector2i(12, 5), Keen4Sprites.all())
	var worm := Creatures.first(world, Keen4Inchworm) as Keen4Inchworm
	var keen := world.player() as GalaxyKeen
	worm.position = keen.position + Vector2i(0, 0x100)
	worm.reset_box()
	var keep: Array = []
	var shot := Creatures.shoot(world, worm, keep)
	Creatures.wait(world, 3)
	assert_true(not keen.is_dying(), "worms do not hurt Keen")
	assert_true(not shot.spent and worm.is_worm(), "nor does the stunner hurt them")


func test_dart_guns_in_four_directions() -> void:
	var rows: PackedStringArray = [
		"....................",
		"....................",
		"....................",
		"....................",
		"....................",
		"K...................",
		"####################",
	]
	var expected: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
	for aim in 4:
		var world := Creatures.world(rows, 53 + aim, [Vector2i(9, 2)])
		var gun := Creatures.first(world, Keen4DartGun) as Keen4DartGun
		assert_true(gun.hidden, "the gun is part of the tiles")
		var fired := Creatures.run_until(
			world, func() -> bool: return Creatures.count(world, GalaxyEnemyShot) > 0, 80
		)
		assert_true(fired < 80 and fired >= 70, "a dart every 150 tics (%d)" % aim)
		var dart := Creatures.first(world, GalaxyEnemyShot) as GalaxyEnemyShot
		var start := dart.position
		Creatures.wait(world, 1)
		assert_equal(dart.position - start, expected[aim] * 128, "64 a tic (%d)" % aim)
	var hard := Creatures.world(rows, 83, [Vector2i(9, 2)])
	assert_equal(Creatures.count(hard, Keen4DartGun), 0, "info 83 only on Hard")
	var down := Creatures.world(rows, 55, [Vector2i(0, 1)])
	var keen := down.player() as GalaxyKeen
	var hit := Creatures.run_until(down, func() -> bool: return keen.is_dying(), 120)
	assert_true(hit < 120, "a dart kills Keen")
	var gone := Creatures.run_until(
		down, func() -> bool: return Creatures.count(down, GalaxyEnemyShot) == 0, 60
	)
	assert_true(gone < 60, "and is gone at the floor")


static func _fireball(world: GalaxyWorld) -> Keen4Berkeloid:
	for object in world.objects:
		var ball := object as Keen4Berkeloid
		if ball != null and ball.is_fireball and not ball.removed:
			return ball
	return null
