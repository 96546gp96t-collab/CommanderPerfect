extends RefCounted
## Small hand-made tiles, tile properties and levels for the Keen 2 tests,
## so that they run without Keen 2's files (see tests/fixtures.gd for Keen
## 1's). The table is long enough for an item from tile 305 on, which leaves
## a different background behind. Also: a session with Keen at a cell and
## where things stand in it (the enemy tests), and copying the Keen 1 files
## under Keen 2's names, the stand-in data for the tests that need real
## files.

const TILE_COUNT := 320

const AIR := 0
const WALL := 1
const FIRE := 2
const RED_DOOR := 3
const YELLOW_CARD := 4
const RED_CARD := 5
const GREEN_CARD := 6
const BLUE_CARD := 7
const PIZZA := 8
const LOLLIPOP := 9
const SODA := 10
const BOOK := 11
const BEAR := 12
const RAYGUN := 13
const EXIT := 14
const JOYSTICK := 15
const ELDER := 16
const TELEPORTER := 17
const LIGHT_SWITCH := 18
## A floor that is only solid on top: Keen can jump up through it.
const LEDGE := 19
## An item from [constant LevelSession.HIGH_TILES_START] on.
const HIGH_LOLLIPOP := 310

## An empty field of 30 x 15 cells with a floor in the bottom row.
const FIELD: PackedStringArray = [
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"##############################",
]

## Level characters and the tiles they stand for.
const LEGEND := {
	".": AIR,
	"#": WALL,
	"X": FIRE,
	"D": RED_DOOR,
	"y": YELLOW_CARD,
	"k": RED_CARD,
	"n": GREEN_CARD,
	"b": BLUE_CARD,
	"5": PIZZA,
	"1": LOLLIPOP,
	"2": SODA,
	"K": BOOK,
	"B": BEAR,
	"g": RAYGUN,
	"E": EXIT,
	"J": JOYSTICK,
	"V": ELDER,
	"T": TELEPORTER,
	"L": LIGHT_SWITCH,
	"H": HIGH_LOLLIPOP,
	"=": LEDGE,
}
const BEHAVIORS: Dictionary[int, TileProperties.Behavior] = {
	FIRE: TileProperties.Behavior.DEADLY,
	RED_DOOR: TileProperties.Behavior.DOOR_RED,
	YELLOW_CARD: TileProperties.Behavior.KEYCARD_YELLOW,
	RED_CARD: TileProperties.Behavior.KEYCARD_RED,
	GREEN_CARD: TileProperties.Behavior.KEYCARD_GREEN,
	BLUE_CARD: TileProperties.Behavior.KEYCARD_BLUE,
	PIZZA: TileProperties.Behavior.POINTS_500,
	LOLLIPOP: TileProperties.Behavior.POINTS_100,
	SODA: TileProperties.Behavior.POINTS_200,
	BOOK: TileProperties.Behavior.POINTS_1000,
	BEAR: TileProperties.Behavior.POINTS_5000,
	RAYGUN: TileProperties.Behavior.RAYGUN,
	EXIT: TileProperties.Behavior.EXIT,
	JOYSTICK: TileProperties.Behavior.SHIP_JOYSTICK,
	ELDER: TileProperties.Behavior.HINT,
	TELEPORTER: TileProperties.Behavior.TELEPORTER,
	LIGHT_SWITCH: TileProperties.Behavior.SWITCH,
	HIGH_LOLLIPOP: TileProperties.Behavior.POINTS_100,
}


## The tile property table as it would be stored in KEEN2.EXE.
static func create_properties() -> TileProperties:
	var planes: Array[PackedInt32Array] = []
	for plane in TileProperties.PLANE_COUNT:
		planes.append(_filled(1 if plane == TileProperties.Field.ANIMATION else 0))
	for side in range(TileProperties.Field.TOP, TileProperties.PLANE_COUNT):
		planes[side][WALL] = 1
	planes[TileProperties.Field.TOP][RED_DOOR] = 1
	planes[TileProperties.Field.TOP][LEDGE] = 1
	planes[TileProperties.Field.BOTTOM][RED_DOOR] = 1
	for tile in BEHAVIORS:
		planes[TileProperties.Field.BEHAVIOR][tile] = BEHAVIORS[tile]
	var table := PackedByteArray()
	for plane in planes:
		for value in plane:
			var bytes := PackedByteArray([0, 0])
			bytes.encode_s16(0, value)
			table.append_array(bytes)
	return TileProperties.from_table(table, TILE_COUNT)


## A level from rows of [constant LEGEND] characters, surrounded by the
## usual border of [constant LevelData.BORDER_CELLS] cells. [param infos]
## puts values into the info layer, at cells counted without the border.
static func create_level(
	rows: PackedStringArray, infos: Dictionary[Vector2i, int] = {}
) -> LevelData:
	var border := LevelData.BORDER_CELLS
	var level := LevelData.new()
	level.width = rows[0].length() + border * 2
	level.height = rows.size() + border * 2
	level.tiles.resize(level.width * level.height)
	level.infos.resize(level.width * level.height)
	for y in rows.size():
		for x in rows[y].length():
			level.tiles[(y + border) * level.width + x + border] = LEGEND[rows[y][x]]
	for cell in infos:
		level.infos[(cell.y + border) * level.width + cell.x + border] = infos[cell]
	return level


## A Keen 2 session in [param rows] with Keen's sprite at the top left of
## [param keen_cell] (counted without the border), before its first tick.
static func begin_session(
	rows: PackedStringArray, keen_cell: Vector2i, infos: Dictionary[Vector2i, int] = {}
) -> Keen2LevelSession:
	return Keen2LevelSession.begin(
		create_level(rows, infos),
		create_properties(),
		Keen2Inventory.new(),
		cell_top_left(keen_cell)
	)


## The top left of [param cell] (counted without the border), in level
## pixels.
static func cell_top_left(cell: Vector2i) -> Vector2:
	return Vector2(column_left(cell.x), row_top(cell.y))


static func column_left(column: int) -> float:
	return (column + LevelData.BORDER_CELLS) * EgaGraphics.TILE_SIZE


static func row_top(row: int) -> float:
	return (row + LevelData.BORDER_CELLS) * EgaGraphics.TILE_SIZE


## Where a sprite with collision box [param box] goes so that the box
## stands on the floor in [param floor_row], at the left of [param column].
static func on_floor(box: Rect2, column: int, floor_row: int) -> Vector2:
	return Vector2(column_left(column), row_top(floor_row) - box.end.y)


## Copies every file of [param from] into [param to] under its Keen 2 name:
## KEEN1.EXE becomes KEEN2.EXE, *.CK1 becomes *.CK2.
static func copy_as_keen_2(from: String, to: String) -> void:
	DirAccess.make_dir_recursive_absolute(to)
	for file_name in DirAccess.get_files_at(from):
		var upper := file_name.to_upper()
		var renamed := upper.replace(GameFiles.EXECUTABLE, Keen2Files.EXECUTABLE)
		renamed = renamed.trim_suffix(".CK1") + (".CK2" if upper.ends_with(".CK1") else "")
		DirAccess.copy_absolute(from.path_join(file_name), to.path_join(renamed))


## Removes the folder [param path] with everything in it.
static func remove_folder(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for sub in directory.get_directories():
		remove_folder(path.path_join(sub))
	for file_name in directory.get_files():
		directory.remove(file_name)
	DirAccess.remove_absolute(path)


static func _filled(value: int) -> PackedInt32Array:
	var values := PackedInt32Array()
	values.resize(TILE_COUNT)
	values.fill(value)
	return values
