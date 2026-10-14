extends "res://tests/test_case.gd"
## Checks the decoders against the real Keen 1 files. Skipped when the game
## data is not available (the files are never part of the repository).


func run_all() -> void:
	if GameFiles.locate() == null:
		skip("no Keen 1 game data found")
		return
	super.run_all()


func test_graphics_have_expected_counts() -> void:
	var graphics := EgaGraphics.load_from(GameFiles.locate())
	assert_true(graphics != null, "graphics should load")
	if graphics == null:
		return
	assert_equal(graphics.tiles.size(), 611, "tile count")
	assert_equal(graphics.font_chars.size(), 256, "font character count")
	assert_equal(graphics.sprites.size(), 119, "sprite count")
	assert_equal(graphics.bitmaps.size(), 18, "bitmap count")
	assert_equal(graphics.header.sprites[0].name, "KEENWALKR1", "first sprite name")
	assert_equal(graphics.find_bitmap("TITLE").get_size(), Vector2i(264, 112), "title size")


func test_every_level_can_be_read() -> void:
	var files := GameFiles.locate()
	for number in files.level_numbers():
		var level := LevelData.parse(files.read(GameFiles.level_file_name(number)))
		assert_true(level != null, "level %d should load" % number)


func test_first_level_has_known_size() -> void:
	var files := GameFiles.locate()
	var level := LevelData.parse(files.read(GameFiles.level_file_name(1)))
	assert_equal(Vector2i(level.width, level.height), Vector2i(120, 21), "level 1 size")


## The original screen shows 320x200 pixels and never scrolls past the border,
## so every map must be at least that big.
func test_playable_areas_fill_the_original_screen() -> void:
	var files := GameFiles.locate()
	for number in files.level_numbers():
		var level := LevelData.parse(files.read(GameFiles.level_file_name(number)))
		var size := LevelMap.playable_pixels(level).size
		assert_true(
			size.x >= DisplaySettings.ORIGINAL_SIZE.x and size.y >= DisplaySettings.ORIGINAL_SIZE.y,
			"level %d is only %s pixels" % [number, size]
		)


func test_every_level_has_one_player_start() -> void:
	var files := GameFiles.locate()
	for number in range(1, 17) + [GameFiles.WORLD_MAP_LEVEL]:
		var level := LevelData.parse(files.read(GameFiles.level_file_name(number)))
		assert_equal(
			level.infos.count(LevelData.PLAYER_START_INFO), 1, "starts in level %d" % number
		)


func test_first_level_starts_at_known_cell() -> void:
	var files := GameFiles.locate()
	var level := LevelData.parse(files.read(GameFiles.level_file_name(1)))
	assert_equal(level.find_info(LevelData.PLAYER_START_INFO), Vector2i(3, 15), "level 1 start")


func test_tile_properties_are_found_in_the_executable() -> void:
	var properties := TileProperties.load_from(GameFiles.locate(), 611)
	assert_true(properties != null, "tile properties should load")
	if properties == null:
		return
	var foreground := 0
	for tile in properties.tile_count:
		if properties.is_foreground(tile):
			foreground += 1
	assert_equal(foreground, 32, "foreground tiles")
	assert_equal(
		properties.floor_type(LevelData.parse(_level_file(1)).tile_at(Vector2i(3, 17))),
		1,
		"floor under the start of level 1"
	)
	assert_true(properties.blocks_left(182), "red wall block is solid")
	assert_true(properties.is_deadly(266), "fire is deadly")
	assert_equal(properties.animation_frames(83), 4, "frames of tile 83")
	assert_equal(properties.animated_tile(86, 1), 83, "tile 86 wraps to 83")
	assert_equal(properties.floor_type(405), TileProperties.Floor.ICE, "ice block")


## Keen must land on solid ground at the start of every level, not fall out or
## into something deadly.
func test_keen_lands_safely_in_every_level() -> void:
	var files := GameFiles.locate()
	var properties := TileProperties.load_from(files, 611)
	for number in range(GameFiles.FIRST_LEVEL, GameFiles.LAST_LEVEL + 1):
		var level := LevelData.parse(_level_file(number))
		var start := level.find_info(LevelData.PLAYER_START_INFO) * EgaGraphics.TILE_SIZE
		var keen := KeenBody.create(LevelCollision.create(level, properties), Vector2(start))
		for tick in KeenPhysics.TICKS_PER_SECOND * 2:
			keen.step(KeenInput.create(0))
		assert_true(not keen.is_dead, "Keen died at the start of level %d" % number)
		assert_equal(keen.state, KeenBody.State.STANDING, "Keen stands in level %d" % number)


## Confirms the meaning of behaviors 2-5 and 18-21: every level with a door
## of some color also has a keycard of that color.
func test_every_door_has_a_keycard_of_its_color() -> void:
	var properties := TileProperties.load_from(GameFiles.locate(), 611)
	var first_card := TileProperties.Behavior.KEYCARD_YELLOW
	for number in range(GameFiles.FIRST_LEVEL, GameFiles.LAST_LEVEL + 1):
		var level := LevelData.parse(_level_file(number))
		var door_colors := {}
		var card_colors := {}
		for tile in level.tiles:
			if properties.is_door(tile):
				door_colors[properties.door_color(tile)] = true
			elif properties.behavior(tile) >= first_card and properties.is_item(tile):
				card_colors[properties.behavior(tile) - first_card] = true
		for color: int in door_colors:
			assert_true(card_colors.has(color), "keycard %d in level %d" % [color, number])


## Every enemy must start inside the level, not stuck in a wall or floor
## through which it would fall out.
func test_enemies_start_in_a_valid_place() -> void:
	var properties := TileProperties.load_from(GameFiles.locate(), 611)
	for number in range(GameFiles.FIRST_LEVEL, GameFiles.LAST_LEVEL + 1):
		var level := LevelData.parse(_level_file(number))
		var start := Vector2(level.find_info(LevelData.PLAYER_START_INFO) * EgaGraphics.TILE_SIZE)
		var session := LevelSession.create(level, properties, Inventory.new(), start, number)
		for enemy in session.enemies():
			enemy.is_active = true
		for tick in KeenPhysics.TICKS_PER_SECOND:
			for enemy in session.enemies():
				enemy.step(session)
		for enemy in session.enemies():
			assert_true(not enemy.removed, "enemy fell out of level %d" % number)


func _level_file(number: int) -> PackedByteArray:
	return GameFiles.locate().read(GameFiles.level_file_name(number))
