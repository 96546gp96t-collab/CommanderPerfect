class_name Keen5Fuses
extends RefCounted
## The fuses of Keen 5 (Omni `ck_keen.c` CK_KeenBreakFuse, the fuse checks
## in CK_KeenJumpDrawFunc and CK_KeenPogoDrawFunc; `ck5_misc.c`
## CK5_ScanInfoLayer; facts and numbers only; docs/keen5/research.md §4):
##   - a fuse is a foreground tile whose top is [constant FUSE_TOP] (57):
##     a flat floor (57 & 7 = 1), not deadly;
##   - the level counts its fuses from info 41 while it is scanned (the
##     count Keen carries, [member Keen5Inventory.fuses_remaining]); on map
##     12 info 41 sets the count to 4 and places the QED ([Keen5Qed]);
##   - Keen landing on one from a jump only plays "keen_land_on_fuse"; on
##     the pogo too, unless he comes down at [constant BREAK_SPEED] units a
##     tic or faster: then it breaks ([method break_fuse]) and he falls on
##     through it.
## Breaking it: an explosion one tile left of Keen's middle column at his
## bottom row ([Keen5Flash]), one fuse fewer, and the 1 × 2 foreground
## tiles there become those at the map's (0, 0) and (0, 1) (the fuse's
## rubble in the corner outside the view). With none left a level-end
## object ends the level 60 tics later ([Keen5LevelEnd]).

## (Omni.)
const FUSE_TOP := 0x39
const BREAK_SPEED := 0x30
const COUNTER_INFO := 41
## The rubble's tiles in the map's top left corner (Omni).
const RUBBLE_TOP := Vector2i(0, 0)
const RUBBLE_BOTTOM := Vector2i(0, 1)
## The sounds of the fuses and the teleport lightning ([Keen5Flash]), with
## their numbers in Keen 5's sound table (Omni EPISODE.CK5), for the
## sound milestone (E8).
const SOUNDS: Dictionary[StringName, int] = {
	&"teleport": 41,
	&"fuse_break": 52,
	&"keen_land_on_fuse": 57,
}
## The QED's map, where info 41 means four fuses and the QED (Omni).
const QED_MAP := 12
const QED_FUSES := 4


## Counts info 41 at [param cell] of [param world] into [param carried]
## (the count is set to 0 before the scan); on the QED's map the count is
## 4 and the QED is placed (Omni CK5_ScanInfoLayer).
static func count_info(
	world: GalaxyWorld,
	cell: Vector2i,
	carried: Keen5Inventory,
	sprites: Dictionary[StringName, int]
) -> void:
	if world.map_number == QED_MAP:
		carried.fuses_remaining = QED_FUSES
		Keen5Qed.spawn(world, cell, sprites)
	else:
		carried.fuses_remaining += 1


## Keen of [param world] carrying [param carried] breaks the fuse under
## him: [param cell] is his middle column and bottom row, the fuse's upper
## tile; the fuse with its top is the tile below (Omni CK_KeenBreakFuse).
static func break_fuse(
	world: GalaxyWorld,
	cell: Vector2i,
	carried: Keen5Inventory,
	sprites: Dictionary[StringName, int]
) -> void:
	Keen5Flash.fuse_explosion(world, cell, sprites)
	carried.fuses_remaining -= 1
	if carried.fuses_remaining == 0:
		Keen5LevelEnd.spawn(world, sprites)
	var top := world.fore_tile(RUBBLE_TOP.x, RUBBLE_TOP.y)
	var bottom := world.fore_tile(RUBBLE_BOTTOM.x, RUBBLE_BOTTOM.y)
	world.set_fore_tile(cell, top)
	world.set_fore_tile(cell + Vector2i.DOWN, bottom)
