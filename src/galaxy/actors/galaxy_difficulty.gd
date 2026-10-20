class_name GalaxyDifficulty
extends RefCounted
## The difficulty of a Galaxy game (Omni D_Easy, D_Normal, D_Hard). The
## info plane of a level places some creatures only from Normal or only on
## Hard (docs/keen4/research.md §6); later milestones add what else it
## changes (Keen's gravity and the stunner's charges on Easy, D10).

enum Level { EASY, NORMAL, HARD }

## Until the menu lets the player choose (D10).
const DEFAULT := Level.NORMAL


## Whether something placed from [param needed] on is there at
## [param level].
static func includes(level: Level, needed: Level) -> bool:
	return level >= needed
