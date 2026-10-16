class_name ShipLevels
extends RefCounted
## The two extra levels of Keen's ship, which the original does not have,
## in a layout of our own (no level file).
##
##   outside  the crashed ship of the title screen (map 90) on the ground of
##            Mars, smoking. Keen starts left of it, as on the title screen.
##            Walking into its back takes him inside, with the walk of the
##            exit doors: there is an exit there that is not drawn. He walks
##            out of sight at the left or right (jumping over that exit) to
##            go back to the world map.
##   inside   a small cabin with a place for each of the four ship parts
##            (see [ShipRepair]); the hatch at the left leads out again.
##
## The cabin is drawn by [ShipInterior]; its tiles are only the background
## (which is left out of the tiles, so that the drawing shows through) and
## the parts in their places. Its walls, floor and ceiling are solid cells
## of their own ([method solid_cells]). An empty place shows the gray picture
## of its part (the tiles of the "missing parts" window); a part that is back
## shows the part itself.
##
## The levels have numbers of their own, above those of the level files, so
## that the rest of the game (the status line, playing online) can tell
## them apart.

const OUTSIDE_LEVEL := 100
const INSIDE_LEVEL := 101
## Coming out of the ship, Keen starts at the cell with this info value,
## next to it, instead of at [constant LevelData.PLAYER_START_INFO].
const DOOR_START_INFO := 254
## The places for the ship parts have these info values, one per
## [enum Inventory.ShipPart] from the first on.
const FIRST_PLACE_INFO := 200
## The outside shows the picture behind level 1 (Mars), when pictures are on.
const OUTSIDE_PICTURE_LEVEL := 1

## Tiles: -1 leaves the background in that cell.
const KEEP := -1
const BACKGROUND_TILE := 143
const GROUND_TILE := 182
const UNDERGROUND_TILE := 185
## Keen's ship as it stands on the title screen: 7x3 cells.
const SHIP_TILES := [
	[351, 352, 353, 354, 355, 356, KEEP],
	[364, 365, 366, 367, 368, 369, 370],
	[377, 378, 379, 380, 381, 382, 383],
]
const MOUNTAIN_TILES := [
	[KEEP, 229, 230],
	[231, 232, 233],
]
## The ship parts, and their gray pictures for a place that is still empty.
const PART_TILES := StatusScreen.SHIP_PART_TILES
const EMPTY_PLACE_TILES := MapMessages.PART_TILES

## The outside, in cells of its playable area: 40x12, wider than any view,
## so that the ship scrolls by.
const OUTSIDE_SIZE := Vector2i(40, 12)
const OUTSIDE_GROUND_ROW := 9
const OUTSIDE_SHIP := Vector2i(14, 6)
## The way into the ship: its back, where Keen stands on the ground.
const OUTSIDE_ENTRANCE: Array[Vector2i] = [Vector2i(15, 7), Vector2i(15, 8)]
const OUTSIDE_MOUNTAINS: Array[Vector2i] = [Vector2i(3, 7), Vector2i(32, 7)]
const OUTSIDE_START := Vector2i(9, 7)
const OUTSIDE_DOOR_START := Vector2i(12, 7)
## Where smoke rises from, in pixels of the playable area: the exhaust and
## a crack in the middle of the ship.
const SMOKE_SOURCES: Array[Vector2] = [Vector2(228, 116), Vector2(280, 100)]

## The cabin: 24x10 cells. Rows 0-1 are the roof, 8-9 the floor; the hatch
## is at the left in rows 6-7, the nose with the cockpit at the right.
const INSIDE_SIZE := Vector2i(24, 10)
const INSIDE_FLOOR_ROW := 8
const INSIDE_CEILING_ROWS := 2
const HATCH_ROWS := Vector2i(6, 7)
const INSIDE_START := Vector2i(2, 6)
## The slope of the nose: in each of these columns, the cells from row 2 down
## to this row are solid.
const NOSE_SLOPE := {19: 3, 20: 4, 21: 5, 22: 7, 23: 7}
## One place per part, by [enum Inventory.ShipPart]: the joystick at the
## controls in the nose, the battery and the vacuum cleaner in the middle,
## the Everclear at the fuel tank near the back.
const PLACE_COLUMNS: PackedInt32Array = [18, 9, 13, 5]


static func is_ship_level(level_number: int) -> bool:
	return level_number == OUTSIDE_LEVEL or level_number == INSIDE_LEVEL


## Name of a level for the status line: the ship's, or that of a level file.
static func title(level_number: int) -> String:
	match level_number:
		OUTSIDE_LEVEL:
			return "Ship"
		INSIDE_LEVEL:
			return "Inside the ship"
	return GameFiles.level_title(level_number)


## The level whose picture is shown behind level [param level_number].
static func picture_level(level_number: int) -> int:
	return OUTSIDE_PICTURE_LEVEL if level_number == OUTSIDE_LEVEL else level_number


## Builds ship level [param level_number] (or returns null for another
## number). Inside, the parts in [param installed] are back in their places;
## without it every place is empty.
static func build(level_number: int, installed: Array[bool] = []) -> LevelData:
	match level_number:
		OUTSIDE_LEVEL:
			return _build_outside()
		INSIDE_LEVEL:
			return _build_inside(installed)
	push_error("Level %d is not a level of the ship." % level_number)
	return null


## The part whose place is marked by [param info], or -1.
static func part_of_place(info: int) -> int:
	var part := info - FIRST_PLACE_INFO
	return part if part >= 0 and part < Inventory.ShipPart.size() else -1


## Where smoke rises from in level [param level_number], in level pixels.
static func smoke_sources(level_number: int) -> Array[Vector2]:
	var sources: Array[Vector2] = []
	if level_number == OUTSIDE_LEVEL:
		var border := Vector2.ONE * LevelData.BORDER_CELLS * EgaGraphics.TILE_SIZE
		for source in SMOKE_SOURCES:
			sources.append(border + source)
	return sources


## The playable cell of the place of [param part] inside the ship.
static func place_cell(part: int) -> Vector2i:
	return Vector2i(PLACE_COLUMNS[part], INSIDE_FLOOR_ROW - 1)


## The cells of level [param level_number] (with the border) where Keen goes
## in as through an exit door, although no door is drawn there.
static func entrance_cells(level_number: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if level_number == OUTSIDE_LEVEL:
		for cell in OUTSIDE_ENTRANCE:
			cells.append(cell + Vector2i.ONE * LevelData.BORDER_CELLS)
	return cells


## The cells of level [param level_number] (with the border) that are solid
## although their tile is not: the walls, roof and floor of the cabin.
static func solid_cells(level_number: int) -> Dictionary[Vector2i, bool]:
	var cells: Dictionary[Vector2i, bool] = {}
	if level_number != INSIDE_LEVEL:
		return cells
	for x in INSIDE_SIZE.x:
		for y in INSIDE_SIZE.y:
			if _is_cabin_wall(Vector2i(x, y)):
				cells[Vector2i(x, y) + Vector2i.ONE * LevelData.BORDER_CELLS] = true
	return cells


static func _is_cabin_wall(cell: Vector2i) -> bool:
	if cell.y < INSIDE_CEILING_ROWS or cell.y >= INSIDE_FLOOR_ROW:
		return true
	if cell.x == 0:
		# The back wall, with the hatch in it.
		return cell.y < HATCH_ROWS.x or cell.y > HATCH_ROWS.y
	return NOSE_SLOPE.has(cell.x) and cell.y <= NOSE_SLOPE[cell.x]


static func _build_outside() -> LevelData:
	var level := _empty(OUTSIDE_SIZE, BACKGROUND_TILE)
	for row in range(OUTSIDE_GROUND_ROW, OUTSIDE_SIZE.y):
		_fill_row(level, row, GROUND_TILE if row == OUTSIDE_GROUND_ROW else UNDERGROUND_TILE)
	for at in OUTSIDE_MOUNTAINS:
		_put(level, at, MOUNTAIN_TILES)
	_put(level, OUTSIDE_SHIP, SHIP_TILES)
	_mark(level, OUTSIDE_START, LevelData.PLAYER_START_INFO)
	_mark(level, OUTSIDE_DOOR_START, DOOR_START_INFO)
	return level


static func _build_inside(installed: Array[bool]) -> LevelData:
	var level := _empty(INSIDE_SIZE, BACKGROUND_TILE)
	for part in PLACE_COLUMNS.size():
		var place := place_cell(part)
		var is_in := part < installed.size() and installed[part]
		_set_cell(level, place, PART_TILES[part] if is_in else EMPTY_PLACE_TILES[part])
		_mark(level, place, FIRST_PLACE_INFO + part)
	_mark(level, INSIDE_START, LevelData.PLAYER_START_INFO)
	return level


## A level of [param size] playable cells, all [param tile], with the usual
## border around it filled the same way.
static func _empty(size: Vector2i, tile: int) -> LevelData:
	var level := LevelData.new()
	level.width = size.x + 2 * LevelData.BORDER_CELLS
	level.height = size.y + 2 * LevelData.BORDER_CELLS
	level.tiles.resize(level.width * level.height)
	level.tiles.fill(tile)
	level.infos.resize(level.width * level.height)
	return level


## Fills playable row [param row] with [param tile], the border included, so
## that the ground goes on where Keen walks out of sight.
static func _fill_row(level: LevelData, row: int, tile: int) -> void:
	for x in level.width:
		level.set_tile(Vector2i(x, row + LevelData.BORDER_CELLS), tile)


## Puts the block [param tiles] with its top left at playable cell [param at].
## (Rows of plain arrays: Godot does not keep constant rows of a typed array.)
static func _put(level: LevelData, at: Vector2i, tiles: Array) -> void:
	for y in tiles.size():
		for x in tiles[y].size():
			var tile: int = tiles[y][x]
			if tile != KEEP:
				_set_cell(level, at + Vector2i(x, y), tile)


static func _set_cell(level: LevelData, cell: Vector2i, tile: int) -> void:
	level.set_tile(cell + Vector2i.ONE * LevelData.BORDER_CELLS, tile)


static func _mark(level: LevelData, cell: Vector2i, info: int) -> void:
	var at := cell + Vector2i.ONE * LevelData.BORDER_CELLS
	level.infos[at.y * level.width + at.x] = info
