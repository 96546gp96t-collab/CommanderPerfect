class_name Keen4Start
extends GalaxyStart
## Where Keen starts in a Keen 4 map, from its info plane (Omni
## `ck4_misc.c:CK4_ScanInfoLayer`, research.md §5-§6), and the sprite he
## shows there until he can move (D4 for the levels, D6 for swimming, D7
## for the world map): the shared [GalaxyStart] by Keen 4's numbers
## ([method Keen4Episode.game_rules], milestone E13):
##   - info 1 / 2: Keen standing, facing right / left, at x = tile × 256,
##     y = tile × 256 − 241 (Omni CK_SpawnKeen): the bottom of his hit box
##     then rests on the tile below;
##   - info 3: Keen on the world map at the tile's corner (Omni
##     CK_SpawnMapKeen, a new game), sprite SPR_MAPKEEN_STAND_W;
##   - info 42: Keen swimming (level 17) at the tile's corner, facing right
##     (Omni CK4_SpawnScubaKeen).
## All three are drawn with priority 1 (Omni).

const MAP_KEEN_SPRITE := Keen4Episode.MAP_KEEN_SPRITE
const SWIMMING_KEEN_SPRITE := Keen4Episode.SWIMMING_KEEN_SPRITE


## Keen's start in [param map] (by Keen 4's rules unless [param rules]
## says otherwise): the first info value that places him, row by row.
## [member kind] is NONE when the map has none.
static func find(
	map: GalaxyMap, rules: GalaxyGameRules = null, into: GalaxyStart = null
) -> Keen4Start:
	var start: Keen4Start = into if into is Keen4Start else Keen4Start.new()
	GalaxyStart.find(map, rules if rules != null else Keen4Episode.game_rules(), start)
	return start
