class_name GalaxyTileKinds
extends RefCounted
## What a foreground tile is, by the low 7 bits of its TILEINFO misc value
## ([method GalaxyTileInfo.misc_kind]; Omni MISCFLAG_*, docs/keen4/research.md
## §4), and the special values of its sides.

const NOTHING := 0
const POLE := 1
const DOOR := 2
const DEADLY := 3
const DROP := 4
const PLATFORM_SWITCH_ON := 5
const PLATFORM_SWITCH_OFF := 6
## Gem holders of the four colours: 7, 8, 9, 10.
const FIRST_GEM_HOLDER := 7
const LAST_GEM_HOLDER := 10
const BRIDGE_SWITCH := 15
## Where Keen shows the moon instead of being bored (Keen 4).
const MOON := 16
## Items lying as tiles: 21-26 points, 27 an extra life, 28 a stunner. Item
## number = misc − this ([GalaxyItems]).
const FIRST_ITEM_TILE := 21
const LAST_ITEM_TILE := 28
const ITEM_TILE_OFFSET := 17
## A floor side of 8-15 is deadly (its slope is the value & 7).
const DEADLY_FLOOR_MASK := ~7
const DEADLY_FLOOR := 8
## A top or bottom side that shots and climbing Keen pass: a pole hole.
const POLE_HOLE := 17
## The foreground tile that is nothing.
const EMPTY_TILE := 0


static func is_gem_holder(kind: int) -> bool:
	return kind >= FIRST_GEM_HOLDER and kind <= LAST_GEM_HOLDER


static func is_item(kind: int) -> bool:
	return kind >= FIRST_ITEM_TILE and kind <= LAST_ITEM_TILE


static func is_switch(kind: int) -> bool:
	return kind in [PLATFORM_SWITCH_ON, PLATFORM_SWITCH_OFF, BRIDGE_SWITCH]


## Whether a floor side [param top] kills what stands on it.
static func is_deadly_floor(top: int) -> bool:
	return top & DEADLY_FLOOR_MASK == DEADLY_FLOOR
