class_name GalaxySkyPockets
extends RefCounted
## The sky that the picture behind a level must not take (ours, D13.2):
## sky shut in by the level's own drawing, such as the inside of level 9's
## glass pillars, domes and floors. The original draws glass as foreground
## tiles with see-through insides over the plain sky tiles, so the sky's
## colour is the glass's colour; with the sky made see-through for the
## picture ([GalaxyBackdropPictures]) the picture showed through the glass
## floor. Only sky that the open sky reaches stays see-through.
##
## A pixel is see-through where its background tile's sky was cleared and
## its foreground tile (if any) lets it through. Within each cell the
## see-through pixels form pockets (4-connected); pockets of neighbouring
## cells join where they share an edge pixel. Pockets joined to a cell on
## the edge of what the view can show (inside the map's border of
## [constant BORDER] tiles, which is solid) are open sky; the others are shut in, and
## [method find] gives their pixels as rows, to be painted in the sky's
## colour behind the tiles. Worked out once per map, from its first tiles
## (tiles a switch changes later keep what was found).

const TILE := GalaxyGraphics.TILE16_SIZE
const BORDER := GalaxyCamera.BORDER_TILES
## A foreground pixel lets the background through below this alpha.
const SEE_THROUGH_ALPHA := 0.5


## The pockets of one pair of tiles (a background and a foreground tile):
## each pixel's pocket (0: not see-through) and each pocket's edge pixels.
class Pockets:
	extends RefCounted
	var labels := PackedByteArray()
	var count := 0
	## Per pocket (index − 1): bit i set when its pixel i of that edge is in it.
	var top := PackedInt32Array()
	var bottom := PackedInt32Array()
	var left := PackedInt32Array()
	var right := PackedInt32Array()


## The shut-in sky of [param map] as one-pixel-high rows in level pixels.
## [param back_image] gives a background tile with its sky cleared (null:
## none), [param fore_image] a foreground tile with its mask (null: none).
static func find(map: GalaxyMap, back_image: Callable, fore_image: Callable) -> Array[Rect2i]:
	var size := Vector2i(map.width, map.height)
	var cache: Dictionary[int, Pockets] = {}
	var cells: Array[Pockets] = []
	var first := PackedInt32Array()
	var nodes := 0
	for y in size.y:
		for x in size.x:
			var back := map.tile(GalaxyMap.Layer.BACKGROUND, x, y)
			var fore := map.tile(GalaxyMap.Layer.FOREGROUND, x, y)
			var key := (back << 16) | fore
			if not cache.has(key):
				var fore_tile: Image = fore_image.call(fore) if fore != 0 else null
				cache[key] = _pockets_of(back_image.call(back), fore_tile)
			cells.append(cache[key])
			first.append(nodes)
			nodes += cache[key].count
	var parents := PackedInt32Array()
	parents.resize(nodes)
	for node in nodes:
		parents[node] = node
	_join_neighbours(cells, first, size, parents)
	var open := _open_roots(cells, first, size, parents)
	return _shut_rows(cells, first, size, parents, open)


## The pockets where [param back] (cleared sky see-through) shows through
## [param fore].
static func _pockets_of(back: Image, fore: Image) -> Pockets:
	var pockets := Pockets.new()
	pockets.labels.resize(TILE * TILE)
	if back == null:
		return pockets
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
	if not any:
		return pockets
	for start in TILE * TILE:
		if through[start] == 1 and pockets.labels[start] == 0:
			pockets.count += 1
			_fill(pockets, through, start)
	return pockets


## Labels the pocket at pixel [param start] and notes its edge pixels.
static func _fill(pockets: Pockets, through: PackedByteArray, start: int) -> void:
	var label := pockets.count
	pockets.top.append(0)
	pockets.bottom.append(0)
	pockets.left.append(0)
	pockets.right.append(0)
	var index := label - 1
	var pending := PackedInt32Array([start])
	pockets.labels[start] = label
	while not pending.is_empty():
		var pixel := pending[pending.size() - 1]
		pending.resize(pending.size() - 1)
		var x := pixel % TILE
		var y := pixel / TILE
		if y == 0:
			pockets.top[index] |= 1 << x
		if y == TILE - 1:
			pockets.bottom[index] |= 1 << x
		if x == 0:
			pockets.left[index] |= 1 << y
		if x == TILE - 1:
			pockets.right[index] |= 1 << y
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := Vector2i(x, y) + step
			if next.x < 0 or next.y < 0 or next.x >= TILE or next.y >= TILE:
				continue
			var at := next.y * TILE + next.x
			if through[at] == 1 and pockets.labels[at] == 0:
				pockets.labels[at] = label
				pending.append(at)


## Joins the pockets of every cell with those of its right and lower
## neighbour that share an edge pixel.
static func _join_neighbours(
	cells: Array[Pockets], first: PackedInt32Array, size: Vector2i, parents: PackedInt32Array
) -> void:
	for y in size.y:
		for x in size.x:
			var here := y * size.x + x
			var pockets := cells[here]
			if pockets.count == 0:
				continue
			if x + 1 < size.x:
				var right := cells[here + 1]
				for a in pockets.count:
					for b in right.count:
						if (pockets.right[a] & right.left[b]) != 0:
							_union(parents, first[here] + a, first[here + 1] + b)
			if y + 1 < size.y:
				var below := cells[here + size.x]
				for a in pockets.count:
					for b in below.count:
						if (pockets.bottom[a] & below.top[b]) != 0:
							_union(parents, first[here] + a, first[here + size.x] + b)


## The roots of the pockets joined to a cell on the edge of what the view
## can show (inside the map's solid border).
static func _open_roots(
	cells: Array[Pockets], first: PackedInt32Array, size: Vector2i, parents: PackedInt32Array
) -> Dictionary[int, bool]:
	var open: Dictionary[int, bool] = {}
	var inner := Rect2i(Vector2i(BORDER, BORDER), size - 2 * Vector2i(BORDER, BORDER))
	for y in range(inner.position.y, inner.end.y):
		for x in range(inner.position.x, inner.end.x):
			var on_edge := (
				x == inner.position.x
				or y == inner.position.y
				or x == inner.end.x - 1
				or y == inner.end.y - 1
			)
			if not on_edge:
				continue
			var here := y * size.x + x
			for pocket in cells[here].count:
				open[_root(parents, first[here] + pocket)] = true
	return open


## The rows of pixels of every pocket not joined to the open sky.
static func _shut_rows(
	cells: Array[Pockets],
	first: PackedInt32Array,
	size: Vector2i,
	parents: PackedInt32Array,
	open: Dictionary[int, bool]
) -> Array[Rect2i]:
	var rows: Array[Rect2i] = []
	for y in size.y:
		for x in size.x:
			var here := y * size.x + x
			var pockets := cells[here]
			var shut := PackedByteArray()
			shut.resize(pockets.count + 1)
			var any := false
			for pocket in pockets.count:
				if not open.has(_root(parents, first[here] + pocket)):
					shut[pocket + 1] = 1
					any = true
			if any:
				_add_rows(rows, pockets.labels, shut, Vector2i(x, y) * TILE)
	return rows


## Adds the runs of pixels whose pocket is [param shut] in a cell at
## [param corner] (pixels).
static func _add_rows(
	rows: Array[Rect2i], labels: PackedByteArray, shut: PackedByteArray, corner: Vector2i
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


static func _root(parents: PackedInt32Array, node: int) -> int:
	var root := node
	while parents[root] != root:
		root = parents[root]
	while parents[node] != root:
		var next := parents[node]
		parents[node] = root
		node = next
	return root


static func _union(parents: PackedInt32Array, a: int, b: int) -> void:
	var first := _root(parents, a)
	var second := _root(parents, b)
	if first != second:
		parents[maxi(first, second)] = mini(first, second)
