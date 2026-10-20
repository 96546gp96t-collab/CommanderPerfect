extends "res://tests/test_case.gd"
## Tests for what a Keen 4 host sends the player who joins (milestone D12):
## the Galaxy snapshot there and back over the wire (the view, every sprite
## with the two Keens marked, sounds, song, brightness, the box, Keen 4's
## numbers), the shared inventory and progress ([Keen4OnlineState]), the
## changed tiles of all three planes in a scene and one by one, the boxes
## named on the host and drawn again from the joiner's own files, and every
## broken message refused. The boxes and a real level need the player's
## files; the rest is made by hand.

const Fixtures := preload("res://tests/galaxy_keen_fixtures.gd")
const Coop := preload("res://tests/galaxy_coop_fixtures.gd")
const Creatures := preload("res://tests/keen4_creature_fixtures.gd")
const FIELD: PackedStringArray = [
	"....................",
	"....................",
	"....................",
	"K.........$.........",
	"####################",
]
const SLUG := 22
const SCENE_ID := 12

var _data: GalaxyData


func _init() -> void:
	var files := Keen4Files.locate()
	if files != null:
		_data = Keen4Episode.load_data(files)


func test_snapshot_there_and_back_with_two_keens() -> void:
	var world := Creatures.world(FIELD, SLUG, [Vector2i(14, 3)])
	var keen := world.player()
	var partner := Coop.add_partner(world, Vector2i(6, 3))
	Coop.hold(world, 3, Coop.still(), Coop.still())
	var sent := GalaxySnapshot.new()
	sent.scene = SCENE_ID
	sent.view = Vector2i(512, 768)
	sent.add_objects(world.objects, keen, partner)
	sent.sounds = PackedByteArray([3, 7 + GalaxySnapshot.INTERRUPT])
	sent.song = 5
	sent.brightness = 50
	sent.box = PackedInt32Array([Keen4BoxNames.Kind.TRY_AGAIN, 4, 1, 9, 0])
	var inventory := Keen4Inventory.new_game()
	inventory.score = 123456
	sent.extra = Keen4OnlineState.pack(inventory, Keen4Progress.new(), 1)
	var got := GalaxySnapshot.from_message(bytes_to_var(var_to_bytes(sent.to_message())))
	assert_true(got != null, "it arrives whole")
	assert_equal(got.scene, SCENE_ID, "the scene")
	assert_equal(got.view, Vector2i(512, 768), "the view")
	assert_equal(got.figures, sent.figures, "every sprite")
	assert_equal(got.sounds, sent.sounds, "the sounds")
	assert_equal([got.song, got.brightness], [5, 50], "song and brightness")
	assert_equal(got.box, sent.box, "the box")
	assert_equal(got.extra, sent.extra, "Keen 4's numbers")
	var hosts := 0
	var partners := 0
	for index in got.figure_count():
		var flags := got.figures[index * GalaxySnapshot.FIGURE_FIELDS + 3]
		hosts += 1 if flags & GalaxySnapshot.HOST_KEEN else 0
		partners += 1 if flags & GalaxySnapshot.PARTNER_KEEN else 0
		if flags & GalaxySnapshot.PARTNER_KEEN:
			var at := index * GalaxySnapshot.FIGURE_FIELDS
			var place := Vector2i(got.figures[at], got.figures[at + 1])
			assert_equal(place, partner.position + partner.draw_offset, "player 2's place")
	assert_equal([hosts, partners], [1, 1], "each Keen marked once")
	assert_true(got.figure_count() >= 3, "two Keens and the slug at least")


func test_alone_no_keen_is_marked_as_partner() -> void:
	var world := Fixtures.world(FIELD)
	var snapshot := GalaxySnapshot.new()
	snapshot.add_objects(world.objects, world.player(), null)
	for index in snapshot.figure_count():
		var flags := snapshot.figures[index * GalaxySnapshot.FIGURE_FIELDS + 3]
		assert_true(flags & GalaxySnapshot.PARTNER_KEEN == 0, "no partner")


func test_keen_4_numbers_there_and_back() -> void:
	var inventory := Keen4Inventory.new_game()
	inventory.score = 987654
	inventory.lives = 7
	inventory.shots = 23
	inventory.drops = 99
	inventory.gems = PackedInt32Array([1, 0, 2, 1])
	inventory.next_life_at = 160000
	var progress := Keen4Progress.new()
	progress.rescued = 5
	progress.wetsuit = true
	for level in [1, 2, 9, 17, 18]:
		progress.mark_done(level)
	var numbers := Keen4OnlineState.pack(inventory, progress, GalaxyDifficulty.Level.HARD)
	assert_true(Keen4OnlineState.is_sane(numbers), "sane")
	assert_true(numbers.size() <= GalaxySnapshot.MAX_EXTRA, "fits the snapshot")
	var got_inventory := GalaxyInventory.new()
	var got_progress := Keen4Progress.new()
	Keen4OnlineState.unpack(numbers, got_inventory, got_progress)
	assert_equal(got_inventory.score, 987654, "the score")
	assert_equal(got_inventory.lives, 7, "the lives")
	assert_equal(got_inventory.shots, 23, "the charges")
	assert_equal(got_inventory.drops, 99, "the drops")
	assert_equal(got_inventory.gems, PackedInt32Array([1, 0, 2, 1]), "the gems")
	assert_equal(got_inventory.next_life_at, 160000, "the next extra life")
	assert_equal(got_progress.rescued, 5, "the rescued")
	assert_true(got_progress.wetsuit, "the wetsuit")
	assert_equal(got_progress.done_levels(), progress.done_levels(), "the levels done")
	assert_equal(numbers[Keen4OnlineState.Field.DIFFICULTY], 2, "the difficulty")
	inventory.lives = -1
	var over := Keen4OnlineState.pack(inventory, progress, 0)
	assert_true(Keen4OnlineState.is_sane(over), "game over (-1 lives) is sane")


func test_broken_keen_4_numbers_change_nothing() -> void:
	var good := Keen4OnlineState.pack(Keen4Inventory.new_game(), Keen4Progress.new(), 1)
	var cases: Array[Array] = [
		[Keen4OnlineState.Field.SCORE, -5],
		[Keen4OnlineState.Field.LIVES, 5000],
		[Keen4OnlineState.Field.RESCUED, 9],
		[Keen4OnlineState.Field.DIFFICULTY, 7],
		[Keen4OnlineState.Field.GEMS, -1],
	]
	for case in cases:
		var bad := good.duplicate()
		bad[case[0]] = case[1]
		assert_true(not Keen4OnlineState.is_sane(bad), "field %d = %d refused" % case)
		var inventory := GalaxyInventory.new()
		inventory.score = 42
		Keen4OnlineState.unpack(bad, inventory, Keen4Progress.new())
		assert_equal(inventory.score, 42, "nothing taken from field %d" % case[0])
	assert_true(not Keen4OnlineState.is_sane(good.slice(1)), "one short")


func test_changed_tiles_of_three_planes_in_a_scene() -> void:
	var original := Fixtures.level(FIELD)
	var map := Fixtures.level(FIELD)
	map.planes[GalaxyMap.Layer.BACKGROUND][3 * map.width + 4] = 77
	map.planes[GalaxyMap.Layer.FOREGROUND][5 * map.width + 12] = 0
	map.planes[GalaxyMap.Layer.INFO][2 * map.width + 9] = 0x1234
	var tiles := GalaxyOnlineMessages.changed_tiles(map, original)
	assert_equal(tiles.size(), 3 * GalaxyOnlineMessages.TILE_FIELDS, "one tile in each plane")
	var message := GalaxyOnlineMessages.scene(SCENE_ID, GalaxyOnlineMessages.Scene.MAP, 4, tiles)
	var read := GalaxyOnlineMessages.read_scene(bytes_to_var(var_to_bytes(message)))
	assert_equal(read.size(), 4, "read back")
	assert_equal(read[0], SCENE_ID, "its id")
	assert_equal(read[1], GalaxyOnlineMessages.Scene.MAP, "a map is played")
	assert_equal(read[2], 4, "map 4")
	var joiner := Fixtures.level(FIELD)
	GalaxyOnlineMessages.apply_tiles(joiner, read[3])
	for layer in GalaxyMap.PLANE_COUNT:
		assert_equal(joiner.planes[layer], map.planes[layer], "plane %d as the host's" % layer)
	assert_equal(GalaxyOnlineMessages.changed_tiles(original, original).size(), 0, "none")


func test_a_changed_tile_one_by_one() -> void:
	for layer in GalaxyMap.PLANE_COUNT:
		var message := GalaxyOnlineMessages.tile(SCENE_ID, layer, Vector2i(30, 40), 501)
		var read := GalaxyOnlineMessages.read_tile(bytes_to_var(var_to_bytes(message)))
		assert_equal(read, [SCENE_ID, layer, Vector2i(30, 40), 501], "plane %d" % layer)
	var bad := GalaxyOnlineMessages.tile(SCENE_ID, GalaxyMap.PLANE_COUNT, Vector2i(1, 1), 5)
	assert_equal(GalaxyOnlineMessages.read_tile(bad), [], "no fourth plane")


func test_tiles_changed_in_a_real_level_reach_the_joiner() -> void:
	if _data == null:
		return
	var number := 2
	var session := Keen4LevelSession.start(
		_data, _data.maps.load_map(number), Keen4Inventory.new_game(), 3, 1, number
	)
	session.player.god_mode = true
	session.add_player().god_mode = true
	for frame in 400:
		var two := KeenInput.create(1 if frame % 200 < 150 else -1, frame % 25 == 0)
		session.run_frame(KeenInput.create(-1, frame % 30 == 0), 2, session.world.tic + 2, two)
		if not session.is_playing():
			break
	# As a switch, a bridge or Miragia would: a tile in each plane.
	var world := session.world
	var cell := Vector2i(20, 6)
	world.set_back_tile(cell, session.map.tile(GalaxyMap.Layer.BACKGROUND, 20, 6) + 1)
	world.set_fore_tile(cell, world.fore_tile(20, 6) + 1)
	world.set_info(cell, world.info_at(20, 6) + 1)
	var original := _data.maps.load_map(number)
	var tiles := GalaxyOnlineMessages.changed_tiles(session.map, original)
	var planes := {}
	for start in range(0, tiles.size(), GalaxyOnlineMessages.TILE_FIELDS):
		planes[tiles[start]] = true
	assert_equal(planes.size(), GalaxyMap.PLANE_COUNT, "tiles of all three planes changed")
	var message := GalaxyOnlineMessages.scene(1, GalaxyOnlineMessages.Scene.MAP, number, tiles)
	var read := GalaxyOnlineMessages.read_scene(bytes_to_var(var_to_bytes(message)))
	assert_equal(read.size(), 4, "a scene of a real level is read")
	var bytes := var_to_bytes(message).size()
	assert_true(bytes < OnlineProtocol.MAX_MESSAGE_SIZE, "small enough (%d bytes)" % bytes)
	var joiner := _data.maps.load_map(number)
	GalaxyOnlineMessages.apply_tiles(joiner, read[3] if read.size() == 4 else PackedInt32Array())
	for layer in GalaxyMap.PLANE_COUNT:
		assert_equal(joiner.planes[layer], session.map.planes[layer], "plane %d" % layer)


func test_boxes_are_named_and_made_again_from_the_joiners_files() -> void:
	if _data == null:
		return
	var names := Keen4BoxNames.new()
	var boxes := Keen4NamedBoxes.create_named(_data, names)
	var messages := Keen4NamedMessages.create_named(_data, names)
	var plain_boxes := Keen4GameBoxes.create(_data)
	var plain_messages := Keen4Messages.create(_data)
	var shown: Array[Image] = []
	shown.append_array(boxes.entering(5))
	shown.append(boxes.one_moment())
	shown.append(boxes.paused())
	shown.append(boxes.cant_swim())
	shown.append(boxes.try_again(7, 1, 13))
	shown.append(boxes.game_over())
	shown.append_array(messages.council(4, 2))
	shown.append_array(messages.janitor())
	shown.append_array(messages.lindsey(5))
	shown.append_array(messages.wetsuit())
	for index in shown.size():
		var image := shown[index]
		var name := names.description_of(image)
		assert_true(not name.is_empty(), "box %d is named" % index)
		assert_true(name.size() <= GalaxySnapshot.MAX_BOX, "box %d's name fits" % index)
		var snapshot := GalaxySnapshot.new()
		snapshot.box = name
		var got := GalaxySnapshot.from_message(bytes_to_var(var_to_bytes(snapshot.to_message())))
		var again := Keen4BoxNames.image_for(got.box, plain_boxes, plain_messages)
		assert_true(again != null, "box %d is made again (%s)" % [index, name])
		if again != null:
			assert_equal(again.get_data(), image.get_data(), "box %d: the same picture" % index)


func test_nonsense_box_names_make_no_picture() -> void:
	if _data == null:
		return
	var boxes := Keen4GameBoxes.create(_data)
	var messages := Keen4Messages.create(_data)
	var kind := Keen4BoxNames.Kind
	var names: Array[PackedInt32Array] = [
		PackedInt32Array(),
		PackedInt32Array([99, 0]),
		PackedInt32Array([kind.NONE, 0]),
		PackedInt32Array([kind.ENTERING, 5]),
		PackedInt32Array([kind.ENTERING, 500, 0]),
		PackedInt32Array([kind.ENTERING, -1, 0]),
		PackedInt32Array([kind.PAUSED, 3]),
		PackedInt32Array([kind.COUNCIL, 4, 2, 99]),
		PackedInt32Array([kind.TRY_AGAIN, 30, 0, 0, 0]),
	]
	for name in names:
		assert_true(Keen4BoxNames.image_for(name, boxes, messages) == null, "%s: none" % name)


func test_broken_snapshots_are_refused() -> void:
	var good := GalaxySnapshot.new()
	good.add_figure(Vector2i(100, 200), 5, 1)
	assert_true(GalaxySnapshot.from_message(good.to_message()) != null, "a good one is read")
	var changes: Array[Array] = [
		[2, GalaxySnapshot.MAX_UNITS],
		[3, -GalaxySnapshot.MAX_UNITS],
		[6, GalaxySnapshot.MAX_SONG + 1],
		[6, -2],
		[7, GalaxySnapshot.FULL_BRIGHTNESS + 1],
		[1, "scene"],
		[4, PackedFloat32Array([1, 2, 3, 4])],
		[4, PackedInt32Array([1, 2, 3])],
		[4, PackedInt32Array([1, 2, GalaxySnapshot.MAX_SPRITE, 0])],
		[4, PackedInt32Array([1, 2, -1, 0])],
		[4, PackedInt32Array([1, 2, 3, GalaxySnapshot.FLAG_MASK + 1])],
		[5, _filled_bytes(GalaxySnapshot.MAX_SOUNDS + 1)],
		[8, _filled_ints(GalaxySnapshot.MAX_BOX + 1)],
		[9, _filled_ints(GalaxySnapshot.MAX_EXTRA + 1)],
		[4, _filled_ints((GalaxySnapshot.MAX_FIGURES + 1) * GalaxySnapshot.FIGURE_FIELDS)],
	]
	for change in changes:
		var message := good.to_message()
		message[change[0]] = change[1]
		assert_true(GalaxySnapshot.from_message(message) == null, "part %d broken" % change[0])
	var short := good.to_message()
	short.pop_back()
	assert_true(GalaxySnapshot.from_message(short) == null, "a part short")
	var long := good.to_message()
	long.append(1)
	assert_true(GalaxySnapshot.from_message(long) == null, "a part too many")


func test_broken_scenes_and_tiles_are_refused() -> void:
	var scene := GalaxyOnlineMessages.Scene
	var tiles := PackedInt32Array([0, 1, 2, 3])
	var bad_scenes: Array[Array] = [
		[OnlineProtocol.Message.GALAXY_SCENE, 1, scene.size(), 4, tiles],
		[OnlineProtocol.Message.GALAXY_SCENE, 1, -1, 4, tiles],
		[
			OnlineProtocol.Message.GALAXY_SCENE,
			1,
			scene.MAP,
			GalaxyOnlineMessages.MAX_MAP + 1,
			tiles
		],
		[OnlineProtocol.Message.GALAXY_SCENE, 1, scene.MAP, 4, PackedInt32Array([0, 1, 2])],
		[OnlineProtocol.Message.GALAXY_SCENE, 1, scene.MAP, 4, PackedInt32Array([3, 1, 2, 4])],
		[OnlineProtocol.Message.GALAXY_SCENE, 1, scene.MAP, 4, PackedInt32Array([0, -1, 2, 4])],
		[OnlineProtocol.Message.GALAXY_SCENE, 1, scene.MAP, 4, PackedInt32Array([0, 1, 2, 70000])],
		[OnlineProtocol.Message.GALAXY_SCENE, 1, scene.MAP, 4, [0, 1, 2, 3]],
		[OnlineProtocol.Message.GALAXY_SCENE, 1, scene.MAP, 4],
		[OnlineProtocol.Message.GALAXY_SCENE, "1", scene.MAP, 4, tiles],
	]
	for message in bad_scenes:
		assert_equal(GalaxyOnlineMessages.read_scene(message), [], "%s refused" % [message])
	var bad_tiles: Array[Array] = [
		[OnlineProtocol.Message.GALAXY_TILE, 1, 0, GalaxyOnlineMessages.MAX_CELL, 2, 3],
		[OnlineProtocol.Message.GALAXY_TILE, 1, 0, 1, 2, -3],
		[OnlineProtocol.Message.GALAXY_TILE, 1, 0, 1, 2],
		[OnlineProtocol.Message.GALAXY_TILE, 1, 0, 1.5, 2, 3],
	]
	for message in bad_tiles:
		assert_equal(GalaxyOnlineMessages.read_tile(message), [], "%s refused" % [message])
	var map := Fixtures.level(FIELD)
	var before := map.planes.duplicate(true)
	GalaxyOnlineMessages.apply_tiles(map, PackedInt32Array([1, 5000, 1, 7, 1, 1, 5000, 7]))
	assert_equal(map.planes, before, "tiles outside the map change nothing")


static func _filled_ints(count: int) -> PackedInt32Array:
	var numbers := PackedInt32Array()
	numbers.resize(count)
	return numbers


static func _filled_bytes(count: int) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(count)
	return bytes
