class_name GalaxySkyPockets
extends RefCounted
## The sky that the picture behind a level must not take (ours, D13.2):
## holes in a floor. The original draws glass as foreground tiles with
## see-through insides over the plain sky tiles, so the sky's colour is the
## glass's colour. With the sky made see-through for the picture
## ([GalaxyBackdropPictures]) the picture shows through the glass, as it
## should, but also where a glass column stands in a floor drawn as a band
## of foreground tiles (level 9's walkway): there the floor had holes.
##
## The rule, per row of cells: a floor cell stands on a cell whose top can
## be walked on (level 9's walkway band stands on the bricks Keen walks
## on). The band is drawn in front, lets nothing through and is not walked
## on itself. A run of floor cells that let the sky through, with the band
## at one end at least and the band or a wall (drawn in front, nothing
## through, walked on) at the other, and closed at the top (the band's top
## line runs over it: no cell lets the sky through in its top pixel row),
## is a hole in the floor: [method find] gives its see-through pixels as
## rows, to be painted in the sky's colour behind the tiles. A run that
## ends anywhere else (the edge of the ground, open sky beside it) is no
## hole, and neither is the sky above a shelf between two walls, nor a run
## open at the top: that is the air above a lower floor (in level 9 the
## top face of a low ledge between a high one and a wall). The picture
## shows there and through the glass above the floor. Worked out once per
## map, from its first tiles (tiles a switch changes later keep what was
## found).

const TILE := GalaxyGraphics.TILE16_SIZE
## A foreground pixel lets the background through below this alpha.
const SEE_THROUGH_ALPHA := 0.5


## The cells of one map, with what each lets through (worked out once per
## pair of tiles).
class Cells:
	extends RefCounted
	var map: GalaxyMap
	var back_image: Callable
	var fore_image: Callable
	var walkable: Callable
	var _masks: Dictionary[int, PackedByteArray] = {}

	## Whether the cell at [param x], [param y] stands on a top that can be
	## walked on.
	func is_floor(x: int, y: int) -> bool:
		if x < 0 or x >= map.width or y + 1 >= map.height:
			return false
		var below := map.tile(GalaxyMap.Layer.FOREGROUND, x, y + 1)
		return below != 0 and walkable.call(below)

	## The see-through pixels of the cell (1 each), or empty when it lets
	## nothing through.
	func mask(x: int, y: int) -> PackedByteArray:
		var back := map.tile(GalaxyMap.Layer.BACKGROUND, x, y)
		var fore := map.tile(GalaxyMap.Layer.FOREGROUND, x, y)
		var key := (back << 16) | fore
		if not _masks.has(key):
			var fore_tile: Image = fore_image.call(fore) if fore != 0 else null
			_masks[key] = GalaxySkyPockets.see_through(back_image.call(back), fore_tile)
		return _masks[key]

	## A floor cell with sky behind it.
	func is_hole(x: int, y: int) -> bool:
		return is_floor(x, y) and not mask(x, y).is_empty()

	## Whether the cell lets the sky through in its top pixel row: air
	## comes in from above, so it is no hole under the floor's top line.
	func is_open_at_top(x: int, y: int) -> bool:
		var through := mask(x, y)
		return not through.is_empty() and through.slice(0, TILE).has(1)

	## A floor cell drawn in front that lets nothing through and is not
	## walked on itself: the floor's band.
	func is_band(x: int, y: int) -> bool:
		return _is_closed(x, y) and not _walkable_at(x, y)

	## A floor cell drawn in front that lets nothing through and is walked
	## on itself: a wall or a block beside the band.
	func is_wall(x: int, y: int) -> bool:
		return _is_closed(x, y) and _walkable_at(x, y)

	func _is_closed(x: int, y: int) -> bool:
		if not is_floor(x, y):
			return false
		return map.tile(GalaxyMap.Layer.FOREGROUND, x, y) != 0 and mask(x, y).is_empty()

	func _walkable_at(x: int, y: int) -> bool:
		return walkable.call(map.tile(GalaxyMap.Layer.FOREGROUND, x, y))


## The holes in the floors of [param map] as one-pixel-high rows in level
## pixels. [param back_image] gives a background tile with its sky cleared
## (null: none), [param fore_image] a foreground tile with its mask (null:
## none), [param walkable] whether a foreground tile's top can be walked
## on.
static func find(
	map: GalaxyMap, back_image: Callable, fore_image: Callable, walkable: Callable
) -> Array[Rect2i]:
	var cells := Cells.new()
	cells.map = map
	cells.back_image = back_image
	cells.fore_image = fore_image
	cells.walkable = walkable
	var rows: Array[Rect2i] = []
	for y in map.height:
		_find_in_row(cells, y, rows)
	return rows


## Adds the holes of row [param y] to [param rows].
static func _find_in_row(cells: Cells, y: int, rows: Array[Rect2i]) -> void:
	var x := 0
	while x < cells.map.width:
		if not cells.is_hole(x, y):
			x += 1
			continue
		var start := x
		while cells.is_hole(x, y):
			x += 1
		if _is_hole_between(cells, start - 1, x, y) and _is_closed_at_top(cells, start, x, y):
			for cell in range(start, x):
				_add_rows(rows, cells.mask(cell, y), Vector2i(cell, y) * TILE)


## Whether a run of see-through floor cells between [param left] and
## [param right] in row [param y] is a hole: the floor's band on one end at
## least, the band or a wall on the other.
static func _is_hole_between(cells: Cells, left: int, right: int, y: int) -> bool:
	var ends: Array[int] = [left, right]
	var bands := 0
	for end in ends:
		if cells.is_band(end, y):
			bands += 1
		elif not cells.is_wall(end, y):
			return false
	return bands > 0


## Whether no cell of the run from [param start] to [param end] (not
## included) in row [param y] lets the sky in from above.
static func _is_closed_at_top(cells: Cells, start: int, end: int, y: int) -> bool:
	for x in range(start, end):
		if cells.is_open_at_top(x, y):
			return false
	return true


## The pixels where [param back] (cleared sky see-through; null: none)
## shows through [param fore] (null: none): 1 each, or empty when none.
static func see_through(back: Image, fore: Image) -> PackedByteArray:
	if back == null:
		return PackedByteArray()
	var through := PackedByteArray()
	through.resize(TILE * TILE)
	var any := false
	for y in TILE:
		for x in TILE:
			var clear := back.get_pixel(x, y).a == 0.0
			if clear and fore != null:
				clear = fore.get_pixel(x, y).a < SEE_THROUGH_ALPHA
			through[y * TILE + x] = 1 if clear else 0
			any = any or clear
	return through if any else PackedByteArray()


## Adds the runs of see-through pixels of [param mask] in a cell at
## [param corner] (pixels).
static func _add_rows(rows: Array[Rect2i], mask: PackedByteArray, corner: Vector2i) -> void:
	for y in TILE:
		var x := 0
		while x < TILE:
			if mask[y * TILE + x] == 0:
				x += 1
				continue
			var start := x
			while x < TILE and mask[y * TILE + x] == 1:
				x += 1
			rows.append(Rect2i(corner + Vector2i(start, y), Vector2i(x - start, 1)))
