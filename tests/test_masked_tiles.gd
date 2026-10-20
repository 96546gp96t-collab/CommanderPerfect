extends "res://tests/test_case.gd"
## Masked tiles (behavior -2): which tiles have a mask (the next tile, in
## black and white), and how [LevelMap] draws them: whole behind the sprites
## and, on a layer in front of them, through the mask ([MaskedTiles]). A
## masked tile without a mask stays a plain foreground tile, and a level
## without masked tiles is drawn exactly as before. The real-data tests run
## for each episode whose files are there.

const AIR := 0
## A masked tile followed by its mask.
const CLOUD := 1
const CLOUD_MASK := 2
## A masked tile followed by an ordinary tile: no mask.
const BROKEN := 3
const RED := 4
const PILLAR := 5
## Two frames: a masked tile with a mask, then that mask.
const ANIMATED := 6
const ANIMATION_FRAMES := 2
const LAST := 8
const TILE_COUNT := 9
const LEGEND := {".": AIR, "C": CLOUD, "B": BROKEN, "P": PILLAR, "A": ANIMATED, "L": LAST}
const HALF := EgaGraphics.TILE_SIZE / 2
const KEEN_2_MASKLESS: PackedInt32Array = [371, 372, 373]
const KEEN_3_CLOUD_LEVEL := 14
const KEEN_3_CLOUD := 108

var _keen1_fixtures := preload("res://tests/fixtures.gd")


func test_a_black_and_white_next_tile_is_a_mask() -> void:
	var graphics := _graphics()
	assert_true(graphics.has_tile_mask(CLOUD), "black and white next tile")
	assert_true(not graphics.has_tile_mask(BROKEN), "colored next tile")
	assert_true(not graphics.has_tile_mask(LAST), "the last tile has no next")
	assert_true(not graphics.has_tile_mask(-1), "no tile")
	assert_true(EgaGraphics.is_black_and_white(graphics.tiles[CLOUD_MASK]), "the mask")
	assert_true(not EgaGraphics.is_black_and_white(graphics.tiles[CLOUD]), "the cloud")


func test_the_tile_set_knows_the_masks() -> void:
	var tile_set := LevelTileSet.build(_graphics())
	assert_true(MaskedTiles.has_mask(tile_set, CLOUD), "cloud")
	assert_true(not MaskedTiles.has_mask(tile_set, BROKEN), "broken")
	assert_true(not MaskedTiles.has_mask(tile_set, TILE_COUNT + 3), "a tile it does not have")
	assert_true(not MaskedTiles.has_mask(TileSet.new(), CLOUD), "an unmarked tile set")
	var material := MaskedTiles.material_of(tile_set)
	assert_true(material != null, "material")
	assert_equal(material.get_shader_parameter("columns"), 16.0, "columns")
	assert_equal(material.get_shader_parameter("rows"), 1.0, "rows of 9 tiles")
	assert_equal(material.get_shader_parameter("holes_drawn"), false, "no picture behind")


func test_holes_count_as_the_backdrop_color() -> void:
	var black := LevelTileSet.build(_graphics(), null, Color.BLACK)
	var white := LevelTileSet.build(_graphics(), null, Color.WHITE)
	var blue := LevelTileSet.build(_graphics(), null, EgaPalette.color(1))
	assert_equal(_holes_drawn(black), true, "black background: holes were black")
	assert_equal(_holes_drawn(white), false, "white background: holes were white")
	assert_equal(_holes_drawn(blue), true, "dark blue: never in a mask, harmless")


func test_masked_tile_drawn_whole_and_through_its_mask() -> void:
	var map := _map(["C.", ".."])
	var cell := _cell(0, 0)
	assert_equal(map.get_cell_atlas_coords(cell), _coords(CLOUD), "whole tile behind")
	assert_equal(map.masked().get_cell_atlas_coords(cell), _coords(CLOUD), "masked in front")
	assert_equal(map.foreground().get_cell_source_id(cell), -1, "not plain foreground")
	assert_equal(map.masked().z_index, map.foreground().z_index, "in front of the sprites")
	assert_true(map.masked().z_index > 0, "above z index 0")
	assert_true(map.masked().material == MaskedTiles.material_of(map.tile_set), "material")
	assert_equal(map.masked().get_used_cells().size(), 1, "only the cloud")
	map.free()


func test_masked_tile_without_mask_stays_foreground() -> void:
	var map := _map(["BP"])
	for x in 2:
		var cell := _cell(x, 0)
		assert_equal(map.get_cell_source_id(cell), -1, "not behind (%d)" % x)
		assert_true(map.foreground().get_cell_source_id(cell) != -1, "in front (%d)" % x)
		assert_equal(map.masked().get_cell_source_id(cell), -1, "not masked (%d)" % x)
	map.free()


func test_set_tile_moves_the_cell_between_layers() -> void:
	var map := _map(["C."])
	var cell := _cell(0, 0)
	map.set_tile(cell, AIR)
	assert_equal(map.masked().get_cell_source_id(cell), -1, "air: no masked part")
	assert_equal(map.get_cell_atlas_coords(cell), _coords(AIR), "air behind")
	map.set_tile(cell, PILLAR)
	assert_equal(map.get_cell_source_id(cell), -1, "pillar: nothing behind")
	assert_equal(map.foreground().get_cell_atlas_coords(cell), _coords(PILLAR), "pillar")
	map.set_tile(cell, CLOUD)
	assert_equal(map.foreground().get_cell_source_id(cell), -1, "cloud: no plain foreground")
	assert_equal(map.get_cell_atlas_coords(cell), _coords(CLOUD), "cloud behind")
	assert_equal(map.masked().get_cell_atlas_coords(cell), _coords(CLOUD), "cloud masked")
	map.free()


func test_animation_keeps_the_layers_right() -> void:
	var map := _map(["A."])
	var cell := _cell(0, 0)
	assert_equal(map.masked().get_cell_atlas_coords(cell), _coords(ANIMATED), "first frame")
	map.animate(LevelMap.ANIMATION_FRAME_TIME)
	assert_equal(map.get_cell_atlas_coords(cell), _coords(ANIMATED + 1), "second frame")
	assert_equal(map.masked().get_cell_source_id(cell), -1, "second frame is no masked tile")
	map.animate(LevelMap.ANIMATION_FRAME_TIME)
	assert_equal(map.masked().get_cell_atlas_coords(cell), _coords(ANIMATED), "back again")
	map.free()


func test_other_graphics_keep_the_masked_layer() -> void:
	var map := _map(["C."])
	var other := LevelTileSet.build(_graphics(), null, Color.WHITE)
	map.use_tile_set(other)
	assert_true(map.masked().tile_set == other, "same tile set")
	assert_true(map.masked().material == MaskedTiles.material_of(other), "its material")
	assert_equal(map.masked().get_cell_atlas_coords(_cell(0, 0)), _coords(CLOUD), "cell kept")
	map.free()


func test_a_level_without_masked_tiles_is_drawn_as_before() -> void:
	var level: LevelData = _keen1_fixtures.create_level(["..P#", "A.Do", "XEJY"])
	var map := LevelMap.new()
	map.tile_set = LevelTileSet.build(_keen1_fixtures.create_graphics())
	var properties: TileProperties = _keen1_fixtures.create_properties()
	map.show_level(level, properties)
	_check_drawn_as_before(map, level, properties, "fixture level")
	map.free()


func test_keen1_has_no_masked_tiles_and_draws_as_before() -> void:
	var files := GameFiles.locate()
	if files == null:
		return
	var graphics := EgaGraphics.load_from(files)
	var properties := TileProperties.load_from(files, graphics.tiles.size())
	for tile in properties.tile_count:
		assert_true(properties.behavior(tile) != TileProperties.Behavior.MASKED, "tile %d" % tile)
	var map := LevelMap.new()
	map.tile_set = LevelTileSet.build(graphics)
	var numbers := range(GameFiles.FIRST_LEVEL, GameFiles.LAST_LEVEL + 1)
	numbers.append_array([GameFiles.WORLD_MAP_LEVEL, GameFiles.ENDING_LEVEL])
	for number: int in numbers:
		if not files.has_file(files.level_file(number)):
			continue
		var level := LevelData.parse(files.read(files.level_file(number)))
		map.show_level(level, properties)
		_check_drawn_as_before(map, level, properties, "Keen 1 level %d" % number)
	map.free()


func test_keen2_masks_but_not_for_371_to_373() -> void:
	var files := Keen2Files.locate()
	if files == null:
		return
	var data := Keen2GameData.load_from(files)
	var masked := _masked_tiles(data.properties)
	assert_true(masked.size() > KEEN_2_MASKLESS.size(), "Keen 2 has masked tiles")
	for tile in masked:
		assert_equal(
			data.graphics.has_tile_mask(tile), not KEEN_2_MASKLESS.has(tile), "tile %d" % tile
		)


func test_keen3_masked_tiles_all_have_masks() -> void:
	var files := Keen3Files.locate()
	if files == null:
		return
	var data := Keen3GameData.load_from(files)
	var masked := _masked_tiles(data.properties)
	assert_true(masked.has(KEEN_3_CLOUD), "the cloud is masked")
	for tile in masked:
		assert_true(data.graphics.has_tile_mask(tile), "tile %d has a mask" % tile)
	var map := LevelMap.new()
	map.tile_set = LevelTileSet.build(data.graphics)
	map.show_level(
		LevelData.parse(files.read(files.level_file(KEEN_3_CLOUD_LEVEL))), data.properties
	)
	var clouds := map.masked().get_used_cells()
	assert_true(not clouds.is_empty(), "the clouds of level 14 are masked")
	for cell in clouds:
		assert_equal(map.get_cell_atlas_coords(cell), _coords(KEEN_3_CLOUD), "cloud behind")
		assert_equal(map.foreground().get_cell_source_id(cell), -1, "no plain foreground")
	map.free()


## Every cell as [LevelMap] drew it before masks: foreground tiles in front,
## the rest behind, nothing on the masked layer.
func _check_drawn_as_before(
	map: LevelMap, level: LevelData, properties: TileProperties, what: String
) -> void:
	var wrong := 0
	var playable := level.playable_rect()
	for y in range(playable.position.y, playable.end.y):
		for x in range(playable.position.x, playable.end.x):
			var cell := Vector2i(x, y)
			var tile := level.tile_at(cell)
			var in_front := properties.is_foreground(tile)
			var front: TileMapLayer = map.foreground() if in_front else map
			var back: TileMapLayer = map if in_front else map.foreground()
			if (
				front.get_cell_atlas_coords(cell) != _coords(tile)
				or back.get_cell_source_id(cell) != -1
			):
				wrong += 1
	assert_equal(wrong, 0, "%s: cells drawn as before" % what)
	assert_equal(map.masked().get_used_cells().size(), 0, "%s: nothing masked" % what)


func _map(rows: PackedStringArray) -> LevelMap:
	var map := LevelMap.new()
	map.tile_set = LevelTileSet.build(_graphics())
	map.show_level(_level(rows), _properties())
	return map


## Colored tiles, with a mask after the cloud: black left, white right.
func _graphics() -> EgaGraphics:
	var graphics := EgaGraphics.new()
	for tile in TILE_COUNT:
		var image := Image.create_empty(
			EgaGraphics.TILE_SIZE, EgaGraphics.TILE_SIZE, false, Image.FORMAT_RGBA8
		)
		image.fill(EgaPalette.color(tile + 1))
		graphics.tiles.append(image)
	for mask in [CLOUD_MASK, ANIMATED + 1]:
		graphics.tiles[mask].fill(Color.WHITE)
		graphics.tiles[mask].fill_rect(
			Rect2i(0, 0, HALF, EgaGraphics.TILE_SIZE), EgaPalette.color(0)
		)
	return graphics


func _properties() -> TileProperties:
	var animation := _filled(1)
	var behavior := _filled(TileProperties.Behavior.NONE)
	for tile in [CLOUD, BROKEN, ANIMATED, LAST]:
		behavior[tile] = TileProperties.Behavior.MASKED
	behavior[PILLAR] = TileProperties.Behavior.FOREGROUND
	for frame in ANIMATION_FRAMES:
		animation[ANIMATED + frame] = ANIMATION_FRAMES
	var sides := _filled(0)
	var table := PackedByteArray()
	for values in [animation, behavior, sides, sides, sides, sides]:
		for value: int in values:
			var bytes := PackedByteArray([0, 0])
			bytes.encode_s16(0, value)
			table.append_array(bytes)
	return TileProperties.from_table(table, TILE_COUNT)


static func _filled(value: int) -> PackedInt32Array:
	var values := PackedInt32Array()
	values.resize(TILE_COUNT)
	values.fill(value)
	return values


func _level(rows: PackedStringArray) -> LevelData:
	var border := LevelData.BORDER_CELLS
	var level := LevelData.new()
	level.width = rows[0].length() + border * 2
	level.height = rows.size() + border * 2
	level.tiles.resize(level.width * level.height)
	level.infos.resize(level.width * level.height)
	for y in rows.size():
		for x in rows[y].length():
			level.tiles[(y + border) * level.width + x + border] = LEGEND[rows[y][x]]
	return level


static func _masked_tiles(properties: TileProperties) -> PackedInt32Array:
	var masked := PackedInt32Array()
	for tile in properties.tile_count:
		if properties.behavior(tile) == TileProperties.Behavior.MASKED:
			masked.append(tile)
	return masked


static func _holes_drawn(tile_set: TileSet) -> bool:
	return MaskedTiles.material_of(tile_set).get_shader_parameter("holes_drawn")


static func _cell(x: int, y: int) -> Vector2i:
	return Vector2i(x, y) + Vector2i.ONE * LevelData.BORDER_CELLS


static func _coords(tile: int) -> Vector2i:
	return LevelTileSet.atlas_coords_of(tile)
