class_name Keen4HighScoreBoard
extends RefCounted
## Keen 4's high-score table drawn over map 19, the way the original prints
## it into the map's picture (Omni `ck_inter.c`: CK_OverlayHighScores,
## CK_SubmitHighScore; US_LineInput in `id_us_1.c`; facts and numbers
## only; seen in the original, D8):
##   - eight rows 16 pixels apart from y 51 of the view: the name from
##     x 24, one council-member tile (8×8 tile 71) per rescued member from
##     x 152 (one pixel lower), the score right-aligned at x 296 in the
##     font's own score digits (a digit's character + 0x51);
##   - printed with XOR 15 over the map's tiles (light grey becomes dark
##     grey);
##   - a new name is typed where its row is: at most 57 characters and
##     while the name is narrower than 112 pixels; the cursor (the font's
##     character 0x80, XOR too) blinks every 35 tics.
## [method overlay] is a picture of the view (320 × 200), see-through
## except where the table changes the map.

const TOP := 51
const ROW_STEP := 16
const NAME_LEFT := 24
const ICONS_LEFT := 152
const ICON_DROP := 1
const ICON_TILE := 71
const ICON_WIDTH := 8
const SCORE_RIGHT := 296
const SCORE_DIGIT_SHIFT := 0x51
const XOR_COLOR := 15
const MAX_NAME_CHARACTERS := 57
const MAX_NAME_WIDTH := 112
const CURSOR := 0x80
const CURSOR_TICS := 35
const VIEW_SIZE := Vector2i(320, 200)
const TILE := 16

var table: GalaxyHighScores
## The row whose name is being typed, or -1.
var typing := -1
## Where the cursor is in that name.
var cursor := 0
var cursor_shown := false
var _cursor_tics := 0
var _graphics: GalaxyGraphics
var _font: GalaxyFont
var _map: GalaxyMap
## The view's top left in the map, in pixels.
var _origin := Vector2i.ZERO


static func create(
	graphics: GalaxyGraphics, scores: GalaxyHighScores, map: GalaxyMap, origin: Vector2i
) -> Keen4HighScoreBoard:
	var board := Keen4HighScoreBoard.new()
	board._graphics = graphics
	board._font = graphics.font(Keen4Episode.MENU_FONT)
	board.table = scores
	board._map = map
	board._origin = origin
	return board


## Starts typing the name of row [param row] (its name is empty).
func start_typing(row: int) -> void:
	typing = row
	cursor = 0
	_cursor_tics = 0
	cursor_shown = false


## Lets [param tics] tics pass; returns whether the cursor blinked.
func advance(tics: int) -> bool:
	if typing < 0:
		return false
	var before := cursor_shown
	_cursor_tics += tics
	cursor_shown = (_cursor_tics / CURSOR_TICS) % 2 == 1
	return cursor_shown != before


## Types [param character] at the cursor when the name has room.
func type_character(character: String) -> void:
	if typing < 0 or character.is_empty():
		return
	var name := table.entries[typing].name
	var code := character.unicode_at(0)
	if code < 0x20 or code > 0x7E:
		return
	if name.length() >= MAX_NAME_CHARACTERS or _font.text_width(name) >= MAX_NAME_WIDTH:
		return
	table.entries[typing].name = name.left(cursor) + character + name.substr(cursor)
	cursor += 1
	_show_cursor()


## Backspace, delete, left, right, home and end, as the original.
func edit(key: Key) -> void:
	if typing < 0:
		return
	var name := table.entries[typing].name
	match key:
		KEY_BACKSPACE:
			if cursor > 0:
				table.entries[typing].name = name.left(cursor - 1) + name.substr(cursor)
				cursor -= 1
		KEY_DELETE:
			if cursor < name.length():
				table.entries[typing].name = name.left(cursor) + name.substr(cursor + 1)
		KEY_LEFT:
			cursor = maxi(cursor - 1, 0)
		KEY_RIGHT:
			cursor = mini(cursor + 1, name.length())
		KEY_HOME:
			cursor = 0
		KEY_END:
			cursor = name.length()
	_show_cursor()


## Ends the typing: with [param keep] the name stays, otherwise it is empty
## (Escape).
func finish(keep: bool) -> void:
	if typing >= 0 and not keep:
		table.entries[typing].name = ""
	typing = -1
	cursor_shown = false


## The table as it lies over the view.
func overlay() -> Image:
	var image := Image.create_empty(VIEW_SIZE.x, VIEW_SIZE.y, false, Image.FORMAT_RGBA8)
	for row in table.entries.size():
		var entry := table.entries[row]
		var top := TOP + row * ROW_STEP
		_print(image, entry.name, Vector2i(NAME_LEFT, top))
		for icon in entry.count:
			_tile(image, Vector2i(ICONS_LEFT + icon * ICON_WIDTH, top + ICON_DROP))
		var score := score_text(entry.score)
		_print(image, score, Vector2i(SCORE_RIGHT - _font.text_width(score), top))
	if typing >= 0 and cursor_shown:
		var name := table.entries[typing].name
		var left := NAME_LEFT + _font.text_width(name.left(cursor)) - 1
		_print(image, String.chr(CURSOR), Vector2i(left, TOP + typing * ROW_STEP))
	return image


## [param score] in the font's score digits.
static func score_text(score: int) -> String:
	var digits := str(score)
	var text := ""
	for index in digits.length():
		text += String.chr(digits.unicode_at(index) + SCORE_DIGIT_SHIFT)
	return text


func _show_cursor() -> void:
	_cursor_tics = CURSOR_TICS
	cursor_shown = true


## [param text] XORed over the map (and over what the overlay already
## changed).
func _print(image: Image, text: String, at: Vector2i) -> void:
	var left := at.x
	for index in text.length():
		var character := text.unicode_at(index)
		for y in _font.height:
			for x in _font.width_of(character):
				if _font.is_set(character, x, y):
					_xor(image, Vector2i(left + x, at.y + y))
		left += _font.width_of(character)


func _xor(image: Image, pixel: Vector2i) -> void:
	if not Rect2i(Vector2i.ZERO, VIEW_SIZE).has_point(pixel):
		return
	var under := image.get_pixelv(pixel)
	if under.a < 0.5:
		under = _map_pixel(pixel)
	image.set_pixelv(pixel, GalaxyEga.xor(under, XOR_COLOR))


func _tile(image: Image, at: Vector2i) -> void:
	var tile := _graphics.tile8(ICON_TILE)
	if tile == null:
		return
	if tile.get_format() != Image.FORMAT_RGBA8:
		tile = tile.duplicate() as Image
		tile.convert(Image.FORMAT_RGBA8)
	image.blit_rect(tile, Rect2i(Vector2i.ZERO, tile.get_size()), at)


## The colour the map shows at [param pixel] of the view: its foreground
## tile where that is not see-through, else its background tile.
func _map_pixel(pixel: Vector2i) -> Color:
	var spot := _origin + pixel
	var cell := spot / TILE
	var inside := spot % TILE
	var fore := _graphics.fore_tile(_map.tile(GalaxyMap.Layer.FOREGROUND, cell.x, cell.y))
	if fore != null:
		var color := fore.get_pixelv(inside)
		if color.a > 0.5:
			return color
	var back := _graphics.back_tile(_map.tile(GalaxyMap.Layer.BACKGROUND, cell.x, cell.y))
	return back.get_pixelv(inside) if back != null else Color.BLACK
