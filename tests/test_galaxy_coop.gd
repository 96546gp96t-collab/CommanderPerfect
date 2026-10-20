extends "res://tests/test_case.gd"
## Tests for two Keens in one Galaxy level (milestone D12), in hand-made
## mini levels (tests/galaxy_keen_fixtures.gd, tests/galaxy_coop_fixtures.gd;
## nothing from the game files): alone the world is the original's; the
## second Keen is the second object and a player; each Keen has his own
## buttons and his own poles, ledges and doors; items and drops are shared;
## deadly tiles, falling out of the map and creatures kill either; the two
## Keens never hurt or block each other; creatures wake in either view and
## go after the nearest living Keen; each Keen rides platforms and shoots
## with the shared charges.

const Fixtures := preload("res://tests/galaxy_keen_fixtures.gd")
const Coop := preload("res://tests/galaxy_coop_fixtures.gd")
const Creatures := preload("res://tests/keen4_creature_fixtures.gd")

const TILE := 256
const SLUG := 22
const PLATFORM_RIGHT := 28
const FALLING := 32
const FIELD: PackedStringArray = [
	"....................",
	"....................",
	"....................",
	"K...................",
	"####################",
]
## Wider than two views: the Keens can be out of each other's sight.
const LONG_ROWS := 90
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

## Shot actions stay alive while a test runs.
var _keep: Array = []


func test_alone_there_is_one_player() -> void:
	var world := Fixtures.world(FIELD)
	assert_true(world.partner == null and world.partner_camera == null, "no partner")
	assert_equal(world.players(), [world.player()] as Array[GalaxyObject], "one Keen")
	var slug := Creatures.place_more(world, SLUG, Vector2i(10, 3))
	assert_true(world.nearest_player(slug.position) == world.player(), "creatures go after him")
	assert_true(not world.is_player(slug), "a slug is no player")


func test_the_partner_is_the_second_object_and_a_player() -> void:
	var world := Creatures.world(FIELD, SLUG, [Vector2i(12, 3)])
	var partner := Coop.add_partner(world, Vector2i(5, 3))
	assert_true(world.objects[1] == partner, "right after player 1")
	assert_true(world.partner == partner, "the world's partner")
	assert_true(world.is_player(partner) and world.is_player(world.player()), "both play")
	assert_equal(world.players().size(), 2, "two Keens")
	assert_true(partner.inventory == (world.player() as GalaxyKeenBody).inventory, "shared")
	world.remove_partner()
	assert_equal(world.players().size(), 1, "he left")
	assert_true(not world.objects.has(partner), "out of the world")


func test_each_keen_steers_his_own() -> void:
	var world := Fixtures.world(FIELD)
	var keen := world.player() as GalaxyKeen
	var partner := Coop.add_partner(world, Vector2i(8, 3))
	Coop.hold(world, 3, Coop.still(), Coop.still())
	var first := keen.position.x
	var second := partner.position.x
	Coop.hold(world, 20, Coop.still(), Fixtures.press(1))
	assert_equal(keen.position.x, first, "player 1 stands still")
	assert_true(partner.position.x > second, "player 2 walks right")
	# His last step ends after he lets go, as alone.
	Coop.hold(world, 4, Coop.still(), Coop.still())
	second = partner.position.x
	Coop.hold(world, 20, Fixtures.press(1), Coop.still())
	assert_true(keen.position.x > first, "player 1 walks")
	assert_equal(partner.position.x, second, "player 2 stands still")


func test_each_keen_climbs_his_own_pole() -> void:
	var rows: PackedStringArray = [
		"..............",
		"..|......|....",
		"..|......|....",
		"..|......|....",
		"..|......|....",
		"..P......|....",
		"##o######o####",
		"..|......|....",
		"..|......|....",
		"##############",
	]
	var world := Fixtures.world(rows)
	var keen := world.player() as GalaxyKeen
	var partner := Coop.add_partner(world, Vector2i(9, 5))
	Coop.hold(world, 1, Fixtures.press(0, -1), Fixtures.press(0, -1))
	assert_equal(keen.action.name, &"pole", "player 1 grabs his pole")
	assert_equal(partner.action.name, &"pole", "player 2 grabs his")
	assert_equal(partner.position.x - keen.position.x, 7 * TILE, "each on his own pole")
	var first := keen.position.y
	var second := partner.position.y
	Coop.hold(world, 8, Fixtures.press(0, -1), Fixtures.press(0, 1))
	assert_true(keen.position.y < first, "player 1 climbs up")
	assert_true(partner.position.y > second, "player 2 slides down")
	Coop.hold(world, 6, Coop.still(), Coop.still())
	Coop.hold(world, 1, Coop.still(), Fixtures.press(1, 0, true))
	assert_equal(partner.action.name, &"jump_1", "player 2 jumps off")
	assert_true(keen.action.name.begins_with("pole"), "player 1 stays on his")


func test_player_2_hangs_on_a_ledge_and_pulls_up() -> void:
	var rows: PackedStringArray = [
		"..................",
		"..................",
		"######............",
		"######............",
		"######............",
		"######............",
		"######........K...",
		"##################",
	]
	var world := Fixtures.world(rows)
	var keen := world.player() as GalaxyKeen
	var partner := Coop.add_partner(world, Vector2i(7, 6), -1)
	var hung := false
	for frame in 60:
		var climb := Fixtures.press(-1, 0, frame < 20)
		Coop.hold(world, 1, Coop.still(), climb)
		if partner.action.name.begins_with("hang"):
			hung = true
			break
	assert_true(hung, "player 2 hangs on the ledge")
	Coop.hold(world, 10, Coop.still(), Coop.still())
	assert_equal(partner.action.name, &"hang_2", "and keeps hanging")
	Coop.hold(world, 1, Coop.still(), Fixtures.press(0, -1))
	assert_equal(partner.action.name, &"pull_1", "his up pulls him up")
	Coop.hold(world, 40, Coop.still(), Coop.still())
	assert_equal(partner.action.name, &"stand", "onto the ledge")
	assert_equal(partner.box.bottom, 4 * TILE - 1, "on the wall's top")
	assert_equal(keen.box.bottom, 9 * TILE - 1, "player 1 still on the floor")


func test_player_2_goes_through_a_door_alone() -> void:
	var rows: PackedStringArray = [
		"....................",
		"..dd................",
		"..........k......K..",
		"####################",
		"....................",
		"....................",
		"####################",
	]
	var world := Fixtures.world(rows)
	# The info plane's K is player 1; the k marks where player 2 starts.
	Fixtures.put_info(world.map, Vector2i(10, 2), 0)
	Fixtures.put_info(world.map, Vector2i(2, 1), (15 << 8) | 7)
	var keen := world.player() as GalaxyKeen
	var partner := Coop.add_partner(world, Vector2i(10, 2), -1)
	var spot := keen.position
	for frame in 60:
		if partner.box.tile_middle == 5:
			break
		Coop.hold(world, 1, Coop.still(), Fixtures.press(-1))
	Coop.hold(world, 1, Coop.still(), Coop.still())
	Coop.hold(world, 1, Coop.still(), Fixtures.press(0, -1))
	Coop.hold(world, 40, Coop.still(), Coop.still())
	assert_equal(partner.position, Vector2i(15 * TILE, 7 * TILE - TILE + 15), "at the target")
	assert_equal(keen.position, spot, "player 1 stays where he was")


func test_items_and_drops_taken_by_player_2_count_for_both() -> void:
	var world := Fixtures.world(["K.........", "......$+*.", "##########"])
	var keen := world.player() as GalaxyKeen
	var lives := keen.inventory.lives
	var partner := Coop.add_partner(world, Vector2i(4, 1))
	Coop.hold(world, 25, Coop.still(), Fixtures.press(1))
	assert_equal(keen.inventory.score, 100, "the 100 points")
	assert_equal(keen.inventory.lives, lives + 1, "the extra life")
	assert_equal(keen.inventory.drops, 1, "the drop")
	assert_true(partner.inventory == keen.inventory, "one inventory")
	for x in [8, 9, 10]:
		assert_equal(world.fore_tile(x, 3), Fixtures.EMPTY, "taken (%d)" % x)


func test_a_deadly_tile_kills_player_2_only() -> void:
	var world := Fixtures.world(["K.........", "......X...", "##########"])
	var keen := world.player() as GalaxyKeen
	var partner := Coop.add_partner(world, Vector2i(3, 1))
	Coop.hold(world, 20, Coop.still(), Fixtures.press(1))
	assert_true(partner.is_dying(), "player 2 dies")
	assert_true(not keen.is_dying(), "player 1 lives")


func test_falling_out_of_the_map_kills_player_2() -> void:
	var world := Fixtures.world(FIELD)
	var keen := world.player() as GalaxyKeen
	var partner := Coop.add_partner(world, Vector2i(8, 3))
	Coop.hold(world, 2, Coop.still(), Coop.still())
	partner.clip = GalaxyObject.Clip.NONE
	partner.position.y = (world.map.height - 1) * TILE
	partner.reset_box()
	Coop.hold(world, 1, Coop.still(), Coop.still())
	# Omni: falling out of the map loses the level at once.
	assert_equal(world.state, GalaxyWorld.LevelState.DIED, "he falls out: the attempt is lost")
	assert_true(not keen.is_dying(), "player 1 did not die")


func test_the_two_keens_never_hurt_or_block_each_other() -> void:
	var world := Fixtures.world(FIELD)
	var keen := world.player() as GalaxyKeen
	var partner := Coop.add_partner(world, Vector2i(0, 3))
	Coop.hold(world, 40, Coop.still(), Coop.still())
	assert_true(not keen.is_dying() and not partner.is_dying(), "both alive on one spot")
	assert_equal(keen.inventory.score, 0, "nothing scored")
	var start := keen.position.x
	Coop.hold(world, 20, Fixtures.press(1), Fixtures.press(1))
	assert_true(keen.position.x > start, "player 1 walks through")
	assert_equal(partner.position.x, keen.position.x, "side by side, not pushed")
	Coop.hold(world, 20, Fixtures.press(0, 0, true), Coop.still())
	assert_true(not partner.is_dying(), "jumping beside him is harmless")


func test_a_slug_kills_player_2() -> void:
	var world := Creatures.world(FIELD, SLUG, [Vector2i(14, 3)])
	var keen := world.player() as GalaxyKeen
	var partner := Coop.add_partner(world, Vector2i(8, 3))
	var slug := Creatures.first(world, Keen4Slug) as Keen4Slug
	slug.position = partner.position
	slug.reset_box()
	Coop.hold(world, 1, Coop.still(), Coop.still())
	assert_true(partner.is_dying(), "the slug kills player 2")
	assert_true(not keen.is_dying(), "not player 1")


func test_creatures_go_after_the_nearest_living_keen() -> void:
	var world := Creatures.world(FIELD, SLUG, [Vector2i(10, 3)])
	var keen := world.player() as GalaxyKeen
	var slug := Creatures.first(world, Keen4Slug) as GalaxyCreature
	var partner := Coop.add_partner(world, Vector2i(16, 3))
	assert_true(world.nearest_player(slug.position) == partner, "player 2 is nearer")
	assert_equal(slug.side_of_player(), 1, "to its right")
	partner.kill()
	assert_true(world.nearest_player(slug.position) == keen, "a dying Keen is not chased")
	assert_equal(slug.side_of_player(), -1, "player 1 to its left")


func test_a_creature_wakes_in_player_2s_view() -> void:
	var alone := _long_world(false)
	var lone_slug := Creatures.first(alone, Keen4Slug)
	var lone_x := lone_slug.position.x
	Creatures.wait(alone, 10)
	assert_equal(lone_slug.position.x, lone_x, "alone: far from the view it sleeps")
	var world := _long_world(true)
	var slug := Creatures.first(world, Keen4Slug)
	var x := slug.position.x
	Coop.hold(world, 10, Coop.still(), Coop.still())
	assert_true(slug.position.x != x, "in player 2's view it crawls")
	assert_true(world.on_screen(slug), "on a screen")
	assert_true(world.on_own_screen(world.partner), "player 2 in his own view")
	assert_true(world.on_own_screen(world.player()), "player 1 in his")
	world.partner_camera.centre_on(0, world.player().box.bottom)
	assert_true(not world.on_own_screen(world.partner), "out of his own view when it moves off")


func test_player_2_rides_a_platform() -> void:
	var world := Creatures.world(SPACE, PLATFORM_RIGHT, [Vector2i(3, 4)])
	Fixtures.put_info(world.map, Vector2i(12, 4), GalaxyPlatform.TURN_POINT)
	var platform := Creatures.first(world, Keen4Platform) as Keen4Platform
	var partner := Coop.add_partner(world, Vector2i(15, 10))
	_drop_onto(world, partner, platform)
	assert_true(partner.platform == platform, "player 2 lands on it")
	var keen := world.player() as GalaxyKeen
	assert_true(keen.platform == null, "player 1 is not on it")
	Coop.hold(world, 2, Coop.still(), Coop.still())
	var keen_x := partner.position.x
	var platform_x := platform.position.x
	Coop.hold(world, 10, Coop.still(), Coop.still())
	assert_true(
		absi((partner.position.x - keen_x) - (platform.position.x - platform_x)) <= 0x1F,
		"he moves with it"
	)
	Coop.hold(world, 1, Coop.still(), Fixtures.press(0, 0, true))
	Coop.hold(world, 3, Coop.still(), Coop.still())
	assert_true(partner.platform == null, "his jump takes him off")


func test_the_falling_platform_sinks_under_player_2() -> void:
	var world := Creatures.world(SPACE, FALLING, [Vector2i(3, 4)])
	Fixtures.put_info(world.map, Vector2i(3, 9), GalaxyPlatform.TURN_POINT)
	var platform := Creatures.first(world, GalaxyFallingPlatform) as GalaxyFallingPlatform
	var partner := Coop.add_partner(world, Vector2i(15, 10))
	Coop.hold(world, 5, Coop.still(), Coop.still())
	var home := platform.position.y
	_drop_onto(world, partner, platform)
	assert_true(partner.platform == platform, "player 2 lands on it")
	Coop.hold(world, 2, Coop.still(), Coop.still())
	assert_true(platform.position.y > home, "it sinks under him")


func test_player_2_shoots_with_the_shared_charges() -> void:
	var world := Fixtures.world(FIELD)
	var keen := world.player() as GalaxyKeen
	var partner := Coop.add_partner(world, Vector2i(8, 3))
	Coop.hold(world, 3, Coop.still(), Coop.still())
	var shots := keen.inventory.shots
	Coop.hold(world, 1, Coop.still(), KeenInput.create(0, false, false, true))
	Coop.hold(world, 4, Coop.still(), Coop.still())
	assert_equal(keen.inventory.shots, shots - 1, "one charge less for both")
	assert_equal(Creatures.count(world, GalaxyStunnerShot), 1, "his shot flies")
	var shot := Creatures.first(world, GalaxyStunnerShot)
	assert_true(absi(shot.position.x - partner.position.x) < 4 * TILE, "from player 2")


## A level wider than two views: player 1 at its left end, a slug near its
## right end, and (with [param two]) player 2 beside the slug.
func _long_world(two: bool) -> GalaxyWorld:
	var rows: PackedStringArray = []
	for y in 4:
		rows.append(("K" if y == 3 else ".") + ".".repeat(LONG_ROWS - 1))
	rows.append("#".repeat(LONG_ROWS))
	var world := Creatures.world(rows, SLUG, [Vector2i(LONG_ROWS - 6, 3)])
	world.camera = Coop.wide_camera(world.map)
	var keen := world.player() as GalaxyKeen
	world.camera.centre_on(keen.position.x, keen.box.bottom)
	if two:
		var partner := Coop.add_partner(world, Vector2i(LONG_ROWS - 14, 3))
		world.partner_camera = Coop.wide_camera(world.map)
		world.partner_camera.centre_on(partner.position.x, partner.box.bottom)
	return world


func _drop_onto(world: GalaxyWorld, keen: GalaxyKeen, carrier: GalaxyObject) -> void:
	keen.position = Vector2i(carrier.box.left, carrier.box.top - 496 - 40)
	keen.reset_box()
	keen.set_action(keen.actions[&"fall_1"])
	for frame in 30:
		Coop.hold(world, 1, Coop.still(), Coop.still())
		if keen.platform == carrier:
			return
