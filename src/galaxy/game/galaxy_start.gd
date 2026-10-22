class_name GalaxyStart
extends RefCounted
## Where Keen starts in a map of a Galaxy episode, from its info plane, and
## the sprite he shows there until he can move (made from Keen 4's
## [Keen4Start], with the numbers from the episode's [GalaxyGameRules];
## Omni CKx_ScanInfoLayer):
##   - Keen standing ([member GalaxyGameRules.keen_right_info] / left),
##     at x = tile × 256, y = tile × 256 − 241 (Omni CK_SpawnKeen): the
##     bottom of his hit box then rests on the tile below;
##   - Keen on the world map ([member GalaxyGameRules.map_keen_info]) at the
##     tile's corner (Omni CK_SpawnMapKeen, a new game).
## Both are drawn with priority 1 (Omni). Keen 4's swimming Keen is Keen 4's
## own ([Keen4Start]).

enum Kind { NONE, STANDING, WORLD_MAP }

const UNITS_PER_TILE := GalaxyCamera.UNITS_PER_TILE
## Keen standing starts this many units above the tile's corner (Omni).
const STANDING_RISE := 241
## Keen's drawing priority (Omni zLayer 1).
const PRIORITY := 1

var kind := Kind.NONE
## The info tile Keen starts on.
var cell := Vector2i.ZERO
## His position, in units.
var position := Vector2i.ZERO
## 1 facing right, -1 facing left.
var facing := 1
var sprite := -1


## Keen's start in [param map] by [param rules]: the first info value that
## places him, row by row. [member kind] is NONE when the map has none.
static func find(map: GalaxyMap, rules: GalaxyGameRules) -> GalaxyStart:
	var start := GalaxyStart.new()
	for y in map.height:
		for x in map.width:
			var info := map.tile(GalaxyMap.Layer.INFO, x, y)
			if start._place(info, Vector2i(x, y), rules):
				return start
	start.cell = Vector2i.ZERO
	start.position = Vector2i.ZERO
	return start


## Whether the camera follows Keen as on the world map.
func is_world_map() -> bool:
	return kind == Kind.WORLD_MAP


## Whether Keen stands in the map, ready to play a level.
func is_standing() -> bool:
	return kind == Kind.STANDING


func _place(info: int, at: Vector2i, rules: GalaxyGameRules) -> bool:
	cell = at
	position = at * UNITS_PER_TILE
	if info == rules.keen_right_info or info == rules.keen_left_info:
		kind = Kind.STANDING
		facing = 1 if info == rules.keen_right_info else -1
		position.y -= STANDING_RISE
		sprite = rules.keen_stand_sprite(facing)
	elif info == rules.map_keen_info:
		kind = Kind.WORLD_MAP
		sprite = rules.map_keen_sprite
	else:
		return false
	return true
