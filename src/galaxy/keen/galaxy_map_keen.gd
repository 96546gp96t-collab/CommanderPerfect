class_name GalaxyMapKeen
extends GalaxyKeenBody
## Keen on a Galaxy world map (Omni `ck_map.c`: CK_SpawnMapKeen,
## CK_MapKeenStill, CK_MapKeenWalk, CK_ScanForLevelEntry; facts and numbers
## only; docs/keen4/research.md §8):
##   - he walks in eight directions, 24 units a tic on each axis held (so a
##     diagonal is faster), clipped by the map's walls; every 4 tics his
##     picture moves on: walking 2, standing, walking 1, standing (seen in
##     the original, D7: 3 pixels a frame);
##   - standing still for 360 tics he waves (two pictures, 5 × 20 tics);
##   - jump, pogo or fire on an entrance (an info word 0xC000 + n, n in
##     [member first_entry] … [member last_entry]) under his box ends the
##     map: [member entered] is the level, [member map_position] where he
##     stood ([method GalaxyWorld.complete] with [constant ENTERED]).
## An episode adds what its map has besides (Keen 4: water, the Foot;
## [Keen4MapKeen]) by overriding [method _touch_tiles].
## Sprites by name: MAP_<dir>_WALK_1, MAP_<dir>_WALK_2, MAP_<dir>_STAND for
## the eight [constant DIRECTION_NAMES], and MAP_WAVE_1, MAP_WAVE_2.

## How a map ends when he enters a level.
const ENTERED := &"entered"
## Entrances: the info words 0xC000 + level (Omni).
const ENTRY_BASE := 0xC000
## The directions in the original's order (Omni IN_dir_*), clockwise from
## north; [constant NO_DIRECTION] when nothing is held.
const DIRECTION_NAMES: PackedStringArray = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
const NO_DIRECTION := 8
const WEST := 6
## (Omni CK_ACT_MapKeenStart, MapKeenWave0-4, MapKeenWalk0.) Standing
## keeps the picture he had.
const ROWS: PackedStringArray = [
	"stand - - step+ -- 360 0 0 still - - wave_1",
	"wave_1 MAP_WAVE_1 MAP_WAVE_1 step+ -- 20 0 0 still - - wave_2",
	"wave_2 MAP_WAVE_2 MAP_WAVE_2 step+ -- 20 0 0 still - - wave_3",
	"wave_3 MAP_WAVE_1 MAP_WAVE_1 step+ -- 20 0 0 still - - wave_4",
	"wave_4 MAP_WAVE_2 MAP_WAVE_2 step+ -- 20 0 0 still - - wave_5",
	"wave_5 MAP_WAVE_1 MAP_WAVE_1 step+ -- 20 0 0 walk - - stand",
	"walk - - slide p 4 24 24 walk - - walk",
]
## The walking pictures, one per step of 4 tics (Omni ck_mapKeenAnimFrame:
## walking 2, standing, walking 1, standing).
const WALK_CYCLE: PackedStringArray = ["WALK_2", "STAND", "WALK_1", "STAND"]
const STAND := "STAND"
const PRIORITY := 1
## Every walking step uses up this many tics he goes on by himself (Omni).
const FORCED_STEP_TICS := 4

## The levels whose entrances he can use (Omni ck_minEnterLevel,
## ck_maxEnterLevel; Keen 4: 1-18).
var first_entry := 1
var last_entry := 18
## The level he entered, 0 while none.
var entered := 0
## Where he stood when he entered it: the game keeps it for the way back.
var map_position := Vector2i.ZERO
## The way he faces, 0-7 ([constant DIRECTION_NAMES]; Omni user1).
var facing := WEST
## The step of the walking pictures (Omni user2).
var walk_step := 3
## Tics he still goes on by himself, without the stick (Omni user3; Keen
## 4's water).
var forced_tics := 0


## Keen of [param world] at [param at] (units), standing facing west.
static func spawn(
	world: GalaxyWorld, at: Vector2i, episode_sprites: Dictionary[StringName, int]
) -> GalaxyMapKeen:
	var keen := GalaxyMapKeen.new()
	keen.place(world, at, episode_sprites)
	return keen


## Puts him in [param world] at [param at], standing facing west (Omni
## CK_SpawnMapKeen).
func place(
	world_in: GalaxyWorld, at: Vector2i, episode_sprites: Dictionary[StringName, int]
) -> void:
	position = at
	direction = Vector2i.ZERO
	world_in.add(self)
	use_sprites(episode_sprites)
	sprite = picture(WEST, STAND)
	start(actions[&"stand"])


## His map actions; he collides like Keen and is always awake.
func use_sprites(episode_sprites: Dictionary[StringName, int]) -> void:
	sprites = episode_sprites
	actions = GalaxyAction.table_from(ROWS, episode_sprites)
	clips_like_keen = true
	activity = Activity.ALWAYS
	priority = PRIORITY


## The sprite of direction [param way] (0-7) and picture [param kind]
## (WALK_1, WALK_2, STAND).
func picture(way: int, kind: String) -> int:
	return sprites.get(StringName("MAP_%s_%s" % [DIRECTION_NAMES[way], kind]), NO_SPRITE)


## The direction held (0-7), or [constant NO_DIRECTION].
func held_direction() -> int:
	return direction_of(Vector2i(input.direction, input.vertical))


## The original's direction number of [param stick] (x and y, -1 to 1).
static func direction_of(stick: Vector2i) -> int:
	if stick == Vector2i.ZERO:
		return NO_DIRECTION
	var angle := atan2(float(stick.x), float(-stick.y))
	return posmod(roundi(angle / (PI / 4.0)), DIRECTION_NAMES.size())


## The map Keen does not die; nothing on the map kills.
func kill() -> void:
	pass


## Think while standing or waving: the stick starts a walk at once, jump,
## pogo or fire looks for an entrance (Omni CK_MapKeenStill).
func _think_still() -> void:
	if held_direction() != NO_DIRECTION:
		_continue_as(&"walk")
		walk_step = 0
		_think_walk()
	if input.jump or input.pogo or input.fire:
		_scan_for_entry()


## Think every 4 tics of walking: the stick, the entrance, the next
## picture (Omni CK_MapKeenWalk); while he goes on by himself the stick
## counts again once those tics are used up (as Keen 4's swimming, seen in
## the original, D7).
func _think_walk() -> void:
	if forced_tics > 0:
		forced_tics = maxi(forced_tics - FORCED_STEP_TICS, 0)
	if forced_tics == 0:
		direction = Vector2i(input.direction, input.vertical)
		if input.jump or input.pogo or input.fire:
			_scan_for_entry()
		var way := held_direction()
		if way == NO_DIRECTION:
			_continue_as(&"stand")
			sprite = picture(facing, STAND)
			return
		facing = way
	walk_step = (walk_step + 1) % WALK_CYCLE.size()
	sprite = picture(facing, WALK_CYCLE[walk_step])


## An entrance under his box: the map ends (Omni CK_ScanForLevelEntry).
func _scan_for_entry() -> void:
	for y in range(box.tile_top, box.tile_bottom + 1):
		for x in range(box.tile_left, box.tile_right + 1):
			var level := world.info_at(x, y) - ENTRY_BASE
			if level >= first_entry and level <= last_entry:
				map_position = position
				entered = level
				world.complete(ENTERED)
				return


## Nothing on the map is taken or kills (an episode adds its own tiles).
func _touch_tiles() -> void:
	pass
