class_name Keen4Arachnut
extends GalaxyCreature
## The Arachnut of Keen 4 (Omni `ck4_obj1.c`, facts and numbers only;
## docs/keen4/research.md §7): it runs 128 units every 6 tics, turning at
## walls and ledges, and turns to Keen every fourth step. Touching it kills
## Keen, also on a pole (its own contact does that). A shot stuns it for 240
## tics (no stars), then it blinks for 80 tics and runs again; a shot meanwhile
## stuns it again.

## (Omni CK4_ACT_Arachnut*.)
const ROWS: PackedStringArray = [
	"run_1 ARACHNUT_1 ARACHNUT_4 step -s 6 128 0 - arachnut walk run_2",
	"run_2 ARACHNUT_2 ARACHNUT_3 step -s 6 128 0 - arachnut walk run_3",
	"run_3 ARACHNUT_3 ARACHNUT_2 step -s 6 128 0 - arachnut walk run_4",
	"run_4 ARACHNUT_4 ARACHNUT_1 step -s 6 128 0 search arachnut walk run_1",
	"stunned ARACHNUT_STUN ARACHNUT_STUN step -s 240 0 0 - stunned - recover_1",
	"recover_1 ARACHNUT_1 ARACHNUT_1 step -s 20 0 0 - stunned - recover_2",
	"recover_2 ARACHNUT_STUN ARACHNUT_STUN step -s 20 0 0 - stunned - recover_3",
	"recover_3 ARACHNUT_1 ARACHNUT_1 step -s 20 0 0 - stunned - recover_4",
	"recover_4 ARACHNUT_STUN ARACHNUT_STUN step -s 20 0 0 - stunned - run_1",
]
const RISE := 0x171
const PRIORITY := 0


## An Arachnut at [param cell] (info 20, 73, 74).
static func spawn(
	world: GalaxyWorld, cell: Vector2i, sprites: Dictionary[StringName, int]
) -> Keen4Arachnut:
	var arachnut := Keen4Arachnut.new()
	arachnut.priority = PRIORITY
	arachnut.direction = Vector2i(random_side(world), 1)
	var at := Vector2i(GalaxyUnits.from_tile(cell.x), GalaxyUnits.from_tile(cell.y) - RISE)
	arachnut.enter(world, at, ROWS, sprites, &"run_1")
	return arachnut


## Think: it turns to Keen (Omni CK4_ArachnutSearch).
func _think_search() -> void:
	direction.x = side_of_player()


## Contact: a shot stuns it; Keen dies (Omni CK4_ArachnutCol).
func _contact_arachnut(other: GalaxyObject) -> void:
	if live_shot(other) != null:
		_contact_stunned(other)
	elif is_player(other):
		kill_player()


## Contact while stunned: a shot stuns it again (Omni
## CK4_ArachnutStunnedCol).
func _contact_stunned(other: GalaxyObject) -> void:
	var shot := live_shot(other)
	if shot != null:
		stun(shot, &"stunned")
