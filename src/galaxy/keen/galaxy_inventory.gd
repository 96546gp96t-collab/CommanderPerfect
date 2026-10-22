class_name GalaxyInventory
extends RefCounted
## What Keen carries in a Galaxy episode: score, lives, stunner charges,
## lifewater drops (or the episode's own), the four gems, and when the next
## extra life comes (Omni `ck_game.c`, `ck_keen.c`; docs/keen4/research.md
## §5). The episode starts it with its own numbers ([Keen4Inventory]).
##
## The items, numbered as the original numbers them: 0-3 the gems, 4-9
## points, 10 an extra life, 11 a stunner ([constant POINTS]).

## Points per item (Omni ck_itemPoints).
const POINTS: PackedInt32Array = [0, 0, 0, 0, 100, 200, 500, 1000, 2000, 5000, 0, 0]
const GEM_COUNT := 4
const EXTRA_LIFE_ITEM := 10
const STUNNER_ITEM := 11
## 100 drops make a life (Omni).
const DROPS_PER_LIFE := 100
## The score box shows at most this many lives and charges (Omni).
const MAX_SHOWN := 99

var score := 0
## The score at which the next extra life comes; it doubles each time.
var next_life_at := 20000
var lives := 3
var shots := 5
var drops := 0
## Gems held, per colour.
var gems := PackedInt32Array([0, 0, 0, 0])
## Charges in a stunner item (Omni: 5, 8 on Easy).
var charges_per_stunner := 5
## Whether points give extra lives: not in demos (Omni CK_IncreaseScore).
var extra_lives_for_points := true


## Adds [param points]; returns whether that gave an extra life (Omni
## CK_IncreaseScore: at the threshold, which then doubles).
func add_score(points: int) -> bool:
	score += points
	if not extra_lives_for_points or score < next_life_at:
		return false
	lives += 1
	next_life_at *= 2
	return true


## Takes item [param item] (see the class description); returns whether an
## extra life came with it. A gem held as a sprite counts up, a gem tile
## ([param as_tile]) only sets its colour (Omni).
func collect(item: int, as_tile := false) -> bool:
	var extra := add_score(POINTS[item]) if item < POINTS.size() else false
	if item < GEM_COUNT:
		gems[item] = 1 if as_tile else gems[item] + 1
	elif item == EXTRA_LIFE_ITEM:
		lives += 1
	elif item == STUNNER_ITEM:
		shots += charges_per_stunner
	return extra


## One more drop; returns whether that made a life (the count starts again).
func add_drop() -> bool:
	drops += 1
	if drops < DROPS_PER_LIFE:
		return false
	drops = 0
	lives += 1
	return true


## Whether a gem of [param colour] is there to put in a holder.
func has_gem(colour: int) -> bool:
	return gems[colour] > 0


func use_gem(colour: int) -> void:
	gems[colour] -= 1


## Gems are lost when a level ends, also by dying (Omni).
func drop_gems() -> void:
	gems = PackedInt32Array([0, 0, 0, 0])
