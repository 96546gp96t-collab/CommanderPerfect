class_name GalaxyDifficulty
extends RefCounted
## The difficulty of a Galaxy game (Omni D_Easy, D_Normal, D_Hard). The
## info plane of a level places some creatures only from Normal or only on
## Hard (docs/keen4/research.md §6); on Easy Keen falls under gravity mid
## after a jump ([member GalaxyKeenAir.easy_jumps]) and a stunner gives 8
## charges ([method Keen4Inventory.charges_for]).

enum Level { EASY, NORMAL, HARD }

## Demos, the high-score map and a level opened with --level.
const DEFAULT := Level.NORMAL


## Whether something placed from [param needed] on is there at
## [param level].
static func includes(level: Level, needed: Level) -> bool:
	return level >= needed
