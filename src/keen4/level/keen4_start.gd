class_name Keen4Start
extends RefCounted
## Where Keen starts in a Keen 4 map, from its info plane (Omni
## `ck4_misc.c:CK4_ScanInfoLayer`, research.md §5-§6), and the sprite he
## shows there until he can move (D4 for the levels, D6 for swimming, D7
## for the world map):
##   - info 1 / 2: Keen standing, facing right / left, at x = tile × 256,
##     y = tile × 256 − 241 (Omni CK_SpawnKeen): the bottom of his hit box
##     then rests on the tile below;
##   - info 3: Keen on the world map at the tile's corner (Omni
##     CK_SpawnMapKeen, a new game), sprite SPR_MAPKEEN_STAND_W;
##   - info 42: Keen swimming (level 17) at the tile's corner, facing right
##     (Omni CK4_SpawnScubaKeen).
## All three are drawn with priority 1 (Omni).

enum Kind { NONE, STANDING, WORLD_MAP, SWIMMING }

const UNITS_PER_TILE := GalaxyCamera.UNITS_PER_TILE
## Keen standing starts this many units above the tile's corner (Omni).
const STANDING_RISE := 241
## Keen's drawing priority (Omni zLayer 1).
const PRIORITY := 1
## Keen on the world map (Omni SPR_MAPKEEN_STAND_W) and swimming to the
## right (SPR_KEENSWIMR1), as sprite indices (Omni chunk − 124 in v1.4).
const MAP_KEEN_SPRITE := 132
const SWIMMING_KEEN_SPRITE := 187

var kind := Kind.NONE
## The info tile Keen starts on.
var cell := Vector2i.ZERO
## His position, in units.
var position := Vector2i.ZERO
## 1 facing right, -1 facing left.
var facing := 1
var sprite := -1


## Keen's start in [param map]: the first info value that places him, row
## by row. [member kind] is NONE when the map has none.
static func find(map: GalaxyMap) -> Keen4Start:
	var start := Keen4Start.new()
	for y in map.height:
		for x in map.width:
			var info := map.tile(GalaxyMap.Layer.INFO, x, y)
			if start._place(info, Vector2i(x, y)):
				return start
	return start


## Whether the camera follows Keen as on the world map.
func is_world_map() -> bool:
	return kind == Kind.WORLD_MAP


func _place(info: int, at: Vector2i) -> bool:
	cell = at
	position = at * UNITS_PER_TILE
	match info:
		Keen4Episode.KEEN_RIGHT_INFO, Keen4Episode.KEEN_LEFT_INFO:
			kind = Kind.STANDING
			facing = 1 if info == Keen4Episode.KEEN_RIGHT_INFO else -1
			position.y -= STANDING_RISE
			sprite = (
				Keen4Episode.KEEN_STAND_RIGHT_SPRITE
				if facing > 0
				else Keen4Episode.KEEN_STAND_LEFT_SPRITE
			)
		Keen4Episode.MAP_KEEN_INFO:
			kind = Kind.WORLD_MAP
			sprite = MAP_KEEN_SPRITE
		Keen4Episode.SWIMMING_KEEN_INFO:
			kind = Kind.SWIMMING
			sprite = SWIMMING_KEEN_SPRITE
		_:
			return false
	return true
