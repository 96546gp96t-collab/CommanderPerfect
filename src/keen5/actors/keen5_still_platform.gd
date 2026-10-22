class_name Keen5StillPlatform
extends GalaxyPlatform
## The platforms of Keen 5 that do not go round by themselves (Omni
## `ck_obj.c` CK_SpawnStandPlatform, CK_SneakPlatSpawn, CK_SneakPlatThink;
## facts and numbers only; docs/keen5/research.md §7). Both are never
## clipped, at their tile's corner; Keen rides them
## ([GalaxyPlatform.touched_by_player]):
##   - the **standing** platform (info 33-35) never moves and sleeps far
##     from the view like a creature; which values are placed is reversed
##     ([Keen5Platforms]);
##   - the **sneak** platform (info 40), always awake, waits until a Keen
##     is in the first picture of a jump (also leaping off a pole) facing
##     it, his front 0-4 tiles from its near side and his position within
##     6 tiles of its own up or down; then it slides away the way he faces,
##     32 units a tic for 48 tics, and back at 16 for 96 tics, and waits
##     again.

## (Omni CK_ACT_StandPlatform, CK_ACT_sneakPlatWait, Sneak, Return.)
const ROWS: PackedStringArray = [
	"stand PLATFORM PLATFORM step -- 32000 0 0 - - - stand",
	"wait PLATFORM PLATFORM think -- 0 0 0 sneak_wait - - -",
	"sneak PLATFORM PLATFORM slide -- 48 32 0 - - - back",
	"back PLATFORM PLATFORM slide -- 96 -16 0 - - - wait",
]
## How far Keen's front may be from its near side, and his position from
## its own up or down, in units (Omni).
const SNEAK_REACH := 0x400
const SNEAK_HEIGHT := 0x600


## A standing platform at [param cell].
static func spawn_standing(
	world: GalaxyWorld, cell: Vector2i, sprites: Dictionary[StringName, int]
) -> Keen5StillPlatform:
	return _spawn(world, cell, Activity.ACTIVE, sprites, &"stand")


## A sneak platform at [param cell].
static func spawn_sneak(
	world: GalaxyWorld, cell: Vector2i, sprites: Dictionary[StringName, int]
) -> Keen5StillPlatform:
	return _spawn(world, cell, Activity.ALWAYS, sprites, &"wait")


static func _spawn(
	world: GalaxyWorld,
	cell: Vector2i,
	awake: Activity,
	sprites: Dictionary[StringName, int],
	first: StringName
) -> Keen5StillPlatform:
	var platform := Keen5StillPlatform.new()
	platform.activity = awake
	platform.priority = 0
	platform.clip = Clip.NONE
	platform.direction = Vector2i(0, 1)
	var at := Vector2i(GalaxyUnits.from_tile(cell.x), GalaxyUnits.from_tile(cell.y))
	platform.enter(world, at, ROWS, sprites, first)
	return platform


## Think while waiting: a Keen starting a jump at it sends it away (Omni
## CK_SneakPlatThink).
func _think_sneak_wait() -> void:
	for player in world.players():
		var keen := player as GalaxyKeenBody
		if keen != null and _jumps_at(keen):
			direction.x = keen.direction.x
			_continue_as(&"sneak")
			return


func _jumps_at(keen: GalaxyKeenBody) -> bool:
	if keen.action != keen.actions.get(&"jump_1"):
		return false
	var gap := box.left - keen.box.right if keen.direction.x == 1 else keen.box.left - box.right
	if gap < 0 or gap > SNEAK_REACH:
		return false
	return absi(keen.position.y - position.y) <= SNEAK_HEIGHT
