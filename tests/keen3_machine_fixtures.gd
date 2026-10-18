extends RefCounted
## A hand-made Mangling Machine for the tests of milestone C7
## (tests/test_keen3_machine.gd), without Keen 3's files: a level of 25x24
## cells with the border of 2 cells and the machine's parts at the places
## docs/keen3/research.md §6 gives for level 16 (the arms at (6,10) and
## (18,16), the legs at (11,18) and (13,18), six sparks, the heart at (12,8)
## with tile 611 two cells left and right of the body), and a tile table
## with the machine's tiles as research §4 describes them. Everything else
## is empty background (169); Keen starts at (3,17) on the floor.

const TILE_COUNT := 624
const BORDER := 245
const EMPTY := Keen3Machine.EMPTY_TILE
const WALL := 471
const FLOOR := Keen3MachineLeg.FLOOR_TILE
const BODY := 420
const SHAFT := Keen3Machine.SHAFT_TILE
const BLOCK := 611
const CLAWS := Keen3MachineArm.CLAW_TILES
const FOOT := Keen3MachineLeg.FOOT_TILES
const SIZE := Vector2i(25, 24)
const PLAYABLE := Rect2i(2, 2, 21, 20)
const FLOOR_ROW := 19
const KEEN_CELL := Vector2i(3, 17)
const LEFT_ARM := Vector2i(6, 10)
const RIGHT_ARM := Vector2i(18, 16)
const LEFT_LEG := Vector2i(11, 18)
const RIGHT_LEG := Vector2i(13, 18)
const HEART := Vector2i(12, 8)
const SPARKS: Array[Vector2i] = [
	Vector2i(11, 4),
	Vector2i(13, 4),
	Vector2i(9, 6),
	Vector2i(15, 6),
	Vector2i(9, 13),
	Vector2i(15, 13)
]
const BLOCKS: Array[Vector2i] = [Vector2i(7, 8), Vector2i(17, 8)]
## The top of the body, under which the legs hang, and the tile above each
## arm (no shaft: the arm turns down there).
const BODY_ROW := 14
const BODY_TOP_ROW := 3
const ARM_TOP_TILE := 619
## Deadly tiles of the machine (behaviour 1, research §4).
const DEADLY_TILES: Array[int] = [597, 618, 619, 620, 621, 622, 623, BODY]


## The tile table: the machine's tiles and the walls solid on every side,
## the machine's deadly tiles deadly.
static func properties() -> TileProperties:
	var planes: Array[PackedInt32Array] = []
	for plane in TileProperties.PLANE_COUNT:
		var values := PackedInt32Array()
		values.resize(TILE_COUNT)
		values.fill(1 if plane == TileProperties.Field.ANIMATION else 0)
		planes.append(values)
	var solid: Array[int] = [WALL, FLOOR, BLOCK, SHAFT, BORDER]
	solid.append_array(Array(CLAWS))
	solid.append_array(Array(FOOT))
	for tile in solid:
		for side in range(TileProperties.Field.TOP, TileProperties.PLANE_COUNT):
			planes[side][tile] = 1
	for tile in DEADLY_TILES:
		planes[TileProperties.Field.BEHAVIOR][tile] = TileProperties.Behavior.DEADLY
	var table := PackedByteArray()
	for plane in planes:
		for value in plane:
			var bytes := PackedByteArray([0, 0])
			bytes.encode_s16(0, value)
			table.append_array(bytes)
	return TileProperties.from_table(table, TILE_COUNT)


## The level with the machine and its info values.
static func level() -> LevelData:
	var data := LevelData.new()
	data.width = SIZE.x
	data.height = SIZE.y
	data.tiles.resize(SIZE.x * SIZE.y)
	data.tiles.fill(BORDER)
	data.infos.resize(SIZE.x * SIZE.y)
	for y in range(PLAYABLE.position.y, PLAYABLE.end.y):
		for x in range(PLAYABLE.position.x, PLAYABLE.end.x):
			var edge := x == PLAYABLE.position.x or x == PLAYABLE.end.x - 1 or y == 2
			data.set_tile(Vector2i(x, y), WALL if edge or y > FLOOR_ROW else EMPTY)
	for x in range(PLAYABLE.position.x + 1, PLAYABLE.end.x - 1):
		data.set_tile(Vector2i(x, FLOOR_ROW), FLOOR)
	_draw_machine(data)
	_put_infos(data)
	return data


## A session in the machine's level, Keen protected by god mode.
static func session() -> Keen3LevelSession:
	var data := level()
	var start := Vector2(KEEN_CELL * EgaGraphics.TILE_SIZE) + Keen3LevelPlay.START_OFFSET
	var result := Keen3LevelSession.started(data, properties(), Keen3Inventory.new(), start)
	result.set_invincible(true)
	return result


static func _draw_machine(data: LevelData) -> void:
	# The body's frame: its top row, its sides and its bottom row.
	for x in range(8, 17):
		data.set_tile(Vector2i(x, BODY_TOP_ROW), BODY)
		data.set_tile(Vector2i(x, BODY_ROW), BODY)
	for y in range(BODY_TOP_ROW, BODY_ROW):
		data.set_tile(Vector2i(8, y), BODY)
		data.set_tile(Vector2i(16, y), BODY)
	for cell in BLOCKS:
		data.set_tile(cell, BLOCK)
	# Each arm: its shaft from row 10 down to its cell, a claw on each side.
	for arm in [LEFT_ARM, RIGHT_ARM]:
		data.set_tile(Vector2i(arm.x, 9), ARM_TOP_TILE)
		for y in range(10, arm.y + 1):
			data.set_tile(Vector2i(arm.x, y), SHAFT)
		for row in CLAWS.size():
			data.set_tile(arm + Vector2i(-1, row), CLAWS[row])
			data.set_tile(arm + Vector2i(1, row), CLAWS[row])
		# The floor under the claws turns the arm up.
		data.set_tile(Vector2i(arm.x, FLOOR_ROW), WALL)
	# Each leg: its shaft under the body, its foot on the floor.
	for leg in [LEFT_LEG, RIGHT_LEG]:
		for y in range(BODY_ROW + 1, leg.y):
			data.set_tile(Vector2i(leg.x, y), SHAFT)
	for index in FOOT.size():
		data.set_tile(Vector2i(LEFT_LEG.x - 3 + index, LEFT_LEG.y), FOOT[index])
		data.set_tile(Vector2i(RIGHT_LEG.x + index, RIGHT_LEG.y), FOOT[index])


static func _put_infos(data: LevelData) -> void:
	var infos: Dictionary[Vector2i, int] = {
		KEEN_CELL: LevelData.PLAYER_START_INFO,
		HEART: Keen3Machine.INFO_HEART,
		LEFT_ARM: Keen3Machine.INFO_ARM,
		RIGHT_ARM: Keen3Machine.INFO_ARM,
		LEFT_LEG: Keen3Machine.INFO_LEFT_LEG,
		RIGHT_LEG: Keen3Machine.INFO_RIGHT_LEG,
	}
	for spark in SPARKS:
		infos[spark] = Keen3Machine.INFO_SPARK
	for cell in infos:
		data.infos[cell.y * data.width + cell.x] = infos[cell]
