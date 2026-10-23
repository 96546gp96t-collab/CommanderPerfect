extends "res://tests/test_case.gd"
## Checks the shared Galaxy game's rules, start and level session
## (milestone E3; [GalaxyGameRules], [GalaxyStart], [GalaxyLevelSession])
## with a hand-made episode ([code]galaxy_game_fixtures.gd[/code]), so no
## game's files are needed: the levels after each other over a missing
## map, the items by info value (one beyond the range, the stunner for few
## charges), Keen's start, the row blocks only, the hooks an episode fills
## in (its own Keen, what he can do, its info values), how a level ends
## (walking out, an object's ending, falling below) and that the gems go
## either way, and a second player.

const Game := preload("res://tests/galaxy_game_fixtures.gd")
const Keen := preload("res://tests/galaxy_keen_fixtures.gd")

const TILE := 256
const STANDING_RISE := 241
const RUN_FRAMES := 120
const FALL_FRAMES := 200
const FEW_SHOTS := 2
## A room (inside the border) as large as the view: the camera's limits
## then lie inside the map.
const BIG_ROOM_SIZE := Vector2i(20, 14)
const OPEN_ROOM: PackedStringArray = [
	"..............",
	"..............",
	"..............",
	"..............",
	"....K.........",
	"##############",
]


## A level session whose Keen and info values are the test's own.
class HookedSession:
	extends GalaxyLevelSession
	var placed: Array[Vector3i] = []
	var set_up := 0

	func _new_keen() -> GalaxyKeen:
		return MarkedKeen.new()

	func _set_up_keen(walker: GalaxyKeen) -> void:
		super(walker)
		set_up += 1

	func _place_info(info: int, cell: Vector2i) -> void:
		placed.append(Vector3i(cell.x, cell.y, info))


class MarkedKeen:
	extends GalaxyKeen


func test_the_levels_follow_each_other_over_a_missing_map() -> void:
	var rules := Game.rules()
	assert_true(rules.is_level(Game.FIRST_LEVEL), "level 1")
	assert_true(not rules.is_level(Game.MISSING_MAP), "the missing map is no level")
	assert_true(not rules.is_level(Game.WORLD_MAP), "the world map is no level")
	assert_true(not rules.is_level(Game.LAST_MAP), "nor the last map")
	assert_equal(rules.next_level(Game.FIRST_LEVEL), 3, "over the missing map")
	assert_equal(rules.next_level(Game.LAST_LEVEL), Game.FIRST_LEVEL, "the first after the last")


func test_items_by_info_value() -> void:
	var rules := Game.rules()
	assert_equal(rules.item_of_info(Game.FIRST_ITEM_INFO), 0, "the first item")
	assert_equal(rules.item_of_info(Game.LAST_ITEM_INFO), 11, "the stunner")
	assert_equal(rules.item_of_info(Game.MORE_ITEM_INFO), Game.MORE_ITEM, "one beyond the range")
	assert_equal(rules.item_of_info(Game.LOW_STUNNER_INFO), -1, "the low stunner depends")
	assert_equal(rules.item_of_info(Game.MORE_ITEM_INFO + 1), -1, "no item")
	assert_equal(rules.charges_for(GalaxyDifficulty.Level.EASY), 8, "8 charges on Easy")
	assert_equal(rules.charges_for(GalaxyDifficulty.Level.HARD), 5, "5 otherwise")


func test_the_messages_name_the_episode() -> void:
	var rules := Game.rules()
	var missing := rules.missing_data_message()
	assert_true(missing.begins_with(Game.NAME + " data not found"), missing)
	assert_true(Game.DATA_FOLDER in missing and Game.DATA_OPTION in missing, missing)
	assert_true(Game.NAME in rules.unreadable_message("x"), "unreadable")


func test_level_sprites_hold_both_frames_of_every_item() -> void:
	var rules := Game.rules()
	var sprites := rules.level_sprites()
	for item in Keen4Sprites.ITEM_FIRST_FRAMES:
		assert_true(sprites.has(item) and sprites.has(item + 1), "item %d" % item)
	assert_true(sprites.has(rules.sprites[&"STAND_R"]), "Keen")


func test_keen_starts_by_the_rules() -> void:
	var rules := Game.rules()
	var map := Keen.level(OPEN_ROOM)
	var start := GalaxyStart.find(map, rules)
	assert_true(start.is_standing(), "standing")
	assert_equal(start.cell, Vector2i(6, 6), "at K")
	assert_equal(start.position, Vector2i(6 * TILE, 6 * TILE - STANDING_RISE), "241 above")
	assert_equal(start.sprite, rules.keen_stand_right_sprite, "facing right")
	Keen.put_info(map, Vector2i(4, 4), rules.keen_left_info)
	Keen.put_info(map, Vector2i(1, 1), rules.map_keen_info)
	start = GalaxyStart.find(map, rules)
	assert_true(start.is_world_map(), "the first one row by row: on the world map")
	assert_equal(start.sprite, Game.MAP_KEEN_SPRITE, "the map sprite")
	assert_equal(
		GalaxyStart.find(Keen.level(["...", "###"]), rules).kind, GalaxyStart.Kind.NONE, "none"
	)


func test_a_map_without_keen_is_no_level() -> void:
	var rules := Game.rules()
	var map := Keen.level(["......", "######"])
	var carried := GalaxyInventory.new()
	assert_true(
		GalaxyLevelSession.start_level(Game.data(), rules, map, carried) == null, "no level"
	)


func test_only_row_blocks_when_the_episode_has_no_column_blocks() -> void:
	var rules := Game.rules()
	var map := Keen.level(OPEN_ROOM)
	Keen.put_info(map, Vector2i(1, 2), Game.ROW_BLOCK_INFO)
	Keen.put_info(map, Vector2i(9, 2), Game.ROW_BLOCK_INFO + 1)
	var session := GalaxyLevelSession.start_level(Game.data(), rules, map, GalaxyInventory.new())
	assert_true(session.camera.row_blocks.has(4), "the row of info 25")
	assert_true(not session.camera.column_blocks.has(11), "26 is no column block here")
	assert_equal(session.camera.column_blocks.size(), 2, "only the map's edges")


func test_items_are_placed_and_sleep() -> void:
	var rules := Game.rules()
	var map := Keen.level(OPEN_ROOM)
	Keen.put_info(map, Vector2i(1, 1), Game.FIRST_ITEM_INFO + 4)
	Keen.put_info(map, Vector2i(2, 1), Game.MORE_ITEM_INFO)
	Keen.put_info(map, Vector2i(3, 1), Game.LOW_STUNNER_INFO)
	var carried := GalaxyInventory.new()
	carried.shots = Game.START_SHOTS
	var session := GalaxyLevelSession.start_level(Game.data(), rules, map, carried)
	assert_equal(_item_kinds(session), [4, Game.MORE_ITEM], "two items; enough charges")
	for object in session.world.objects:
		if object is GalaxyItem:
			assert_equal(object.activity, GalaxyObject.Activity.INACTIVE, "items sleep")
	carried.shots = FEW_SHOTS
	session = GalaxyLevelSession.start_level(Game.data(), rules, map, carried)
	assert_true(_item_kinds(session).has(GalaxyInventory.STUNNER_ITEM), "a stunner for few")


func test_the_hooks_give_the_episode_its_keen_and_its_objects() -> void:
	var rules := Game.rules()
	var map := Keen.level(OPEN_ROOM)
	Keen.put_info(map, Vector2i(7, 2), 9)
	var session := HookedSession.new()
	var began := session.begin(
		Game.data(), rules, map, GalaxyInventory.new(), 0, GalaxyDifficulty.Level.EASY, 3
	)
	assert_true(began, "a level")
	assert_true(session.keen is MarkedKeen, "the episode's Keen")
	assert_equal(session.set_up, 1, "set up once")
	assert_true(session.keen.easy_jumps, "easy jumps on Easy")
	assert_equal(session.inventory.charges_per_stunner, 8, "8 charges a stunner on Easy")
	assert_equal(session.placed, [Vector3i(9, 4, 9)], "the other info value, not Keen's")
	assert_equal(session.number, 3, "its number")
	assert_equal(session.world.map_number, 3, "the world knows it")


func test_walking_out_completes_the_level_and_the_gems_go() -> void:
	var session := _session(_big_room(), Vector2i.RIGHT)
	session.inventory.gems = PackedInt32Array([1, 0, 1, 0])
	var right := KeenInput.create(1, false, false)
	for frame in RUN_FRAMES:
		session.run_frame(right, 2, (frame + 1) * 2)
		if not session.is_playing():
			break
	assert_true(session.is_done(), "out of the right side: done")
	assert_equal(session.ending(), &"", "by walking out")
	assert_equal(session.inventory.gems, PackedInt32Array([0, 0, 0, 0]), "gems gone")


func test_an_object_ends_the_level_its_way() -> void:
	var session := _session(OPEN_ROOM)
	session.world.complete(&"by_the_door")
	assert_true(session.is_done(), "done")
	assert_equal(session.ending(), &"by_the_door", "its ending")
	session.run_frame(KeenInput.new(), 2, 2)
	assert_true(session.is_done(), "nothing runs after")


func test_falling_below_the_level_kills_even_in_god_mode() -> void:
	var session := _session(_big_room(), Vector2i.DOWN)
	session.keen.god_mode = true
	for frame in FALL_FRAMES:
		session.run_frame(KeenInput.new(), 2, (frame + 1) * 2)
		if not session.is_playing():
			break
	assert_true(session.is_lost(), "dead")


func test_a_second_player_joins_and_leaves() -> void:
	var session := _session(OPEN_ROOM)
	var partner := session.add_player()
	assert_true(partner is GalaxyKeen, "a walking Keen")
	assert_equal(partner.position, session.keen.position, "where player 1 is")
	assert_true(session.camera_2 != null, "his own view")
	assert_true(partner.inventory == session.inventory, "the shared inventory")
	assert_true(session.add_player() == partner, "only one")
	session.remove_player()
	assert_true(session.partner == null and session.camera_2 == null, "gone")


## A level of [param rows]; with [param open] RIGHT the right edge is
## open on Keen's rows, with DOWN the floor and the bottom edge are gone.
func _session(rows: PackedStringArray, open := Vector2i.ZERO) -> GalaxyLevelSession:
	var map := Keen.level(rows)
	var plane := map.planes[GalaxyMap.Layer.FOREGROUND]
	for y in map.height:
		for x in map.width:
			var right_edge := open == Vector2i.RIGHT and x >= map.width - 3 and y < map.height - 3
			var below := open == Vector2i.DOWN and y >= map.height - 3
			if right_edge or below:
				plane[y * map.width + x] = Keen.EMPTY
	map.planes[GalaxyMap.Layer.FOREGROUND] = plane
	var carried := GalaxyInventory.new()
	return GalaxyLevelSession.start_level(Game.data(), Game.rules(), map, carried)


## A room as large as the view and its border, Keen on its floor.
static func _big_room() -> PackedStringArray:
	var rows := PackedStringArray()
	for row in BIG_ROOM_SIZE.y - 1:
		rows.append(".".repeat(BIG_ROOM_SIZE.x))
	rows[rows.size() - 1] = "....K" + ".".repeat(BIG_ROOM_SIZE.x - 5)
	rows.append("#".repeat(BIG_ROOM_SIZE.x))
	return rows


static func _item_kinds(session: GalaxyLevelSession) -> Array[int]:
	var kinds: Array[int] = []
	for object in session.world.objects:
		var item := object as GalaxyItem
		if item != null:
			kinds.append(item.kind)
	return kinds
