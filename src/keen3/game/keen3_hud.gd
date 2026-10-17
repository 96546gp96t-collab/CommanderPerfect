class_name Keen3Hud
extends Hud
## The [Hud] of Keen 3 (widescreen only): the same two panels as Keen 1 and
## 2 (lives and score; raygun charges and keycards), with two changes:
##   - the little Keen for the lives is Keen 3's own map Keen looking at the
##     player (sprite 35; Keen 1's number 36 is another frame in Keen 3)
##   - while the ankh protects Keen, a third panel under the right one shows
##     the ankh and its time in whole "seconds" as the status screen counts
##     them ([method Keen3Body.ankh_seconds])
## The view sets [member ankh_tile] (the first tile with the ankh's
## behaviour, [method Keen2Icons.first_tile_with]) and calls
## [method show_ankh_time] every frame.

## Keen 3's map Keen looking at the player (MAPKEEND1).
const KEEN_3_LIFE_SPRITE := 35

## The ankh's tile; -1 draws no picture in its panel.
var ankh_tile := -1
## The ankh time shown; -1 when the ankh does not run (no panel).
var _ankh_seconds := -1


## Shows the ankh time, [param seconds], or no ankh panel when
## [param running] is false. Redraws only when something changed.
func show_ankh_time(running: bool, seconds: int) -> void:
	var shown := seconds if running else -1
	if shown == _ankh_seconds:
		return
	_ankh_seconds = shown
	queue_redraw()


func _draw() -> void:
	super._draw()
	if _textures != null and _ankh_seconds >= 0:
		_draw_ankh_panel()


## Lives and score, as [Hud] draws them, with Keen 3's little Keen.
func _draw_left_panel() -> void:
	var lives := str(_lives)
	var score := SCORE_LABEL + str(_score)
	var width := ICON + lives.length() * CHAR + SCORE_GAP + score.length() * CHAR
	var inside := _panel(Vector2(MARGIN, MARGIN), width)
	var keen := _textures.sprite(KEEN_3_LIFE_SPRITE)
	if keen != null:
		draw_texture(keen, inside)
	var x := inside.x + ICON
	_textures.draw_text(self, Vector2(x, inside.y + TEXT_OFFSET), lives, true)
	x += lives.length() * CHAR + SCORE_GAP
	_textures.draw_text(self, Vector2(x, inside.y + TEXT_OFFSET), score, true)


## The ankh and its time, against the right edge under the right panel.
func _draw_ankh_panel() -> void:
	var seconds := str(_ankh_seconds)
	var width := ICON + seconds.length() * CHAR
	var left := view_size.x - MARGIN - width - 2 * PADDING
	var top := MARGIN + ICON + 2 * PADDING + MARGIN
	var inside := _panel(Vector2(left, top), width)
	if ankh_tile >= 0:
		_draw_tile(inside, ankh_tile)
	_textures.draw_text(self, Vector2(inside.x + ICON, inside.y + TEXT_OFFSET), seconds, true)
