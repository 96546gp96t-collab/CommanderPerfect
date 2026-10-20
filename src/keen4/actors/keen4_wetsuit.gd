class_name Keen4Wetsuit
extends GalaxyCreature
## The wetsuit (scuba gear) in Keen 4's Miragia (info 35; Omni `ck4_obj3.c`,
## CK4_SpawnWetsuit and CK4_WetsuitCol, facts and numbers only;
## docs/keen4/research.md §7): it lies a tile above its info tile. Keen
## touching it while standing on something takes it: his message
## ([Keen4Messages]), Keen has the wetsuit ([Keen4Progress]: he can swim on
## the world map, D7) and the level is done ([code]&"wetsuit"[/code]).

## (Omni CK4_ACT_Wetsuit0.)
const ROWS: PackedStringArray = [
	"lie SCUBA_GEAR SCUBA_GEAR step -- 30000 0 0 - wetsuit - lie",
]
## It lies this far above the info tile's corner (Omni).
const RISE := 0x100
const PRIORITY := 0
const TAKEN := &"wetsuit"


## The wetsuit at [param cell] (info 35).
static func spawn(
	world: GalaxyWorld, cell: Vector2i, sprites: Dictionary[StringName, int]
) -> Keen4Wetsuit:
	var wetsuit := Keen4Wetsuit.new()
	wetsuit.priority = PRIORITY
	var at := Vector2i(GalaxyUnits.from_tile(cell.x), GalaxyUnits.from_tile(cell.y) - RISE)
	wetsuit.enter(world, at, ROWS, sprites, &"lie")
	return wetsuit


## Contact: Keen standing on something takes it (Omni CK4_WetsuitCol).
func _contact_wetsuit(other: GalaxyObject) -> void:
	if is_player(other) and other.top_hit != 0 and world.ending != TAKEN:
		world.complete(TAKEN)
