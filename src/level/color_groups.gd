class_name ColorGroups
extends RefCounted
## Which pixels of a plain colour in a level's tiles are open and which are
## shut in by the level's own drawing (a fix of 22-10 for the pictures
## behind Keen 1's levels, [method Keen1Walls.holes]).
##
## Keen 1's sky is plain light grey and its dark rooms plain black, and the
## same colours are drawn in things: the shading along the bottom of the
## white snow platforms is the sky's grey and touches the left and right
## edges of their tiles, so the colour rule took it for the sky and the
## picture showed through the platform's bottom edge; the black specks
## along the bottom of a sand platform took the wall. Seen across the tiles
## they are shut in: the shading runs from tile to tile to the platform's
## rounded ends and never reaches the open sky.
##
## So the pixels of the colour that touch a tile's edge
## ([method BackdropHoles.edge_flood]) are split into groups (joined side
## by side or one above the other), and the groups of neighbouring cells
## join where both have the colour at the same place of their shared edge.
## A join is open when it holds a cell that is all of that colour (the
## plain sky, the plain dark), or reaches the edge of the level. The atlas
## has one picture per tile, so a tile's group stays only when it is shut
## in wherever the level uses that tile.

const SIZE := EgaGraphics.TILE_SIZE
const LAST := SIZE - 1

var _level: LevelData
var _area: Rect2i
## For each tile the level uses that has the colour at its edge: the
## group of each pixel (0 for none, else 1 and up), and how many there are.
var _labels: Dictionary[int, PackedByteArray] = {}
var _counts: Dictionary[int, int] = {}
## The node of a cell's first group (its others follow), -1 for none.
var _first_node := PackedInt32Array()
var _parent := PackedInt32Array()
## Whether each root's join holds a plain cell.
var _open := PackedByteArray()


## The groups of [param color] in [param level], whose tiles are
## [param tiles].
static func create(level: LevelData, tiles: Array[Image], color: Color) -> ColorGroups:
	var groups := ColorGroups.new()
	groups._group(level, tiles, color)
	return groups


func _group(level: LevelData, tiles: Array[Image], color: Color) -> void:
	_level = level
	_area = level.playable_rect()
	_label_tiles(tiles, color)
	_make_nodes()
	_join_neighbours()
	_mark_open()


## [method shut_pixels] of [param level] (tiles [param tiles], colour
## [param color]) in every step of its animations ([param properties]; one
## step without them): every frame of an animated tile that shows the colour
## gets its own groups, shut in where they are in every step that shows it.
## The black face of Keen 1's exit sign blinks between two tiles; the level
## names one, so without the steps the other frame let the wall show.
static func shut_in_every_step(
	level: LevelData, tiles: Array[Image], color: Color, properties: TileProperties = null
) -> Dictionary[int, PackedByteArray]:
	var result: Dictionary[int, PackedByteArray] = {}
	var labels: Dictionary[int, PackedByteArray] = {}
	var counts: Dictionary[int, int] = {}
	for step in _steps(level, tiles, color, properties):
		# A tile's groups are the same in every step: label each tile once.
		var groups := ColorGroups.new()
		groups._labels = labels
		groups._counts = counts
		groups._group(_stepped(level, properties, step), tiles, color)
		var shut := groups.shut_pixels()
		for tile: int in groups._shown_tiles():
			var pixels := PackedByteArray()
			pixels.resize(SIZE * SIZE)
			if shut.has(tile):
				pixels = shut[tile]
			if result.has(tile):
				for i in pixels.size():
					pixels[i] = pixels[i] & result[tile][i]
			result[tile] = pixels
	for tile: int in result.keys():
		if not result[tile].has(1):
			result.erase(tile)
	return result


## How many steps the animations of [param level] have that matter for
## [param color]: the most frames of an animated tile it uses that shows the
## colour at its edge in one of them; 1 without [param properties].
static func _steps(
	level: LevelData, tiles: Array[Image], color: Color, properties: TileProperties
) -> int:
	var steps := 1
	if properties == null:
		return steps
	var seen := {}
	var area := level.playable_rect()
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			var tile := level.tile_at(Vector2i(x, y))
			var frames := properties.animation_frames(tile)
			if frames <= steps or seen.has(tile):
				continue
			seen[tile] = true
			for step in frames:
				var frame := properties.animated_tile(tile, step)
				if frame < tiles.size() and BackdropHoles.edge_flood(tiles[frame], color).has(1):
					steps = frames
					break
	return steps


## [param level] with every animated tile [param step] steps further.
static func _stepped(level: LevelData, properties: TileProperties, step: int) -> LevelData:
	if step == 0:
		return level
	var result := LevelData.new()
	result.width = level.width
	result.height = level.height
	result.tiles = level.tiles.duplicate()
	result.infos = level.infos
	for i in result.tiles.size():
		result.tiles[i] = properties.animated_tile(result.tiles[i], step)
	return result


## Per tile, 1 for every pixel of a group that is shut in wherever the
## level uses the tile; only tiles that have such a group.
func shut_pixels() -> Dictionary[int, PackedByteArray]:
	var open_somewhere: Dictionary[int, PackedByteArray] = {}
	for tile: int in _labels:
		var flags := PackedByteArray()
		flags.resize(_counts[tile] + 1)
		open_somewhere[tile] = flags
	for y in _area.size.y:
		for x in _area.size.x:
			var first := _first_node[y * _area.size.x + x]
			if first < 0:
				continue
			var tile := _tile_at(x, y)
			for group in range(1, _counts[tile] + 1):
				if _open[_find(first + group - 1)]:
					open_somewhere[tile][group] = 1
	var shut: Dictionary[int, PackedByteArray] = {}
	for tile: int in _labels:
		var pixels := PackedByteArray()
		pixels.resize(SIZE * SIZE)
		var any := false
		for i in pixels.size():
			var group := _labels[tile][i]
			if group > 0 and not open_somewhere[tile][group]:
				pixels[i] = 1
				any = true
		if any:
			shut[tile] = pixels
	return shut


## Whether the group of pixel [param pixel] of the cell at [param cell]
## (level cells) is open; false where there is no such group.
func is_open(cell: Vector2i, pixel: Vector2i) -> bool:
	var at := cell - _area.position
	if not Rect2i(Vector2i.ZERO, _area.size).has_point(at):
		return false
	var first := _first_node[at.y * _area.size.x + at.x]
	if first < 0:
		return false
	var group := _labels[_tile_at(at.x, at.y)][pixel.y * SIZE + pixel.x]
	return group > 0 and _open[_find(first + group - 1)] == 1


## The tiles of the level that have groups.
func _shown_tiles() -> Array[int]:
	var shown: Array[int] = []
	var seen := {}
	for y in _area.size.y:
		for x in _area.size.x:
			var tile := _tile_at(x, y)
			if _labels.has(tile) and not seen.has(tile):
				seen[tile] = true
				shown.append(tile)
	return shown


func _tile_at(x: int, y: int) -> int:
	return _level.tile_at(_area.position + Vector2i(x, y))


func _label_tiles(tiles: Array[Image], color: Color) -> void:
	for y in _area.size.y:
		for x in _area.size.x:
			var tile := _tile_at(x, y)
			if _labels.has(tile) or _counts.has(tile) or tile < 0 or tile >= tiles.size():
				continue
			var flood := BackdropHoles.edge_flood(tiles[tile], color)
			var labels := PackedByteArray()
			labels.resize(SIZE * SIZE)
			var count := 0
			for start in labels.size():
				if flood[start] and not labels[start]:
					count += 1
					_fill(flood, labels, start, count)
			_counts[tile] = count
			if count > 0:
				_labels[tile] = labels


## Gives the pixels of [param flood] joined to [param start] the label
## [param label].
static func _fill(flood: PackedByteArray, labels: PackedByteArray, start: int, label: int) -> void:
	var pending: Array[int] = [start]
	labels[start] = label
	while not pending.is_empty():
		var i: int = pending.pop_back()
		var x := i % SIZE
		var neighbours: Array[int] = []
		if x > 0:
			neighbours.append(i - 1)
		if x < LAST:
			neighbours.append(i + 1)
		if i >= SIZE:
			neighbours.append(i - SIZE)
		if i < SIZE * LAST:
			neighbours.append(i + SIZE)
		for j in neighbours:
			if flood[j] and not labels[j]:
				labels[j] = label
				pending.append(j)


func _make_nodes() -> void:
	_first_node.resize(_area.size.x * _area.size.y)
	var nodes := 0
	for y in _area.size.y:
		for x in _area.size.x:
			var tile := _tile_at(x, y)
			var count: int = _counts.get(tile, 0)
			_first_node[y * _area.size.x + x] = nodes if count > 0 else -1
			nodes += count
	_parent.resize(nodes)
	for node in nodes:
		_parent[node] = node


func _join_neighbours() -> void:
	for y in _area.size.y:
		for x in _area.size.x:
			if _first_node[y * _area.size.x + x] < 0:
				continue
			if x + 1 < _area.size.x:
				_join(x, y, x + 1, y, Vector2i.RIGHT)
			if y + 1 < _area.size.y:
				_join(x, y, x, y + 1, Vector2i.DOWN)


## Joins the groups of the cells at ([param x], [param y]) and the one
## [param step] further that meet on their shared edge.
func _join(x: int, y: int, next_x: int, next_y: int, step: Vector2i) -> void:
	var next_first := _first_node[next_y * _area.size.x + next_x]
	if next_first < 0:
		return
	var first := _first_node[y * _area.size.x + x]
	var labels := _labels[_tile_at(x, y)]
	var next_labels := _labels[_tile_at(next_x, next_y)]
	for i in SIZE:
		var a := i * SIZE + LAST if step == Vector2i.RIGHT else LAST * SIZE + i
		var b := i * SIZE if step == Vector2i.RIGHT else i
		if labels[a] > 0 and next_labels[b] > 0:
			_union(first + labels[a] - 1, next_first + next_labels[b] - 1)


func _mark_open() -> void:
	_open.resize(_parent.size())
	for y in _area.size.y:
		for x in _area.size.x:
			var first := _first_node[y * _area.size.x + x]
			if first < 0:
				continue
			var tile := _tile_at(x, y)
			if _is_plain(tile):
				_open[_find(first)] = 1
			for group in _groups_at_level_edge(tile, x, y):
				_open[_find(first + group - 1)] = 1
	# Every node takes its root's answer when asked ([method _find]).


## The groups of [param tile] in the cell at ([param x], [param y]) that
## reach the edge of the level's playable area: the colour goes on beyond
## it (the sky beside a pillar at the level's edge).
func _groups_at_level_edge(tile: int, x: int, y: int) -> PackedInt32Array:
	var groups := PackedInt32Array()
	var labels := _labels[tile]
	for i in SIZE:
		var edges := PackedInt32Array()
		if x == 0:
			edges.append(i * SIZE)
		if x == _area.size.x - 1:
			edges.append(i * SIZE + LAST)
		if y == 0:
			edges.append(i)
		if y == _area.size.y - 1:
			edges.append(LAST * SIZE + i)
		for at in edges:
			if labels[at] > 0 and not groups.has(labels[at]):
				groups.append(labels[at])
	return groups


## Whether all of [param tile] is the colour: one group of every pixel.
func _is_plain(tile: int) -> bool:
	return _counts.get(tile, 0) == 1 and not _labels[tile].has(0)


func _find(node: int) -> int:
	var root := node
	while _parent[root] != root:
		root = _parent[root]
	while _parent[node] != root:
		var next := _parent[node]
		_parent[node] = root
		node = next
	return root


func _union(a: int, b: int) -> void:
	var root_a := _find(a)
	var root_b := _find(b)
	if root_a != root_b:
		_parent[root_b] = root_a
