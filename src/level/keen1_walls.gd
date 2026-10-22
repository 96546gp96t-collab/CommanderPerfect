class_name Keen1Walls
extends LevelWalls
## Keen 1's sky and walls behind the levels (milestone AB2, the user's
## choice of 22-10-2026): outside the grey is the sky (a picture that glides,
## as level 1's since 16-10), and the black of the dark rooms (the shrines,
## the castle of level 16, the tunnel of level 13) is a stone wall fixed to
## the level.
##
## Grey is two things in Keen 1: outside it is the sky, but in a dark room
## every grey triangle hangs under a blue lamp (tile 156): a cone of light.
## The cones stay grey, as in the original. A grey region (cells joined
## through grey that touches their shared edge) is a cone when a cell of it
## lies right under a lamp ([method sky_kept_cells]). Grey without a lamp
## is the sky only where it has room: a cell next to the black of a dark
## room (tile 155, also diagonally) is sky only when it is joined to a grey
## cell that is not, within [constant ROOM_REACH] cells, so a long narrow
## grey strip between dark walls stays grey (the
## slopes and corners inside the castle of level 16, the corner at the
## bottom left of level 9's shrine). So the levels outside (1, 3, 4, 7, 8,
## 14) show their sky everywhere, the dark rooms (2, 5, 6, 11) keep every
## cone, and the mixed ones (9, 10, 12, 13, 15, 16) show the sky only
## outside; tests/test_level_walls_data.gd checks it on the real levels.

## The sky outside (Mars' sky is plain light grey in the original).
const SKY_TILE := 143
## The black of a dark room.
const WALL_TILE := 155
## A lamp at the ceiling of a dark room; the grey under it is its light.
const LAMP_TILE := 156
## How many cells next to the dark a grey cell may be from a cell with
## room, and still be the sky (the edge of the sky along a dark room's
## wall). Two would give the sky back the upper parts of the slopes in the
## castle of level 16.
const ROOM_REACH := 1
## Every cell around a cell, also diagonally.
const AROUND: Array[Vector2i] = [
	Vector2i(-1, -1),
	Vector2i(0, -1),
	Vector2i(1, -1),
	Vector2i(-1, 0),
	Vector2i(1, 0),
	Vector2i(-1, 1),
	Vector2i(0, 1),
	Vector2i(1, 1),
]


## Keen 1's walls: textures in [param folder] or the player's own folder in
## [param files], for the tiles [param tiles].
static func create(
	files: GameFiles, tiles: Array[Image], folder := BackdropPictures.FOLDER
) -> Keen1Walls:
	var walls := Keen1Walls.new()
	walls._textures = BackdropPictures.walls(files, folder)
	walls._tiles = tiles
	return walls


## The sky is always the grey of [constant SKY_TILE], also in a dark room
## whose most used plain tile is its black.
func holes(_level: LevelData, sky_color: Color, wall: bool) -> BackdropHoles:
	var sky := _color_of(SKY_TILE) if sky_color.a > 0.0 else Color.TRANSPARENT
	var wall_color := _color_of(WALL_TILE) if wall else Color.TRANSPARENT
	if sky.a <= 0.0 and wall_color.a <= 0.0:
		return null
	return BackdropHoles.create(sky, wall_color)


## The cells of the grey regions of [param level] that hang under a lamp.
func sky_kept_cells(level: LevelData, holes: BackdropHoles) -> Dictionary[Vector2i, bool]:
	var kept: Dictionary[Vector2i, bool] = {}
	if holes == null or not holes.has_sky():
		return kept
	var skies := _sky_masks(level, holes.sky_color)
	var roomy := _roomy_cells(level, skies)
	for region in _regions(level, skies):
		var lit := _under_a_lamp(level, region)
		for cell: Vector2i in region:
			if lit or not roomy.has(cell):
				kept[cell] = true
	return kept


## The cells with sky colour that have room to be the sky: not next to the
## black of a dark room, or joined to such a cell.
func _roomy_cells(
	level: LevelData, skies: Dictionary[int, PackedByteArray]
) -> Dictionary[Vector2i, bool]:
	var area := level.playable_rect()
	var open: Dictionary[Vector2i, bool] = {}
	var near: Array[Vector2i] = []
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			var cell := Vector2i(x, y)
			if not skies.has(level.tile_at(cell)):
				continue
			if _next_to_the_dark(level, cell):
				near.append(cell)
			else:
				open[cell] = true
	var roomy := open.duplicate()
	for reach in ROOM_REACH:
		var reached: Array[Vector2i] = []
		for cell in near:
			if not roomy.has(cell) and _beside_roomy(level, skies, roomy, cell):
				reached.append(cell)
		for cell in reached:
			roomy[cell] = true
	return roomy


## Whether [param cell] is joined through grey to a cell of [param roomy].
static func _beside_roomy(
	level: LevelData,
	skies: Dictionary[int, PackedByteArray],
	roomy: Dictionary[Vector2i, bool],
	cell: Vector2i
) -> bool:
	for step in LatticeWalls.NEIGHBOURS:
		var next := cell + step
		if roomy.has(next) and _joined(skies, level.tile_at(cell), level.tile_at(next), step):
			return true
	return false


static func _next_to_the_dark(level: LevelData, cell: Vector2i) -> bool:
	var bounds := Rect2i(0, 0, level.width, level.height)
	for step in AROUND:
		if bounds.has_point(cell + step) and level.tile_at(cell + step) == WALL_TILE:
			return true
	return false


## For every tile that [param level] uses, its pixels of [param color] that
## touch the tile's edge; only tiles that have some.
func _sky_masks(level: LevelData, color: Color) -> Dictionary[int, PackedByteArray]:
	var masks: Dictionary[int, PackedByteArray] = {}
	var area := level.playable_rect()
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			var tile := level.tile_at(Vector2i(x, y))
			if masks.has(tile) or tile < 0 or tile >= _tiles.size():
				continue
			masks[tile] = BackdropHoles.edge_flood(_tiles[tile], color)
	for tile in masks.keys():
		if not masks[tile].has(1):
			masks.erase(tile)
	return masks


## The cells of [param level] with sky colour, in regions that are joined
## where both cells have it at the same place on their shared edge.
func _regions(level: LevelData, skies: Dictionary[int, PackedByteArray]) -> Array[Array]:
	var area := level.playable_rect()
	var seen: Dictionary[Vector2i, bool] = {}
	var regions: Array[Array] = []
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			var start := Vector2i(x, y)
			if seen.has(start) or not skies.has(level.tile_at(start)):
				continue
			var region: Array[Vector2i] = []
			var pending: Array[Vector2i] = [start]
			seen[start] = true
			while not pending.is_empty():
				var cell: Vector2i = pending.pop_back()
				region.append(cell)
				for step in LatticeWalls.NEIGHBOURS:
					var next := cell + step
					if seen.has(next) or not area.has_point(next):
						continue
					if _joined(skies, level.tile_at(cell), level.tile_at(next), step):
						seen[next] = true
						pending.append(next)
			regions.append(region)
	return regions


## Whether a cell of [param region] lies right under a lamp.
static func _under_a_lamp(level: LevelData, region: Array) -> bool:
	for cell: Vector2i in region:
		if level.tile_at(cell + Vector2i.UP) == LAMP_TILE:
			return true
	return false


## Whether tile [param from] and the tile [param to] beside it (one
## [param step] away) both have sky colour at a place on their shared edge.
static func _joined(
	skies: Dictionary[int, PackedByteArray], from: int, to: int, step: Vector2i
) -> bool:
	if not skies.has(from) or not skies.has(to):
		return false
	var size := EgaGraphics.TILE_SIZE
	var last := size - 1
	for i in size:
		var a: int
		var b: int
		match step:
			Vector2i.RIGHT:
				a = i * size + last
				b = i * size
			Vector2i.LEFT:
				a = i * size
				b = i * size + last
			Vector2i.DOWN:
				a = last * size + i
				b = i
			_:
				a = i
				b = last * size + i
		if skies[from][a] and skies[to][b]:
			return true
	return false
