extends "res://tests/test_case.gd"
## Tests for the sky shut in by a level's drawing ([GalaxySkyPockets], D13.2;
## the glass of Keen 4's level 9): sky that the open sky reaches stays
## see-through for the picture behind the level; sky shut in by foreground
## tiles (a ring of glass, a hole inside one tile) keeps its colour. Made-up
## maps and tiles, no files.

const SIZE := Vector2i(12, 12)
const SKY := 1
const SOLID := 2
const HOLED := 3
const EDGE_GAP := 4
const TILE := 16
const HOLE := Rect2i(6, 6, 4, 4)


func test_open_sky_stays_see_through() -> void:
	var map := _map()
	assert_equal(_pixels(GalaxySkyPockets.find(map, _back, _fore)), 0, "nothing shut in")


func test_sky_inside_a_ring_of_tiles_is_shut_in() -> void:
	var map := _map()
	_ring(map, Rect2i(4, 4, 4, 4))
	var rows := GalaxySkyPockets.find(map, _back, _fore)
	assert_equal(_pixels(rows), 4 * TILE * TILE, "the four cells inside the ring")
	for row in rows:
		assert_true(
			Rect2i(5 * TILE, 5 * TILE, 2 * TILE, 2 * TILE).encloses(row), "inside: %s" % row
		)


func test_a_gap_in_the_ring_lets_the_open_sky_in() -> void:
	var map := _map()
	_ring(map, Rect2i(4, 4, 4, 4))
	_put(map, GalaxyMap.Layer.FOREGROUND, Vector2i(5, 4), 0)
	assert_equal(_pixels(GalaxySkyPockets.find(map, _back, _fore)), 0, "open through the gap")


func test_a_hole_inside_one_tile_is_shut_in() -> void:
	var map := _map()
	_put(map, GalaxyMap.Layer.FOREGROUND, Vector2i(5, 5), HOLED)
	var rows := GalaxySkyPockets.find(map, _back, _fore)
	assert_equal(_pixels(rows), HOLE.get_area(), "the hole's pixels")
	assert_equal(rows[0].position, Vector2i(5, 5) * TILE + HOLE.position, "where the hole is")


func test_see_through_pixels_on_a_tile_edge_join_the_open_sky() -> void:
	var map := _map()
	_put(map, GalaxyMap.Layer.FOREGROUND, Vector2i(5, 5), EDGE_GAP)
	assert_equal(_pixels(GalaxySkyPockets.find(map, _back, _fore)), 0, "open at the edge")


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
	for y in SIZE.y:
		for x in SIZE.x:
			var inner := Rect2i(2, 2, SIZE.x - 4, SIZE.y - 4)
			if not inner.has_point(Vector2i(x, y)):
				_put(map, GalaxyMap.Layer.FOREGROUND, Vector2i(x, y), SOLID)
	return map


func _ring(map: GalaxyMap, rect: Rect2i) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var edge := (
				x == rect.position.x
				or y == rect.position.y
				or x == rect.end.x - 1
				or y == rect.end.y - 1
			)
			if edge:
				_put(map, GalaxyMap.Layer.FOREGROUND, Vector2i(x, y), SOLID)


static func _put(map: GalaxyMap, layer: GalaxyMap.Layer, cell: Vector2i, tile: int) -> void:
	map.planes[layer][cell.y * map.width + cell.x] = tile


## The sky tile with its sky cleared: wholly see-through.
static func _back(tile: int) -> Image:
	var image := Image.create_empty(TILE, TILE, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT if tile == SKY else Color.BLUE)
	return image


## Foreground tiles: solid; solid with a hole in the middle; solid with a
## see-through gap along its top edge.
static func _fore(tile: int) -> Image:
	var image := Image.create_empty(TILE, TILE, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	if tile == HOLED:
		image.fill_rect(HOLE, Color.TRANSPARENT)
	elif tile == EDGE_GAP:
		image.fill_rect(Rect2i(4, 0, 4, 6), Color.TRANSPARENT)
	return image


static func _pixels(rows: Array[Rect2i]) -> int:
	var count := 0
	for row in rows:
		count += row.get_area()
	return count
