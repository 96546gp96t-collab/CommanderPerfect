class_name Keen4Inchworm
extends GalaxyCreature
## The inchworms of Keen 4 and the Foot they make (Omni `ck4_obj2.c`,
## `ck_keen.c`, facts and numbers only; docs/keen4/research.md §7):
##   - an inchworm creeps towards Keen, 128 units every 30 tics, turning at
##     walls and ledges; the worms start out of step (a random part of 30
##     tics). They do nothing to Keen and the stunner does nothing to them;
##   - when one worm touches 11 others in the same frame, it becomes the
##     Foot (5 tiles higher, with four puffs of smoke around it) and all
##     other worms are gone;
##   - the Foot (also placed by info 10) stands still; when Keen walks into
##     it, it carries him off: the level ends (the flight over the world map
##     is D7's; for now the level is done, [member GalaxyWorld.ending]
##     [code]&"foot"[/code]).

## (Omni CK4_ACT_Inchworm*, CK4_ACT_Foot*, CK4_ACT_FootPoof*.)
const ROWS: PackedStringArray = [
	"creep_1 INCHWORM_L_1 INCHWORM_R_1 step -s 30 128 0 creep worm walk creep_2",
	"creep_2 INCHWORM_L_2 INCHWORM_R_2 step -s 30 128 0 creep worm walk creep_1",
	"foot FOOT FOOT think -- 30000 0 0 - - - -",
	"puff_1 PUFF_1 PUFF_1 step -- 12 0 0 - - - puff_2",
	"puff_2 PUFF_2 PUFF_2 step -- 12 0 0 - - - puff_3",
	"puff_3 PUFF_3 PUFF_3 step -- 12 0 0 - - - puff_4",
	"puff_4 PUFF_4 PUFF_4 step -- 12 0 0 - - - -",
]
const WORM_PRIORITY := 2
const FOOT_PRIORITY := 0
const PUFF_PRIORITY := 3
## The worms start a random / 32 tics into their first step (Omni).
const START_DIVISOR := 32
## Touching this many other worms in one frame makes the Foot (Omni).
const WORMS_FOR_FOOT := 11
## The Foot stands this much higher than the worm that became it; one
## placed by the info plane 3 tiles above its tile (Omni).
const FOOT_RISE := 0x500
const FOOT_RISE_TILES := 3
## The four puffs around the new Foot (Omni).
const PUFFS: Array[Vector2i] = [
	Vector2i(-0x80, 0x100), Vector2i(0x100, 0x180), Vector2i(0x280, 0x100), Vector2i(0, -0x80)
]
## The level's ending when the Foot carries Keen off.
const FOOT_ENDING := &"foot"
const CREEP := "creep"

## It is the Foot.
var is_foot := false
## The other worms it touched in the frame ending on tic [member _counted]
## (Omni user1, user2).
var _touching := 0
var _counted := -1


## An inchworm at [param cell] (info 11).
static func spawn(
	world: GalaxyWorld, cell: Vector2i, sprites: Dictionary[StringName, int]
) -> Keen4Inchworm:
	var worm := Keen4Inchworm.new()
	worm.priority = WORM_PRIORITY
	worm.direction = Vector2i(random_side(world), 1)
	var at := Vector2i(GalaxyUnits.from_tile(cell.x), GalaxyUnits.from_tile(cell.y))
	worm.enter(world, at, ROWS, sprites, &"creep_1")
	worm.action_timer = world.random() / START_DIVISOR
	return worm


## The Foot at [param cell] (info 10).
static func spawn_foot(
	world: GalaxyWorld, cell: Vector2i, sprites: Dictionary[StringName, int]
) -> Keen4Inchworm:
	var foot := Keen4Inchworm.new()
	foot.is_foot = true
	foot.priority = FOOT_PRIORITY
	var tile_y := GalaxyUnits.from_tile(cell.y - FOOT_RISE_TILES)
	foot.enter(world, Vector2i(GalaxyUnits.from_tile(cell.x), tile_y), ROWS, sprites, &"foot")
	return foot


## Keen walks into the Foot: it carries him off (Omni CK_KeenColFunc,
## LS_Foot).
func touched_by_player(_player: GalaxyObject, holding: bool) -> void:
	if is_foot and not holding:
		world.ending = FOOT_ENDING
		world.state = GalaxyWorld.LevelState.COMPLETED


## Whether it is a worm (not the Foot or a puff).
func is_worm() -> bool:
	return not is_foot and not removed and action.name.begins_with(CREEP)


## Think: towards Keen (Omni CK4_InchwormMove).
func _think_creep() -> void:
	direction.x = -1 if position.x > nearest_player().position.x else 1


## Contact: worms count the worms they touch (Omni CK4_InchwormCol).
func _contact_worm(other: GalaxyObject) -> void:
	var worm := other as Keen4Inchworm
	if worm == null or not worm.is_worm() or not is_worm():
		return
	if _counted != world.tic:
		_counted = world.tic
		_touching = 0
	_touching += 1
	if _touching == WORMS_FOR_FOOT:
		_become_foot()


func _become_foot() -> void:
	world.play_sound(&"foot_appear")
	position.y -= FOOT_RISE
	is_foot = true
	_become(&"foot")
	for offset in PUFFS:
		var puff := Keen4Inchworm.new()
		puff.priority = PUFF_PRIORITY
		puff.direction = Vector2i.ZERO
		puff.enter(world, position + offset, ROWS, sprites, &"puff_1")
	for object in world.objects:
		var worm := object as Keen4Inchworm
		if worm != null and worm != self and worm.is_worm():
			world.remove(worm)
