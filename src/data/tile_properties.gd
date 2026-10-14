class_name TileProperties
extends RefCounted
## How every tile behaves: which sides are solid, whether it kills, whether
## it is drawn in front of Keen, and how it is animated.
##
## Keen 1 keeps this table in KEEN1.EXE: six arrays of one 16-bit word per
## tile, one after another (see docs/file-formats.md):
##   0  animation   number of frames (1 = not animated)
##   1  behavior    see [enum Behavior]; signed
##   2  top         solid when landing on it; also the floor type, see [enum Floor]
##   3  right       solid when walking into it from the right
##   4  bottom      solid when bumping into it from below
##   5  left        solid when walking into it from the left
##
## The table is found by its shape, so that every version of the game works
## without knowing where its table is. The positions known from the
## ModdingWiki are tried first.

## Tile behaviors. 23 (switch) and 24 (teleporter) are not used yet; they
## follow in milestone 5.
enum Behavior {
	MASKED = -2,  ## drawn in front of Keen through a mask (the next tile)
	FOREGROUND = -1,  ## drawn in front of Keen
	NONE = 0,
	DEADLY = 1,
	DOOR_YELLOW = 2,
	DOOR_RED = 3,
	DOOR_GREEN = 4,
	DOOR_BLUE = 5,
	POINTS_500 = 6,  ## pizza
	POINTS_100 = 7,  ## lollipop
	POINTS_200 = 8,  ## soda
	POINTS_1000 = 9,  ## book
	POINTS_5000 = 10,  ## teddy bear
	SHIP_JOYSTICK = 11,
	SHIP_BATTERY = 12,
	SHIP_VACUUM = 13,
	SHIP_WHISKEY = 14,
	RAYGUN = 15,
	POGO = 16,
	EXIT = 17,
	KEYCARD_YELLOW = 18,
	KEYCARD_RED = 19,
	KEYCARD_GREEN = 20,
	KEYCARD_BLUE = 21,
	HINT = 22,  ## a Yorp or Garg statue that shows a message
}

## The four colors of keycards and doors, in the order of their behaviors.
enum KeyColor { YELLOW, RED, GREEN, BLUE }

## What the top side of a tile is like to stand on.
enum Floor { NONE = 0, SOLID = 1, SLIPPERY = 2, ICE = 3 }

enum Field { ANIMATION, BEHAVIOR, TOP, RIGHT, BOTTOM, LEFT }
const PLANE_COUNT := 6
const BYTES_PER_ENTRY := 2

## Image offsets of the table in known versions (1.1 and 1.31).
const KNOWN_OFFSETS: PackedInt32Array = [0x131F8, 0x130F8]
## Limits used to recognize the table.
const MAX_ANIMATION_FRAMES := 8
const MIN_BEHAVIOR := -2
const MAX_BEHAVIOR := 31

var tile_count := 0
var _planes: Array[PackedInt32Array] = []
## For each tile, the first tile of the animation it belongs to.
var _animation_start := PackedInt32Array()


## Reads the table for [param tile_count] tiles from the program image
## [param image] (see [method DosExecutable.load_image]). Returns null when no
## table is found.
static func find_in_image(image: PackedByteArray, tile_count: int) -> TileProperties:
	var table_size := tile_count * PLANE_COUNT * BYTES_PER_ENTRY
	var candidates := Array(KNOWN_OFFSETS)
	for offset in range(0, image.size() - table_size + 1, BYTES_PER_ENTRY):
		candidates.append(offset)
	for offset: int in candidates:
		if offset + table_size <= image.size() and _looks_like_table(image, offset, tile_count):
			return from_table(image.slice(offset, offset + table_size), tile_count)
	push_error("No tile property table for %d tiles found in the executable." % tile_count)
	return null


## Loads the table from KEEN1.EXE. Returns null when that fails.
static func load_from(files: GameFiles, tile_count: int) -> TileProperties:
	var image := DosExecutable.load_image(files.read(GameFiles.EXECUTABLE))
	if image.is_empty():
		return null
	return find_in_image(image, tile_count)


## Builds the properties from the raw table: [constant PLANE_COUNT] arrays of
## [param tile_count] little-endian words.
static func from_table(table: PackedByteArray, tile_count: int) -> TileProperties:
	var properties := TileProperties.new()
	properties.tile_count = tile_count
	for plane in PLANE_COUNT:
		var values := PackedInt32Array()
		values.resize(tile_count)
		for tile in tile_count:
			values[tile] = table.decode_s16((plane * tile_count + tile) * BYTES_PER_ENTRY)
		properties._planes.append(values)
	properties._find_animation_starts()
	return properties


func behavior(tile: int) -> int:
	return _value(Field.BEHAVIOR, tile)


func is_deadly(tile: int) -> bool:
	return behavior(tile) == Behavior.DEADLY


func is_door(tile: int) -> bool:
	return behavior(tile) >= Behavior.DOOR_YELLOW and behavior(tile) <= Behavior.DOOR_BLUE


## The keycard color that opens door [param tile]. Only for doors.
func door_color(tile: int) -> KeyColor:
	return (behavior(tile) - Behavior.DOOR_YELLOW) as KeyColor


## Whether Keen picks up [param tile] when he touches it: points, ship parts,
## the raygun, the pogo stick and keycards. The exit is not an item.
func is_item(tile: int) -> bool:
	var value := behavior(tile)
	return (
		value >= Behavior.POINTS_500 and value <= Behavior.KEYCARD_BLUE and value != Behavior.EXIT
	)


func is_hint(tile: int) -> bool:
	return behavior(tile) == Behavior.HINT


func is_exit(tile: int) -> bool:
	return behavior(tile) == Behavior.EXIT


func is_foreground(tile: int) -> bool:
	return behavior(tile) == Behavior.FOREGROUND or behavior(tile) == Behavior.MASKED


func floor_type(tile: int) -> Floor:
	return _value(Field.TOP, tile) as Floor


func blocks_top(tile: int) -> bool:
	return _value(Field.TOP, tile) != Floor.NONE


func blocks_right(tile: int) -> bool:
	return _value(Field.RIGHT, tile) != 0


func blocks_bottom(tile: int) -> bool:
	return _value(Field.BOTTOM, tile) != 0


func blocks_left(tile: int) -> bool:
	return _value(Field.LEFT, tile) != 0


func animation_frames(tile: int) -> int:
	return maxi(1, _value(Field.ANIMATION, tile))


func is_animated(tile: int) -> bool:
	return animation_frames(tile) > 1


## The tile shown [param steps] animation steps after [param tile]. An
## animation is a run of consecutive tiles; the level can start it at any of
## them, so neighbouring cells can be out of step.
func animated_tile(tile: int, steps: int) -> int:
	if tile < 0 or tile >= tile_count:
		return tile
	var frames := animation_frames(tile)
	var start := _animation_start[tile]
	return start + posmod(tile - start + steps, frames)


func _value(field: Field, tile: int) -> int:
	if tile < 0 or tile >= tile_count:
		return 0
	return _planes[field][tile]


## Consecutive tiles with the same frame count n form animations of n tiles
## each, starting at the first tile of the run. In Keen 1 the runs are not
## aligned to multiples of n (e.g. 83-86), so the alignment comes from the run.
func _find_animation_starts() -> void:
	_animation_start.resize(tile_count)
	var run_start := 0
	for tile in tile_count:
		var frames := animation_frames(tile)
		if tile == 0 or frames != animation_frames(tile - 1):
			run_start = tile
		_animation_start[tile] = tile - (tile - run_start) % frames


static func _looks_like_table(image: PackedByteArray, offset: int, tile_count: int) -> bool:
	for tile in tile_count:
		var position := offset + tile * BYTES_PER_ENTRY
		var frames := image.decode_s16(position)
		if frames < 1 or frames > MAX_ANIMATION_FRAMES:
			return false
		var tile_behavior := image.decode_s16(position + tile_count * BYTES_PER_ENTRY)
		if tile_behavior < MIN_BEHAVIOR or tile_behavior > MAX_BEHAVIOR:
			return false
		for plane in range(Field.TOP, PLANE_COUNT):
			var side := image.decode_s16(position + plane * tile_count * BYTES_PER_ENTRY)
			if side < 0 or side > Floor.ICE:
				return false
	return true
