extends "res://tests/test_case.gd"
## Checks the Galaxy action system and physics (milestone D4) with
## hand-made actions and levels: the action rows, how timers, velocities and
## protection work (Omni CK_RunAction), the world's frame (waking and
## sleeping, both contact functions, the map's last row), the tile clipping
## (floors, walls, ceilings, the clamp per frame, sticking to the ground)
## and gravity on odd tics. Numbers from Omnispeak (research.md §3-§4).

const Fixtures := preload("res://tests/galaxy_keen_fixtures.gd")

const TILE := 256


## An object that counts its thinks and contacts.
class Counter:
	extends GalaxyObject
	var thinks := 0
	var reacts := 0
	var touched: Array[GalaxyObject] = []

	func _think_count() -> void:
		thinks += 1

	func _react_count() -> void:
		reacts += 1

	func _contact_count(other: GalaxyObject) -> void:
		touched.append(other)


const ROWS: PackedStringArray = [
	"once - - step -- 6 10 0 count - count after",
	"after - - think -- 0 0 0 count - count after",
	"slide - - slide -- 6 10 0 - - - -",
	"first - - slide -- 1 10 0 - - - guarded",
	"guarded - - slide p- 1 10 0 - - - slow",
	"first_2 - - slide -- 1 10 0 - - - unguarded",
	"unguarded - - slide -- 1 10 0 - - - slow",
	"slow - - slide -- 10 10 0 - - - -",
	"touchy - - think -- 0 0 0 - count - touchy",
	"fall - - think -- 0 0 0 fall - - fall",
]


func test_rows_become_linked_actions() -> void:
	var actions := GalaxyAction.table_from(ROWS, {})
	assert_equal(actions.size(), ROWS.size(), "one action per row")
	var once: GalaxyAction = actions[&"once"]
	assert_equal(once.type, GalaxyAction.Type.STEP, "step")
	assert_equal(once.timer, 6, "timer")
	assert_equal(once.velocity, Vector2i(10, 0), "velocity")
	assert_equal(once.think, &"_think_count", "think by name")
	assert_equal(once.react, &"_react_count", "react by name")
	assert_equal(once.next, actions[&"after"], "next linked")
	assert_equal(actions[&"slide"].next, null, "no next: removed")
	assert_true(actions[&"guarded"].protect, "p: protect")
	assert_true(not actions[&"unguarded"].protect, "-: no protection")
	var keen := GalaxyKeenActions.create(Keen4Sprites.all())
	assert_equal(keen.size(), GalaxyKeenActions.ROWS.size(), "all of Keen's actions read")
	assert_equal(keen[&"stand"].right_sprite, 6, "Keen 4's standing sprite")
	assert_true(keen[&"run_1"].stick_to_ground and keen[&"run_1"].protect, "running: ps")


func test_a_step_moves_once_and_a_slide_every_tic() -> void:
	var world := _world()
	var actions := GalaxyAction.table_from(ROWS, {})
	var once := _counter(world, actions[&"once"])
	var slide := _counter(world, actions[&"slide"])
	var start := once.position.x
	_frames(world, 2)
	assert_equal(once.position.x - start, 0, "a step does nothing before its timer ends")
	assert_equal(slide.position.x - start, 40, "a slide moves 10 a tic")
	_frames(world, 1)
	assert_equal(once.position.x - start, 10, "at the end it moves once")
	assert_equal(once.thinks, 1, "and thinks once")
	assert_equal(once.action, actions[&"after"], "then the next action")
	assert_true(slide.removed, "a slide without next is removed")
	_frames(world, 2)
	assert_equal(once.thinks, 3, "a think action thinks every frame")


func test_protection_lets_an_action_end_in_the_frame_it_began() -> void:
	var world := _world()
	var actions := GalaxyAction.table_from(ROWS, {})
	var guarded := _counter(world, actions[&"first"])
	var unguarded := _counter(world, actions[&"first_2"])
	var start := guarded.position.x
	_frames(world, 1)
	# 2 tics: 1 in the first action, 1 left for the next one (timer 1).
	assert_equal(guarded.position.x - start, 20, "protected: it runs to its end")
	assert_equal(guarded.action, actions[&"slow"], "and the one after follows")
	assert_equal(unguarded.position.x - start, 10, "not protected: the leftover tic is lost")
	assert_equal(unguarded.action, actions[&"unguarded"], "it ends in the next frame")


func test_both_contact_functions_run() -> void:
	var world := _world()
	var actions := GalaxyAction.table_from(ROWS, {})
	var one := _counter(world, actions[&"touchy"])
	var two := _counter(world, actions[&"touchy"])
	var far := _counter(world, actions[&"touchy"])
	for object in [one, two, far]:
		object.sprite = 6
	far.position.x = 5 * TILE
	for object in [one, two, far]:
		object.reset_box()
	_frames(world, 1)
	assert_equal(one.touched, [two] as Array[GalaxyObject], "the first touches the second")
	assert_equal(two.touched, [one] as Array[GalaxyObject], "and the second the first")
	assert_true(far.touched.is_empty(), "boxes apart: no contact")


func test_objects_sleep_far_from_the_view_and_wake_near_it() -> void:
	var world := _world(80)
	var actions := GalaxyAction.table_from(ROWS, {})
	var near := _counter(world, actions[&"touchy"])
	var far := _counter(world, actions[&"touchy"])
	for object in [near, far]:
		object.sprite = 6
	far.position.x = 60 * TILE
	near.position.x = 4 * TILE
	for object in [near, far]:
		object.reset_box()
	_frames(world, 1)
	assert_equal(far.activity, GalaxyObject.Activity.INACTIVE, "far away: asleep at once")
	assert_equal(near.activity, GalaxyObject.Activity.ACTIVE, "near: awake")
	world.camera.reposition(Vector2i(45 * TILE, 0))
	_frames(world, 1)
	assert_equal(far.activity, GalaxyObject.Activity.ACTIVE, "the view came near: awake")


func test_gravity_acts_on_odd_tics() -> void:
	var world := _world()
	var actions := GalaxyAction.table_from(ROWS, {})
	var falling := _counter(world, actions[&"fall"])
	falling.clip = GalaxyObject.Clip.NONE
	falling.velocity.y = -6
	world.tics = 2
	world.tic = 4
	falling.step = Vector2i.ZERO
	GalaxyPhysics.gravity_high(falling)
	assert_equal(falling.velocity.y, -2, "tic 3 is odd: +4")
	assert_equal(falling.step.y, -6 + -2, "the even tic adds the old speed, the odd the new")
	falling.step = Vector2i.ZERO
	world.tic = 6
	GalaxyPhysics.gravity_high(falling)
	assert_equal(falling.velocity.y, 0, "between −4 and 0 it stops at 0")
	assert_equal(falling.step.y, -2 + -2, "and the rest of the frame adds nothing")
	falling.velocity.y = 68
	falling.step = Vector2i.ZERO
	GalaxyPhysics.gravity_high(falling)
	assert_equal(falling.velocity.y, GalaxyPhysics.MAX_FALL, "at most 70")
	falling.velocity.x = 3
	GalaxyPhysics.damp_x(falling)
	assert_equal(falling.velocity.x, 2, "damping: 1 per odd tic")
	falling.velocity.x = 23
	GalaxyPhysics.accelerate_x(falling, 2, 24)
	assert_equal(falling.velocity.x, 24, "accelerating up to the limit")
	falling.velocity.x = 1
	falling.direction.x = 1
	GalaxyPhysics.accelerate_x(falling, -2, 24)
	assert_equal(falling.direction.x, -1, "a speed that changes sign turns him")


func test_clipping_floors_walls_and_ceilings() -> void:
	var world := (
		Fixtures
		. world(
			[
				"..........",
				"..^^......",
				"..........",
				"..........",
				"....K.#...",
				"##########",
			]
		)
	)
	var keen := world.player() as GalaxyKeen
	var clip := world.clip
	assert_equal(keen.box.bottom, 7 * TILE - 1, "standing on the floor")
	keen.step = Vector2i(400, 0)
	clip.update_normal(keen)
	assert_equal(keen.left_hit, 1, "the wall's left side stopped him")
	assert_equal(keen.box.right, 8 * TILE - 1, "just before the wall")
	keen.action = null
	keen.step = Vector2i(0, 400)
	clip.update_normal(keen)
	assert_equal(
		keen.box.bottom, 7 * TILE - 1, "a fall faster than 255 a frame is clamped, the floor holds"
	)
	keen.position = Vector2i(4 * TILE, 4 * TILE + 32)
	keen.reset_box()
	keen.step = Vector2i(0, -64)
	clip.update_normal(keen)
	assert_equal(keen.bottom_hit, 1, "the ceiling stopped him")
	assert_equal(keen.box.top, 4 * TILE, "under the ceiling")


func test_sticking_to_the_ground_keeps_him_on_a_ledge() -> void:
	var world := Fixtures.world(["..........", "...K......", "####......", "##########"])
	var keen := world.player() as GalaxyKeen
	var y := keen.position.y
	keen.step = Vector2i(200, 0)
	world.clip.update_normal(keen)
	assert_equal(keen.position.y, y, "no floor under him: he stays on his row")
	assert_equal(keen.top_hit, 0, "and knows there is no floor (he will fall)")


func test_the_clock_starts_a_level_with_three_tics() -> void:
	var clock := GalaxyClock.new()
	clock.start_level()
	assert_equal(clock.advance(2.0 / 70.0), 0, "two tics are not yet the first frame")
	assert_equal(clock.advance(1.0 / 70.0), 1, "three are")
	assert_equal(clock.run_frame(), GalaxyClock.LEVEL_START_TICS, "the first frame: 3 tics")
	clock.advance(2.0 / 70.0)
	assert_equal(clock.run_frame(), GalaxyClock.NORMAL_TICS, "then 2")
	assert_equal(clock.tic, 5, "frames start on odd tics from then on")


func _world(width := 30) -> GalaxyWorld:
	var rows := PackedStringArray()
	for row in 15:
		rows.append(".".repeat(width))
	rows.append("#".repeat(width))
	var world := GalaxyWorld.create(
		Fixtures.level(rows), Fixtures.tile_info(), Fixtures.sprite_infos()
	)
	world.camera = GalaxyCamera.for_map(Vector2i(width + 4, rows.size() + 4))
	return world


func _counter(world: GalaxyWorld, action: GalaxyAction) -> Counter:
	var counter := Counter.new()
	counter.clip = GalaxyObject.Clip.NONE
	counter.position = Vector2i(2 * TILE, 2 * TILE)
	world.add(counter)
	counter.action = action
	return counter


func _frames(world: GalaxyWorld, count: int) -> void:
	for frame in count:
		world.run_frame(GalaxyClock.NORMAL_TICS, world.tic + GalaxyClock.NORMAL_TICS)
