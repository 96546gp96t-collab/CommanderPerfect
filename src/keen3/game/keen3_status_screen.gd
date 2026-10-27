class_name Keen3StatusScreen
extends RefCounted
## Fills a [Keen3Window] with Keen 3's status screen (Space in the original,
## the status key here; the game stands still while it is open). The box is
## 28x11 cells inside its border, which puts it at x 40-279, y 48-151 of the
## 320x200 view, where the original has it (seen in js-dos in C1). The
## places are Chocolate Keen's (`CVort3_show_pause_menu`), checked against
## the original:
##   row 0     labels (score, next extra Keen)
##   row 1     the score ending before column 10, the next extra Keen
##             before column 26
##   row 2     labels (Keens, pistol)
##   rows 3-5  a little Keen (sprite 0) per life from column 1, two columns
##             apart, at most 9; the pistol (tile 216) at column 21, 4 px
##             below row 3; the charges at column 24, row 4
##   row 6     labels (ankh time, keycards)
##   rows 7-9  the ankh (tile 214) at column 3, 4 px below row 7; the ankh
##             time in whole seconds at column 7, row 8; the keycards Keen
##             has (tiles 217-220) at columns 13, 17, 21 and 25, 4 px below
##             row 7
##   row 10    the line asking for a key
## The label lines come from KEEN3.EXE ([member Keen3GameData.status_lines]):
## the four full lines lie on rows 0, 2, 6 and 10, the one-space lines are
## short gray bars that divide the white value areas (row 1 at column 12,
## rows 3-5 at column 19, rows 7-9 at column 11). They are written in the
## font's second half: red letters on gray bars, as in the original.
## Without the lines from the EXE the box has no labels.
##
## With two players on one keyboard (milestone C10) each Keen has his own
## ankh: then the ankh time of each stands with his player's number,
## player 1's ("1:9") on row 8 and player 2's ("2:4") on row 9 under it.

const SIZE := Vector2i(28, 11)
const LINE_COUNT := 11
## The rows of the one-space lines, and their columns.
const DIVIDER_COLUMNS: Dictionary[int, int] = {1: 12, 3: 19, 4: 19, 5: 19, 7: 11, 8: 11, 9: 11}
const NUMBER_ROW := 1
const SCORE_END := 10
const EXTRA_LIFE_END := 26
const LIFE_SPRITE := 0
const LIFE_CELL := Vector2i(1, 3)
const LIFE_CELLS := 2
const MAX_LIVES_SHOWN := 9
## Tiles sit this far below their row.
const TILE_SHIFT := Vector2(0, 4)
const PISTOL_TILE := 216
const PISTOL_CELL := Vector2i(21, 3)
const CHARGES_CELL := Vector2i(24, 4)
const ANKH_TILE := 214
const ANKH_CELL := Vector2i(3, 7)
const ANKH_TIME_CELL := Vector2i(7, 8)
## The keycard tiles, in the order of [enum TileProperties.KeyColor], and
## their places.
const KEYCARD_TILES: PackedInt32Array = [217, 218, 219, 220]
const KEYCARD_CELLS: Array[Vector2i] = [
	Vector2i(13, 7), Vector2i(17, 7), Vector2i(21, 7), Vector2i(25, 7)
]


## Fills [param window] with what [param inventory] holds and
## [param ankh_seconds] (the ankh time as the status screen counts it).
## [param lines] are the box's lines from KEEN3.EXE, or empty.
## [param partner_ankh_seconds] is player 2's ankh time when two play on one
## keyboard, otherwise -1.
static func fill(
	window: Keen3Window,
	inventory: Inventory,
	ankh_seconds: int,
	lines: PackedStringArray,
	partner_ankh_seconds := -1,
) -> void:
	window.open(SIZE)
	if lines.size() == LINE_COUNT:
		_put_labels(window, GameTexts.fixed_lines(Keen3Texts.STATUS, lines))
	window.put_text_right(SCORE_END, NUMBER_ROW, str(inventory.score))
	window.put_text_right(EXTRA_LIFE_END, NUMBER_ROW, str(inventory.next_extra_life()))
	for life in clampi(inventory.lives, 0, MAX_LIVES_SHOWN):
		window.put_sprite(LIFE_CELL + Vector2i(life * LIFE_CELLS, 0), LIFE_SPRITE)
	window.put_tile_shifted(PISTOL_CELL, PISTOL_TILE, TILE_SHIFT)
	window.put_text(CHARGES_CELL, str(inventory.charges))
	window.put_tile_shifted(ANKH_CELL, ANKH_TILE, TILE_SHIFT)
	if partner_ankh_seconds < 0:
		window.put_text(ANKH_TIME_CELL, str(ankh_seconds))
	else:
		window.put_text(ANKH_TIME_CELL, "1:%d" % ankh_seconds)
		window.put_text(ANKH_TIME_CELL + Vector2i.DOWN, "2:%d" % partner_ankh_seconds)
	for color in KEYCARD_TILES.size():
		if inventory.keycards[color]:
			window.put_tile_shifted(KEYCARD_CELLS[color], KEYCARD_TILES[color], TILE_SHIFT)


## The label lines: full lines from column 0, the dividers at their column.
static func _put_labels(window: Keen3Window, lines: PackedStringArray) -> void:
	for row in lines.size():
		var line := lines[row]
		if line.length() == SIZE.x:
			window.put_label(Vector2i(0, row), line)
		elif DIVIDER_COLUMNS.has(row):
			window.put_label(Vector2i(DIVIDER_COLUMNS[row], row), line)
