class_name GalaxyStatusWindow
extends RefCounted
## The status window of a Galaxy episode (Enter; made from Keen 4's
## [Keen4StatusWindow], milestone E6; Omni `ck_play.c:CK_DrawStatusWindow`,
## facts and numbers only): a window of 192 × 152 pixels framed by the 8×8
## tiles 54-62, grey inside, with
##   - LOCATION and the map's name on a white bar;
##   - SCORE and EXTRA (the next extra life);
##   - the episode's own row on the left ([method _draw_middle]: Keen 4's
##     RESCUED, Keen 5's KEYCARD) and LEVEL (the difficulty on a white bar)
##     on the right;
##   - KEYS (the gems), AMMO, KEENS (lives) and the drops (Keen 4's DROPS,
##     Keen 5's VITALIN);
##   - what the episode has below them ([method _draw_bottom]: Keen 4's
##     wetsuit) and the window's own "press a key" tiles
##     ([member key_tiles_at]);
## numbers as digit tiles in black bars (blank tile 41, '0' tile 42, as the
## score box). The labels are the player's own texts (the rules' status
## run); the original prints them with XOR, so on grey they are dark grey
## and on white black. Beside it hang the two masked pictures that hold it
## (Keen's arm at the left, a strap at the top; [method arm],
## [method strap]). [GalaxyStatusDrop] lets it drop and rise.

## The labels of the status run, in order (the episode's own row is the
## fourth; Keen 4 has two more after the drops).
enum Text { LOCATION, SCORE, EXTRA, MIDDLE, LEVEL, EASY, NORMAL, HARD, KEYS, AMMO, LIVES, DROPS }

const SIZE := Vector2i(192, 152)
## Where the window, the arm and the strap are when it is down (screen
## pixels; Omni STATUS_X, STATUS_Y, and the masked pictures' places).
const WINDOW_AT := Vector2i(64, 16)
const ARM_AT := Vector2i(40, 0)
const STRAP_AT := Vector2i(136, 0)
const ARM_PICTURE := 1
const STRAP_PICTURE := 2
## The frame's tiles (Omni).
const FRAME_TOP_LEFT := 54
const FRAME_TOP := 55
const FRAME_TOP_RIGHT := 56
const FRAME_LEFT := 57
const FRAME_RIGHT := 59
const FRAME_BOTTOM_LEFT := 60
const FRAME_BOTTOM := 61
const FRAME_BOTTOM_RIGHT := 62
const CELL := 8
## Tiles: a blank digit, '0' (the others follow), the first gem, the first
## "press a key" tile (two rows of ten).
const BLANK_DIGIT := 41
const ZERO_DIGIT := 42
const FIRST_GEM := 36
const FIRST_KEY_TILE := 72
const KEY_TILES := Vector2i(10, 2)
## Where the "press a key" tiles are in Keen 4 (Omni: 5 cells further
## right than in Keen 5 and 6).
const KEEN_4_KEY_TILES_AT := Vector2i(160, 140)
## The colours (EGA 0, 7, 8, 15): the bars, inside, labels on grey.
const BLACK := Color8(0, 0, 0)
const GREY := Color8(170, 170, 170)
const DARK_GREY := Color8(85, 85, 85)
const WHITE := Color8(255, 255, 255)
## Screen pixels of the parts (Omni): left and right columns, and the rows.
const INSIDE := Rect2i(72, 24, 176, 136)
const LEFT := 80
const RIGHT := 176
const COLUMN_WIDTH := 64
const NAME_AREA := Rect2i(80, 28, 160, 0)
const NAME_BAR := Rect2i(79, 38, 162, 20)
const NAME_TOP := 40 - 2
const UPPER_LABELS := 61
const SCORE_BAR := Rect2i(79, 71, 66, 10)
const EXTRA_BAR := Rect2i(175, 71, 66, 10)
const MIDDLE_LABELS := 85
const DIFFICULTY_BAR := Rect2i(175, 95, 66, 10)
const DIFFICULTY_TOP := 96
const KEYS_ROW := 112
const KEYS_BAR := Rect2i(119, 111, 34, 10)
const AMMO_BAR := Rect2i(215, 111, 26, 10)
const LIVES_ROW := 128
const LIVES_BAR := Rect2i(127, 127, 18, 10)
const DROPS_BAR := Rect2i(224, 127, 16, 10)
const DROPS_DIGITS_AT := Vector2i(224, 128)
const SCORE_DIGITS := 8
const AMMO_DIGITS := 3
const SMALL_DIGITS := 2
const GEMS := 4

## Where the "press a key" tiles are (screen pixels).
var key_tiles_at := KEEN_4_KEY_TILES_AT
var _graphics: GalaxyGraphics
var _font: GalaxyFont
var _labels := PackedStringArray()
var _names := PackedStringArray()
## The picture being drawn, in screen pixels.
var _screen: Image


## The window of [param data] by [param game_rules] (its font and texts).
static func create(data: GalaxyData, game_rules: GalaxyGameRules) -> GalaxyStatusWindow:
	var window := GalaxyStatusWindow.new()
	window.use_data(data, game_rules)
	return window


## Takes the pictures, the font and the texts of [param data].
func use_data(data: GalaxyData, game_rules: GalaxyGameRules) -> void:
	_graphics = data.graphics
	_font = data.graphics.font(game_rules.menu_font)
	_labels = data.executable.texts(game_rules.status_texts)
	_names = data.executable.level_names()


## The window, on a see-through picture of the whole screen (320 × 200)
## where it hangs when it is down, for map [param map] with what Keen carries
## ([param inventory]), the [param progress] of the game and its
## [param difficulty] (Omni CK_DrawStatusWindow).
func window(
	map: int, inventory: GalaxyInventory, progress: GalaxyProgress, difficulty: int
) -> Image:
	_screen = Image.create_empty(
		GalaxyWindow.SCREEN_SIZE.x, GalaxyWindow.SCREEN_SIZE.y, false, Image.FORMAT_RGBA8
	)
	_frame()
	_screen.fill_rect(INSIDE, GREY)
	_centred(label(Text.LOCATION), NAME_AREA.position.x, NAME_AREA.size.x, NAME_AREA.position.y)
	_screen.fill_rect(NAME_BAR, WHITE)
	var name := map_name(map)
	var name_height := GalaxyWindow._lines(name).size() * _font.height if _font != null else 0
	_centred(
		name,
		NAME_AREA.position.x,
		NAME_AREA.size.x,
		(NAME_BAR.size.y - name_height) / 2 + NAME_TOP,
		BLACK
	)
	_column_label(Text.SCORE, LEFT, UPPER_LABELS)
	_number_bar(SCORE_BAR, SCORE_DIGITS, inventory.score)
	_column_label(Text.EXTRA, RIGHT, UPPER_LABELS)
	_number_bar(EXTRA_BAR, SCORE_DIGITS, inventory.next_life_at)
	_draw_middle(inventory, progress)
	_column_label(Text.LEVEL, RIGHT, MIDDLE_LABELS)
	_screen.fill_rect(DIFFICULTY_BAR, WHITE)
	_centred(label(_difficulty_label(difficulty)), RIGHT, COLUMN_WIDTH, DIFFICULTY_TOP, BLACK)
	_draw_counts(inventory)
	_draw_bottom(inventory, progress)
	for y in KEY_TILES.y:
		for x in KEY_TILES.x:
			_tile(FIRST_KEY_TILE + y * KEY_TILES.x + x, key_tiles_at + Vector2i(x, y) * CELL)
	return _screen


## The arm that holds the window at the left (a masked picture).
func arm() -> Image:
	return _masked(ARM_PICTURE)


## The strap at the top.
func strap() -> Image:
	return _masked(STRAP_PICTURE)


## The name of map [param map] as the window shows it.
func map_name(map: int) -> String:
	return _names[map] if map >= 0 and map < _names.size() else ""


## The label number [param which] of the status run ([enum Text], or an
## episode's own beyond them).
func label(which: int) -> String:
	return _labels[which] if which >= 0 and which < _labels.size() else ""


## The episode's own row at the left of the LEVEL row (nothing by
## default).
func _draw_middle(_inventory: GalaxyInventory, _progress: GalaxyProgress) -> void:
	pass


## What the episode shows below the counts (nothing by default).
func _draw_bottom(_inventory: GalaxyInventory, _progress: GalaxyProgress) -> void:
	pass


func _draw_counts(inventory: GalaxyInventory) -> void:
	_left_label(Text.KEYS, LEFT, KEYS_ROW)
	_screen.fill_rect(KEYS_BAR, BLACK)
	for gem in GEMS:
		if inventory.has_gem(gem):
			_tile(FIRST_GEM + gem, Vector2i(KEYS_BAR.position.x + 1 + CELL * gem, KEYS_ROW))
	_left_label(Text.AMMO, RIGHT, KEYS_ROW)
	_number_bar(AMMO_BAR, AMMO_DIGITS, inventory.shots)
	_left_label(Text.LIVES, LEFT, LIVES_ROW)
	_number_bar(LIVES_BAR, SMALL_DIGITS, inventory.lives)
	_left_label(Text.DROPS, RIGHT, LIVES_ROW)
	_number_bar(DROPS_BAR, SMALL_DIGITS, inventory.drops, DROPS_DIGITS_AT)


func _frame() -> void:
	var outer := Rect2i(WINDOW_AT, SIZE)
	var right := outer.end.x - CELL
	var bottom := outer.end.y - CELL
	_tile(FRAME_TOP_LEFT, outer.position)
	_tile(FRAME_BOTTOM_LEFT, Vector2i(outer.position.x, bottom))
	_tile(FRAME_TOP_RIGHT, Vector2i(right, outer.position.y))
	_tile(FRAME_BOTTOM_RIGHT, Vector2i(right, bottom))
	for x in range(outer.position.x + CELL, right, CELL):
		_tile(FRAME_TOP, Vector2i(x, outer.position.y))
		_tile(FRAME_BOTTOM, Vector2i(x, bottom))
	for y in range(outer.position.y + CELL, bottom, CELL):
		_tile(FRAME_LEFT, Vector2i(outer.position.x, y))
		_tile(FRAME_RIGHT, Vector2i(right, y))


## A label centred over a column (Omni US_CPrint in a window of 64).
func _column_label(which: int, left: int, top: int) -> void:
	_centred(label(which), left, COLUMN_WIDTH, top)


## A label from the left of the column (Omni US_Print).
func _left_label(which: int, left: int, top: int) -> void:
	_print(label(which), Vector2i(left, top), DARK_GREY)


## Black [param bar] with [param value] right-aligned in [param digits]
## digit tiles, one pixel in from its corner unless [param at] says where
## (Omni CK_DrawLongRight).
func _number_bar(bar: Rect2i, digits: int, value: int, at := Vector2i(-1, -1)) -> void:
	if at == Vector2i(-1, -1):
		at = bar.position + Vector2i(1, 1)
	_screen.fill_rect(bar, BLACK)
	var text := str(maxi(value, 0))
	var x := at.x
	for place in range(digits, 0, -1):
		var tile := BLANK_DIGIT
		if place <= text.length():
			tile = ZERO_DIGIT + text.unicode_at(text.length() - place) - "0".unicode_at(0)
		_tile(tile, Vector2i(x, at.y))
		x += CELL


func _centred(text: String, left: int, width: int, top: int, color := DARK_GREY) -> void:
	if _font == null:
		return
	var y := top
	for line in GalaxyWindow._lines(text):
		_print(line, Vector2i(left + (width - _font.text_width(line)) / 2, y), color)
		y += _font.height


func _print(text: String, at: Vector2i, color: Color) -> void:
	if _font == null:
		return
	var picture := _font.render(text, color)
	_screen.blend_rect(picture, Rect2i(Vector2i.ZERO, picture.get_size()), at)


func _tile(index: int, at: Vector2i) -> void:
	var tile := _graphics.tile8(index)
	if tile == null:
		return
	if tile.get_format() != Image.FORMAT_RGBA8:
		tile = tile.duplicate() as Image
		tile.convert(Image.FORMAT_RGBA8)
	_screen.blit_rect(tile, Rect2i(Vector2i.ZERO, tile.get_size()), at)


func _masked(index: int) -> Image:
	var picture := _graphics.masked_picture(index)
	if picture != null and picture.get_format() != Image.FORMAT_RGBA8:
		picture = picture.duplicate() as Image
		picture.convert(Image.FORMAT_RGBA8)
	return picture


static func _difficulty_label(difficulty: int) -> Text:
	match difficulty:
		GalaxyDifficulty.Level.EASY:
			return Text.EASY
		GalaxyDifficulty.Level.HARD:
			return Text.HARD
	return Text.NORMAL
