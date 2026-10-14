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
		assert_equal(keen.state, KeenBody.State.STANDING, "Keen starts on the floor in %d" % number)
		var start_y := keen.position.y
		for tick in KeenPhysics.TICKS_PER_SECOND * 2:
			keen.step(KeenInput.create(0))
		assert_true(not keen.is_dead, "Keen died at the start of level %d" % number)
		assert_equal(keen.state, KeenBody.State.STANDING, "Keen stands in level %d" % number)
		assert_equal(keen.position.y, start_y, "Keen did not fall in level %d" % number)


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


## The statue messages are found, and the levels they belong to are exactly
## the levels with a statue.
func test_statue_messages_match_the_statues() -> void:
	var files := GameFiles.locate()
	var hints := HintTexts.load_from(files)
	assert_true(hints != null, "messages found")
	if hints == null:
		return
	assert_equal(hints.messages.size(), HintTexts.HINT_LEVELS.size(), "one per statue")
	assert_equal(hints.for_level(11)[3].strip_edges(), "GAAARRRRRGG!", "the Garg statue")
	var properties := TileProperties.load_from(files, 611)
	for number in range(GameFiles.FIRST_LEVEL, GameFiles.LAST_LEVEL + 1):
		var level := LevelData.parse(_level_file(number))
		var has_statue := Array(level.tiles).any(
			func(tile: int) -> bool: return properties.is_hint(tile)
		)
		assert_equal(has_statue, HintTexts.HINT_LEVELS.has(number), "statue in level %d" % number)


## The world map has an entrance for every level, the ship, and the three
## teleporters whose destinations [MapSession] knows.
func test_world_map_has_all_entrances() -> void:
	var map := LevelData.parse(_level_file(GameFiles.WORLD_MAP_LEVEL))
	var levels := {}
	for info in map.infos:
		if MapInfo.level_of(info) != 0:
			levels[MapInfo.level_of(info)] = true
	assert_equal(levels.size(), GameFiles.LAST_LEVEL, "an entrance for every level")
	assert_true(map.find_info(MapInfo.SHIP).x >= 0, "the ship")
	for teleporter: int in MapSession.TELEPORTER_DESTINATIONS:
		assert_true(map.find_info(teleporter).x >= 0, "teleporter %d" % teleporter)
	assert_true(map.find_info(MapSession.SECRET_DESTINATION).x >= 0, "secret destination")
	assert_equal(map.find_info(LevelData.PLAYER_START_INFO), Vector2i(12, 37), "start")


## Every level can be reached from the start: on foot, through teleporters,
## past blocking entrances once their level is done, and through the
## teleporter in level 13.
func test_every_level_can_be_reached() -> void:
	var map := LevelData.parse(_level_file(GameFiles.WORLD_MAP_LEVEL))
	var properties := TileProperties.load_from(GameFiles.locate(), 611)
	var game := GameProgress.new()
	var collision := MapCollision.create_for_map(map, properties, game)
	var reached := {}
	var queue: Array[Vector2i] = [map.find_info(LevelData.PLAYER_START_INFO)]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_back()
		if reached.has(cell):
			continue
		reached[cell] = true
		var info := map.info_at(cell)
		var next: Array[Vector2i] = [
			cell + Vector2i.LEFT, cell + Vector2i.RIGHT, cell + Vector2i.UP, cell + Vector2i.DOWN
		]
		if MapInfo.level_of(info) != 0 and not game.is_completed(MapInfo.level_of(info)):
			# Keen plays the level; blocked cells may now let him through.
			game.complete_level(MapInfo.level_of(info))
			next.append_array(reached.keys())
			reached.clear()
			reached[cell] = true
		if MapSession.TELEPORTER_DESTINATIONS.has(info):
			next.append(map.find_info(MapSession.TELEPORTER_DESTINATIONS[info]))
		if MapInfo.level_of(info) == 13:
			next.append(map.find_info(MapSession.SECRET_DESTINATION))
		for neighbor in next:
			if not reached.has(neighbor) and _walkable(collision, neighbor):
				queue.append(neighbor)
	assert_equal(game.completed_levels().size(), GameFiles.LAST_LEVEL, "levels reached")


## Keen walks from the start of the map to level 1 and enters it.
func test_keen_walks_into_level_1() -> void:
	var map := LevelData.parse(_level_file(GameFiles.WORLD_MAP_LEVEL))
	var properties := TileProperties.load_from(GameFiles.locate(), 611)
	var session := MapSession.create(map, properties, GameProgress.new())
	for tick in 20:
		session.step(KeenInput.toward(Vector2i.DOWN))
	for tick in 120:
		session.step(KeenInput.toward(Vector2i.RIGHT))
	assert_equal(session.cell_under_keen(), Vector2i(21, 40), "stopped by the right half")
	session.step(KeenInput.toward(Vector2i.ZERO, true))
	assert_equal(session.chosen_level, 1, "enters level 1")


## The teleporter in level 13 is there, and only there.
func test_only_level_13_has_a_teleporter() -> void:
	var properties := TileProperties.load_from(GameFiles.locate(), 611)
	for number in range(GameFiles.FIRST_LEVEL, GameFiles.LAST_LEVEL + 1):
		var level := LevelData.parse(_level_file(number))
		var has_teleporter := Array(level.tiles).any(
			func(tile: int) -> bool: return properties.is_teleporter(tile)
		)
		assert_equal(has_teleporter, number == 13, "teleporter in level %d" % number)


func test_ending_files_can_be_read() -> void:
	var files := GameFiles.locate()
	var texts := EndingTexts.load_from(files)
	assert_true(texts != null, "texts of the ending")
	if texts != null:
		assert_equal(texts.missing_parts[0], "Your ship is missing", "ship message")
		assert_equal(texts.home_messages[-1][-1], "destroy Earth!", "last message at home")
	var picture := FinaleImage.load_from(files)
	assert_true(picture != null, "FINALE.CK1")
	if picture != null:
		assert_true(not picture.is_invisible(), "the picture is not empty")
	var lines := TextDocument.layout(files.read(GameFiles.END_TEXT), EndingSequence.TEXT_WIDTH)
	assert_true(lines.size() > EndingSequence.TEXT_LINES, "ENDTEXT.CK1 needs scrolling")
	for line in lines:
		assert_true(line.length() <= EndingSequence.TEXT_WIDTH, "fits: " + line)


func _walkable(collision: MapCollision, cell: Vector2i) -> bool:
	return (
		collision.tile_at(cell) >= 0
		and not collision.is_solid(cell, LevelCollision.Edge.TOP)
		and not collision.is_solid(cell, LevelCollision.Edge.LEFT)
	)


func _level_file(number: int) -> PackedByteArray:
	return GameFiles.locate().read(GameFiles.level_file_name(number))


func test_every_sound_is_in_the_sound_file() -> void:
	var file := SoundFile.load_from(GameFiles.locate())
	assert_true(file != null, "SOUNDS.CK1")
	if file == null:
		return
	for id: Sound.Id in Sound.FILE_NAMES:
		var name := Sound.FILE_NAMES[id]
		assert_true(file.sounds.has(name), name)
		if file.sounds.has(name):
			assert_true(not file.sounds[name].divisors.is_empty(), "%s has data" % name)
