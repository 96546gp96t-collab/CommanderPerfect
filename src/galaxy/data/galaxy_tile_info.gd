class_name GalaxyTileInfo
extends RefCounted
## What every 16×16 tile does (TILEINFO): one table after another, each as
## long as its tile set. For the background tiles: the animation time and
## the animation offset; for the foreground tiles: the top, right, bottom
## and left sides, the animation offset, the special meaning ("misc") and
## the animation time. The order was checked against Keen 4 v1.0 (an
## animation offset always leads to another animated tile). See
## docs/keen4/file-formats.md, "TILEINFO".

enum Back { ANIMATION_TIME, ANIMATION_OFFSET }
enum Fore { TOP, RIGHT, BOTTOM, LEFT, ANIMATION_OFFSET, MISC, ANIMATION_TIME }

const BACK_TABLES := 2
const FORE_TABLES := 7
## Misc bit: the tile is drawn in front of the sprites.
const IN_FRONT := 0x80
## The low bits of misc: what the tile is (a pole, a door, ...).
const MISC_KIND := 0x7F
const BYTE_RANGE := 256
const HALF_BYTE_RANGE := 128

var back_count := 0
var fore_count := 0
var _data := PackedByteArray()


## The tile information for [param back_tiles] background and
## [param fore_tiles] foreground tiles at the start of [param data]; null
## when [param data] is too short.
static func parse(data: PackedByteArray, back_tiles: int, fore_tiles: int) -> GalaxyTileInfo:
	var size := BACK_TABLES * back_tiles + FORE_TABLES * fore_tiles
	if back_tiles < 0 or fore_tiles < 0 or data.size() < size:
		push_error("The tile information is %d bytes, %d are needed." % [data.size(), size])
		return null
	var info := GalaxyTileInfo.new()
	info.back_count = back_tiles
	info.fore_count = fore_tiles
	info._data = data.slice(0, size)
	return info


## Table [param table] of background tile [param tile] (0 outside the set).
func back(table: Back, tile: int) -> int:
	if tile < 0 or tile >= back_count:
		return 0
	return _data[table * back_count + tile]


## Table [param table] of foreground tile [param tile] (0 outside the set).
func fore(table: Fore, tile: int) -> int:
	if tile < 0 or tile >= fore_count:
		return 0
	return _data[BACK_TABLES * back_count + table * fore_count + tile]


## The tile that background tile [param tile] turns into after its
## animation time; [param tile] itself when it does not move.
func next_back_tile(tile: int) -> int:
	return tile + _signed(back(Back.ANIMATION_OFFSET, tile))


## The tile that foreground tile [param tile] turns into.
func next_fore_tile(tile: int) -> int:
	return tile + _signed(fore(Fore.ANIMATION_OFFSET, tile))


## Whether foreground tile [param tile] is drawn in front of the sprites.
func is_in_front(tile: int) -> bool:
	return fore(Fore.MISC, tile) & IN_FRONT != 0


## The meaning of foreground tile [param tile] without the in-front bit.
func misc_kind(tile: int) -> int:
	return fore(Fore.MISC, tile) & MISC_KIND


static func _signed(byte: int) -> int:
	return byte - BYTE_RANGE if byte >= HALF_BYTE_RANGE else byte
