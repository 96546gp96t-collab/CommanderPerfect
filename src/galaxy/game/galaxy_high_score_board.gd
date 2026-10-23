class_name GalaxyHighScoreBoard
extends RefCounted
## The high-score table of a Galaxy episode drawn over its high-score map,
## the way the original prints it into the map's picture (made from Keen
## 4's [Keen4HighScoreBoard], milestone E7; Omni `ck_inter.c`:
## CK_OverlayHighScores, CK_SubmitHighScore; US_LineInput in `id_us_1.c`;
## facts and numbers only; seen in Keen 4, D8, and Keen 5, E7):
##   - eight rows 16 pixels apart from the rules' top margin
##     ([member GalaxyGameRules.high_score_top]): the name from the left
##     margin, the score right-aligned at the right margin in the font's own
##     score digits (a digit's character + 0x51); Keen 4 also shows one
##     council-member tile per rescued member from x 152 (one pixel lower),
##     Keen 5 no extra column ([member GalaxyGameRules.high_score_icon_tile]
##     -1);
##   - printed with the rules' colour XORed over the map's tiles (Keen 4 15:
##     light grey becomes dark grey; Keen 5 12);
##   - a new name is typed where its row is: at most 57 characters and
##     while the name is narrower than 112 pixels; the cursor (the font's
##     character 0x80, XOR too) blinks every 35 tics.
## [method overlay] is a picture of the view (320 × 200), see-through
## except where the table changes the map.

const ROW_STEP := 16
const ICONS_LEFT := 152
const ICON_DROP := 1
const ICON_WIDTH := 8
const SCORE_DIGIT_SHIFT := 0x51
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
var _top := 0
var _left := 0
var _right := 0
var _color := 0
var _icon_tile := -1


static func create(
	graphics: GalaxyGraphics,
	game_rules: GalaxyGameRules,
	scores: GalaxyHighScores,
	map: GalaxyMap,
	origin: Vector2i
) -> GalaxyHighScoreBoard:
	var board := GalaxyHighScoreBoard.new()
	board._graphics = graphics
	board._font = graphics.font(game_rules.menu_font)
	board.table = scores
	board._map = map
	board._origin = origin
	board._top = game_rules.high_score_top
	board._left = game_rules.high_score_left
	board._right = game_rules.high_score_right
	board._color = game_rules.high_score_color
	board._icon_tile = game_rules.high_score_icon_tile
	return board


## The original's table from the player's program (empty places when it is
## not found; none for an episode without one).
static func defaults(
	data: GalaxyData, game_rules: GalaxyGameRules
) -> Array[GalaxyHighScores.Entry]:
	var image := data.executable.image
	var count := game_rules.high_score_count
	var start := GalaxyHighScores.find_defaults(image, count, game_rules.high_score_offsets)
	if start < 0 and count > 0:
		push_error("The high-score table was not found in the program.")
		var empty: Array[GalaxyHighScores.Entry] = []
		for place in count:
			empty.append(GalaxyHighScores.Entry.new())
		return empty
	return GalaxyHighScores.defaults_at(image, start, count)


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
		var top := _top + row * ROW_STEP
		_print(image, entry.name, Vector2i(_left, top))
		if _icon_tile >= 0:
			for icon in entry.count:
				_tile(image, Vector2i(ICONS_LEFT + icon * ICON_WIDTH, top + ICON_DROP))
		var score := score_text(entry.score)
		_print(image, score, Vector2i(_right - _font.text_width(score), top))
	if typing >= 0 and cursor_shown:
		var name := table.entries[typing].name
		var left := _left + _font.text_width(name.left(cursor)) - 1
		_print(image, String.chr(CURSOR), Vector2i(left, _top + typing * ROW_STEP))
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
	image.set_pixelv(pixel, GalaxyEga.xor(under, _color))


func _tile(image: Image, at: Vector2i) -> void:
	var tile := _graphics.tile8(_icon_tile)
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
