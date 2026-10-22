class_name Keen4Egg
extends GalaxyCreature
## The egg of Keen 4's blue bird (Omni `ck4_obj1.c`, facts and numbers
## only; docs/keen4/research.md §7): it lies still until Keen touches it or
## a shot hits it; then it breaks (the broken shell stays), three bits of
## shell fly off and the bird ([Keen4Bird]) hatches, facing Keen.

## (Omni CK4_ACT_Egg0, CK4_ACT_Eggshell*.)
const ROWS: PackedStringArray = [
	"egg EGG EGG think -s 8 0 0 - egg - -",
	"broken EGG_BROKEN EGG_BROKEN step -- 30000 0 0 - - - -",
	"chip_1 EGG_CHIP_1 EGG_CHIP_1 think -- 0 0 0 fall - chip -",
	"chip_2 EGG_CHIP_2 EGG_CHIP_2 think -- 0 0 0 fall - chip -",
	"chip_3 EGG_CHIP_3 EGG_CHIP_3 think -- 0 0 0 fall - chip -",
]
const RISE := 0x71
const PRIORITY := 2
## The bird hatches this far above the egg (Omni).
const BIRD_RISE := 0x80
## The three bits of shell: their action and how they fly off (Omni).
const CHIPS: Array[StringName] = [&"chip_1", &"chip_2", &"chip_3"]
const CHIP_SPEEDS: Array[Vector2i] = [Vector2i(-28, -40), Vector2i(28, -40), Vector2i(0, -56)]

## Broken (or a bit of shell): it touches nothing any more.
var broken := false


## An egg at [param cell] (info 13).
static func spawn(
	world: GalaxyWorld, cell: Vector2i, sprites: Dictionary[StringName, int]
) -> Keen4Egg:
	var egg := Keen4Egg.new()
	egg.priority = PRIORITY
	var at := Vector2i(GalaxyUnits.from_tile(cell.x), GalaxyUnits.from_tile(cell.y) - RISE)
	egg.enter(world, at, ROWS, sprites, &"egg")
	return egg


## Contact: Keen or a shot breaks it and the bird hatches (Omni
## CK4_EggCol).
func _contact_egg(other: GalaxyObject) -> void:
	var shot := live_shot(other)
	if shot == null and not is_player(other):
		return
	if shot != null:
		shot.hit()
	broken = true
	activity = Activity.ON_SCREEN_ONLY
	_become(&"broken")
	Keen4Bird.hatch(world, position + Vector2i(0, -BIRD_RISE), sprites)
	for chip in CHIPS.size():
		var bit := Keen4Egg.new()
		bit.broken = true
		bit.activity = Activity.ON_SCREEN_ONLY
		bit.priority = 0
		bit.direction = Vector2i.ZERO
		bit.velocity = CHIP_SPEEDS[chip]
		bit.enter(world, position, ROWS, sprites, CHIPS[chip])


## React of a bit of shell: it stops on the ground (Omni CK4_EggshellDraw).
func _react_chip() -> void:
	if top_hit != 0:
		velocity = Vector2i.ZERO
