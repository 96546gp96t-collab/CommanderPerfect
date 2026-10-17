extends "res://tests/test_case.gd"
## Checks the decoders against the player's real Keen 2 files. Skipped when
## they are not available: Keen 2 is not shareware, so this only runs where
## the player put their own files in game_data/keen2 (they are never part of
## the repository). The numbers come from docs/keen2/research.md.

const TILE_COUNT := 689
const SPRITE_COUNT := 134
const CITY_COUNT := 8
const NEW_SOUND := "EARTHPOW"
const TEXT_WIDTH := 40
## Facts of version 1.31, read from the files (docs/keen2/research.md).
const CITY_NAMES: PackedStringArray = [
	"London", "Cairo", "Sydney", "New York", "Paris", "Rome", "Moscow", "Wash D.C."
]
const CITY_LEVELS: PackedInt32Array = [4, 6, 7, 9, 11, 13, 15, 16]
const ELDER_LEVELS: PackedInt32Array = [8, 10]
const ELDER_MESSAGE_LINES: PackedInt32Array = [8, 11]
const SPRITE_NAMES: Dictionary[int, String] = {
	48: "YOUTHLEFT1",
	52: "YOUTHRIGHT1",
	74: "GRUNTLEFT1",
	78: "GRUNTRIGHT1",
	84: "GRUNTJUMPL",
	85: "GRUNTJUMPR",
	96: "ELITEFIREL",
	98: "ELITEJUMPL",
	99: "ELITEJUMPR",
	102: "SCRUBL1",
	112: "GUARDLEFT1",
	116: "GUARDRIGHT1",
	120: "GUARDSTAND1",
	122: "KEENSHOT",
	123: "TANKSHOT",
	126: "PLATFORM1",
	128: "SPARK1",
}
const RAYGUN_ICON := 175
const KEYCARD_ICONS: PackedInt32Array = [190, 191, 192, 193]
const EARTH_FIRST_TILE := 572
const EARTH_LAST_TILE := 600
const SHIP_CELL := Vector2i(6, 5)
const SHIP_TILE := 593
## The row of the status box with "TARGETS SAVED" and "KEYS".
const STATUS_TARGETS_ROW := 6

var _files: GameFiles
var _executable: Keen2Executable


func run_all() -> void:
	_files = Keen2Files.locate()
	if _files == null:
		skip("no Keen 2 game data found")
		return
	_executable = Keen2Executable.load_from(_files)
	super.run_all()


func test_graphics_have_expected_counts() -> void:
	var graphics := EgaGraphics.load_from(_files, Keen2Files.EXTENSION)
	assert_true(graphics != null, "graphics should load")
	if graphics == null:
		return
	assert_equal(graphics.tiles.size(), TILE_COUNT, "tile count")
	assert_equal(graphics.sprites.size(), SPRITE_COUNT, "sprite count")


func test_every_map_loads() -> void:
	for number in Keen2Files.expected_level_numbers():
		var file_name := _files.level_file(number)
		assert_true(_files.has_file(file_name), "%s is there" % file_name)
		assert_true(LevelData.parse(_files.read(file_name)) != null, "%s loads" % file_name)


func test_finale_loads() -> void:
	assert_true(FinaleImage.load_from(_files, Keen2Files.FINALE) != null, "FINALE.CK2")


func test_executable_has_a_known_version() -> void:
	assert_true(_executable != null, "KEEN2.EXE unpacks")
	if _executable != null:
		assert_true(_executable.version != Keen2Executable.UNKNOWN_VERSION, "a known version")


func test_tile_properties_are_found() -> void:
	if _executable == null:
		return
	assert_true(_executable.tile_properties(TILE_COUNT) != null, "the tile table")


func test_sounds_include_the_earth_exploding() -> void:
	if _executable == null:
		return
	var sounds := _executable.sounds()
	assert_true(sounds != null, "the sound block parses")
	if sounds != null:
		assert_true(sounds.sounds.has(NEW_SOUND), "Keen 2's new sound")


func test_texts_are_found() -> void:
	if _executable == null:
		return
	for block in Keen2Executable.TextBlock.size():
		var text := _executable.text(block as Keen2Executable.TextBlock)
		var name: String = Keen2Executable.TextBlock.keys()[block]
		assert_true(not text.is_empty(), "%s is found" % name)
		if not text.is_empty():
			assert_true(TextDocument.layout(text, TEXT_WIDTH).size() > 1, "%s has lines" % name)


func test_eight_city_names() -> void:
	if _executable == null:
		return
	var names := _executable.city_names()
	assert_equal(names.size(), CITY_COUNT, "eight cities")
	assert_true(_executable.to_be_continued().begins_with("TO BE CONTINUED"), "the last record")


func test_city_names_are_the_eight_cities() -> void:
	if _executable == null:
		return
	assert_equal(_executable.city_names(), CITY_NAMES, "the names, in level order")


func test_elder_messages_are_found() -> void:
	if _executable == null:
		return
	for index in ELDER_MESSAGE_LINES.size():
		var lines := _executable.elder_message(index)
		assert_equal(lines.size(), ELDER_MESSAGE_LINES[index], "lines of message %d" % index)
		assert_true(not "\n".join(lines).contains("ENTER"), "message %d has no prompt" % index)


func test_sprite_names_fit_the_enemies() -> void:
	var header := EgaHeader.parse(_files.read("EGAHEAD.CK2"))
	assert_true(header != null, "EGAHEAD.CK2")
	if header == null:
		return
	for sprite in SPRITE_NAMES:
		assert_equal(header.sprites[sprite].name, SPRITE_NAMES[sprite], "sprite %d" % sprite)


func test_collision_boxes_come_from_the_sprite_table() -> void:
	var header := EgaHeader.parse(_files.read("EGAHEAD.CK2"))
	if header == null:
		return
	var boxes: Dictionary[int, Rect2] = {
		Keen2Grunt.SPRITE_WALK_LEFT: Keen2Grunt.BODY_BOX,
		Keen2Elite.SPRITE_WALK_LEFT: Keen2Elite.BODY_BOX,
		Keen2Youth.SPRITE_RUN_LEFT: Keen2Youth.BODY_BOX,
		Keen2Scrub.SPRITE_FIRST: Keen2Scrub.BODY_BOX,
		Keen2GuardRobot.SPRITE_HOVER_LEFT: Keen2GuardRobot.BODY_BOX,
		Keen2Platform.SPRITE_FIRST: Keen2Platform.BODY_BOX,
		Keen2Spark.SPRITE_FIRST: Keen2Spark.BODY_BOX,
	}
	for sprite in boxes:
		var hitbox: Rect2i = header.sprites[sprite].hitbox
		# The table holds the last pixel inside the box, not the one after it.
		var box := Rect2(hitbox.position, hitbox.size + Vector2i.ONE)
		assert_equal(box, boxes[sprite], "box of sprite %d" % sprite)


func test_switch_and_item_tiles_have_their_behaviour() -> void:
	var properties := _properties()
	if properties == null:
		return
	assert_equal(
		properties.behavior(Keen2Switches.LEVER_UP), Keen2Switches.BEHAVIOR_SWITCH_UP, "up"
	)
	assert_equal(
		properties.behavior(Keen2Switches.LEVER_DOWN), Keen2Switches.BEHAVIOR_SWITCH_DOWN, "down"
	)
	assert_equal(Keen2Icons.raygun(properties), RAYGUN_ICON, "raygun icon")
	assert_equal(Keen2Icons.keycards(properties), KEYCARD_ICONS, "keycard icons")


func test_only_levels_8_and_10_have_an_elder() -> void:
	var properties := _properties()
	if properties == null:
		return
	var levels := PackedInt32Array()
	for number in range(Keen2Files.FIRST_LEVEL, Keen2Files.LAST_LEVEL + 1):
		var level := LevelData.parse(_files.read(_files.level_file(number)))
		for cell in _cells(level):
			if cell.y + 1 >= level.height:
				continue
			var below := level.tile_at(cell + Vector2i.DOWN)
			if properties.is_hint(level.tile_at(cell)) and below == Keen2LevelSession.ELDER_LIGHT:
				levels.append(number)
	assert_equal(levels, ELDER_LEVELS, "the Elders")


func test_every_city_has_one_machine_with_its_switch() -> void:
	var properties := _properties()
	if properties == null:
		return
	for number in range(Keen2Files.FIRST_LEVEL, Keen2Files.LAST_LEVEL + 1):
		var level := LevelData.parse(_files.read(_files.level_file(number)))
		var sparks: Array[Vector2i] = []
		for cell in _cells(level):
			if level.info_at(cell) == Keen2LevelSession.INFO_SPARK:
				sparks.append(cell)
		assert_equal(sparks.size(), 1 if number in CITY_LEVELS else 0, "sparks in %d" % number)
		for spark in sparks:
			var lever := level.tile_at(spark + Keen2Tantalus.SWITCH_OFFSET)
			assert_equal(lever, Keen2Switches.LEVER_UP, "the switch of level %d" % number)


func test_map_81_has_the_earth_and_the_ship() -> void:
	var level := LevelData.parse(_files.read(_files.level_file(Keen2Files.SPACE_LEVEL)))
	assert_equal(level.tile_at(Keen2EarthExplosion.EARTH_CELL), EARTH_FIRST_TILE, "Earth")
	var last := Keen2EarthExplosion.EARTH_CELL + Vector2i.ONE * (Keen2EarthExplosion.EARTH_SIZE - 1)
	assert_equal(level.tile_at(last), EARTH_LAST_TILE, "the Earth's last tile")
	assert_equal(level.tile_at(last + Vector2i.ONE), Keen2EarthExplosion.SPACE_TILE, "space")
	assert_equal(level.tile_at(SHIP_CELL), SHIP_TILE, "the ship's start")


func test_status_box_and_ending_texts_are_found() -> void:
	if _executable == null:
		return
	var box := _executable.status_box_lines()
	assert_equal(box.size(), Keen2Executable.STATUS_BOX_LINES, "the status box")
	if box.size() == Keen2Executable.STATUS_BOX_LINES:
		assert_true(box[STATUS_TARGETS_ROW].contains("TARGETS SAVED"), "its labels")
	for which in Keen2Executable.EndingText.size():
		var lines := _executable.ending_text(which as Keen2Executable.EndingText)
		assert_true(not lines.is_empty(), "ending text %d" % which)
		for line in lines:
			assert_true(line != "finale.ck2", "no file name in text %d" % which)
	var last := _executable.ending_text(Keen2Executable.EndingText.TO_BE_CONTINUED)
	assert_true(not last.is_empty() and last[0].begins_with("TO BE CONTINUED"), "the last page")


func test_world_map_has_an_entrance_for_every_level() -> void:
	var map := LevelData.parse(_files.read(_files.level_file(Keen2Files.WORLD_MAP_LEVEL)))
	assert_true(map != null, "map 80")
	if map == null:
		return
	for number in range(Keen2Files.FIRST_LEVEL, Keen2Files.LAST_LEVEL + 1):
		var found := map.infos.has(number) or map.infos.has(number | MapInfo.BLOCKING_FLAG)
		assert_true(found, "an entrance of level %d" % number)
	assert_true(not map.infos.has(MapInfo.SHIP), "no ship")
	assert_true(map.find_info(LevelData.PLAYER_START_INFO).x >= 0, "Keen's start")


func _properties() -> TileProperties:
	return _executable.tile_properties(TILE_COUNT) if _executable != null else null


func _cells(level: LevelData) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in level.height:
		for x in level.width:
			cells.append(Vector2i(x, y))
	return cells
