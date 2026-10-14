class_name MapInfo
extends RefCounted
## What the values in the info layer of the world map mean (see
## docs/file-formats.md and docs/world-map.md):
##   1-16      entrance of that level
##   + 0x8000  the same, and the cell blocks the way until the level is done
##   20        Keen's ship
##   34-46     a teleporter; the value says where it leads
##   255       where Keen starts

const SHIP := 20
const BLOCKING_FLAG := 0x8000
const VALUE_MASK := 0x7FFF
const FIRST_TELEPORTER := 34
const LAST_TELEPORTER := 46


## The level that [param info] is an entrance of, or 0.
static func level_of(info: int) -> int:
	var level := info & VALUE_MASK
	if level >= GameFiles.FIRST_LEVEL and level <= GameFiles.LAST_LEVEL:
		return level
	return 0


## Whether [param info] marks a cell that Keen cannot walk through until its
## level is done.
static func is_blocking(info: int) -> bool:
	return info & BLOCKING_FLAG != 0 and level_of(info) != 0


static func is_teleporter(info: int) -> bool:
	return info >= FIRST_TELEPORTER and info <= LAST_TELEPORTER


static func is_ship(info: int) -> bool:
	return info == SHIP
