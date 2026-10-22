class_name GalaxyMapFlag
extends GalaxyObject
## A flag on a Galaxy world map where a level is done (Omni `ck_map.c`:
## CK_MapFlagSpawn, CK_FlippingFlagSpawn, CK_MapFlagThrown, CK_MapFlagFall,
## CK_MapFlagLand; facts and numbers only; docs/keen4/research.md §8):
##   - a waving flag stands at its holder's tile plus the episode's offset,
##     four pictures of 10 tics, each flag starting at its own point of the
##     wave (a random number / 16 tics), in front of everything;
##   - the flag of the level just finished is thrown: it leaves Keen (a
##     tile up and left of his place), and follows 30 points from there to
##     a little above its holder: straight on sideways (there in 24 of
##     them), up and down in an arc ([method arc]); a point every 2 tics, at
##     most 50 tics; meanwhile it flips (five pictures of 12 tics); then it
##     lands 128 units lower, in its holder, and waves.
## A flag is not clipped and moves by being put on its points (not by a
## step, which the tile collision would limit).
## The episode gives the offsets ([member wave_offset],
## [member throw_offset]); sprites FLAG_WAVE_1-4, FLAG_FLIP_1-4,
## FLAG_FALL_1.

const PRIORITY := 3
## (Omni CK_ACT_MapFlag0-3, MapFlagFlips0-6.)
const ROWS: PackedStringArray = [
	"wave_1 FLAG_WAVE_1 FLAG_WAVE_1 step -- 10 0 0 - - - wave_2",
	"wave_2 FLAG_WAVE_2 FLAG_WAVE_2 step -- 10 0 0 - - - wave_3",
	"wave_3 FLAG_WAVE_3 FLAG_WAVE_3 step -- 10 0 0 - - - wave_4",
	"wave_4 FLAG_WAVE_4 FLAG_WAVE_4 step -- 10 0 0 - - - wave_1",
	"throw FLAG_FLIP_1 FLAG_FLIP_1 think -- 6 0 0 thrown - - flip_1",
	"flip_1 FLAG_FLIP_1 FLAG_FLIP_1 step+ -- 12 0 0 fall - - flip_2",
	"flip_2 FLAG_FLIP_2 FLAG_FLIP_2 step+ -- 12 0 0 fall - - flip_3",
	"flip_3 FLAG_FLIP_3 FLAG_FLIP_3 step+ -- 12 0 0 fall - - flip_4",
	"flip_4 FLAG_FLIP_4 FLAG_FLIP_4 step+ -- 12 0 0 fall - - flip_5",
	"flip_5 FLAG_FALL_1 FLAG_FALL_1 step+ -- 12 0 0 fall - - land",
	"land FLAG_FALL_1 FLAG_FALL_1 step+ p 1 0 0 land - - wave_1",
]
## The points of the throw, and the tics it takes at most (Omni, Keen 4).
const POINTS := 30
const SIDEWAYS_POINTS := 24
const THROW_TICS := 50
const TICS_PER_POINT := 2
## The thrown flag starts a tile up and left of Keen's place.
const THROW_START := Vector2i(-0x100, -0x100)
## It lands this much under the end of the throw.
const LANDING_DROP := 0x80
## The arc (Omni, Keen 4): rising 0x30 a point for 10 points, then
## 16 a point from 0x140, falling 16 a point to 0x1E0, then 0x30 a point.
const ARC_RISE := 0x30
const ARC_TOP_STEP := 16
const ARC_SLOW_FROM := 0x140
const ARC_SLOW_TO := 0x1E0
const ARC_PHASES: PackedInt32Array = [10, 15, 20]
const ARC_LAST := 29
## A flag starts its wave at a random number / this.
const WAVE_START_DIVISOR := 16

## The path of a thrown flag, and where it lands.
var path: Array[Vector2i] = []
var target := Vector2i.ZERO
## Tics of the throw so far (Omni user3).
var throw_tics := 0
var _actions: Dictionary[StringName, GalaxyAction] = {}


## A waving flag for the holder at [param cell], [param offset] units from
## its tile's corner.
static func wave_at(
	world: GalaxyWorld, cell: Vector2i, offset: Vector2i, sprites: Dictionary[StringName, int]
) -> GalaxyMapFlag:
	var flag := GalaxyMapFlag._made(world, sprites)
	flag.position = _corner(cell) + offset
	flag.activity = Activity.ACTIVE
	flag.start(flag._actions[&"wave_1"])
	flag.action_timer = world.random() / WAVE_START_DIVISOR
	return flag


## A flag thrown from Keen's place [param from] (units) to the holder at
## [param cell], ending [param offset] units from its corner.
static func throw_from(
	world: GalaxyWorld,
	from: Vector2i,
	cell: Vector2i,
	offset: Vector2i,
	sprites: Dictionary[StringName, int]
) -> GalaxyMapFlag:
	var flag := GalaxyMapFlag._made(world, sprites)
	flag.position = from + THROW_START
	flag.target = _corner(cell) + offset
	flag.path = arc(flag.position, flag.target)
	flag.activity = Activity.ALWAYS
	flag.start(flag._actions[&"throw"])
	return flag


## The 30 points from [param from] to [param to] (Omni
## CK_FlippingFlagSpawn, Keen 4).
static func arc(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var points: Array[Vector2i] = []
	var delta := to - from
	for index in POINTS:
		var x := from.x + delta.x * mini(index, SIDEWAYS_POINTS) / SIDEWAYS_POINTS
		var y := from.y + delta.y * index / POINTS
		if index < ARC_PHASES[0]:
			y -= index * ARC_RISE
		elif index < ARC_PHASES[1]:
			y -= index * ARC_TOP_STEP + ARC_SLOW_FROM
		elif index < ARC_PHASES[2]:
			y -= (ARC_PHASES[2] - index) * ARC_TOP_STEP + ARC_SLOW_TO
		else:
			y -= (ARC_LAST - index) * ARC_RISE
		points.append(Vector2i(x, y))
	return points


static func _made(world: GalaxyWorld, sprites: Dictionary[StringName, int]) -> GalaxyMapFlag:
	var flag := GalaxyMapFlag.new()
	flag._actions = GalaxyAction.table_from(ROWS, sprites)
	flag.clip = Clip.NONE
	flag.priority = PRIORITY
	world.add(flag)
	return flag


## Whether it still flies.
func is_thrown() -> bool:
	return action != null and not action.name.begins_with("wave")


## Think before the throw: off it goes (Omni CK_MapFlagThrown; the
## original waits until the map has faded in, the view does that).
func _think_thrown() -> void:
	world.play_sound(&"flag_flip", true)
	action = action.next


## Think while flying: to the point of the tics so far (Omni
## CK_MapFlagFall).
func _think_fall() -> void:
	throw_tics = mini(throw_tics + world.tics, THROW_TICS)
	position = path[mini(throw_tics / TICS_PER_POINT, path.size() - 1)]


## Think when it lands: in its holder (Omni CK_MapFlagLand).
func _think_land() -> void:
	position = target + Vector2i(0, LANDING_DROP)
	world.play_sound(&"flag_land")


static func _corner(cell: Vector2i) -> Vector2i:
	return Vector2i(GalaxyUnits.from_tile(cell.x), GalaxyUnits.from_tile(cell.y))
