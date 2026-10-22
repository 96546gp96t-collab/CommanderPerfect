extends "res://tests/test_case.gd"
## Tests for milestone AB2 with the player's own Keen 1 and Keen 2 files
## (each part returns early without them): Keen 2's lattice, its shadows,
## an item, the riveted box, a sign board and the dark shafts' cones;
## Keen 1's light cones that stay grey (level 2, the castle of level 16)
## while its sky shows outside.

const SIZE := EgaGraphics.TILE_SIZE
const KIND := BackdropHoles.Kind
## Keen 2, version 1.31.
const LATTICE := 143
const SHADOW_TILE := 148
const CONE_EDGE := 157
const PLATFORM := 265
const RIVETED_BOX := 400
const BOARD_CORNER := 38
const TEAL_LEVEL := 12
const DARK_LEVEL := 5
## The rows of the platform (tile 265): its body, and the shadow under it.
const PLATFORM_ROWS := Rect2i(0, 0, SIZE, 5)
## Keen 1: a cell under a lamp in level 2, and in level 16 one under a lamp
## in the castle and one of the sky outside.
const LEVEL_2_CONE := Vector2i(3, 3)
const LEVEL_16_CONE := Vector2i(97, 18)
const LEVEL_16_SKY := Vector2i(10, 10)


func test_keen_2_lattice_tiles() -> void:
	var tiles := _keen_2_tiles()
	if tiles.is_empty():
		return
	var walls := LatticeWalls.create(tiles[LATTICE])
	assert_equal(walls.kinds(tiles[LATTICE]).count(KIND.LIT), SIZE * SIZE, "143 all lit")
	var shadow := walls.kinds(tiles[SHADOW_TILE])
	assert_true(shadow.count(KIND.SHADOW) > SIZE, "148 has its shadow")
	assert_equal(shadow.count(KIND.NONE), 0, "and no lattice is left in it")
	var platform := walls.kinds(tiles[PLATFORM])
	for i in PLATFORM_ROWS.size.y * SIZE:
		assert_equal(platform[i], KIND.NONE, "the platform stays whole (pixel %d)" % i)
	assert_true(platform.count(KIND.LIT) > SIZE * SIZE / 2, "the lattice under it is wall")
	assert_equal(walls.kinds(tiles[RIVETED_BOX]).count(KIND.NONE), SIZE * SIZE, "no X in the box")
	assert_equal(walls.kinds(tiles[BOARD_CORNER]).count(KIND.NONE), SIZE * SIZE, "board whole")


func test_keen_2_cone_in_the_dark() -> void:
	var tiles := _keen_2_tiles()
	if tiles.is_empty():
		return
	var kinds := LatticeWalls.create(tiles[LATTICE], tiles[Keen2Walls.DARK_LATTICE_TILE]).kinds(
		tiles[CONE_EDGE]
	)
	assert_equal(kinds[0], KIND.DARK, "the dark part of the cone's edge")
	assert_equal(kinds[SIZE * SIZE - 1], KIND.LIT, "the light of the cone")
	assert_equal(kinds.count(KIND.NONE), 0, "nothing of the lattice is left")


func test_keen_2_levels_get_their_rules() -> void:
	var files := Keen2Files.locate()
	var data := Keen2GameData.load_from(files) if files != null else null
	if data == null:
		return
	var walls := Keen2Walls.create(files, data.graphics.tiles)
	var teal_level := LevelData.parse(files.read(files.level_file(TEAL_LEVEL)))
	var holes := walls.holes(teal_level, Color.TRANSPARENT, true)
	assert_true(holes.wall_color.a > 0.0, "the teal of level 12 is the wall")
	var dark_level := LevelData.parse(files.read(files.level_file(DARK_LEVEL)))
	assert_true(walls.holes(dark_level, Color.TRANSPARENT, true).lattice.has_dark(), "level 5")
	assert_true(walls.holes(dark_level, Color.TRANSPARENT, false) == null, "no texture, no wall")


func test_keen_1_cones_stay_grey_and_the_sky_shows_outside() -> void:
	var files := GameFiles.locate()
	var graphics := EgaGraphics.load_from(files) if files != null else null
	if graphics == null:
		return
	var walls := Keen1Walls.create(files, graphics.tiles)
	var sky := EgaPalette.color(EgaPalette.LIGHT_GRAY)
	var level_2 := LevelData.parse(files.read(GameFiles.level_file_name(2)))
	var holes := walls.holes(level_2, sky, true)
	assert_equal(holes.sky_color, sky, "the sky is grey, not the room's black")
	var kept := walls.sky_kept_cells(level_2, holes)
	assert_true(kept.has(LEVEL_2_CONE), "a cone of level 2 stays grey")
	assert_equal(kept.size(), _grey_cells(level_2, holes, graphics.tiles), "all of them")
	var level_16 := LevelData.parse(files.read(GameFiles.level_file_name(16)))
	kept = walls.sky_kept_cells(level_16, walls.holes(level_16, sky, true))
	assert_true(kept.has(LEVEL_16_CONE), "a cone in the castle stays grey")
	assert_true(not kept.has(LEVEL_16_SKY), "the sky outside shows")
	var level_1 := LevelData.parse(files.read(GameFiles.level_file_name(1)))
	assert_true(walls.sky_kept_cells(level_1, walls.holes(level_1, sky, false)).is_empty(), "1")


## How many cells of [param level] have grey that touches their edge.
static func _grey_cells(level: LevelData, holes: BackdropHoles, tiles: Array[Image]) -> int:
	var count := 0
	var area := level.playable_rect()
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			var tile := level.tile_at(Vector2i(x, y))
			if BackdropHoles.edge_flood(tiles[tile], holes.sky_color).has(1):
				count += 1
	return count


static func _keen_2_tiles() -> Array[Image]:
	var files := Keen2Files.locate()
	var data := Keen2GameData.load_from(files) if files != null else null
	return data.graphics.tiles if data != null else ([] as Array[Image])
