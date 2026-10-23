class_name Keen5Flash
extends GalaxyCreature
## Pictures that only show, in front of everything and never clipped (Omni
## `ck5_misc.c` CK5_SpawnFuseExplosion, CK5_SpawnLightning; facts and
## numbers only; docs/keen5/research.md §4):
##   - a fuse's **explosion**: FUSEFLASH1 for 10 tics, 2 for 20, 3 for 10,
##     then gone; one tile left of the tile it is made for, with the sound
##     "fuse_break";
##   - the **teleport lightning** when Keen starts into the door to
##     Korath III: a bolt across, TELEPORTSPARK1 and 2, 6 tics each, at
##     (Keen's left column − half a tile, his bottom row − 5 tiles), and a
##     bolt down over him, TELEPORTZAP1 and 2, at (his left column, his top
##     row − half a tile), with the sound "teleport". The bolts go on until
##     the level ends.

## (Omni CK5_ACT_FuseExplosion0-2, CK5_ACT_LightningH0-1, V0-1.)
const ROWS: PackedStringArray = [
	"fuse_1 FUSEFLASH1 FUSEFLASH1 step -- 10 0 0 - - - fuse_2",
	"fuse_2 FUSEFLASH2 FUSEFLASH2 step -- 20 0 0 - - - fuse_3",
	"fuse_3 FUSEFLASH3 FUSEFLASH3 step -- 10 0 0 - - - -",
	"across_1 TELEPORTSPARK1 TELEPORTSPARK1 step -- 6 0 0 - - - across_2",
	"across_2 TELEPORTSPARK2 TELEPORTSPARK2 step -- 6 0 0 - - - across_1",
	"down_1 TELEPORTZAP1 TELEPORTZAP1 step -- 6 0 0 - - - down_2",
	"down_2 TELEPORTZAP2 TELEPORTZAP2 step -- 6 0 0 - - - down_1",
]
## In front of everything (Omni zLayer 3).
const PRIORITY := 3
## Where the bolts go, from Keen's tiles, in units (Omni).
const ACROSS_FROM_KEEN := Vector2i(-0x80, -0x500)
const DOWN_FROM_KEEN := Vector2i(0, -0x80)


## The explosion of the fuse at [param cell] (map cells), one tile left
## of it, with its sound.
static func fuse_explosion(
	world: GalaxyWorld, cell: Vector2i, sprites: Dictionary[StringName, int]
) -> Keen5Flash:
	var at := Vector2i(GalaxyUnits.from_tile(cell.x - 1), GalaxyUnits.from_tile(cell.y))
	var flash := _show(world, at, sprites, &"fuse_1")
	world.play_sound(&"fuse_break")
	return flash


## The two bolts of the teleport lightning round [param keen], with its
## sound; returns them.
static func lightning(
	world: GalaxyWorld, keen: GalaxyObject, sprites: Dictionary[StringName, int]
) -> Array[Keen5Flash]:
	var box := keen.box
	var across := Vector2i(
		GalaxyUnits.from_tile(box.tile_left), GalaxyUnits.from_tile(box.tile_bottom)
	)
	var down := Vector2i(GalaxyUnits.from_tile(box.tile_left), GalaxyUnits.from_tile(box.tile_top))
	var bolts: Array[Keen5Flash] = [
		_show(world, across + ACROSS_FROM_KEEN, sprites, &"across_1"),
		_show(world, down + DOWN_FROM_KEEN, sprites, &"down_1"),
	]
	world.play_sound(&"teleport")
	return bolts


static func _show(
	world: GalaxyWorld, at: Vector2i, sprites: Dictionary[StringName, int], first: StringName
) -> Keen5Flash:
	var flash := Keen5Flash.new()
	flash.priority = PRIORITY
	flash.clip = Clip.NONE
	flash.direction = Vector2i.ZERO
	flash.enter(world, at, ROWS, sprites, first)
	return flash
