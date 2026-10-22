extends "res://tests/test_case.gd"
## Checks Keen 4's ground creatures in hand-made mini levels (milestone
## D5): the slug, the Mad Mushroom, the egg and the bird, the Arachnut, the
## Skypest, the Wormmouth and the cloud: where the info plane puts them on
## each difficulty, how they move, what the stunner does and what kills
## Keen (Omni numbers; docs/keen4/research.md §6 and §7).

const Fixtures := preload("res://tests/galaxy_keen_fixtures.gd")
const Creatures := preload("res://tests/keen4_creature_fixtures.gd")

const TILE := 256
## A floor with Keen at the far left and room for a creature.
const FIELD: PackedStringArray = [
	"....................",
	"....................",
	"....................",
	"K...................",
	"####################",
]

## Shot actions stay alive while a test runs.
var _keep: Array = []


func test_info_values_and_difficulty() -> void:
	var cell: Array[Vector2i] = [Vector2i(10, 3)]
	for value in [22, 43, 44]:
		var counts: Array[int] = []
		for level in [GalaxyDifficulty.Level.EASY, GalaxyDifficulty.Level.NORMAL, 2]:
			var world := Creatures.world(FIELD, value, cell, level)
			counts.append(Creatures.count(world, Keen4Slug))
		var expected: Array[int] = [1, 1, 1]
		if value == 43:
			expected = [0, 1, 1]
		elif value == 44:
			expected = [0, 0, 1]
		assert_equal(counts, expected, "slug info %d on Easy, Normal, Hard" % value)
	var normal := Creatures.world(FIELD, 77, cell)
	assert_equal(Creatures.count(normal, Keen4Bird), 1, "a bird from Normal on")
	var easy := Creatures.world(FIELD, 77, cell, GalaxyDifficulty.Level.EASY)
	assert_equal(Creatures.count(easy, Keen4Bird), 0, "no bird on Easy")
	assert_equal(GalaxyDifficulty.DEFAULT, GalaxyDifficulty.Level.NORMAL, "Normal for now")


func test_slug_crawls_turns_and_kills() -> void:
	var rows: PackedStringArray = [
		"....................",
		"K..................#",
		"####################",
	]
	var world := Creatures.world(rows, 22, [Vector2i(14, 1)])
	var slug := Creatures.first(world, Keen4Slug) as Keen4Slug
	assert_equal(slug.position.y, (1 + 2) * TILE - Keen4Slug.RISE, "placed 0x71 above its tile")
	var start := slug.position.x
	Creatures.wait(world, 8)
	assert_true(slug.position.x != start, "it crawls")
	assert_equal(absi(slug.position.x - start) % 64, 0, "64 units a step")
	slug.direction.x = 1
	var turned := false
	var facing := slug.direction.x
	for frame in 200:
		Creatures.wait(world, 1)
		if slug.direction.x != facing:
			turned = true
			break
	assert_true(turned, "it turns at the wall or edge")
	var keen := world.player() as GalaxyKeen
	slug.position = keen.position
	slug.reset_box()
	Creatures.wait(world, 1)
	assert_true(keen.is_dying(), "touching the slug kills Keen")


func test_slug_slime_and_stun() -> void:
	var world := Creatures.world(FIELD, 22, [Vector2i(14, 3)])
	var slug := Creatures.first(world, Keen4Slug) as Keen4Slug
	var slimed := Creatures.run_until(world, func() -> bool: return _slime(world) != null, 3000)
	assert_true(slimed < 3000, "it leaves slime now and then")
	var slime := _slime(world)
	assert_equal(slime.action.timer, 300, "the slime kills for 300 tics")
	assert_equal(slime.action.contact, &"_contact_lethal", "it kills")
	assert_equal(slime.action.next.timer, 60, "then fades for 60")
	Creatures.shoot(world, slug, _keep)
	Creatures.wait(world, 2)
	assert_true(slug.stunned, "the shot stuns it")
	assert_true(slug.action.name.begins_with("stunned"), "its stunned action")
	Creatures.wait(world, 40)
	assert_true(slug.overlays.size() == 1, "stars over it")
	assert_true(
		slug.overlays[0].sprite in [40, 41, 42], "the three star sprites (Omni SPR_STARS1-3)"
	)
	assert_equal(slug.overlays[0].offset, Keen4Slug.STARS, "half a tile higher")
	var before := slug.position
	Creatures.wait(world, 300)
	assert_true(slug.stunned and slug.position == before, "it stays stunned")


func test_mushroom_hops_twice_then_leaps() -> void:
	var world := Creatures.world(FIELD, 21, [Vector2i(10, 3)])
	var mushroom := Creatures.first(world, Keen4Mushroom) as Keen4Mushroom
	var speeds: Array[int] = []
	for frame in 300:
		var before := mushroom.velocity.y
		Creatures.wait(world, 1)
		if mushroom.velocity.y < before and mushroom.velocity.y < 0 and before >= 0:
			speeds.append(mushroom.velocity.y)
	assert_true(speeds.size() >= 3, "it bounces")
	assert_true(-68 in speeds and -40 in speeds, "hops of -40 and a leap of -68")
	assert_equal(mushroom.direction.x, -1, "it faces Keen")
	var keep: Array = []
	var shot := Creatures.shoot(world, mushroom, keep)
	Creatures.wait(world, 2)
	assert_true(shot.spent and not mushroom.stunned, "the stunner does nothing")
	var keen := world.player() as GalaxyKeen
	mushroom.position = keen.position
	mushroom.reset_box()
	Creatures.wait(world, 1)
	assert_true(keen.is_dying(), "touching it kills Keen")


func test_egg_hatches_a_bird_that_walks_to_keen() -> void:
	var world := Creatures.world(FIELD, 13, [Vector2i(8, 3)])
	var egg := Creatures.first(world, Keen4Egg) as Keen4Egg
	assert_equal(Creatures.count(world, Keen4Bird), 0, "an egg, no bird yet")
	Creatures.shoot(world, egg, _keep)
	Creatures.wait(world, 2)
	assert_true(egg.broken, "the shot breaks it")
	var bird := Creatures.first(world, Keen4Bird) as Keen4Bird
	assert_true(bird != null, "the bird hatches")
	assert_equal(bird.direction.x, -1, "facing Keen")
	assert_equal(Creatures.count(world, Keen4Egg), 4, "the shell and three bits")
	var start := bird.position.x
	Creatures.wait(world, 55)
	assert_equal(bird.position.x, start, "it stands 120 tics")
	Creatures.wait(world, 30)
	assert_true(bird.position.x < start, "then walks to Keen")
	Creatures.shoot(world, bird, _keep)
	Creatures.wait(world, 2)
	assert_true(bird.stunned and bird.action.name == &"stunned", "stunned")
	Creatures.wait(world, 120 + 40 + 2)
	assert_true(
		not bird.stunned and bird.action.name.begins_with("walk"), "after 320 tics it walks"
	)


func test_bird_flies_up_to_keen() -> void:
	var rows: PackedStringArray = [
		"....................",
		"K.......############",
		"########............",
		"....................",
		"....................",
		"....................",
		"####################",
	]
	var world := Creatures.world(rows, 77, [Vector2i(14, 5)])
	var bird := Creatures.first(world, Keen4Bird) as Keen4Bird
	var flew := Creatures.run_until(
		world, func() -> bool: return bird.action.name.begins_with("fly"), 400
	)
	assert_true(flew < 400, "Keen 3+ tiles higher: it flies")
	assert_equal(bird.clip, GalaxyObject.Clip.SIMPLE, "with a plain box")
	Creatures.wait(world, 40)
	assert_true(absi(bird.velocity.x) <= 16 and absi(bird.velocity.y) <= 16, "at most 16")


func test_arachnut_runs_kills_and_recovers() -> void:
	var world := Creatures.world(FIELD, 20, [Vector2i(14, 3)])
	var nut := Creatures.first(world, Keen4Arachnut) as Keen4Arachnut
	assert_equal(nut.position.y, (3 + 2) * TILE - Keen4Arachnut.RISE, "placed 0x171 above")
	Creatures.wait(world, 24)
	assert_equal(nut.direction.x, -1, "it turns to Keen")
	Creatures.shoot(world, nut, _keep)
	Creatures.wait(world, 2)
	assert_true(nut.stunned, "stunned")
	assert_true(nut.overlays.is_empty(), "no stars")
	var keen := world.player() as GalaxyKeen
	Creatures.wait(world, 100)
	assert_true(nut.action.name.begins_with("stunned"), "240 tics")
	Creatures.wait(world, 60)
	assert_true(nut.action.name.begins_with("run"), "then 80 tics blinking, then it runs")
	nut.position = keen.position
	nut.reset_box()
	Creatures.wait(world, 1)
	assert_true(keen.is_dying(), "a running Arachnut kills Keen")


func test_skypest_dies_only_under_the_pogo() -> void:
	var rows: PackedStringArray = [
		"....................",
		"....................",
		"K...................",
		"####################",
	]
	var world := Creatures.world(rows, 8, [Vector2i(12, 2)])
	var pest := Creatures.first(world, Keen4Skypest) as Keen4Skypest
	var shot := Creatures.shoot(world, pest, _keep)
	Creatures.wait(world, 1)
	assert_true(shot.spent and not pest.squashed, "a shot only pushes it")
	assert_true(pest.velocity.x >= Keen4Skypest.SPEED - 4, "20 in the shot's way")
	var landed := Creatures.run_until(
		world, func() -> bool: return pest.action.name.begins_with("preen"), 3000
	)
	assert_true(landed < 3000, "it lands and preens")
	var keen := world.player() as GalaxyKeen
	keen.position = pest.position
	keen.reset_box()
	Creatures.wait(world, 1)
	assert_true(not keen.is_dying() and not pest.squashed, "walking into it does nothing")
	keen.position = Vector2i(pest.position.x - 64, pest.box.top - 2 * TILE)
	keen.reset_box()
	keen.set_action(keen.actions[&"pogo_2"])
	keen.velocity = Vector2i.ZERO
	var squashed := Creatures.run_until(world, func() -> bool: return pest.squashed, 60)
	assert_true(squashed < 60, "landing on it on the pogo stick squashes it")
	assert_equal(pest.action.name, &"squashed", "for good")


func test_wormmouth_hides_and_bites_in_front() -> void:
	var world := Creatures.world(FIELD, 7, [Vector2i(16, 3)])
	var worm := Creatures.first(world, Keen4Wormmouth) as Keen4Wormmouth
	assert_equal(worm.position.y, (3 + 2) * TILE + Keen4Wormmouth.DROP, "in the ground")
	var keep: Array = []
	var shot := Creatures.shoot(world, worm, keep)
	Creatures.wait(world, 2)
	assert_true(not worm.stunned and not shot.spent, "as a mound nothing hurts it")
	var keen := world.player() as GalaxyKeen
	var bit := Creatures.run_until(
		world, func() -> bool: return worm.action.name.begins_with("bite"), 2000
	)
	assert_true(bit < 2000, "it comes to Keen and bites")
	Creatures.wait(world, 10)
	assert_true(keen.is_dying(), "the bite kills Keen in front of it")


func test_cloud_wakes_and_strikes() -> void:
	var rows: PackedStringArray = [
		"....................",
		"....................",
		"....................",
		"....................",
		"K...................",
		"####################",
	]
	var world := Creatures.world(rows, 9, [Vector2i(0, 0)])
	var cloud := Creatures.first(world, Keen4Cloud) as Keen4Cloud
	Creatures.wait(world, 30)
	assert_true(not cloud.is_awake_cloud(), "asleep until Keen touches it")
	var keen := world.player() as GalaxyKeen
	keen.god_mode = true
	cloud._contact_cloud(keen)
	assert_equal(cloud.action.name, &"waking", "Keen wakes it")
	var struck := Creatures.run_until(world, func() -> bool: return _bolt(world) != null, 600)
	assert_true(struck < 600, "over Keen it strikes")
	assert_equal(cloud.position.x & Keen4Cloud.GRID_MASK, 0, "lined up on 8 pixels")
	var bolt := _bolt(world)
	assert_equal(bolt.action.contact, &"_contact_lethal", "the bolt kills")
	var keep: Array = []
	var shot := Creatures.shoot(world, cloud, keep)
	Creatures.wait(world, 2)
	assert_true(not shot.spent, "the stunner flies through a cloud")


static func _slime(world: GalaxyWorld) -> GalaxyObject:
	for object in world.objects:
		if object.action != null and object.action.name == &"slime_1" and not object.removed:
			return object
	return null


static func _bolt(world: GalaxyWorld) -> GalaxyObject:
	for object in world.objects:
		if object.action != null and object.action.name.begins_with("bolt") and not object.removed:
			return object
	return null
