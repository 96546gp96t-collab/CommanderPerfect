extends "res://tests/test_case.gd"
## Checks what Keen touches in hand-made mini levels (milestone D4): items
## lying as tiles and as sprites, lifewater drops (100 make a life), extra
## lives at 20,000 points and then each doubling, gem holders and the door
## that opens in three steps, the bridge switch, the stunner shot (64 a
## tic, walls, pole holes, charges), deadly tiles, dying and leaving the
## level (Omni numbers; docs/keen4/research.md §5 and §9).

const Fixtures := preload("res://tests/galaxy_keen_fixtures.gd")

const TILE := 256
const SHOT_PER_FRAME := 128


func test_item_and_drop_tiles() -> void:
	var world := Fixtures.world(["..........", "..K$+*....", "##########"])
	var keen := world.player() as GalaxyKeen
	var lives := keen.inventory.lives
	Fixtures.run(world, 20, func(_frame: int) -> KeenInput: return Fixtures.press(1))
	assert_equal(keen.inventory.score, 100, "the 100-point tile")
	assert_equal(keen.inventory.lives, lives + 1, "the extra life tile")
	assert_equal(keen.inventory.drops, 1, "a drop")
	for x in [5, 6, 7]:
		assert_equal(world.fore_tile(x, 3), Fixtures.EMPTY, "taken tiles are gone (%d)" % x)
	var shown := world.objects.filter(func(object: GalaxyObject) -> bool: return object != keen)
	assert_true(shown.size() >= 2, "what was taken rises or splashes")


func test_a_hundred_drops_make_a_life() -> void:
	var inventory := Keen4Inventory.new_game()
	for drop in 99:
		assert_true(not inventory.add_drop(), "no life yet")
	assert_true(inventory.add_drop(), "the 100th drop")
	assert_equal(inventory.lives, Keen4Inventory.START_LIVES + 1, "one more life")
	assert_equal(inventory.drops, 0, "the count starts again")


func test_extra_lives_at_20000_then_doubling() -> void:
	var inventory := Keen4Inventory.new_game()
	assert_equal(inventory.lives, 3, "a new game: 3 lives")
	assert_equal(inventory.shots, 5, "5 charges")
	assert_true(not inventory.add_score(19999), "not yet")
	assert_true(inventory.add_score(1), "20,000")
	assert_equal(inventory.next_life_at, 40000, "then 40,000")
	assert_true(not inventory.add_score(19999), "not at 39,999")
	assert_true(inventory.add_score(1), "40,000")
	assert_equal(inventory.next_life_at, 80000, "then 80,000")
	assert_equal(inventory.lives, 5, "two lives more")


func test_items_lying_as_sprites() -> void:
	var world := Fixtures.world(["............", "..K.........", "############"])
	var keen := world.player() as GalaxyKeen
	var actions := keen.item_actions()
	var sprites := Keen4Sprites.all()
	var gem := GalaxyItem.place(world, Vector2i(7, 3), 0, sprites, actions)
	var points := GalaxyItem.place(world, Vector2i(8, 3), 9, sprites, actions)
	var stunner := GalaxyItem.place(
		world, Vector2i(9, 3), GalaxyInventory.STUNNER_ITEM, sprites, actions
	)
	assert_equal(gem.sprite, Keen4Sprites.ITEM_FIRST_FRAMES[0], "the red gem")
	Fixtures.run(world, 11, Fixtures.nothing)
	assert_equal(
		gem.sprite, Keen4Sprites.ITEM_FIRST_FRAMES[0] + 1, "its second frame after 20 tics"
	)
	Fixtures.run(world, 25, func(_frame: int) -> KeenInput: return Fixtures.press(1))
	assert_equal(keen.inventory.gems[0], 1, "a red gem")
	assert_equal(keen.inventory.score, 5000, "5000 points")
	assert_equal(keen.inventory.shots, 5 + 5, "5 charges more")
	assert_true(gem.taken and points.taken and stunner.taken, "all taken")
	assert_equal(points.sprite, Keen4Sprites.ITEM_SHADOWS[9], "showing what it gave")
	assert_equal(points.priority, GalaxyItem.RISING_PRIORITY, "in front")
	Fixtures.run(world, 25, Fixtures.nothing)
	assert_true(points.removed or not world.objects.has(points), "risen and gone after 40 tics")


func test_a_gem_opens_its_door_in_three_steps() -> void:
	var rows: PackedStringArray = [
		"................",
		"..........B.....",
		"..........B.....",
		"....K..G..B.....",
		"################",
	]
	var map := Fixtures.level(rows)
	# The holder points at the door's top tile (map cells).
	Fixtures.put_info(map, Vector2i(7, 3), (12 << 8) | 3)
	var world := GalaxyWorld.create(map, Fixtures.tile_info(), Fixtures.sprite_infos())
	world.camera = Fixtures.camera_for(map)
	var keen := GalaxyKeen.spawn(world, Vector2i(6, 5), 1, Keen4Sprites.all())
	var right := func(_frame: int) -> KeenInput: return Fixtures.press(1)
	Fixtures.run(world, 30, right)
	assert_true(keen.box.right < 12 * TILE, "without a gem the door stops him")
	assert_equal(world.fore_tile(9, 5), Fixtures.GEM_HOLDER, "the holder is empty")
	keen.inventory.gems[0] = 1
	keen.position.x = 6 * TILE
	keen.reset_box()
	for frame in 30:
		Fixtures.run(world, 1, right)
		if keen.action.name == "place_gem":
			break
	assert_equal(keen.action.name, &"place_gem", "on the holder he puts the gem in")
	assert_equal(keen.position.x, 9 * TILE - 64, "standing at its spot")
	assert_equal(keen.inventory.gems[0], 0, "the gem is used")
	Fixtures.run(world, 4, Fixtures.nothing)
	assert_equal(world.fore_tile(9, 5), Fixtures.GEM_HOLDER_FULL, "the holder shows the gem (+18)")
	# The door's tiles move on three times, 10 tics (5 frames) apart.
	var seen := PackedInt32Array()
	var frames_per_step := PackedInt32Array()
	for frame in 30:
		var tile := world.fore_tile(12, 4)
		if seen.is_empty() or seen[-1] != tile:
			seen.append(tile)
			frames_per_step.append(0)
		frames_per_step[-1] += 1
		Fixtures.run(world, 1, Fixtures.nothing)
	assert_equal(seen, PackedInt32Array([40, 41, 42, 43]), "the door's three steps")
	assert_equal(frames_per_step[1], 5, "10 tics a step")
	assert_equal(world.fore_tile(12, 3), 43, "its top tile too")
	Fixtures.run(world, 40, right)
	assert_true(keen.box.right > 12 * TILE, "he walks through")


func test_shots_fly_hit_walls_and_pass_pole_holes() -> void:
	var world := (
		Fixtures
		. world(
			[
				"................",
				"................",
				"................",
				"................",
				"..K.........#...",
				"################",
			]
		)
	)
	var keen := world.player() as GalaxyKeen
	var fire := func(_frame: int) -> KeenInput: return KeenInput.create(0, false, false, true)
	Fixtures.run(world, 1, fire)
	Fixtures.run(world, 5, Fixtures.nothing)
	var shots := world.objects.filter(
		func(object: GalaxyObject) -> bool: return object is GalaxyStunnerShot
	)
	assert_equal(shots.size(), 1, "one shot")
	assert_equal(keen.inventory.shots, 4, "one charge used")
	var shot: GalaxyStunnerShot = shots[0]
	var x := shot.position.x
	Fixtures.run(world, 1, Fixtures.nothing)
	assert_equal(shot.position.x - x, SHOT_PER_FRAME, "64 units a tic")
	Fixtures.run(world, 20, Fixtures.nothing)
	assert_true(shot.spent, "it hit the wall")
	assert_true(shot.box.right < 14 * TILE + 16, "at the wall")
	keen.inventory.shots = 0
	Fixtures.run(world, 1, fire)
	Fixtures.run(world, 10, Fixtures.nothing)
	var more := world.objects.filter(
		func(object: GalaxyObject) -> bool: return object is GalaxyStunnerShot and not object.spent
	)
	assert_true(more.is_empty(), "without charges nothing comes out")
	var hole := (
		Fixtures
		. world(
			[
				"..........",
				"..........",
				"..........",
				"....o.....",
				"....|.....",
				"....P.....",
				"##########",
			]
		)
	)
	var climber := hole.player() as GalaxyKeen
	Fixtures.run(hole, 1, func(_frame: int) -> KeenInput: return Fixtures.press(0, -1))
	Fixtures.run(hole, 2, Fixtures.nothing)
	var shooting_up := func(_frame: int) -> KeenInput:
		var input := KeenInput.create(0, false, false, true)
		input.vertical = -1
		return input
	# Up first starts climbing; the climb then takes the fire button.
	Fixtures.run(hole, 2, shooting_up)
	var passed := false
	for frame in 12:
		Fixtures.run(hole, 1, Fixtures.nothing)
		for object in hole.objects:
			var up_shot := object as GalaxyStunnerShot
			if (
				up_shot != null
				and up_shot.direction == Vector2i.UP
				and up_shot.box.bottom < 5 * TILE
			):
				passed = true
	assert_true(passed, "a shot up from the pole goes through the pole hole")
	assert_equal(climber.action.name, &"pole", "back on the pole after shooting")


func test_deadly_tiles_and_dying() -> void:
	var world := Fixtures.world(["..........", "..K.X.....", "##########"])
	var keen := world.player() as GalaxyKeen
	Fixtures.run(world, 10, func(_frame: int) -> KeenInput: return Fixtures.press(1))
	assert_true(keen.is_dying(), "a deadly tile kills him")
	assert_equal(keen.clip, GalaxyObject.Clip.NONE, "he falls through everything")
	assert_true(keen.scroll_disabled, "the view stops")
	var y := keen.position.y
	Fixtures.run(world, 3, Fixtures.nothing)
	assert_true(keen.position.y < y, "he flies up first")
	Fixtures.run(world, 100, Fixtures.nothing)
	assert_equal(world.state, GalaxyWorld.LevelState.DIED, "out of the view: the level is lost")
	var floor_world := Fixtures.world(["..........", "..K.......", "##DD######"])
	var floor_keen := floor_world.player() as GalaxyKeen
	Fixtures.run(floor_world, 10, func(_frame: int) -> KeenInput: return Fixtures.press(1))
	assert_true(floor_keen.is_dying(), "a deadly floor kills him")
	var god := Fixtures.world(["..........", "..K.X.....", "##########"])
	var god_keen := god.player() as GalaxyKeen
	god_keen.god_mode = true
	Fixtures.run(god, 10, func(_frame: int) -> KeenInput: return Fixtures.press(1))
	assert_true(not god_keen.is_dying(), "not in god mode")


func test_falling_out_of_the_level_and_leaving_it() -> void:
	var session := _session(["..........", "....K.....", "###....###", "###....###"], true)
	var keen := session.keen
	for frame in 80:
		session.run_frame(KeenInput.new(), GalaxyClock.NORMAL_TICS, session.world.tic + 2)
	assert_true(keen.is_dying() or session.is_lost(), "falling out of the map kills him")
	var walk := _session(["....................", "..K.................", "####################"])
	for frame in 120:
		walk.run_frame(Fixtures.press(-1), GalaxyClock.NORMAL_TICS, walk.world.tic + 2)
		if not walk.is_playing():
			break
	assert_true(walk.is_done(), "walking out to the left ends the level")


## A level session of [param rows] without the game's files; the border's
## sides are open, and its bottom too with [param open_bottom].
func _session(rows: PackedStringArray, open_bottom := false) -> Keen4LevelSession:
	var session := Keen4LevelSession.new()
	session.world = Fixtures.world(rows)
	# The border's left and right columns open: Keen can leave there.
	var map := session.world.map
	for y in map.height - 2:
		for x in [0, 1, map.width - 2, map.width - 1]:
			map.planes[GalaxyMap.Layer.FOREGROUND][y * map.width + x] = Fixtures.EMPTY
	if open_bottom:
		for y in range(map.height - 2, map.height):
			for x in map.width:
				map.planes[GalaxyMap.Layer.FOREGROUND][y * map.width + x] = Fixtures.EMPTY
	session.map = map
	session.keen = session.world.player() as GalaxyKeen
	session.camera = session.world.camera
	session.inventory = session.keen.inventory
	return session
