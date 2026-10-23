extends "res://tests/test_case.gd"
## Tests for the grey under Keen's ship in our ship level (E12.1, the
## user's test in widescreen with the pictures on): Keen 1's rule keeps
## grey that a level's drawing shuts in, and the ship with the ground shut
## in the sky under it, so it stayed grey. [method
## ShipLevels.open_sky_under_ship] lets it through in that level only; the
## ship's own grey shading stays. Skipped without Keen 1's files.

const SIZE := EgaGraphics.TILE_SIZE
## The ship's bottom row of tiles, which stand on the ground.
const BOTTOM_ROW := 2

var _graphics: EgaGraphics
var _walls: Keen1Walls
var _sky := Color.TRANSPARENT


func run_all() -> void:
	var files := GameFiles.locate()
	if files == null:
		skip("no Keen 1 game data found")
		return
	_graphics = EgaGraphics.load_from(files)
	var properties := TileProperties.load_from(files, _graphics.tiles.size())
	_walls = Keen1Walls.create(files, _graphics.tiles, BackdropPictures.FOLDER, properties)
	_sky = BackdropPictures.color_of(_graphics.tiles[Keen1Walls.SKY_TILE])
	super.run_all()


func test_the_grey_under_the_ship_is_the_sky() -> void:
	var holes := _holes()
	assert_true(_shut_on_the_ground(holes) > 0, "the bug: the grey under the ship is shut in")
	ShipLevels.open_sky_under_ship(holes, _graphics.tiles)
	assert_equal(_shut_on_the_ground(holes), 0, "the grey on the ground shows the picture")


func test_the_ships_own_grey_stays() -> void:
	var holes := _holes()
	var before := _shut_above_the_bottom_row(holes)
	assert_true(before > 0, "the ship's shading is shut in")
	ShipLevels.open_sky_under_ship(holes, _graphics.tiles)
	assert_equal(_shut_above_the_bottom_row(holes), before, "the upper rows keep their grey")


func test_nothing_without_the_picture() -> void:
	var holes := _walls.holes(ShipLevels.build(ShipLevels.OUTSIDE_LEVEL), Color.TRANSPARENT, true)
	var key := holes.key()
	ShipLevels.open_sky_under_ship(holes, _graphics.tiles)
	assert_equal(holes.key(), key, "4:3 or pictures off: the original")


func _holes() -> BackdropHoles:
	return _walls.holes(ShipLevels.build(ShipLevels.OUTSIDE_LEVEL), _sky, false)


## The shut-in grey pixels in the bottom line of the ship's bottom row of
## tiles: where the grey stands on the ground.
func _shut_on_the_ground(holes: BackdropHoles) -> int:
	var count := 0
	for tile: int in ShipLevels.SHIP_TILES[BOTTOM_ROW]:
		if not holes.shut_in.has(tile):
			continue
		for x in SIZE:
			var at := Vector2i(x, SIZE - 1)
			if (
				holes.shut_in[tile][at.y * SIZE + at.x]
				and _graphics.tiles[tile].get_pixelv(at) == _sky
			):
				count += 1
	return count


func _shut_above_the_bottom_row(holes: BackdropHoles) -> int:
	var count := 0
	for row in BOTTOM_ROW:
		for tile: int in ShipLevels.SHIP_TILES[row]:
			if holes.shut_in.has(tile):
				count += holes.shut_in[tile].count(1)
	return count
