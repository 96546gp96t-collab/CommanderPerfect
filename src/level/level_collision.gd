class_name LevelCollision
extends RefCounted
## Answers how a box (Keen, later also enemies) can move through a level.
##
## Every tile side can be solid on its own, so a box only stops when it
## crosses a tile edge whose side faces it: moving down it stops on a tile
## with a solid top, moving right on a solid left side, and so on. That is how
## one-way platforms work: their top is solid, their other sides are not.
##
## Everything outside the playable area is a wall, except below it: falling
## out of the bottom of a level is possible (and deadly).
##
## Doors are solid from every side; opening one with a keycard removes its
## tiles from the level.

enum Edge { TOP, RIGHT, BOTTOM, LEFT }

const TILE_SIZE := EgaGraphics.TILE_SIZE
## Lets a box that stands exactly on an edge count as touching it, despite
## floating-point rounding.
const EDGE_TOLERANCE := 0.001

var level: LevelData
var properties: TileProperties


static func create(level_data: LevelData, tile_properties: TileProperties) -> LevelCollision:
	var collision := LevelCollision.new()
	collision.level = level_data
	collision.properties = tile_properties
	return collision


## The tile in [param cell] as seen by the game, or -1 outside the playable
## area.
func tile_at(cell: Vector2i) -> int:
	if not level.playable_rect().has_point(cell):
		return -1
	return level.tile_at(cell)


## Whether [param edge] of the tile in [param cell] stops a box.
func is_solid(cell: Vector2i, edge: Edge) -> bool:
	var playable := level.playable_rect()
	if not playable.has_point(cell):
		return cell.y < playable.end.y
	var tile := level.tile_at(cell)
	if properties.is_door(tile):
		return true
	match edge:
		Edge.TOP:
			return properties.blocks_top(tile)
		Edge.RIGHT:
			return properties.blocks_right(tile)
		Edge.BOTTOM:
			return properties.blocks_bottom(tile)
	return properties.blocks_left(tile)


## How far [param box] can move horizontally, at most [param distance].
func sweep_x(box: Rect2, distance: float) -> float:
	var rows := _cells_spanned(box.position.y, box.end.y)
	if distance > 0.0:
		var column := ceili(box.end.x / TILE_SIZE - EDGE_TOLERANCE)
		while column * TILE_SIZE < box.end.x + distance:
			if _any_solid_in_column(column, rows, Edge.LEFT):
				return maxf(0.0, column * TILE_SIZE - box.end.x)
			column += 1
	elif distance < 0.0:
		var column := floori(box.position.x / TILE_SIZE + EDGE_TOLERANCE) - 1
		while (column + 1) * TILE_SIZE > box.position.x + distance:
			if _any_solid_in_column(column, rows, Edge.RIGHT):
				return minf(0.0, (column + 1) * TILE_SIZE - box.position.x)
			column -= 1
	return distance


## How far [param box] can move vertically, at most [param distance].
func sweep_y(box: Rect2, distance: float) -> float:
	var columns := _cells_spanned(box.position.x, box.end.x)
	if distance > 0.0:
		var row := ceili(box.end.y / TILE_SIZE - EDGE_TOLERANCE)
		while row * TILE_SIZE < box.end.y + distance:
			if _any_solid_in_row(row, columns, Edge.TOP):
				return maxf(0.0, row * TILE_SIZE - box.end.y)
			row += 1
	elif distance < 0.0:
		var row := floori(box.position.y / TILE_SIZE + EDGE_TOLERANCE) - 1
		while (row + 1) * TILE_SIZE > box.position.y + distance:
			if _any_solid_in_row(row, columns, Edge.BOTTOM):
				return minf(0.0, (row + 1) * TILE_SIZE - box.position.y)
			row -= 1
	return distance


## The floor under [param box]: the best [enum TileProperties.Floor] of the
## tiles its bottom edge rests on, or NONE when it is not standing on
## anything. Ice wins over a normal floor, like in the original, where Keen
## slides as soon as one foot is on ice.
func floor_under(box: Rect2) -> TileProperties.Floor:
	var row := roundi(box.end.y / TILE_SIZE)
	if absf(row * TILE_SIZE - box.end.y) > EDGE_TOLERANCE:
		return TileProperties.Floor.NONE
	var result := TileProperties.Floor.NONE
	for column in _cells_spanned(box.position.x, box.end.x):
		var cell := Vector2i(column, row)
		if not is_solid(cell, Edge.TOP):
			continue
		var tile := tile_at(cell)
		var kind := TileProperties.Floor.SOLID
		if tile >= 0 and not properties.is_door(tile):
			kind = properties.floor_type(tile)
		result = maxi(result, kind) as TileProperties.Floor
	return result


## Whether [param box] overlaps a deadly tile.
func touches_deadly_tile(box: Rect2) -> bool:
	for cell in cells_under(box):
		var tile := tile_at(cell)
		if tile >= 0 and properties.is_deadly(tile):
			return true
	return false


## The cells that [param box] overlaps, row by row.
static func cells_under(box: Rect2) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for row in _cells_spanned(box.position.y, box.end.y):
		for column in _cells_spanned(box.position.x, box.end.x):
			cells.append(Vector2i(column, row))
	return cells


## Whether [param box] is completely below the playable area.
func is_below_level(box: Rect2) -> bool:
	return box.position.y >= level.playable_rect().end.y * TILE_SIZE


## Cell numbers covered by the pixel range [param from] to [param to]. A box
## that ends exactly on a cell edge does not cover the next cell.
static func _cells_spanned(from: float, to: float) -> PackedInt32Array:
	var cells := PackedInt32Array()
	var first := floori(from / TILE_SIZE + EDGE_TOLERANCE)
	var last := ceili(to / TILE_SIZE - EDGE_TOLERANCE) - 1
	for cell in range(first, last + 1):
		cells.append(cell)
	return cells


func _any_solid_in_column(column: int, rows: PackedInt32Array, edge: Edge) -> bool:
	for row in rows:
		if is_solid(Vector2i(column, row), edge):
			return true
	return false


func _any_solid_in_row(row: int, columns: PackedInt32Array, edge: Edge) -> bool:
	for column in columns:
		if is_solid(Vector2i(column, row), edge):
			return true
	return false
