class_name Keen2Screens
extends RefCounted
## The screens of Keen 2's map 90 that are not levels, a row of screens of
## 20 tiles as in Keen 1, cut out with [method Backdrops.screen]. Keen 2
## uses other screens than Keen 1 (B10, seen in the original): the title
## goes over the first screen (the wall with the fires), with the TITLE
## bitmap and "PRESS F1 FOR HELP"; the high score table goes on the gray
## screen framed with tile 395 (cells 84-103), not the frame at cells
## 62-83 that Keen 1's table uses. The table has a third column: the SAVED
## bitmap and the number of cities instead of ship parts. All places are
## the original's, in pixels from the top left of the screen.

const TITLE_SCREEN := Rect2i(2, 2, 20, 13)
const TITLE_BITMAP := Backdrops.TITLE_BITMAP
const TITLE_POSITION := Vector2(32, 1)
const HELP_BITMAP := "F1HELP"
const HELP_POSITION := Vector2(96, 182)
const HIGH_SCORE_SCREEN := Rect2i(84, 2, 20, 13)
const HIGH_SCORE_BITMAP := "HIGHSCOR"
const HIGH_SCORE_POSITION := Vector2(88, 7)
## The NAME and SCORE headings; the SAVED bitmap is 8 pixels taller and
## starts 4 higher.
const HEADINGS: Dictionary[String, Vector2] = {
	"NAME": Vector2(40, 44), "SCORE": Vector2(152, 44), "SAVED": Vector2(232, 40)
}
## The text of the first row, and the rows below it.
const FIRST_ROW_TOP := 64
const ROW_HEIGHT := Backdrops.ROW_HEIGHT
const NAME_LEFT := 40
const SCORE_RIGHT := 200
const CITIES_LEFT := 256


## Puts the title on the title screen of a map made by [method Backdrops.screen].
static func show_title(layer: PictureLayer) -> void:
	layer.clear()
	var origin := Vector2(LevelData.BORDER_CELLS, LevelData.BORDER_CELLS) * EgaGraphics.TILE_SIZE
	layer.put_bitmap(origin + TITLE_POSITION, TITLE_BITMAP)
	layer.put_bitmap(origin + HELP_POSITION, HELP_BITMAP)


## Fills the high score screen with [param table].
static func show_high_scores(layer: PictureLayer, table: Keen2HighScores) -> void:
	layer.clear()
	var origin := Vector2(LevelData.BORDER_CELLS, LevelData.BORDER_CELLS) * EgaGraphics.TILE_SIZE
	layer.put_bitmap(origin + HIGH_SCORE_POSITION, HIGH_SCORE_BITMAP)
	for heading: String in HEADINGS:
		layer.put_bitmap(origin + HEADINGS[heading], heading)
	for place in table.entries.size():
		var entry := table.entries[place]
		var top := origin.y + FIRST_ROW_TOP + place * ROW_HEIGHT
		var score := str(entry.score)
		var score_left := SCORE_RIGHT - score.length() * EgaGraphics.FONT_CHAR_SIZE
		layer.put_text(Vector2(origin.x + NAME_LEFT, top), entry.name)
		layer.put_text(Vector2(origin.x + score_left, top), score)
		layer.put_text(Vector2(origin.x + CITIES_LEFT, top), str(entry.cities))
