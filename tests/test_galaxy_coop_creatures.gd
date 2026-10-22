extends "res://tests/test_case.gd"
## Tests for Keen 4's creatures and people with two Keens (milestone D12),
## in hand-made mini levels (tests/keen4_creature_fixtures.gd,
## tests/galaxy_coop_fixtures.gd; nothing from the game files): they go
## after the nearer Keen and can kill either (Berkeloid, Lick, Mimrock,
## cloud, Dopefish, mine), player 2 rides and steers a Bounder, rescues a
## council member, takes the wetsuit and hears Lindsey; under water two
## Keens swim.

const Fixtures := preload("res://tests/galaxy_keen_fixtures.gd")
const Creatures := preload("res://tests/keen4_creature_fixtures.gd")
const Coop := preload("res://tests/galaxy_coop_fixtures.gd")

const TILE := 256
const BERKELOID := 5
const LINDSEY := 6
const COUNCIL := 4
const CLOUD := 9
const BOUNDER := 12
const LICK := 14
const DOPEFISH := 15
const SCHOOLFISH := 16
const MIMROCK := 19
const WETSUIT := 35
const MINE_DOWN := 71
const WALK_FRAMES := 60
## Player 1 at the far left, room on the right.
const FIELD: PackedStringArray = [
	"..............................",
	"..............................",
	"..............................",
	"K.............................",
	"##############################",
]
const WATER: PackedStringArray = [
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
	"..............................",
	"..............................",
]

var _keep: Array = []


func test_a_berkeloid_kills_player_2() -> void:
	var world := Creatures.world(FIELD, BERKELOID, [Vector2i(20, 3)])
	var partner := Coop.add_partner(world, Vector2i(14, 3))
	var berk := Creatures.first(world, Keen4Berkeloid)
	berk.position = partner.position
	berk.reset_box()
	Coop.hold(world, 1, Coop.still(), Coop.still())
	assert_true(partner.is_dying(), "touching it kills player 2")
	assert_true(not (world.player() as GalaxyKeen).is_dying(), "not player 1")


func test_a_lick_hops_to_the_nearer_keen_and_burns_him() -> void:
	var world := Creatures.world(FIELD, LICK, [Vector2i(16, 3)])
	var lick := Creatures.first(world, Keen4Lick) as Keen4Lick
	var partner := Coop.add_partner(world, Vector2i(25, 3), -1)
	var start := lick.position.x
	Coop.hold(world, 60, Coop.still(), Coop.still())
	assert_true(lick.position.x > start, "it hops right, to player 2")
	var keen := world.player() as GalaxyKeen
	for frame in 600:
		Coop.hold(world, 1, Coop.still(), Coop.still())
		if partner.is_dying():
			break
	assert_true(partner.is_dying(), "its flame kills player 2")
	assert_true(not keen.is_dying(), "player 1 far away lives")


func test_a_mimrock_sneaks_after_the_nearer_keen() -> void:
	var world := Creatures.world(FIELD, MIMROCK, [Vector2i(18, 3)])
	var rock := Creatures.first(world, Keen4Mimrock) as Keen4Mimrock
	var keen := world.player() as GalaxyKeen
	keen.direction.x = -1
	var partner := Coop.add_partner(world, Vector2i(24, 3))
	partner.direction.x = -1
	var start := rock.position.x
	Coop.hold(world, 30, Coop.still(), Coop.still())
	assert_equal(rock.position.x, start, "player 2 looks at it: it sits")
	partner.direction.x = 1
	var sneaking := false
	for frame in 60:
		Coop.hold(world, 1, Coop.still(), Coop.still())
		if rock.action.name.begins_with("sneak"):
			sneaking = true
			break
	assert_true(sneaking, "player 2 looks away: it sneaks")
	Coop.hold(world, 4, Coop.still(), Coop.still())
	assert_true(rock.position.x > start, "toward player 2")


func test_the_cloud_strikes_over_player_2() -> void:
	var rows: PackedStringArray = [
		"..............................",
		"..............................",
		"..............................",
		"..............................",
		"K.............................",
		"##############################",
	]
	var world := Creatures.world(rows, CLOUD, [Vector2i(20, 0)])
	var cloud := Creatures.first(world, Keen4Cloud) as Keen4Cloud
	var partner := Coop.add_partner(world, Vector2i(22, 4))
	partner.god_mode = true
	cloud._contact_cloud(partner)
	assert_equal(cloud.action.name, &"waking", "player 2 wakes it")
	var struck := -1
	for frame in 600:
		Coop.hold(world, 1, Coop.still(), Coop.still())
		var bolt := _bolt(world)
		if bolt != null:
			struck = bolt.position.x
			break
	assert_true(struck >= 0, "it strikes")
	assert_true(absi(struck - partner.position.x) < 3 * TILE, "over player 2, not player 1")


func test_player_2_rides_and_steers_a_bounder() -> void:
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
	var world := Creatures.world(rows, BOUNDER, [Vector2i(10, 8)])
	var ball := Creatures.first(world, Keen4Bounder) as Keen4Bounder
	var partner := Coop.add_partner(world, Vector2i(20, 8))
	Coop.hold(world, 30, Coop.still(), Coop.still())
	partner.position = Vector2i(ball.box.left - 64, ball.box.top - 3 * TILE)
	partner.reset_box()
	partner.set_action(partner.actions[&"fall_1"])
	partner.velocity = Vector2i.ZERO
	var landed := 0
	while partner.platform != ball and landed < 200:
		partner.position.x = ball.box.left - 64
		Coop.hold(world, 1, Coop.still(), Coop.still())
		landed += 1
	assert_true(landed < 200, "player 2 lands on it and rides it")
	assert_true(not partner.is_dying(), "it never hurts him")
	partner.position.x = ball.box.right - 100
	partner.reset_box()
	var steered := false
	for frame in 120:
		Coop.hold(world, 1, Coop.still(), Coop.still())
		if ball.direction.x == 1:
			steered = true
			break
	assert_true(steered, "on its right side he steers it right")


func test_player_2_rescues_a_council_member() -> void:
	var world := Creatures.world(FIELD, COUNCIL, [Vector2i(16, 3)])
	Coop.add_partner(world, Vector2i(12, 3))
	Coop.hold(world, WALK_FRAMES, Coop.still(), Fixtures.press(1))
	assert_equal(world.state, GalaxyWorld.LevelState.COMPLETED, "the level is done")
	assert_equal(world.ending, Keen4Council.RESCUED, "by player 2's rescue")


func test_player_2_takes_the_wetsuit() -> void:
	var world := Creatures.world(FIELD, WETSUIT, [Vector2i(18, 3)])
	Coop.add_partner(world, Vector2i(14, 3))
	Coop.hold(world, WALK_FRAMES, Coop.still(), Fixtures.press(1))
	assert_equal(world.state, GalaxyWorld.LevelState.COMPLETED, "taking it ends the level")
	assert_equal(world.ending, Keen4Wetsuit.TAKEN, "with the wetsuit")


func test_lindsey_speaks_to_player_2() -> void:
	var world := Creatures.world(FIELD, LINDSEY, [Vector2i(20, 2)])
	var lindsey := Creatures.first(world, Keen4Lindsey) as Keen4Lindsey
	var partner := Coop.add_partner(world, Vector2i(16, 3))
	Coop.hold(world, 2, Coop.still(), Coop.still())
	partner.position = lindsey.position
	partner.reset_box()
	Coop.hold(world, 1, Coop.still(), Coop.still())
	assert_equal(world.conversation, Keen4Lindsey.MESSAGE, "her message")
	assert_equal(world.state, GalaxyWorld.LevelState.PLAYING, "the level goes on")


func test_two_keens_swim() -> void:
	var world := _water()
	var keen := world.player() as Keen4SwimmingKeen
	var partner := Coop.add_swimmer(world, Vector2i(16, 3))
	assert_true(partner is Keen4SwimmingKeen, "player 2 swims too")
	Coop.hold(world, 8, Coop.still(), Coop.still())
	var first := keen.position
	var second := partner.position
	Coop.hold(world, 30, Coop.still(), KeenInput.create(1))
	assert_true(partner.position.x > second.x, "player 2 swims right")
	assert_true(absi(keen.position.x - first.x) < TILE, "player 1 only sinks")
	assert_true(keen.position.y > first.y, "sinking")


func test_the_dopefish_eats_the_nearer_swimmer() -> void:
	var world := _water(DOPEFISH, [Vector2i(20, 8)])
	var keen := world.player() as Keen4SwimmingKeen
	keen.god_mode = false
	var partner := Coop.add_swimmer(world, Vector2i(24, 6))
	for frame in 300:
		Coop.hold(world, 1, Coop.still(), Coop.still())
		if partner.eaten or keen.eaten:
			break
	assert_true(partner.eaten, "it catches player 2")
	assert_true(not keen.eaten, "not player 1")
	for frame in 200:
		Coop.hold(world, 1, Coop.still(), Coop.still())
		if world.state != GalaxyWorld.LevelState.PLAYING:
			break
	assert_equal(world.state, GalaxyWorld.LevelState.DIED, "the attempt is lost for both")


func test_school_fish_follow_the_nearer_swimmer() -> void:
	var world := _water(SCHOOLFISH, [Vector2i(20, 8)])
	var fish := Creatures.first(world, Keen4Schoolfish) as Keen4Schoolfish
	var partner := Coop.add_swimmer(world, Vector2i(26, 8))
	partner.god_mode = true
	var distance := (fish.position - partner.position).length()
	Coop.hold(world, 60, Coop.still(), Coop.still())
	assert_true((fish.position - partner.position).length() < distance, "it comes to player 2")


func test_a_mine_kills_player_2_swimming() -> void:
	var world := _water(MINE_DOWN, [Vector2i(20, 1)])
	var mine := Creatures.first(world, Keen4Mine) as Keen4Mine
	var partner := Coop.add_swimmer(world, Vector2i(24, 3))
	partner.position = mine.position
	partner.reset_box()
	Coop.hold(world, 1, Coop.still(), Coop.still())
	assert_true(partner.is_dying(), "the mine kills player 2")
	assert_true(not (world.player() as Keen4SwimmingKeen).is_dying(), "not player 1")


## Open water with player 1 swimming at the left and [param info] at
## [param cells] (as tests/test_keen4_water.gd).
func _water(info := 0, cells: Array[Vector2i] = []) -> GalaxyWorld:
	var map := Fixtures.level(WATER)
	var world := GalaxyWorld.create(map, Fixtures.tile_info(), Fixtures.sprite_infos())
	world.camera = Fixtures.camera_for(map)
	world.random_table = Creatures.random_table()
	world.map_number = Keen4Messages.UNDER_WATER_LEVEL
	var keen := Keen4SwimmingKeen.spawn(world, Vector2i(4, 5), Keen4Sprites.all())
	keen.inventory = Keen4Inventory.new_game()
	Creatures.give_boxes(world)
	for cell in cells:
		Fixtures.put_info(map, cell, info)
	Keen4Creatures.place_all(world, GalaxyDifficulty.Level.HARD, Keen4Sprites.all())
	return world


static func _bolt(world: GalaxyWorld) -> GalaxyObject:
	for object in world.objects:
		if object.action != null and object.action.name.begins_with("bolt") and not object.removed:
			return object
	return null
