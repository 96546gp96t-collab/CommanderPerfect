class_name Keen4Council
extends GalaxyCreature
## A member of the High Council of Keen 4 (info 4; Omni `ck4_obj1.c`,
## CK4_SpawnCouncilMember and CK4_CouncilWalk, `ck_keen.c`, `ck4_misc.c`,
## facts and numbers only; docs/keen4/research.md §7, §9):
##   - he shuffles 64 units every 10 tics, turning at walls and ledges; at
##     every step he stops to think with a chance of (tics × 8) in 256: he
##     stands 120 tics, then steps 128 on;
##   - Keen touching him while standing on something (not on a pole or
##     ledge) rescues him: the level is done ([code]&"council"[/code]); the
##     view shows the messages and counts him ([Keen4Messages],
##     [Keen4Progress]);
##   - in level 14 he is the **janitor**: touching him shows the janitor's
##     five boxes, then he is gone; he does not count and the level goes on;
##   - under water (level 17) the swimming Keen rescues him by touching him
##     ([Keen4SwimmingKeen]).

## (Omni CK4_ACT_CouncilWalk0-1, CK4_ACT_CouncilPause.)
const ROWS: PackedStringArray = [
	"walk_1 MEMBER_SHUFFLE_L_1 MEMBER_SHUFFLE_R_1 step -s 10 64 0 walk - walk walk_2",
	"walk_2 MEMBER_SHUFFLE_L_2 MEMBER_SHUFFLE_R_2 step -s 10 64 0 walk - walk walk_1",
	"pause MEMBER_THINK_L MEMBER_THINK_R step -- 120 128 0 - - - walk_1",
]
## He stands this far above the info tile's corner (Omni).
const RISE := 369
const PRIORITY := 0
## He stops to think when (tics << this) is more than a random number
## (Omni).
const PAUSE_SHIFT := 3
## The janitor's level (Omni CK4_JanitorLevel).
const JANITOR_LEVEL := 14
const RESCUED := &"council"
const JANITOR := &"janitor"

## Touched once: nothing more happens until the view has shown it.
var _met := false


## A council member at [param cell] (info 4).
static func spawn(
	world: GalaxyWorld, cell: Vector2i, sprites: Dictionary[StringName, int]
) -> Keen4Council:
	var member := Keen4Council.new()
	member.priority = PRIORITY
	member.direction = Vector2i(random_side(world), 1)
	var at := Vector2i(GalaxyUnits.from_tile(cell.x), GalaxyUnits.from_tile(cell.y) - RISE)
	member.enter(world, at, ROWS, sprites, &"walk_1")
	return member


## Whether this one is the janitor.
func is_janitor() -> bool:
	return world.map_number == JANITOR_LEVEL


## Keen touches him walking, jumping or standing: standing on something,
## he rescues him (or meets the janitor) (Omni CK_KeenColFunc).
func touched_by_player(player: GalaxyObject, holding: bool) -> void:
	if holding or player.top_hit == 0:
		return
	rescue()


## He is rescued: the level is done, or the janitor talks and is gone.
func rescue() -> void:
	if _met:
		return
	_met = true
	if is_janitor():
		world.ask(JANITOR)
		world.remove(self)
	else:
		world.complete(RESCUED)


## Think at every step: now and then he stops to think (Omni
## CK4_CouncilWalk).
func _think_walk() -> void:
	if (world.tics << PAUSE_SHIFT) > world.random():
		_continue_as(&"pause")
