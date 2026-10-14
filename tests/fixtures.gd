extends RefCounted
## Small hand-made tiles, tile properties and levels for the tests, so that
## they run without the original game data.

const TILE_COUNT := 16

const AIR := 0
const WALL := 1
const PLATFORM := 2
const ICE := 3
const SLIPPERY := 4
const FIRE := 5
const PILLAR := 6
const DOOR := 7
## Two animations of four frames in one run: tiles 8-11 and 12-15.
const ANIMATION_START := 8
const ANIMATION_FRAMES := 4

## Level characters and the tiles they stand for.
const LEGEND := {
	".": AIR,
	"#": WALL,
	"-": PLATFORM,
	"I": ICE,
	"S": SLIPPERY,
	"X": FIRE,
	"P": PILLAR,
	"D": DOOR,
	"A": ANIMATION_START,
}


## The tile property table as it would be stored in the executable.
static func create_table() -> PackedByteArray:
	var animation := _filled(1)
	var behavior := _filled(TileProperties.Behavior.NONE)
	var top := _filled(0)
	var right := _filled(0)
	var bottom := _filled(0)
	var left := _filled(0)
	for tile in [WALL, ICE, SLIPPERY]:
		right[tile] = 1
		bottom[tile] = 1
		left[tile] = 1
	top[WALL] = TileProperties.Floor.SOLID
	top[PLATFORM] = TileProperties.Floor.SOLID
	top[ICE] = TileProperties.Floor.ICE
	top[SLIPPERY] = TileProperties.Floor.SLIPPERY
	behavior[FIRE] = TileProperties.Behavior.DEADLY
	behavior[PILLAR] = TileProperties.Behavior.FOREGROUND
	behavior[DOOR] = TileProperties.Behavior.DOOR_RED
	top[DOOR] = 1
	bottom[DOOR] = 1
	for tile in range(ANIMATION_START, TILE_COUNT):
		animation[tile] = ANIMATION_FRAMES

	var table := PackedByteArray()
	for plane in [animation, behavior, top, right, bottom, left]:
		for value: int in plane:
			var bytes := PackedByteArray([0, 0])
			bytes.encode_s16(0, value)
			table.append_array(bytes)
	return table


static func create_properties() -> TileProperties:
	return TileProperties.from_table(create_table(), TILE_COUNT)


## A level from rows of [constant LEGEND] characters, surrounded by the
## usual border of [constant LevelData.BORDER_CELLS] cells.
static func create_level(rows: PackedStringArray) -> LevelData:
	var border := LevelData.BORDER_CELLS
	var level := LevelData.new()
	level.width = rows[0].length() + border * 2
	level.height = rows.size() + border * 2
	level.tiles.resize(level.width * level.height)
	level.infos.resize(level.width * level.height)
	for y in rows.size():
		for x in rows[y].length():
			level.tiles[(y + border) * level.width + x + border] = LEGEND[rows[y][x]]
	return level


static func create_collision(rows: PackedStringArray) -> LevelCollision:
	return LevelCollision.create(create_level(rows), create_properties())


## Plain-colored tiles, enough for every tile number above.
static func create_graphics() -> EgaGraphics:
	var graphics := EgaGraphics.new()
	for i in TILE_COUNT:
		var tile := Image.create_empty(
			EgaGraphics.TILE_SIZE, EgaGraphics.TILE_SIZE, false, Image.FORMAT_RGBA8
		)
		tile.fill(EgaPalette.color(i % 16))
		graphics.tiles.append(tile)
	return graphics


static func _filled(value: int) -> PackedInt32Array:
	var values := PackedInt32Array()
	values.resize(TILE_COUNT)
	values.fill(value)
	return values
