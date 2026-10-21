extends "res://tests/test_case.gd"
## Tests for the holes in a floor ([GalaxySkyPockets], D13.2; the glass of
## Keen 4's level 9): where see-through glass stands in a floor's band of
## foreground tiles (on a top that is walked on), its sky keeps the sky's
## colour; the picture behind the level shows through all other glass (its
## inside, a ring, a dome on a platform) and above a shelf between walls.
## Made-up maps and tiles, no files.

const SIZE := Vector2i(16, 12)
const SKY := 1
## Foreground tiles: solid and walked on; the floor's band (solid, not
## walked on); glass (all see-through).
const SOLID := 2
const BAND := 3
const GLASS := 4
const TILE := 16
## The ground Keen walks on, and the band of the floor on it.
const GROUND_ROW := 9
const BAND_ROW := 8


func test_open_sky_keeps_the_picture() -> void:
	assert_equal(_pixels(_find(_map())), 0, "nothing painted")


func test_glass_standing_in_the_floor_band_is_painted() -> void:
	var map := _floor_map()
	_put(map, Vector2i(6, BAND_ROW), GLASS)
	_put(map, Vector2i(7, BAND_ROW), GLASS)
	var rows := _find(map)
	assert_equal(_pixels(rows), 2 * TILE * TILE, "the two glass cells in the band")
	for row in rows:
		assert_true(
			Rect2i(6 * TILE, BAND_ROW * TILE, 2 * TILE, TILE).encloses(row), "in the band: %s" % row
		)


func test_glass_above_the_floor_keeps_the_picture() -> void:
	var map := _floor_map()
	for y in range(4, BAND_ROW):
		_put(map, Vector2i(6, y), GLASS)
	_put(map, Vector2i(6, BAND_ROW), GLASS)
	assert_equal(_pixels(_find(map)), TILE * TILE, "only the cell in the band")


func test_a_ring_of_glass_keeps_the_picture_inside() -> void:
	var map := _map()
	for y in range(3, 7):
		for x in range(4, 8):
			var edge := x == 4 or x == 7 or y == 3 or y == 6
			if edge:
				_put(map, Vector2i(x, y), BAND)
	assert_equal(_pixels(_find(map)), 0, "the inside of the ring is no floor")


func test_glass_at_the_end_of_the_ground_is_no_hole() -> void:
	var map := _floor_map()
	# The ground stops at column 10: the band's last cell is glass.
	for x in range(10, SIZE.x - 2):
		_put(map, Vector2i(x, GROUND_ROW), 0)
		_put(map, Vector2i(x, BAND_ROW), 0)
	_put(map, Vector2i(9, BAND_ROW), GLASS)
	assert_equal(_pixels(_find(map)), 0, "open sky beside it")


func test_sky_above_a_shelf_between_walls_keeps_the_picture() -> void:
	var map := _map()
	for x in range(4, 10):
		_put(map, Vector2i(x, 6), SOLID)
	for y in range(2, 9):
		_put(map, Vector2i(3, y), SOLID)
		_put(map, Vector2i(10, y), SOLID)
	assert_equal(_pixels(_find(map)), 0, "walls on both ends: no band")


func test_glass_between_the_band_and_a_wall_is_painted() -> void:
	var map := _floor_map()
	_put(map, Vector2i(9, BAND_ROW), GLASS)
	_put(map, Vector2i(10, BAND_ROW), SOLID)
	assert_equal(_pixels(_find(map)), TILE * TILE, "the band on one end, a wall on the other")


## A map of sky with a solid foreground border of two tiles, as Galaxy
## maps have.
func _map() -> GalaxyMap:
	var map := GalaxyMap.new()
	map.width = SIZE.x
	map.height = SIZE.y
	for layer in GalaxyMap.PLANE_COUNT:
		var plane := PackedInt32Array()
		plane.resize(SIZE.x * SIZE.y)
		map.planes.append(plane)
	map.planes[GalaxyMap.Layer.BACKGROUND].fill(SKY)
	var inner := Rect2i(2, 2, SIZE.x - 4, SIZE.y - 4)
	for y in SIZE.y:
		for x in SIZE.x:
			if not inner.has_point(Vector2i(x, y)):
				_put(map, Vector2i(x, y), SOLID)
	return map


## [method _map] with ground across it and a floor's band on the ground.
func _floor_map() -> GalaxyMap:
	var map := _map()
	for x in range(2, SIZE.x - 2):
		_put(map, Vector2i(x, GROUND_ROW), SOLID)
		_put(map, Vector2i(x, BAND_ROW), BAND)
	return map


func _find(map: GalaxyMap) -> Array[Rect2i]:
	return GalaxySkyPockets.find(map, _back, _fore, _walkable)


static func _put(map: GalaxyMap, cell: Vector2i, tile: int) -> void:
	map.planes[GalaxyMap.Layer.FOREGROUND][cell.y * map.width + cell.x] = tile


## The sky tile with its sky cleared: wholly see-through.
static func _back(tile: int) -> Image:
	var image := Image.create_empty(TILE, TILE, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT if tile == SKY else Color.BLUE)
	return image


static func _fore(tile: int) -> Image:
	var image := Image.create_empty(TILE, TILE, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT if tile == GLASS else Color.WHITE)
	return image


static func _walkable(tile: int) -> bool:
	return tile == SOLID


static func _pixels(rows: Array[Rect2i]) -> int:
	var count := 0
	for row in rows:
		count += row.get_area()
	return count
