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
## ([constant WINNING_LEVEL], Mortimer's castle) is done.
##
## A saved game (milestone C8, [Keen3SaveGames]) keeps what [GameProgress]
## keeps and the view's corner, as the original's saved game keeps its
## screenX/Y (Choco `CVort_save_game`). Messie is not saved: the original
## puts her at her start whenever a game starts or is loaded (Choco
## `CVort_draw_worldmap`), and so do we.

const WINNING_LEVEL := 16
## The key of the view's corner in a saved game.
const MAP_CORNER_KEY := "map_corner"

## The top left of the view over the map; [constant Vector2.INF] until the
## map has been shown.
var map_corner := Vector2.INF
## Messie on the map; null until the map has been shown.
var messie: Keen3Messie


func _init(keen_inventory: Inventory = null) -> void:
	inventory = keen_inventory if keen_inventory != null else Keen3Inventory.new()


## A game read by [SaveGames] (which knows only [GameProgress]) as a Keen 3
## game: the same inventory, completed levels and place on the map, and the
## view's corner from [param saved], the game's dictionary in the file.
static func from_game(game: GameProgress, saved := {}) -> Keen3Progress:
	var progress := Keen3Progress.new(game.inventory)
	for number in game.completed_levels():
		progress.complete_level(number)
	progress.map_position = game.map_position
	var corner: Variant = saved.get(MAP_CORNER_KEY, [])
	if corner is Array and corner.size() == 2:
		progress.map_corner = Vector2(float(corner[0]), float(corner[1]))
	return progress


## Whether the game is won: level 16 is done.
func is_won() -> bool:
	return is_completed(WINNING_LEVEL)


## What [GameProgress] saves, and the view's corner.
func to_dict() -> Dictionary:
	var data := super.to_dict()
	var corner := [] if not map_corner.is_finite() else [map_corner.x, map_corner.y]
	data[MAP_CORNER_KEY] = corner
	return data
