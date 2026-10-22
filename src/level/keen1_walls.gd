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
##
## The fixes of 22-10 (the user's test in widescreen):
##   - a grey cell next to the dark on one side only (no dark on the
##     opposite side, within [constant SHUT_REACH] cells) is sky when it is
##     joined to the sky, however far: the steps of grey triangles where a
##     dark room's wall slants down to the floor next to the sky (levels 9
##     and 10) show the picture, as the open sky beside them does; a narrow
##     grey strip between dark walls stays grey
##   - black is the wall only where it is two by two pixels thick, so the
##     outlines of platforms, blocks and mushrooms stay black
##     ([member BackdropHoles.thick_wall])
##   - grey and black that the level's drawing shuts in are not the sky or
##     the wall ([ColorGroups]): the shading under the white snow platforms
##     runs from tile to tile to the platform's rounded ends and stays grey,
##     the black specks along a sand platform's bottom stay black
##
## And of the user's second test (22-10): black that a block's or a sign's
## own drawing holds is not the wall (the bottom triangle of the dark
## studded blocks, the exit sign: [member BackdropHoles.block_tiles]),
## every frame of an animation gets its own shut-in pixels and the holes of
## the others ([method ColorGroups.shut_in_every_step]: the blinking exit
## sign), and the light that falls through a gap in a wall of blocks into a
## dark room is grey from the wall on ([method _close_inside_gaps]: the
## castle of level 16).

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
## How far (in cells) dark on the opposite side makes a grey cell next to
## the dark lie between two dark walls.
const SHUT_REACH := 4
## The widest gap in a wall of blocks (in cells) through which the sky does
## not pass into a dark room ([method _wall_gaps]).
const GAP_SIZE := 3
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

var _properties: TileProperties
var _blocks: Dictionary[int, bool] = {}


## Keen 1's walls: textures in [param folder] or the player's own folder in
## [param files], for the tiles [param tiles], whose [param properties] tell
## the animations (none without them).
static func create(
	files: GameFiles,
	tiles: Array[Image],
	folder := BackdropPictures.FOLDER,
	properties: TileProperties = null
) -> Keen1Walls:
	var walls := Keen1Walls.new()
	walls._textures = BackdropPictures.walls(files, folder)
	walls._tiles = tiles
	walls._properties = properties
	walls._animations = animations(properties, tiles.size())
	walls._blocks = blocks(properties, tiles.size())
	return walls


## The tiles among the first [param count] of [param properties] that are
## solid on every side; none without properties.
static func blocks(properties: TileProperties, count: int) -> Dictionary[int, bool]:
	var found: Dictionary[int, bool] = {}
	if properties == null:
		return found
	for tile in mini(count, properties.tile_count):
		if (
			properties.blocks_top(tile)
			and properties.blocks_bottom(tile)
			and properties.blocks_left(tile)
			and properties.blocks_right(tile)
		):
			found[tile] = true
	return found


## The sky is always the grey of [constant SKY_TILE], also in a dark room
## whose most used plain tile is its black.
func holes(level: LevelData, sky_color: Color, wall: bool) -> BackdropHoles:
	var sky := _color_of(SKY_TILE) if sky_color.a > 0.0 else Color.TRANSPARENT
	var wall_color := _color_of(WALL_TILE) if wall else Color.TRANSPARENT
	if sky.a <= 0.0 and wall_color.a <= 0.0:
		return null
	var holes := BackdropHoles.create(sky, wall_color)
	holes.thick_wall = true
	holes.animations = _animations
	holes.block_tiles = _blocks
	for color: Color in [sky, wall_color]:
		if color.a > 0.0:
			_add_pixels(
				holes.shut_in, ColorGroups.shut_in_every_step(level, _tiles, color, _properties)
			)
	return holes


## Adds the pixels of [param more] to those of [param pixels], tile by tile.
static func _add_pixels(
	pixels: Dictionary[int, PackedByteArray], more: Dictionary[int, PackedByteArray]
) -> void:
	for tile: int in more:
		if not pixels.has(tile):
			pixels[tile] = more[tile]
			continue
		var both := pixels[tile].duplicate()
		for i in both.size():
			both[i] = both[i] | more[tile][i]
		pixels[tile] = both


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
	_spread_along_one_side(level, skies, roomy, near)
	for reach in ROOM_REACH:
		var reached: Array[Vector2i] = []
		for cell in near:
			if not roomy.has(cell) and _beside_roomy(level, skies, roomy, cell):
				reached.append(cell)
		for cell in reached:
			roomy[cell] = true
	_close_inside_gaps(level, skies, roomy, near)
	return roomy


## Takes from [param roomy] the grey beyond a gap in a wall of blocks
## ([method _wall_gaps]) that lies mostly next to the dark ([param near])
## and turns grey somewhere: the grey cells joined to each other without
## passing a gap, beside a gap, at least half of them near the dark, and
## some of them not the sky already. The light that falls through a gap in
## the castle wall of level 16 is a cone of light from the wall on, not
## from a cell or two further in; the gap itself shows the sky.
func _close_inside_gaps(
	level: LevelData,
	skies: Dictionary[int, PackedByteArray],
	roomy: Dictionary[Vector2i, bool],
	near: Array[Vector2i]
) -> void:
	var gaps := _wall_gaps(level, skies)
	if gaps.is_empty():
		return
	var dark: Dictionary[Vector2i, bool] = {}
	for cell in near:
		dark[cell] = true
	var area := level.playable_rect()
	var seen: Dictionary[Vector2i, bool] = {}
	var closed: Dictionary[Vector2i, bool] = {}
	for start: Vector2i in gaps:
		for step in LatticeWalls.NEIGHBOURS:
			var first := start + step
			if seen.has(first) or gaps.has(first) or not area.has_point(first):
				continue
			if not _joined(skies, level.tile_at(start), level.tile_at(first), step):
				continue
			var part := _part_without(level, skies, gaps, first, seen)
			var near_count := 0
			for cell in part:
				near_count += 1 if dark.has(cell) else 0
			if near_count * 2 >= part.size() and _turns_grey(level, skies, roomy, gaps, part):
				for cell in part:
					roomy.erase(cell)
					closed[cell] = true
	_open_gaps(level, skies, roomy, gaps, closed)


## Whether a cell of [param part], or a gap cell ([param gaps]) beside it,
## is not the sky ([param roomy]).
static func _turns_grey(
	level: LevelData,
	skies: Dictionary[int, PackedByteArray],
	roomy: Dictionary[Vector2i, bool],
	gaps: Dictionary[Vector2i, bool],
	part: Array[Vector2i]
) -> bool:
	for cell in part:
		if not roomy.has(cell):
			return true
		for step in LatticeWalls.NEIGHBOURS:
			var next := cell + step
			if (
				gaps.has(next)
				and not roomy.has(next)
				and _joined(skies, level.tile_at(cell), level.tile_at(next), step)
			):
				return true
	return false


## Gives the cells of [param gaps] the sky where they are joined to the sky
## outside (a cell of [param roomy] that is no gap), directly or through
## other gap cells, and takes it from those beside [param closed] that are
## not: the gap in the wall shows the sky as one piece up to the wall's
## inner side, with the grey just outside it.
static func _open_gaps(
	level: LevelData,
	skies: Dictionary[int, PackedByteArray],
	roomy: Dictionary[Vector2i, bool],
	gaps: Dictionary[Vector2i, bool],
	closed: Dictionary[Vector2i, bool]
) -> void:
	if closed.is_empty():
		return
	var outside: Dictionary[Vector2i, bool] = {}
	var pending: Array[Vector2i] = []
	for cell: Vector2i in gaps:
		for step in LatticeWalls.NEIGHBOURS:
			var next := cell + step
			if (
				roomy.has(next)
				and not gaps.has(next)
				and _joined(skies, level.tile_at(cell), level.tile_at(next), step)
			):
				outside[cell] = true
				pending.append(cell)
				break
	while not pending.is_empty():
		var cell: Vector2i = pending.pop_back()
		for step in LatticeWalls.NEIGHBOURS:
			var next := cell + step
			if (
				gaps.has(next)
				and not outside.has(next)
				and _joined(skies, level.tile_at(cell), level.tile_at(next), step)
			):
				outside[next] = true
				pending.append(next)
	for cell: Vector2i in gaps:
		if not _beside_any(cell, closed):
			continue
		if not outside.has(cell):
			roomy.erase(cell)
			continue
		roomy[cell] = true
		# The grey beside the gap on the outside (a step of the slope that
		# leads to it) is the sky as well.
		for step in LatticeWalls.NEIGHBOURS:
			var next := cell + step
			if (
				not closed.has(next)
				and not gaps.has(next)
				and skies.has(level.tile_at(next))
				and _joined(skies, level.tile_at(cell), level.tile_at(next), step)
			):
				roomy[next] = true


static func _beside_any(cell: Vector2i, cells: Dictionary[Vector2i, bool]) -> bool:
	for step in LatticeWalls.NEIGHBOURS:
		if cells.has(cell + step):
			return true
	return false


## The grey cells joined to [param start] without passing a cell of
## [param gaps], each added to [param seen].
static func _part_without(
	level: LevelData,
	skies: Dictionary[int, PackedByteArray],
	gaps: Dictionary[Vector2i, bool],
	start: Vector2i,
	seen: Dictionary[Vector2i, bool]
) -> Array[Vector2i]:
	var area := level.playable_rect()
	var part: Array[Vector2i] = []
	var pending: Array[Vector2i] = [start]
	seen[start] = true
	while not pending.is_empty():
		var cell: Vector2i = pending.pop_back()
		part.append(cell)
		for step in LatticeWalls.NEIGHBOURS:
			var next := cell + step
			if seen.has(next) or gaps.has(next) or not area.has_point(next):
				continue
			if _joined(skies, level.tile_at(cell), level.tile_at(next), step):
				seen[next] = true
				pending.append(next)
	return part


## The grey cells in a gap of a wall of blocks: along their column or their
## row, the grey (at most [constant GAP_SIZE] cells) ends at a block on
## both sides, a cell that is neither grey nor the dark of a room. The light
## that falls through a gap in the castle wall of level 16 into the dark
## inside is a cone of light from there on, not the sky
## ([method _close_inside_gaps]).
func _wall_gaps(
	level: LevelData, skies: Dictionary[int, PackedByteArray]
) -> Dictionary[Vector2i, bool]:
	var gaps: Dictionary[Vector2i, bool] = {}
	var area := level.playable_rect()
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			var cell := Vector2i(x, y)
			if not skies.has(level.tile_at(cell)):
				continue
			for axis: Vector2i in [Vector2i.DOWN, Vector2i.RIGHT]:
				var ahead := _gap_end(level, skies, cell, axis)
				var behind := _gap_end(level, skies, cell, -axis)
				if ahead == 0 or behind == 0 or ahead + behind - 1 > GAP_SIZE:
					continue
				var across := Vector2i(axis.y, axis.x)
				if (
					_is_wall_end(level, skies, cell + axis * ahead, across)
					and _is_wall_end(level, skies, cell - axis * behind, across)
				):
					gaps[cell] = true
	return gaps


## Whether the block at [param cell] is the end of a thin wall: a cell
## beside it [param across] the wall (on one side or the other) is no block
## ([member _blocks]; without the tile properties: neither grey nor dark).
## A low passage under a ledge has blocks beside its floor and ceiling.
func _is_wall_end(
	level: LevelData, skies: Dictionary[int, PackedByteArray], cell: Vector2i, across: Vector2i
) -> bool:
	for side: Vector2i in [across, -across]:
		var tile := level.tile_at(cell + side)
		if _blocks.is_empty():
			if _is_dark(level, cell + side) or skies.has(tile):
				return true
		elif not _blocks.has(tile):
			return true
	return false


## How many cells from [param cell] in steps of [param step] the first block
## lies with only grey before it (at most [constant GAP_SIZE]); 0 when the
## grey ends at the dark, the level's edge, or goes on further.
static func _gap_end(
	level: LevelData, skies: Dictionary[int, PackedByteArray], cell: Vector2i, step: Vector2i
) -> int:
	var area := level.playable_rect()
	for reach in range(1, GAP_SIZE + 1):
		var next := cell + step * reach
		if not area.has_point(next) or _is_dark(level, next):
			return 0
		if not skies.has(level.tile_at(next)):
			return reach
	return 0


## Adds to [param roomy] the cells of [param near] that have the dark on one
## side only and are joined to it, through each other as far as they go.
func _spread_along_one_side(
	level: LevelData,
	skies: Dictionary[int, PackedByteArray],
	roomy: Dictionary[Vector2i, bool],
	near: Array[Vector2i]
) -> void:
	var one_sided: Array[Vector2i] = []
	for cell in near:
		if not _between_the_dark(level, skies, cell):
			one_sided.append(cell)
	var grown := true
	while grown:
		grown = false
		for cell in one_sided:
			if not roomy.has(cell) and _beside_roomy(level, skies, roomy, cell):
				roomy[cell] = true
				grown = true


## Whether [param cell] has the dark of a room on two opposite sides: a
## dark cell around it, and another one on the other side of it within
## [constant SHUT_REACH] cells, with only grey between (a block between
## them, such as the studded row above level 9's floor, belongs to another
## room).
static func _between_the_dark(
	level: LevelData, skies: Dictionary[int, PackedByteArray], cell: Vector2i
) -> bool:
	for step in AROUND:
		if not _is_dark(level, cell + step):
			continue
		for reach in range(1, SHUT_REACH + 1):
			var other := cell - step * reach
			if _is_dark(level, other):
				return true
			if not skies.has(level.tile_at(other)):
				break
	return false


static func _is_dark(level: LevelData, cell: Vector2i) -> bool:
	var bounds := Rect2i(0, 0, level.width, level.height)
	return bounds.has_point(cell) and level.tile_at(cell) == WALL_TILE


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
	for step in AROUND:
		if _is_dark(level, cell + step):
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
