class_name Keen3MapInfo
extends RefCounted
## What the info values of Keen 3's world map (map 80) mean, beyond Keen
## 1's ([MapInfo]), and the clock the original map runs on (Chocolate Keen
## `game/worldmap.c`, `episodes/episode3.c`; docs/keen3/research.md §8):
##   1-16, 0x8000 + n  the entrance of level n; with 0x8000 the cell blocks
##                     the way until the level is done ([MapInfo])
##   20                the ship: one of four messages
##   0x0Fsd            a teleporter: s is its own slot, d the slot it sends
##                     Keen to
##   0x2000            Messie's path; 0x2100 her weed; 0x2200 a landing
##   255               Keen's start
##
## The original moves Keen and Messie a fixed distance per drawn frame, not
## per clock tick: [constant FRAMES_PER_SECOND] frames a second (one every
## 6 ticks of its 145.65 Hz clock). [method ticks_for_frames] and
## [constant FRAMES_PER_TICK] turn its frames into our 60 ticks a second.

const SHIP := MapInfo.SHIP
const PATH := 0x2000
const WEED := 0x2100
const LANDING := 0x2200
## Teleporters have 0xF in the third nibble.
const TELEPORTER_MASK := 0x0F00
const SLOT_MASK := 0xF
const OWN_SLOT_SHIFT := 4
## The values 0x2000-0x22FF all belong to Messie (path, weed, landings).
const MESSIE_FIRST := 0x2000
const MESSIE_LAST := 0x22FF
## Frames the original draws per second (Choco: 145.65 / 6).
const FRAMES_PER_SECOND := 24.275
const FRAMES_PER_TICK := FRAMES_PER_SECOND / 60.0


static func is_teleporter(info: int) -> bool:
	return info & MapInfo.VALUE_MASK & TELEPORTER_MASK == TELEPORTER_MASK


## The teleporter's own slot (0-15).
static func own_slot(info: int) -> int:
	return (info >> OWN_SLOT_SHIFT) & SLOT_MASK


## The slot (0-15) that the teleporter sends Keen to.
static func destination_slot(info: int) -> int:
	return info & SLOT_MASK


static func is_messie_cell(info: int) -> bool:
	return info >= MESSIE_FIRST and info <= MESSIE_LAST


## Whether Messie swims through a cell with [param info]: her path or weed.
static func is_water_path(info: int) -> bool:
	return info == PATH or info == WEED


## How many of our ticks [param frames] frames of the original take.
static func ticks_for_frames(frames: float) -> float:
	return frames / FRAMES_PER_TICK


## [param pixels] per frame of the original, in pixels per tick.
static func speed_per_tick(pixels: float) -> float:
	return pixels * FRAMES_PER_TICK
