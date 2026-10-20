extends "res://tests/test_case.gd"
## Checks Keen 4's council members, the janitor, Princess Lindsey and the
## wetsuit in hand-made mini levels (milestone D6), and what a game keeps of
## them ([Keen4Progress]) (Omni numbers; docs/keen4/research.md §7, §9).

const Fixtures := preload("res://tests/galaxy_keen_fixtures.gd")
const Creatures := preload("res://tests/keen4_creature_fixtures.gd")

const TILE := 256
const COUNCIL := 4
const LINDSEY := 6
const WETSUIT := 35
const FIELD: PackedStringArray = [
	"....................",
	"....................",
	"....................",
	"K...................",
	"####################",
]
const WALK_FRAMES := 60


func test_a_council_member_walks_and_pauses() -> void:
	var world := Creatures.world(FIELD, COUNCIL, [Vector2i(12, 3)])
	var member := Creatures.first(world, Keen4Council) as Keen4Council
	assert_equal(member.position.y, 5 * TILE - Keen4Council.RISE, "369 above his tile (Omni)")
	assert_equal(member.priority, 0, "behind Keen")
	var x := member.position.x
	var steps := PackedInt32Array()
	var paused := false
	for frame in 200:
		Creatures.wait(world, 1)
		if member.position.x != x:
			steps.append(absi(member.position.x - x))
			x = member.position.x
		if member.action.name == &"pause":
			paused = true
	assert_true(steps.has(64), "he shuffles 64 units a step")
	assert_true(paused, "and stops to think now and then")
	assert_equal(world.state, GalaxyWorld.LevelState.PLAYING, "nothing ends by itself")


func test_touching_a_council_member_rescues_him() -> void:
	var world := Creatures.world(FIELD, COUNCIL, [Vector2i(4, 3)])
	Creatures.hold(world, WALK_FRAMES, Fixtures.press(1))
	assert_equal(world.state, GalaxyWorld.LevelState.COMPLETED, "the level is done")
	assert_equal(world.ending, Keen4Council.RESCUED, "by a rescue")


func test_only_standing_keen_rescues_him() -> void:
	var world := Creatures.world(FIELD, COUNCIL, [Vector2i(13, 3)])
	var member := Creatures.first(world, Keen4Council) as Keen4Council
	var keen := world.player() as GalaxyKeen
	keen.top_hit = 0
	member.touched_by_player(keen, false)
	assert_equal(world.state, GalaxyWorld.LevelState.PLAYING, "not while in the air")
	keen.top_hit = 1
	member.touched_by_player(keen, true)
	assert_equal(world.state, GalaxyWorld.LevelState.PLAYING, "not from a pole or ledge")
	member.touched_by_player(keen, false)
	assert_equal(world.state, GalaxyWorld.LevelState.COMPLETED, "standing he rescues him")


func test_the_janitor_talks_and_is_gone() -> void:
	var world := Creatures.world(FIELD, COUNCIL, [Vector2i(4, 3)])
	world.map_number = Keen4Council.JANITOR_LEVEL
	var member := Creatures.first(world, Keen4Council) as Keen4Council
	assert_true(member.is_janitor(), "in level 14 he is the janitor")
	var asked := &""
	for frame in WALK_FRAMES:
		Creatures.hold(world, 1, Fixtures.press(1))
		if not world.conversation.is_empty():
			asked = world.conversation
			world.conversation = &""
	assert_equal(asked, Keen4Council.JANITOR, "his boxes are asked for")
	assert_true(not world.objects.has(member), "and he is gone")
	assert_equal(world.state, GalaxyWorld.LevelState.PLAYING, "the level goes on")


func test_lindsey_floats_and_gives_her_message() -> void:
	var world := Creatures.world(FIELD, LINDSEY, [Vector2i(10, 2)])
	var lindsey := Creatures.first(world, Keen4Lindsey) as Keen4Lindsey
	assert_equal(lindsey.home, 4 * TILE - Keen4Lindsey.RISE, "a tile above her info tile")
	var lowest := lindsey.position.y
	var highest := lindsey.position.y
	for frame in 100:
		Creatures.wait(world, 1)
		lowest = maxi(lowest, lindsey.position.y)
		highest = mini(highest, lindsey.position.y)
	assert_true(highest < lindsey.home and lowest > lindsey.home, "she bobs up and down")
	assert_true(lowest - lindsey.home < TILE, "around her place")
	var keen := world.player() as GalaxyKeen
	keen.position.x = lindsey.position.x
	keen.position.y = lindsey.position.y
	keen.reset_box()
	Creatures.wait(world, 1)
	assert_equal(world.conversation, Keen4Lindsey.MESSAGE, "her message")
	assert_true(not world.objects.has(lindsey), "she is gone")
	assert_equal(world.state, GalaxyWorld.LevelState.PLAYING, "the level goes on")


func test_the_wetsuit_ends_the_level() -> void:
	var world := Creatures.world(FIELD, WETSUIT, [Vector2i(6, 3)])
	var wetsuit := Creatures.first(world, Keen4Wetsuit) as Keen4Wetsuit
	assert_equal(wetsuit.position.y, 5 * TILE - Keen4Wetsuit.RISE, "a tile above its tile")
	Creatures.hold(world, WALK_FRAMES, Fixtures.press(1))
	assert_equal(world.state, GalaxyWorld.LevelState.COMPLETED, "taking it ends the level")
	assert_equal(world.ending, Keen4Wetsuit.TAKEN, "with the wetsuit")


func test_progress_counts_rescues_and_keeps_the_wetsuit() -> void:
	var progress := Keen4Progress.new()
	assert_equal(progress.rescue(), 0, "the first rescue hears answer 0")
	assert_equal(progress.rescue(), 1, "the second answer 1")
	for rescue in 5:
		progress.rescue()
	assert_true(not progress.all_rescued(), "seven are not all")
	assert_equal(progress.rescue(), 7, "the eighth hears the last answer")
	assert_true(progress.all_rescued(), "eight are all (Omni)")
	assert_true(not progress.wetsuit, "no wetsuit in a new game")
	progress.mark_done(9)
	progress.mark_done(3)
	assert_equal(progress.done_levels(), PackedInt32Array([3, 9]), "the levels done")
	assert_true(progress.is_done(9) and not progress.is_done(4), "done or not")
