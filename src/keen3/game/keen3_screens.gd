class_name Keen3Screens
extends RefCounted
## The screens of Keen 3's map 90 that are not levels (milestone C8), a row
## of screens of 20 tiles as in Keen 1 and 2, cut out with
## [method Backdrops.screen]. Seen in the original in js-dos (C1) and in
## Choco (`CVort3_draw_scores`), all places in pixels from the top left of
## the screen, whose top is map row 2:
##   - the title over the first screen (cells 2-21) with the TITLE bitmap
##     and F1HELP, which sits further right than in Keen 1 and 2
##   - the high score table on cells 84-103: HIGHSCOR, the NAME and SCORE
##     bitmaps, and per place a name and a score in the font's second half
##     (red letters on gray, as the original draws them); Keen 3 has no
##     third column
##   Title and table were compared pixel for pixel with the original in C11:
##   the same apart from the phase of the animated tiles.

const TITLE_SCREEN := Rect2i(2, 2, 20, 13)
const TITLE_BITMAP := Backdrops.TITLE_BITMAP
const TITLE_POSITION := Vector2(32, 1)
const HELP_BITMAP := "F1HELP"
const HELP_POSITION := Vector2(120, 182)
const HIGH_SCORE_SCREEN := Rect2i(84, 2, 20, 13)
const HIGH_SCORE_BITMAP := "HIGHSCOR"
const HIGH_SCORE_POSITION := Vector2(88, 7)
const HEADINGS: Dictionary[String, Vector2] = {"NAME": Vector2(80, 44), "SCORE": Vector2(192, 44)}
## The text of the first row, and the rows below it.
const FIRST_ROW_TOP := 64
const ROW_HEIGHT := Backdrops.ROW_HEIGHT
const NAME_LEFT := 80
const SCORE_RIGHT := 240


## Puts the title on the title screen of a map made by [method Backdrops.screen].
static func show_title(layer: PictureLayer) -> void:
	layer.clear()
	layer.put_bitmap(_origin() + TITLE_POSITION, TITLE_BITMAP)
	layer.put_bitmap(_origin() + HELP_POSITION, HELP_BITMAP)


## Fills the high score screen with [param table]; its third column (Keen
## 2's cities) is not shown.
static func show_high_scores(layer: PictureLayer, table: Keen2HighScores) -> void:
	layer.clear()
	var origin := _origin()
	layer.put_bitmap(origin + HIGH_SCORE_POSITION, HIGH_SCORE_BITMAP)
	for heading: String in HEADINGS:
		layer.put_bitmap(origin + HEADINGS[heading], heading)
	for place in table.entries.size():
		var entry := table.entries[place]
		var top := origin.y + FIRST_ROW_TOP + place * ROW_HEIGHT
		var score := str(entry.score)
		var score_left := SCORE_RIGHT - score.length() * EgaGraphics.FONT_CHAR_SIZE
		layer.put_text(Vector2(origin.x + NAME_LEFT, top), Keen3Window.label_text(entry.name))
		layer.put_text(Vector2(origin.x + score_left, top), Keen3Window.label_text(score))


## The names of a new high score table: the original fills all
## [constant Keen2HighScores.PLACES] places with the names of KEEN3.EXE in
## turn (Yorpy, Gargile, Zzapp!, Yorpy, ...), each with 100 points (seen in
## the original, C11); Keen 2's table leaves the places after them empty.
static func default_names(names: PackedStringArray) -> PackedStringArray:
	var all := PackedStringArray()
	if names.is_empty():
		return all
	for place in Keen2HighScores.PLACES:
		all.append(names[place % names.size()])
	return all


## The top left of the screen in the map made by [method Backdrops.screen]:
## its border lies before it.
static func _origin() -> Vector2:
	return Vector2(LevelData.BORDER_CELLS, LevelData.BORDER_CELLS) * EgaGraphics.TILE_SIZE
