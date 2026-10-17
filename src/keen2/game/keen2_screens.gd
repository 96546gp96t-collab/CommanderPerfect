class_name Keen2Screens
extends RefCounted
## The screens of Keen 2's map 90 that are not levels. Map 90 has the same
## layout as Keen 1's: a row of screens of 20 tiles, with the title screen
## (space, the mothership and the Earth) and the high score frame at the
## same cells, so Keen 1's [Backdrops] cuts them out and draws the title
## unchanged. The high score table is Keen 2's own: a third column with the
## SAVED bitmap and the number of cities instead of ship parts.
##
## The places follow Keen 1's table, moved down as Commander Genius moves
## Keen 2's (its headings 4 pixels lower, the rows too); they are estimates.

const TITLE_SCREEN := Backdrops.TITLE_SCREEN
const HIGH_SCORE_SCREEN := Backdrops.HIGH_SCORE_SCREEN
const HIGH_SCORE_BITMAP := "HIGHSCOR"
const HIGH_SCORE_TOP := Backdrops.HIGH_SCORE_TOP
## The NAME and SCORE headings, and the rows below them.
const HEADINGS_TOP := 50  # estimate
const FIRST_ROW_TOP := 68  # estimate
const ROW_HEIGHT := Backdrops.ROW_HEIGHT
const HEADINGS: Dictionary[String, int] = {"NAME": 36, "SCORE": 168}  # estimate
const NAME_LEFT := Backdrops.NAME_LEFT
const SCORE_RIGHT := Backdrops.SCORE_RIGHT
## The SAVED bitmap is 24 pixels high: its top is 4 pixels above the
## others, and the number of cities goes under its middle.
const SAVED_BITMAP := "SAVED"
const SAVED_POSITION := Vector2(240, 46)  # estimate
const CITIES_LEFT := 260  # estimate
const TEXT_OFFSET := Backdrops.TEXT_OFFSET


## Puts the title on the title screen of a map made by [method Backdrops.screen].
static func show_title(layer: PictureLayer) -> void:
	Backdrops.show_title(layer)


## Fills the high score screen with [param table].
static func show_high_scores(layer: PictureLayer, table: Keen2HighScores) -> void:
	layer.clear()
	var origin := Vector2(LevelData.BORDER_CELLS, LevelData.BORDER_CELLS) * EgaGraphics.TILE_SIZE
	var width := HIGH_SCORE_SCREEN.size.x * EgaGraphics.TILE_SIZE
	var title_left := (width - layer.bitmap_width(HIGH_SCORE_BITMAP)) / 2
	layer.put_bitmap(origin + Vector2(title_left, HIGH_SCORE_TOP), HIGH_SCORE_BITMAP)
	for heading: String in HEADINGS:
		layer.put_bitmap(origin + Vector2(HEADINGS[heading], HEADINGS_TOP), heading)
	layer.put_bitmap(origin + SAVED_POSITION, SAVED_BITMAP)
	for place in table.entries.size():
		var entry := table.entries[place]
		var top := origin.y + FIRST_ROW_TOP + place * ROW_HEIGHT + TEXT_OFFSET
		var score := str(entry.score)
		var score_left := SCORE_RIGHT - score.length() * EgaGraphics.FONT_CHAR_SIZE
		layer.put_text(Vector2(origin.x + NAME_LEFT, top), entry.name)
		layer.put_text(Vector2(origin.x + score_left, top), score)
		layer.put_text(Vector2(origin.x + CITIES_LEFT, top), str(entry.cities))
