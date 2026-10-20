class_name Keen4Lindsey
extends GalaxyCreature
## Princess Lindsey of Keen 4 (info 6; Omni `ck4_obj3.c`, CK4_SpawnLindsey
## and CK4_LindseyFloat, `ck_keen.c`, facts and numbers only;
## docs/keen4/research.md §7, §9): she floats a tile above her info tile,
## bobbing up and down (speeding up 1 on odd tics, at most 8 a tic, turning
## 32 units from her place), four pictures of 20 tics. Keen touching her
## (walking, jumping or standing) shows her message, a hint
## ([Keen4Messages]), and she is gone; the level goes on.

## (Omni CK4_ACT_Lindsey0-3.)
const ROWS: PackedStringArray = [
	"float_1 LINDSEY_1 LINDSEY_1 step+ -- 20 0 0 float - - float_2",
	"float_2 LINDSEY_2 LINDSEY_2 step+ -- 20 0 0 float - - float_3",
	"float_3 LINDSEY_3 LINDSEY_3 step+ -- 20 0 0 float - - float_4",
	"float_4 LINDSEY_4 LINDSEY_4 step+ -- 20 0 0 float - - float_1",
]
## She floats this far above the info tile's corner (Omni).
const RISE := 0x100
const PRIORITY := 0
## Bobbing (Omni): the speed-up, the top speed and how far from her place.
const BOB_ACCEL := 1
const BOB_MAX := 8
const BOB_REACH := 0x20
const MESSAGE := &"lindsey"

## Her place (y, in units).
var home := 0


## Lindsey at [param cell] (info 6).
static func spawn(
	world: GalaxyWorld, cell: Vector2i, sprites: Dictionary[StringName, int]
) -> Keen4Lindsey:
	var lindsey := Keen4Lindsey.new()
	lindsey.priority = PRIORITY
	lindsey.direction = Vector2i(1, 1)
	var at := Vector2i(GalaxyUnits.from_tile(cell.x), GalaxyUnits.from_tile(cell.y) - RISE)
	lindsey.home = at.y
	lindsey.enter(world, at, ROWS, sprites, &"float_1")
	return lindsey


## Keen touches her: her message, and she is gone (Omni CK_KeenColFunc).
func touched_by_player(_player: GalaxyObject, holding: bool) -> void:
	if holding or removed:
		return
	world.ask(MESSAGE)
	world.remove(self)


## Think: bobbing around her place (Omni CK4_LindseyFloat).
func _think_float() -> void:
	bob(self, home, BOB_ACCEL, BOB_MAX, BOB_REACH)


## Moves [param object] up and down around [param place] (y, units): it
## speeds up by [param accel] on odd tics up to [param top] and turns once
## it is more than [param reach] above or below it (Omni CK4_LindseyFloat,
## CK4_SpritePatrol).
static func bob(object: GalaxyObject, place: int, accel: int, top: int, reach: int) -> void:
	GalaxyPhysics.accelerate_y(object, object.direction.y * accel, top)
	if place - object.position.y > reach:
		object.direction.y = 1
	if object.position.y - place > reach:
		object.direction.y = -1
