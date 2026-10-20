class_name Keen4MapKeen
extends GalaxyMapKeen
## Keen on Keen 4's world map: the [GalaxyMapKeen] walk, plus the water and
## the Foot (Omni `ck4_map.c`: CK4_MapMiscFlagsCheck, CK4_MapKeenSwim,
## CK4_MapKeenFoot, and CK_SpawnMapKeen's flight; facts and numbers only;
## docs/keen4/research.md §8):
##   - the tile under the middle of his box is water (misc 11-14, the
##     side of the water it lies on): without the wetsuit he asks for the
##     "I can't swim!" box ([constant CANT_SWIM]) and is pushed back by
##     what he moved; with it he swims (16 units a tic, two pictures per
##     direction, 6 tics each), first 18 tics straight on into the water
##     by himself, and on the next water tile he walks out the same way
##     (seen in the original, D7: he walks on at once; Omnispeak stands
##     him first);
##   - the Foot carries him ([method fly_on_foot]): from the west of the
##     map to the Pyramid of the Forbidden in 280 tics, otherwise back in
##     140, in a straight line, in front of everything; then he stands.
## Sprites: MAP_SWIM_<dir>_1 / _2, MAP_FOOT_1 / _2.

## What he asks for in water without the wetsuit.
const CANT_SWIM := &"cant_swim"
## The water tiles: misc 11-14, the north, east, south and west side.
const WATER_NORTH := 11
const WATER_WEST := 14
## The way he swims into the water from each side (Omni
## ck4_wetsuitOffs), and the way out when he swims already
## (ck4_wetsuitOffs2).
const INTO_WATER: PackedInt32Array = [4, 6, 0, 2]
const OUT_OF_WATER: PackedInt32Array = [4, 5, 6, 7, 0, 1, 2, 3]
## Tics he swims on by himself into or out of the water (Omni).
const WATER_TICS := 18
## Every swimming step uses up this many of them (Omni).
const SWIM_STEP_TICS := 6
const SWIM_FRAMES := 2
## (Omni CK4_ACT_MapKeenSwim0, MapKeenFoot0-1.)
const SWIM_ROWS: PackedStringArray = [
	"swim - - slide p 6 16 16 swim - - swim",
	"foot_1 MAP_FOOT_1 MAP_FOOT_1 step+ -- 30 0 0 foot - - foot_2",
	"foot_2 MAP_FOOT_2 MAP_FOOT_2 step+ -- 30 0 0 foot - - foot_1",
]
## The Foot's flight (Omni CK_SpawnMapKeen): from left of x 0x1400 to the
## Pyramid of the Forbidden (0x1E00, 0x3700) in 280 tics; otherwise back
## to (0x1000, 0x2F00) in 140.
const FOOT_WEST_OF := 0x1400
const FOOT_PYRAMID := Vector2i(0x1E00, 0x3700)
const FOOT_PYRAMID_TICS := 280
const FOOT_BACK := Vector2i(0x1000, 0x2F00)
const FOOT_BACK_TICS := 140
const FLYING_PRIORITY := 3

## Whether he has the wetsuit ([Keen4Progress.wetsuit]).
var wetsuit := false
## Tics of the flight left (Omni user1 while flying).
var flight_tics := 0


## Keen 4's map Keen in [param world] at [param at] (units).
static func spawn_keen4(
	world: GalaxyWorld, at: Vector2i, episode_sprites: Dictionary[StringName, int], suit: bool
) -> Keen4MapKeen:
	var keen := Keen4MapKeen.new()
	keen.wetsuit = suit
	keen.place(world, at, episode_sprites)
	return keen


## Where the Foot takes him from [param from] (units), and in how many
## tics.
static func flight_target(from: Vector2i) -> Vector3i:
	if from.x < FOOT_WEST_OF:
		return Vector3i(FOOT_PYRAMID.x, FOOT_PYRAMID.y, FOOT_PYRAMID_TICS)
	return Vector3i(FOOT_BACK.x, FOOT_BACK.y, FOOT_BACK_TICS)


func use_sprites(episode_sprites: Dictionary[StringName, int]) -> void:
	super(episode_sprites)
	actions.merge(GalaxyAction.table_from(SWIM_ROWS, episode_sprites))


## Starts the flight on the Foot from where he is (Omni CK_SpawnMapKeen
## after the Foot): not clipped, in front of everything.
func fly_on_foot() -> void:
	var target := flight_target(position)
	flight_tics = target.z
	velocity = Vector2i(
		(target.x - position.x) / target.z + 1, (target.y - position.y) / target.z + 1
	)
	clip = Clip.NONE
	priority = FLYING_PRIORITY
	direction = Vector2i.ZERO
	_become(&"foot_1")


func is_flying() -> bool:
	return _is_in([&"foot_1", &"foot_2"])


## The sprite of swimming in direction [param way] (0-7), picture
## [param frame] (0 or 1).
func swim_picture(way: int, frame: int) -> int:
	var name := "MAP_SWIM_%s_%d" % [GalaxyMapKeen.DIRECTION_NAMES[way], frame + 1]
	return sprites.get(StringName(name), NO_SPRITE)


## Think while flying: on by his speed; at the end he stands where the
## flight ends (Omni CK4_MapKeenFoot).
func _think_foot() -> void:
	flight_tics -= world.tics
	step = velocity * world.tics
	if flight_tics > 0:
		return
	step -= velocity * -flight_tics
	priority = PRIORITY
	facing = GalaxyMapKeen.WEST
	walk_step = 3
	forced_tics = 0
	direction = Vector2i.ZERO
	_continue_as(&"stand")
	sprite = picture(GalaxyMapKeen.WEST, GalaxyMapKeen.STAND)
	clip = Clip.NORMAL


## Think every 6 tics of swimming: on by himself, or the stick; the next
## picture (Omni CK4_MapKeenSwim). The stick counts again in the think that
## uses up the last tics on his own (seen in the original, D7: he turns
## round in the water after 12 tics, not 18 as Omnispeak's order gives).
func _think_swim() -> void:
	if forced_tics > 0:
		forced_tics = maxi(forced_tics - SWIM_STEP_TICS, 0)
	if forced_tics == 0:
		direction = Vector2i(input.direction, input.vertical)
		var way := held_direction()
		if way != GalaxyMapKeen.NO_DIRECTION:
			facing = way
	sprite = swim_picture(facing, walk_step)
	walk_step = (walk_step + 1) % SWIM_FRAMES


## After the contacts: water under the middle of his box (Omni
## CK4_MapMiscFlagsCheck).
func _touch_tiles() -> void:
	if forced_tics > 0 or is_flying():
		return
	var middle_y := GalaxyUnits.to_tile(box.top + (box.bottom - box.top) / 2)
	var kind := world.misc_of(world.fore_tile(box.tile_middle, middle_y))
	if kind < WATER_NORTH or kind > WATER_WEST:
		return
	if not wetsuit:
		world.ask(CANT_SWIM)
		step = -moved
		direction = Vector2i.ZERO
		world.clip.update_normal(self)
		return
	var swimming := action == actions[&"swim"]
	facing = INTO_WATER[kind - WATER_NORTH]
	if swimming:
		facing = OUT_OF_WATER[facing]
	direction = _direction_of_way(facing)
	walk_step = 0
	forced_tics = WATER_TICS
	_become(&"walk" if swimming else &"swim")


## The stick of direction [param way] (0, 2, 4, 6: north, east, south,
## west).
static func _direction_of_way(way: int) -> Vector2i:
	match way:
		0:
			return Vector2i(0, -1)
		2:
			return Vector2i(1, 0)
		4:
			return Vector2i(0, 1)
		6:
			return Vector2i(-1, 0)
	return Vector2i.ZERO
