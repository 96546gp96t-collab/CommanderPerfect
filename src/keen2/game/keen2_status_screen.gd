class_name Keen2StatusScreen
extends RefCounted
## Fills a [GameWindow] with Keen 2's status screen: the box of the original
## (its lines come from KEEN2.EXE: "SCORE", "EXTRA KEEN AT", "KEENS",
## "PISTOL", "TARGETS SAVED", "KEYS", "PLEASE PRESS A KEY"), with the score,
## the next extra life, a little Keen per life, the raygun with its charges,
## the names of the saved cities and the keycards Keen has.
##
## The numbers, the little Keens and the raygun stand where the original
## shows them (B10, seen in the original); the cities and keycards still
## come from Commander Genius's status screen, shifted by the border
## (Commander Genius counts it as column and row 0). The original draws its
## labels on gray bars and the numbers in white boxes; this box is plain.
## Without the lines from KEEN2.EXE the same labels are written in their
## place.

## The box inside the border: 28 columns, 12 rows.
const SIZE := Vector2i(28, 12)
## Used when KEEN2.EXE's lines are not found; same places as the original.
const FALLBACK_LINES: PackedStringArray = [
	"    SCORE     EXTRA KEEN AT",
	"",
	"    KEENS            PISTOL",
	"",
	"",
	"",
	"   TARGETS SAVED      KEYS",
	"",
	"",
	"",
	"",
	"     PLEASE PRESS A KEY",
]
## The numbers in row 1: the score ends before column 10, the next extra
## life before column 26.
const NUMBER_ROW := 1
const SCORE_END := 10
const EXTRA_LIFE_END := 26
## A little Keen (standing, 2x3 cells) per life, from column 1 of row 3 (in
## column 0 its sprite would touch the border); at most
## [constant MAX_LIVES_SHOWN].
const LIFE_SPRITE := 0
const LIFE_CELL := Vector2i(1, 3)
const LIFE_CELLS := 2
const MAX_LIVES_SHOWN := 7  # estimate
## The raygun icon and its charges, written from column 24 (the original
## draws the icon half a row lower).
const RAYGUN_TILE := 414
const RAYGUN_CELL := Vector2i(21, 3)
const CHARGES_CELL := Vector2i(24, 4)
## Where each city's name goes, in the order of [constant
## Keen2Progress.CITY_LEVELS] (two columns, as Commander Genius has them).
const CITY_CELLS: Array[Vector2i] = [
	Vector2i(0, 7),
	Vector2i(7, 7),
	Vector2i(0, 8),
	Vector2i(7, 9),
	Vector2i(0, 9),
	Vector2i(7, 8),
	Vector2i(0, 10),
	Vector2i(7, 10),
]  # estimate
## The keycard icons, in the order of [enum TileProperties.KeyColor].
const KEYCARD_TILES: PackedInt32Array = [424, 425, 426, 427]
const KEYCARD_CELLS: Array[Vector2i] = [
	Vector2i(20, 7), Vector2i(24, 7), Vector2i(20, 9), Vector2i(24, 9)
]  # estimate


## Fills [param window]. [param lines] are the box's lines from KEEN2.EXE
## (or empty), [param city_names] the eight names (or empty: then no names).
static func fill(
	window: GameWindow,
	progress: Keen2Progress,
	lines: PackedStringArray,
	city_names: PackedStringArray
) -> void:
	var inventory := progress.inventory
	window.open(SIZE)
	var box := FALLBACK_LINES
	if lines.size() == SIZE.y:
		box = GameTexts.fixed_lines(Keen2Texts.STATUS, lines)
	for row in box.size():
		window.put_text(Vector2i(0, row), box[row])
	window.put_text_right(SCORE_END, NUMBER_ROW, str(inventory.score))
	window.put_text_right(EXTRA_LIFE_END, NUMBER_ROW, str(inventory.next_extra_life()))
	for life in clampi(inventory.lives, 0, MAX_LIVES_SHOWN):
		window.put_sprite(LIFE_CELL + Vector2i(life * LIFE_CELLS, 0), LIFE_SPRITE)
	window.put_tile(RAYGUN_CELL, RAYGUN_TILE)
	window.put_text(CHARGES_CELL, str(inventory.charges))
	var saved := progress.saved_cities()
	if city_names.size() == saved.size():
		var names := Keen2Texts.city_names(city_names)
		for city in saved.size():
			if saved[city]:
				window.put_text(CITY_CELLS[city], names[city])
	for color in KEYCARD_TILES.size():
		if inventory.keycards[color]:
			window.put_tile(KEYCARD_CELLS[color], KEYCARD_TILES[color])
