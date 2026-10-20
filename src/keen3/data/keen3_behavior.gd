class_name Keen3Behavior
extends RefCounted
## The tile behaviours that only Keen 3 has, on top of
## [enum TileProperties.Behavior] (which stays Keen 1's). The values are
## those of the tile table in KEEN3.EXE (docs/keen3/research.md §4).

## The ankh: Keen cannot die or be stunned for a while.
const ANKH := 27
## A single charge for the raygun.
const SINGLE_CHARGE := 28


## Whether [param behavior] is one of Keen 3's own items.
static func is_keen3_item(behavior: int) -> bool:
	return behavior == ANKH or behavior == SINGLE_CHARGE
