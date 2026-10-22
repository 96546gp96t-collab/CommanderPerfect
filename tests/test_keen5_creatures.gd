extends "res://tests/test_case.gd"
## Checks Keen 5's walking creatures in hand-made mini levels (milestone
## E4; [Keen5Sparky], [Keen5Ampton], [Keen5Shelley], [Keen5Korath],
## [Keen5Slicestar], [Keen5Volteface]; Omni `ck5_obj1.c`, `ck5_obj2.c`,
## `ck5_obj3.c`; docs/keen5/research.md §7): their speeds and timers, what
## kills Keen and what only pushes him, which shots stun and which are
## absorbed, the hit points, and the original's rules kept (the diagonal
## Slicestar never starts right-up). No game files are needed.

const Fixtures := preload("res://tests/keen5_creature_fixtures.gd")
const Keen := preload("res://tests/galaxy_keen_fixtures.gd")

const TILE := 256
const FRAME_TICS := 2
## Info values (Omni).
const SPARKY := 4
const SLICESTAR_UP := 10
const SLICESTAR_DIAGONAL := 19
const SLICESTAR_RIGHT := 22
const B_BLOCK := 31
const AMPTON := 42
const VOLTEFACE := 71
const SHELLEY := 74
const KORATH := 124
const ARROW_RIGHT := 92
const ARROW_DOWN := 93
const ARROW_LEFT := 94
const ARROW_UP := 91
## A long corridor with Keen far right.
const CORRIDOR: PackedStringArray = [
	"..............................",
	"..............................",
	"..............................",
	"............................K.",
	"##############################",
]


func test_a_sparky_walks_16_a_tic_and_turns_at_a_wall() -> void:
	var world := Fixtures.world(CORRIDOR, SPARKY, [Vector2i(10, 3)] as Array[Vector2i])
	var sparky := Fixtures.first(world, Keen5Sparky) as Keen5Sparky
	assert_equal(sparky.box.bottom, 6 * TILE - 1, "it stands on the floor")
	var steps := _walk_steps(world, sparky, &"walk_", 40)
	assert_true(not steps.is_empty(), "it walks")
	for step in steps:
		assert_equal(absi(step), 128, "128 units a step")
	assert_equal(sparky.actions[&"walk_1"].timer, 8, "a step every 8 tics: 16 a tic")
	# Walking left it reaches the wall and turns round.
	sparky.direction.x = -1
	var turned := Fixtures.run_until(
		world, func() -> bool: return sparky.action.name.begins_with("turn"), 200
	)
	assert_true(turned < 200, "it turns at the wall")


func test_a_sparky_sees_keen_and_charges_at_32_a_tic() -> void:
	var sounds: Array[StringName] = []
	var world := Fixtures.world(
		CORRIDOR, SPARKY, [Vector2i(10, 3)] as Array[Vector2i], GalaxyDifficulty.DEFAULT, sounds
	)
	var sparky := Fixtures.first(world, Keen5Sparky) as Keen5Sparky
	Fixtures.keen(world).god_mode = true
	sparky.direction.x = 1
	sparky.set_action(sparky.actions[&"search_1"])
	var charging := Fixtures.run_until(
		world, func() -> bool: return sparky.action.name.begins_with("charge"), 120
	)
	assert_true(charging < 120, "Keen at its height to the right: it charges")
	assert_true(sounds.has(&"sparky_prepare_charge"), "with its sound")
	assert_equal(sparky.direction.x, 1, "towards Keen")
	var steps := _walk_steps(world, sparky, &"charge_", 8)
	for step in steps:
		assert_equal(step, 128, "128 units every 4 tics: 32 a tic")
	assert_true(sounds.has(&"keen_walk_1"), "its footsteps")


func test_a_sparky_does_not_see_keen_above_it() -> void:
	var rows := CORRIDOR.duplicate()
	rows[0] = ".........................K...."
	rows[3] = ".............................."
	rows[1] = "##############################"
	var world := Fixtures.world(rows, SPARKY, [Vector2i(10, 3)] as Array[Vector2i])
	var sparky := Fixtures.first(world, Keen5Sparky) as Keen5Sparky
	sparky.direction.x = 1
	sparky.set_action(sparky.actions[&"search_1"])
	Fixtures.wait(world, 30)
	assert_true(not sparky.action.name.begins_with("ready"), "Keen too high: no charge")


func test_a_sparky_kills_keen_and_is_stunned_for_good() -> void:
	var world := Fixtures.world(CORRIDOR, SPARKY, [Vector2i(26, 3)] as Array[Vector2i])
	var sparky := Fixtures.first(world, Keen5Sparky) as Keen5Sparky
	var dies := Fixtures.run_until(world, func() -> bool: return Fixtures.keen_dies(world), 200)
	assert_true(dies < 200, "touching it kills Keen")
	world = Fixtures.world(CORRIDOR, SPARKY, [Vector2i(10, 3)] as Array[Vector2i])
	sparky = Fixtures.first(world, Keen5Sparky) as Keen5Sparky
	var keep := []
	Fixtures.shoot(world, sparky, keep)
	Fixtures.wait(world, 3)
	assert_true(sparky.stunned, "a shot stuns it")
	assert_equal(sparky.stars_offset, Vector2i(0x40, 0), "its stars")
	Fixtures.wait(world, 200)
	assert_true(sparky.stunned and sparky.action.name == &"stunned", "for good")


func test_a_little_ampton_pushes_keen_and_is_stunned() -> void:
	var sounds: Array[StringName] = []
	var world := Fixtures.world(
		CORRIDOR, AMPTON, [Vector2i(25, 3)] as Array[Vector2i], GalaxyDifficulty.DEFAULT, sounds
	)
	var ampton := Fixtures.first(world, Keen5Ampton) as Keen5Ampton
	assert_equal(ampton.box.bottom, 6 * TILE - 1, "it stands on the floor")
	ampton.direction.x = 1
	var keen := Fixtures.keen(world)
	var start := keen.position.x
	Fixtures.wait(world, 60)
	assert_true(not keen.is_dying(), "walking into Keen it does not kill him")
	assert_true(keen.position.x != start or ampton.direction.x == -1, "it pushes him or turns")
	assert_true(sounds.has(&"ampton_walk_1") and sounds.has(&"ampton_walk_2"), "its steps")
	var keep := []
	Fixtures.shoot(world, ampton, keep)
	Fixtures.wait(world, 3)
	assert_true(ampton.stunned, "a shot stuns it")
	assert_true(sounds.has(&"ampton_stun"), "with its sound")


func test_a_little_ampton_works_a_computer() -> void:
	var world := Fixtures.world(CORRIDOR, AMPTON, [Vector2i(10, 3)] as Array[Vector2i])
	var ampton := Fixtures.first(world, Keen5Ampton) as Keen5Ampton
	ampton.direction.x = 1
	# At its box's top row (it is a tile and a half tall).
	Fixtures.put_tile(world, Vector2i(12, 2), Fixtures.COMPUTER)
	var working := Fixtures.run_until(
		world, func() -> bool: return ampton.action.name.begins_with("computer"), 100
	)
	assert_true(working < 100, "at a computer it works it")
	assert_equal(ampton.actions[&"computer_1"].timer, 12, "pictures of 12 tics")


func test_a_little_ampton_climbs_a_pole_kills_there_and_gets_off() -> void:
	var rows: PackedStringArray = [
		"..............|...............",
		"..............|...............",
		"..............|...............",
		"..............|...............",
		"..............|...............",
		"..............|...............",
		"..............|...............",
		"..............|.............K.",
		"##############o###############",
		"..............|...............",
		"..............|...............",
		"##############################",
	]
	var world := Fixtures.world(rows, AMPTON, [Vector2i(10, 7)] as Array[Vector2i])
	var ampton := Fixtures.first(world, Keen5Ampton) as Keen5Ampton
	ampton.direction.x = 1
	var on_pole := Fixtures.run_until(world, func() -> bool: return ampton.is_on_pole(), 400)
	assert_true(on_pole < 400, "it takes the pole")
	assert_equal(ampton.clip, GalaxyObject.Clip.NONE, "unclipped on the pole")
	# Its first frame on the pole takes the original's leftover tic (−1).
	Fixtures.wait(world, 1)
	var y := ampton.position.y
	Fixtures.wait(world, 1)
	assert_equal(absi(ampton.position.y - y), 64, "32 units a tic on the pole")
	# Keen touching it on the pole dies.
	var keen := Fixtures.keen(world)
	keen.position = ampton.position
	keen.reset_box()
	Fixtures.wait(world, 1)
	assert_true(keen.is_dying(), "on the pole it kills")
	var off := Fixtures.run_until(world, func() -> bool: return not ampton.is_on_pole(), 400)
	assert_true(off < 400, "it gets off again")


func test_an_ampton_knocks_keen_off_a_pole() -> void:
	var rows: PackedStringArray = [
		"............|.................",
		"............|.................",
		"............|.................",
		"............P.................",
		"##############################",
	]
	var world := Fixtures.world(rows, AMPTON, [Vector2i(9, 3)] as Array[Vector2i])
	var ampton := Fixtures.first(world, Keen5Ampton) as Keen5Ampton
	var keen := Fixtures.keen(world)
	keen.direction.x = 1
	Keen.run(world, 2, func(_frame: int) -> KeenInput: return Keen.press(0, -1))
	assert_true(keen.action.name.begins_with("pole"), "Keen holds the pole")
	ampton.position.x = keen.position.x
	ampton.position.y = keen.box.bottom - ampton.box.bottom + ampton.position.y
	ampton.reset_box()
	Fixtures.wait(world, 1)
	assert_true(keen.action.name.begins_with("fall"), "knocked off the pole")
	assert_true(not keen.is_dying(), "not killed")


func test_a_korath_is_harmless_pushes_and_is_stunned() -> void:
	var world := Fixtures.world(CORRIDOR, KORATH, [Vector2i(25, 3)] as Array[Vector2i])
	var korath := Fixtures.first(world, Keen5Korath) as Keen5Korath
	korath.direction.x = 1
	var keen := Fixtures.keen(world)
	Fixtures.wait(world, 120)
	assert_true(not keen.is_dying(), "it never kills Keen")
	assert_equal(korath.stars_offset, Vector2i(0, -0x80), "its stars")
	var keep := []
	Fixtures.shoot(world, korath, keep)
	Fixtures.wait(world, 3)
	assert_true(korath.stunned, "a shot stuns it")


func test_a_korath_waits_now_and_then() -> void:
	var world := Fixtures.world(CORRIDOR, KORATH, [Vector2i(5, 3)] as Array[Vector2i])
	var korath := Fixtures.first(world, Keen5Korath) as Keen5Korath
	var waited := Fixtures.run_until(
		world, func() -> bool: return korath.action.name == &"wait", 600
	)
	assert_true(waited < 600, "it stops and waits")
	assert_equal(korath.actions[&"wait"].timer, 30, "30 tics")


func test_a_straight_slicestar_turns_at_b_blocks_and_takes_20_shots() -> void:
	var rows: PackedStringArray = [
		"..............................",
		"..............................",
		"............................K.",
		"##############################",
	]
	var world := Fixtures.world(rows, SLICESTAR_RIGHT, [Vector2i(4, 0)] as Array[Vector2i])
	Keen.put_info(world.map, Vector2i(10, 0), B_BLOCK)
	Keen.put_info(world.map, Vector2i(2, 0), B_BLOCK)
	var star := Fixtures.first(world, Keen5Slicestar) as Keen5Slicestar
	assert_equal(star.direction, Vector2i.RIGHT, "info 22 starts right")
	var x := star.position.x
	Fixtures.wait(world, 1)
	assert_equal(star.position.x - x, 12 * 3, "12 units a tic (the first frame is 3 tics)")
	var turned := Fixtures.run_until(world, func() -> bool: return star.direction.x == -1, 100)
	assert_true(turned < 100, "it turns at the B-block")
	assert_true(star.box.tile_right < 12, "before the B-block")
	assert_equal(star.health, 20, "20 hit points")
	var keep := []
	for shot in 19:
		Fixtures.shoot(world, star, keep)
		Fixtures.wait(world, 2)
	assert_equal(star.health, 1, "each shot costs one")
	assert_equal(star.action.name, &"axis", "still going")
	Fixtures.shoot(world, star, keep)
	Fixtures.wait(world, 2)
	assert_equal(star.action.name, &"burst", "the last one bursts it")
	Fixtures.wait(world, 15)
	assert_equal(Fixtures.count(world, Keen5Slicestar), 0, "gone after 20 tics")


func test_a_vertical_slicestar_starts_up_and_kills_keen() -> void:
	var world := Fixtures.world(CORRIDOR, SLICESTAR_UP, [Vector2i(27, 1)] as Array[Vector2i])
	var star := Fixtures.first(world, Keen5Slicestar) as Keen5Slicestar
	assert_equal(star.direction, Vector2i.UP, "info 10 starts up")
	star.position = Fixtures.keen(world).position
	star.reset_box()
	Fixtures.wait(world, 1)
	assert_true(Fixtures.keen_dies(world), "touching it kills Keen")
	assert_true(Fixtures.keen(world).platform == null, "Keen never rides it")


func test_a_diagonal_slicestar_never_starts_right_up() -> void:
	var starts: Dictionary[Vector2i, bool] = {}
	for random in 256:
		var world := Fixtures.world(CORRIDOR, 0, [] as Array[Vector2i])
		var table := PackedByteArray()
		table.resize(256)
		table.fill(random)
		world.random_table = table
		var star := Keen5Slicestar.spawn_diagonal(world, Vector2i(6, 3), Keen5Sprites.all())
		starts[star.direction] = true
	assert_equal(starts.size(), 3, "three ways")
	assert_true(not starts.has(Vector2i(1, -1)), "never right-up (the original's bug)")


func test_a_diagonal_slicestar_bounces_in_its_box_and_takes_50_shots() -> void:
	var rows: PackedStringArray = [
		"..........",
		"..........",
		"..........",
		"..........",
		"..........",
		"........K.",
		"##########",
	]
	var sounds: Array[StringName] = []
	var world := Fixtures.world(
		rows,
		SLICESTAR_DIAGONAL,
		[Vector2i(3, 1)] as Array[Vector2i],
		GalaxyDifficulty.DEFAULT,
		sounds
	)
	Fixtures.keen(world).god_mode = true
	var star := Fixtures.first(world, Keen5Slicestar) as Keen5Slicestar
	assert_equal(star.clip, GalaxyObject.Clip.SIMPLE, "box-clipped")
	assert_equal(star.health, 50, "50 hit points")
	var at := star.position
	Fixtures.wait(world, 1)
	var moved := star.position - at
	assert_equal(absi(moved.x), 24 * 3, "24 units a tic sideways")
	assert_equal(absi(moved.y), 24 * 3, "and up or down")
	Fixtures.wait(world, 200)
	assert_true(sounds.has(&"slice_bump"), "it bounces off the walls")
	var inside := Rect2i(2 * TILE, 2 * TILE, 10 * TILE, 7 * TILE)
	assert_true(inside.has_point(star.position), "it stays inside")


func test_a_shelley_explodes_when_shot_and_its_blast_and_pieces_kill() -> void:
	var sounds: Array[StringName] = []
	var world := Fixtures.world(
		CORRIDOR, SHELLEY, [Vector2i(10, 3)] as Array[Vector2i], GalaxyDifficulty.DEFAULT, sounds
	)
	var shelley := Fixtures.first(world, Keen5Shelley) as Keen5Shelley
	assert_equal(shelley.box.bottom, 6 * TILE - 1, "it stands on the floor")
	var keep := []
	Fixtures.shoot(world, shelley, keep)
	Fixtures.wait(world, 2)
	assert_true(sounds.has(&"shelley_explode"), "a shot makes it explode")
	assert_true(shelley.action.name.begins_with("die"), "it dies")
	Fixtures.wait(world, 6)
	assert_equal(Fixtures.count(world, Keen5Piece), 2, "two pieces fly off")
	assert_true(shelley.removed, "it is gone")
	var blast := _blast(world)
	assert_true(blast != null, "a blast where it was")
	assert_equal(blast.action.contact, &"_contact_deadly", "the blast kills")


func test_an_enemy_shot_makes_a_shelley_explode() -> void:
	var sounds: Array[StringName] = []
	var world := Fixtures.world(
		CORRIDOR, SHELLEY, [Vector2i(10, 3)] as Array[Vector2i], GalaxyDifficulty.DEFAULT, sounds
	)
	var shelley := Fixtures.first(world, Keen5Shelley) as Keen5Shelley
	var shot := Keen5Shot.launch(
		world,
		shelley.position + Vector2i(-200, 0),
		Vector2i(60, 0),
		Keen5RoboRed.SHOT_ROWS,
		Keen5Sprites.all(),
		&"fly_1"
	)
	assert_true(shot != null and shot.is_enemy_shot, "an enemy shot")
	Fixtures.wait(world, 4)
	assert_true(sounds.has(&"shelley_explode"), "it explodes")
	assert_true(shot.removed, "the shot is gone")


func test_keen_is_pushed_by_a_shelley_and_inside_it_sets_it_off() -> void:
	var world := Fixtures.world(CORRIDOR, SHELLEY, [Vector2i(20, 3)] as Array[Vector2i])
	var shelley := Fixtures.first(world, Keen5Shelley) as Keen5Shelley
	var keen := Fixtures.keen(world)
	keen.god_mode = true
	# Beside it: pushed, nothing happens.
	keen.position.x = shelley.box.right - 64 - Keen.KEEN_BOX.position.x
	keen.reset_box()
	Fixtures.wait(world, 1)
	assert_true(shelley.action.name.begins_with("walk"), "Keen beside it: no explosion")
	# His middle inside its box: it explodes.
	keen.position.x = shelley.box.middle - (Keen.KEEN_BOX.end.x + Keen.KEEN_BOX.position.x) / 2
	keen.reset_box()
	Fixtures.wait(world, 1)
	assert_true(shelley.action.name.begins_with("die"), "Keen's middle inside: it explodes")


func test_a_shelley_waits_at_a_ledge_and_dives_onto_keen() -> void:
	var rows: PackedStringArray = [
		"..............................",
		"..............................",
		"..............................",
		"..............................",
		"##########....................",
		"..............................",
		"..............................",
		"..............K...............",
		"##############################",
	]
	var sounds: Array[StringName] = []
	var world := Fixtures.world(
		rows, SHELLEY, [Vector2i(7, 3)] as Array[Vector2i], GalaxyDifficulty.DEFAULT, sounds
	)
	var shelley := Fixtures.first(world, Keen5Shelley) as Keen5Shelley
	shelley.direction.x = 1
	var waiting := Fixtures.run_until(
		world, func() -> bool: return shelley.action.name == &"wait", 100
	)
	assert_true(waiting < 100, "at the ledge it waits")
	var keen := Fixtures.keen(world)
	keen.position.x = shelley.position.x + 2 * TILE
	keen.reset_box()
	var diving := Fixtures.run_until(
		world, func() -> bool: return shelley.action.name.begins_with("dive"), 60
	)
	assert_true(diving < 60, "Keen below and 1-3 tiles ahead: it dives")
	assert_equal(shelley.velocity, Vector2i(16, -24), "16 sideways, 24 up")
	var landed := Fixtures.run_until(
		world, func() -> bool: return sounds.has(&"shelley_explode"), 60
	)
	assert_true(landed < 60, "landing it explodes")


func test_a_volteface_follows_the_arrows_at_32_a_tic() -> void:
	var rows: PackedStringArray = [
		"..............................",
		"..............................",
		"..............................",
		"............................K.",
		"##############################",
	]
	var map := Keen.level(rows)
	# A square path: right along row 0 from x 3 to 8, down to row 2, left
	# back to 3, up.
	for x in range(3, 8):
		Keen.put_info(map, Vector2i(x, 0), ARROW_RIGHT)
		Keen.put_info(map, Vector2i(x + 1, 2), ARROW_LEFT)
	Keen.put_info(map, Vector2i(8, 0), ARROW_DOWN)
	Keen.put_info(map, Vector2i(8, 1), ARROW_DOWN)
	Keen.put_info(map, Vector2i(3, 2), ARROW_UP)
	Keen.put_info(map, Vector2i(3, 1), ARROW_UP)
	Keen.put_info(map, Vector2i(5, 0), VOLTEFACE)
	var world := Fixtures.world_of(map)
	var volte := Fixtures.first(world, Keen5Volteface) as Keen5Volteface
	assert_equal(volte.activity, GalaxyObject.Activity.ALWAYS, "always awake")
	assert_equal(world.info_at(7, 2), ARROW_RIGHT, "it writes its arrow (right)")
	var start := volte.position
	Fixtures.wait(world, 1)
	assert_equal(volte.position - start, Vector2i(32 * 3, 0), "32 units a tic, right")
	# Round the square: 14 tiles, 3584 units, 112 tics; after 113 tics one
	# tic further.
	Fixtures.wait(world, 55)
	assert_equal(volte.position, start + Vector2i(32, 0), "round the square and back")


func test_a_volteface_kills_and_a_shot_stuns_it_300_tics() -> void:
	var map := Keen.level(CORRIDOR)
	for x in range(4, 27):
		Keen.put_info(map, Vector2i(x, 3), ARROW_RIGHT)
	Keen.put_info(map, Vector2i(27, 3), ARROW_LEFT)
	Keen.put_info(map, Vector2i(5, 3), VOLTEFACE)
	var world := Fixtures.world_of(map)
	var volte := Fixtures.first(world, Keen5Volteface) as Keen5Volteface
	var keep := []
	Fixtures.shoot(world, volte, keep)
	Fixtures.wait(world, 2)
	assert_equal(volte.action.name, &"stunned", "a shot stuns it")
	var at := volte.position
	var keen := Fixtures.keen(world)
	keen.position = volte.position
	keen.reset_box()
	Fixtures.wait(world, 140)
	assert_equal(volte.position, at, "it stands while stunned")
	assert_true(not keen.is_dying(), "harmless meanwhile")
	Fixtures.wait(world, 15)
	assert_true(volte.action.name.begins_with("move"), "after 300 tics it moves on")
	assert_true(keen.is_dying(), "and kills again")


## The steps (x moves) [param creature] makes in actions named
## [param prefix]… within [param frames] frames.
func _walk_steps(world: GalaxyWorld, creature: GalaxyObject, prefix: String, frames: int) -> Array:
	var steps := []
	for frame in frames:
		var was := creature.position.x
		var name := creature.action.name
		Fixtures.wait(world, 1)
		var moved := creature.position.x - was
		if moved != 0 and name.begins_with(prefix) and creature.action.name.begins_with(prefix):
			steps.append(moved)
	return steps


## The blast a Shelley left (a plain Keen5Creature).
func _blast(world: GalaxyWorld) -> GalaxyObject:
	for object in world.objects:
		if object.get_script() == Keen5Creature and not object.removed:
			return object
	return null
