class_name Keen5OpenSky
extends RefCounted
## Where the picture behind a Keen 5 level may show (ours, milestone E10;
## docs/keen5/gameplay.md "Pictures behind the levels"). Keen 5's space is
## black, and the station is drawn with black too: the stripes of its
## hazard walls, the lines of its blue walls, the slots of its vents, the
## insides of its doors. Keen 4's rule (the sky's colour wherever it
## touches a tile's edge) would put the picture in all of those. So:
##   - a tile that is mostly sky loses all of the sky's colour that touches
##     its edge (Keen 4's rule); any other tile only the parts that are wide:
##     they hold a square of [constant WIDE] x [constant WIDE] pixels of it
##     ([method cleared]); a stripe or a line is narrower;
##   - of what is then see-through, only the parts joined to the open sky
##     show the picture: joined, pixel to pixel across the cells, to a cell
##     that shows nothing but an open-sky tile (stars, or Korath III's
##     sky; nothing in front), or to the edge of the map (the outside). A
##     door's black inside, a dark slot or a closed box has no stars and
##     keeps its colour ([method closed]), as do the light cyan corners of
##     the platforms in Korath III's base; a window with stars shows the
##     picture.

const TILE := GalaxyGraphics.TILE16_SIZE
## The map's border, which the view never shows, and the cells along it:
## what lies there is the outside.
const EDGE := GalaxyCamera.BORDER_TILES + 1
## The side of the square of sky a part of a tile must hold to be cleared.
const WIDE := 4
## A tile with at least this many pixels of the sky's colour is mostly sky.
const MOSTLY := TILE * TILE / 2
const SIDES: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]


## [param image] (a background tile) with the sky of [param color] made
## see-through: in a tile that is mostly sky (space with stars, a window's
## inside) all of it that touches the edge, as Keen 4's rule; in any other
## tile only the parts that touch the edge and hold a [constant WIDE]-pixel
## square.
static func cleared(image: Image, color: Color) -> Image:
	if _share_of(image, color) >= MOSTLY:
		return GalaxyBackdropPictures.cleared(image, color)
	var result := image.duplicate() as Image
	result.convert(Image.FORMAT_RGBA8)
	var seen := {}
	for start in _edge_pixels(image.get_size()):
		if seen.has(start) or not image.get_pixelv(start).is_equal_approx(color):
			continue
		var part := _part_of(image, color, start, seen)
		if _holds_square(part):
			for pixel in part:
				result.set_pixelv(pixel, Color.TRANSPARENT)
	return result


## The see-through pixels of [param map] that are not joined to its open
## sky, as one-pixel-high rows in level pixels: they keep the sky's colour.
## [param back_image] gives a background tile cleared for the picture,
## [param fore_image] a foreground tile (null: none), [param open_tiles]
## the background tiles that are open sky.
static func closed(
	map: GalaxyMap, back_image: Callable, fore_image: Callable, open_tiles: PackedInt32Array
) -> Array[Rect2i]:
	var parts := Parts.new()
	parts.find(map, back_image, fore_image)
	parts.join_neighbours(map)
	var open := parts.open_roots(map, open_tiles)
	return parts.rows_not_in(map, open)


## The parts of see-through pixels in every cell of a map, joined across
## the cells (a union-find over the parts).
class Parts:
	extends RefCounted
	## Per pair of tiles: the part of each of the cell's pixels (0: none).
	var _labels: Dictionary[int, PackedInt32Array] = {}
	var _counts: Dictionary[int, int] = {}
	## Per cell: its pair of tiles and the number of its first part.
	var _keys := PackedInt32Array()
	var _first := PackedInt32Array()
	var _parent := PackedInt32Array()

	## Works out the parts of every cell of [param map].
	func find(map: GalaxyMap, back_image: Callable, fore_image: Callable) -> void:
		var total := 0
		_keys.resize(map.width * map.height)
		_first.resize(map.width * map.height)
		for y in map.height:
			for x in map.width:
				var back := map.tile(GalaxyMap.Layer.BACKGROUND, x, y)
				var fore := map.tile(GalaxyMap.Layer.FOREGROUND, x, y)
				var key := (back << 16) | fore
				if not _labels.has(key):
					var fore_tile: Image = fore_image.call(fore) if fore != 0 else null
					var mask := GalaxySkyPockets.see_through(back_image.call(back), fore_tile)
					_label(key, mask)
				var cell := y * map.width + x
				_keys[cell] = key
				_first[cell] = total
				total += _counts[key]
		_parent.resize(total)
		for part in total:
			_parent[part] = part

	## Joins the parts that touch across the side between two cells.
	func join_neighbours(map: GalaxyMap) -> void:
		for y in map.height:
			for x in map.width:
				var cell := y * map.width + x
				if _counts[_keys[cell]] == 0:
					continue
				if x + 1 < map.width:
					_join_side(cell, cell + 1, TILE - 1, 0, TILE)
				if y + 1 < map.height:
					_join_side(cell, cell + map.width, (TILE - 1) * TILE, 0, 1)

	## The roots of the parts joined to a cell of open sky: one of
	## [param open_tiles] with nothing in front, or a cell
	## of the map's border or along it (beyond it is the outside).
	func open_roots(map: GalaxyMap, open_tiles: PackedInt32Array) -> Dictionary[int, bool]:
		var roots: Dictionary[int, bool] = {}
		var inside := Keen5OpenSky.inside(map)
		for y in map.height:
			for x in map.width:
				var back := map.tile(GalaxyMap.Layer.BACKGROUND, x, y)
				var open := map.tile(GalaxyMap.Layer.FOREGROUND, x, y) == 0 and open_tiles.has(back)
				if not open and inside.has_point(Vector2i(x, y)):
					continue
				var cell := y * map.width + x
				for part in _counts[_keys[cell]]:
					roots[_root(_first[cell] + part)] = true
		return roots

	## The pixels of the parts whose root is not in [param open], as rows.
	func rows_not_in(map: GalaxyMap, open: Dictionary[int, bool]) -> Array[Rect2i]:
		var rows: Array[Rect2i] = []
		for y in map.height:
			for x in map.width:
				var cell := y * map.width + x
				var key := _keys[cell]
				if _counts[key] == 0:
					continue
				var shut := PackedByteArray()
				shut.resize(_counts[key] + 1)
				var any := false
				for part in _counts[key]:
					if not open.has(_root(_first[cell] + part)):
						shut[part + 1] = 1
						any = true
				if any:
					_add_rows(rows, _labels[key], shut, Vector2i(x, y) * TILE)
		return rows

	## Numbers the 4-joined parts of [param mask] (1 per see-through pixel).
	func _label(key: int, mask: PackedByteArray) -> void:
		var labels := PackedInt32Array()
		labels.resize(TILE * TILE)
		var count := 0
		if not mask.is_empty():
			for start in TILE * TILE:
				if mask[start] == 0 or labels[start] != 0:
					continue
				count += 1
				_flood(mask, labels, start, count)
		_labels[key] = labels
		_counts[key] = count

	static func _flood(
		mask: PackedByteArray, labels: PackedInt32Array, start: int, part: int
	) -> void:
		var pending: Array[int] = [start]
		labels[start] = part
		while not pending.is_empty():
			var index: int = pending.pop_back()
			var at := Vector2i(index % TILE, index / TILE)
			for side in SIDES:
				var next := at + side
				if next.x < 0 or next.y < 0 or next.x >= TILE or next.y >= TILE:
					continue
				var other := next.y * TILE + next.x
				if mask[other] == 1 and labels[other] == 0:
					labels[other] = part
					pending.append(other)

	## Joins the parts of [param cell] and [param next] along their shared
	## side: pixel [param from] + i * [param step] of the cell meets pixel
	## [param to] + i * [param step] of the next.
	func _join_side(cell: int, next: int, from: int, to: int, step: int) -> void:
		var labels := _labels[_keys[cell]]
		var others := _labels[_keys[next]]
		if _counts[_keys[next]] == 0:
			return
		for i in TILE:
			var mine := labels[from + i * step]
			var theirs := others[to + i * step]
			if mine != 0 and theirs != 0:
				_union(_first[cell] + mine - 1, _first[next] + theirs - 1)

	func _root(part: int) -> int:
		var root := part
		while _parent[root] != root:
			root = _parent[root]
		while _parent[part] != root:
			var up := _parent[part]
			_parent[part] = root
			part = up
		return root

	func _union(a: int, b: int) -> void:
		var root_a := _root(a)
		var root_b := _root(b)
		if root_a != root_b:
			_parent[root_b] = root_a

	## Adds the runs of pixels of a cell at [param corner] whose part is
	## shut (1 in [param shut]).
	static func _add_rows(
		rows: Array[Rect2i], labels: PackedInt32Array, shut: PackedByteArray, corner: Vector2i
	) -> void:
		for y in TILE:
			var x := 0
			while x < TILE:
				if shut[labels[y * TILE + x]] == 0:
					x += 1
					continue
				var start := x
				while x < TILE and shut[labels[y * TILE + x]] == 1:
					x += 1
				rows.append(Rect2i(corner + Vector2i(start, y), Vector2i(x - start, 1)))


## How many pixels of [param image] are [param color].
static func _share_of(image: Image, color: Color) -> int:
	var count := 0
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).is_equal_approx(color):
				count += 1
	return count


## The cells of [param map] away from its edge: the rest is the border
## and the cells along it, where the outside begins.
static func inside(map: GalaxyMap) -> Rect2i:
	var edge := Vector2i(EDGE, EDGE)
	return Rect2i(edge, Vector2i(map.width, map.height) - 2 * edge)


## The pixels on the edge of a tile of [param size].
static func _edge_pixels(size: Vector2i) -> Array[Vector2i]:
	var pixels: Array[Vector2i] = []
	for x in size.x:
		pixels.append_array([Vector2i(x, 0), Vector2i(x, size.y - 1)])
	for y in range(1, size.y - 1):
		pixels.append_array([Vector2i(0, y), Vector2i(size.x - 1, y)])
	return pixels


## The pixels of [param color] joined to [param start] (marked in
## [param seen]).
static func _part_of(image: Image, color: Color, start: Vector2i, seen: Dictionary) -> Dictionary:
	var part := {start: true}
	seen[start] = true
	var pending: Array[Vector2i] = [start]
	var whole := Rect2i(Vector2i.ZERO, image.get_size())
	while not pending.is_empty():
		var pixel: Vector2i = pending.pop_back()
		for side in SIDES:
			var next := pixel + side
			if whole.has_point(next) and not seen.has(next):
				if image.get_pixelv(next).is_equal_approx(color):
					seen[next] = true
					part[next] = true
					pending.append(next)
	return part


## Whether [param part] (pixels as keys) holds a square of [constant WIDE].
static func _holds_square(part: Dictionary) -> bool:
	for corner: Vector2i in part:
		var whole := true
		for dy in WIDE:
			for dx in WIDE:
				if not part.has(corner + Vector2i(dx, dy)):
					whole = false
					break
			if not whole:
				break
		if whole:
			return true
	return false
