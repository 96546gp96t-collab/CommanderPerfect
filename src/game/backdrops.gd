class_name Backdrops
extends RefCounted
## The screens of map 90 that are not levels: the original draws its title
## and high score table on them. The map is one row of screens, each 20
## tiles wide (see docs/file-formats.md); two of them are used here:
##   title       Keen next to his ship; the TITLE bitmap goes above them
##   high scores a red frame; the HIGHSCOR bitmap, the column headings and
##               the table go inside it
## Each screen is cut out of the map ([method LevelData.crop]), so that in
## widescreen the screens next to it stay hidden behind black bars.

## The cells of each screen in map 90. The high score screen includes the
## red edges on both sides of its frame.
const TITLE_SCREEN := Rect2i(42, 2, 20, 13)
const HIGH_SCORE_SCREEN := Rect2i(62, 2, 22, 13)
const TITLE_BITMAP := "TITLE"
## Top of the TITLE bitmap below the top of the title screen, in pixels.
const TITLE_TOP := 16

## Positions on the high score screen, in pixels from its top left.
const HIGH_SCORE_TOP := 20
const HEADINGS_TOP := 46
const FIRST_ROW_TOP := 64
const ROW_HEIGHT := 16
const NAME_LEFT := 40
const SCORE_RIGHT := 216
const PARTS_LEFT := 240
## The headings, each above the left edge of its column.
const HEADINGS: Dictionary[String, int] = {"NAME": 36, "SCORE": 168, "PARTS": 248}
## The ship part tiles, in the order of [enum Inventory.ShipPart].
const PART_TILES := StatusScreen.SHIP_PART_TILES
## Text is 8 pixels high, rows are 16: this puts it in the middle.
const TEXT_OFFSET := 4


## The screen [param area] of [param backdrops] (map 90) as a map of its own.
static func screen(backdrops: LevelData, area: Rect2i) -> LevelData:
	return backdrops.crop(area)


## Puts the title on the title screen of a map made by [method screen].
static func show_title(layer: PictureLayer) -> void:
	layer.clear()
	var left := (TITLE_SCREEN.size.x * EgaGraphics.TILE_SIZE - layer.bitmap_width(TITLE_BITMAP)) / 2
	layer.put_bitmap(_origin() + Vector2(left, TITLE_TOP), TITLE_BITMAP)


## Fills the high score screen with [param table].
static func show_high_scores(layer: PictureLayer, table: HighScores) -> void:
	layer.clear()
	var origin := _origin()
	var width := HIGH_SCORE_SCREEN.size.x * EgaGraphics.TILE_SIZE
	var title_left := (width - layer.bitmap_width("HIGHSCOR")) / 2
	layer.put_bitmap(origin + Vector2(title_left, HIGH_SCORE_TOP), "HIGHSCOR")
	for heading: String in HEADINGS:
		layer.put_bitmap(origin + Vector2(HEADINGS[heading], HEADINGS_TOP), heading)
	for place in table.entries.size():
		var entry := table.entries[place]
		var top := origin.y + FIRST_ROW_TOP + place * ROW_HEIGHT
		var score := str(entry.score)
		var score_left := SCORE_RIGHT - score.length() * EgaGraphics.FONT_CHAR_SIZE
		layer.put_text(Vector2(origin.x + NAME_LEFT, top + TEXT_OFFSET), entry.name)
		layer.put_text(Vector2(origin.x + score_left, top + TEXT_OFFSET), score)
		for part in entry.ship_parts.size():
			if entry.ship_parts[part]:
				var left := origin.x + PARTS_LEFT + part * EgaGraphics.TILE_SIZE
				layer.put_tile(Vector2(left, top), PART_TILES[part])


## Top left of a cut-out screen, in pixels: just inside its border.
static func _origin() -> Vector2:
	return Vector2(LevelData.BORDER_CELLS, LevelData.BORDER_CELLS) * EgaGraphics.TILE_SIZE
