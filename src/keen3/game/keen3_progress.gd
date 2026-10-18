class_name Keen3Progress
extends GameProgress
## One game of Keen 3 from start to finish: what Keen carries (a
## [Keen3Inventory]), which levels he has completed and where he stands on
## the world map, as [GameProgress] keeps them for Keen 1, plus what Keen
## 3's map keeps while Keen is in a level (Choco `CVort_draw_worldmap`):
##   - the part of the map the view showed ([member map_corner]): after a
##     level the view is back where it was
##   - Messie ([member messie]): she is put at her start once per game and
##     waits where she is while Keen plays a level
## Keen 3 has no ship parts and no cities: the game is won when level 16
## ([constant WINNING_LEVEL], Mortimer's castle) is done. Saving comes in
## milestone C8.

const WINNING_LEVEL := 16

## The top left of the view over the map; [constant Vector2.INF] until the
## map has been shown.
var map_corner := Vector2.INF
## Messie on the map; null until the map has been shown.
var messie: Keen3Messie


func _init(keen_inventory: Inventory = null) -> void:
	inventory = keen_inventory if keen_inventory != null else Keen3Inventory.new()


## Whether the game is won: level 16 is done.
func is_won() -> bool:
	return is_completed(WINNING_LEVEL)
