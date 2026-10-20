class_name GalaxyMenuView
extends RefCounted
## Draws the control panel of a Galaxy episode ([GalaxyMenuController]) as
## the original does (Omni `id_us_2.c`: US_DrawCards, USL_DrawCard,
## USL_DrawCardItem, USL_DrawMenuFooter, USL_CtlDialog; `ck_us_2.c`: the
## save boxes and the key boxes; facts only), on a 320 × 200 picture:
##   - the wrist watch over the whole screen; on its screen the card's title
##     picture at (80, 48) on a line at y 55, the choices one under the
##     other from the card's place, each an 8×8 icon and its name in the
##     watch font, the one under the cursor bright; the footer under a line
##     at y 133 ("Arrows move", "Enter selects", "ESC to quit / back out");
##   - the save slots as boxes 11 pixels apart with the save's name (or
##     "Empty" in the middle); the keys with their key in a box;
##   - a dialog: the watch's empty screen, a framed box in its middle with
##     the question, a line, and the answer lines;
##   - the Sound and Music cards with a ring before the unchecked choices
##     (Omni us_menu_itemChecked*: the icons after the normal ones);
##   - Paddle War through [GalaxyPaddleWarView];
##   - ours (D12): a card without a title picture shows its first line as
##     its title; the online pages through [GalaxyOnlinePageView].
## The colours were checked against the original (v1.0) pixel for pixel.

## EGA colours of the panel (seen in v1.0).
const BACKGROUND := 8
const NORMAL := 2
const BRIGHT := 10
## The 8×8 icons in front of a choice (Omni us_menu_item*Tile).
const ICON := 92
const ICON_SELECTED := 93
const ICON_UNCHECKED := 94
const ICON_UNCHECKED_SELECTED := 95
const ICON_DISABLED := 96
const ICON_DISABLED_SELECTED := 97
## The card's title and its line (Omni).
const TITLE_AT := Vector2i(80, 48)
const LINE_LEFT := 77
const LINE_RIGHT := 231
const TITLE_LINE_Y := 55
const FOOTER_LINE_Y := 133
const FOOTER_Y := 135
const FOOTER_LEFT := 78
const FOOTER_RIGHT := 230
## The watch's screen: from x 74, 160 wide, from y 48, 102 high (Omni).
const SCREEN_AT := Vector2i(74, 48)
const SCREEN_SIZE := Vector2i(160, 102)
## Choices: from x (card x + 74) rounded up to whole bytes, y card y + 60,
## a row of 8 pixels each; the row's bar from x 75, 159 wide (Omni).
const ITEMS_AT := Vector2i(74, 60)
const ROW := 8
const ROW_BAR_LEFT := 75
const ROW_BAR_WIDTH := 159
const BYTE := 8
const TEXT_SHIFT := Vector2i(8, 1)
## Rows a card shows; more scroll (Omni us_menu_maxCardItems).
const MAX_ROWS := 9
## Save boxes: 11 pixels apart, 148 × 9; the name 2 pixels in, "Empty" 60
## (Omni CK_US_DrawSavegameItemBorder).
const SLOT_ROW := 11
const SLOT_SIZE := Vector2i(148, 9)
const SLOT_TEXT := Vector2i(2, 2)
const EMPTY_TEXT_X := 60
const EMPTY := "Empty"
## Key boxes: 90 pixels from the choice, 40 wide; the key's name at 96
## (Omni CK_US_ControlsMenuProc); wider when the name needs it.
const KEY_BOX_X := 90
const KEY_BOX_WIDTH := 40
const KEY_TEXT_X := 96
const KEY_TEXT_MARGIN := 4
## The cursor while a key is waited for (Omni CK_US_SetKeyBinding).
const KEY_CURSOR_TILE := 100
const KEY_CURSOR_X := 106
## The cursor of the name being typed (the font's character 0x80, as the
## high-score name), on the last column of the text (seen in v1.0).
const TYPING_CURSOR := 0x80
const TYPING_CURSOR_SHIFT := -1
## Dialog: width of the longest line + 7, its lines one font height apart
## (Omni USL_CtlDialog).
const DIALOG_EXTRA_WIDTH := 7
const DIALOG_RULE_INSET := 3

var _graphics: GalaxyGraphics
var _cards: GalaxyMenuCards
var _font: GalaxyFont
var _image: Image
var _paddle_war: GalaxyPaddleWarView
var _online_pages: GalaxyOnlinePageView
## The game the Paddle War picture shows.
var _paddle_game: GalaxyPaddleWar


static func create(graphics: GalaxyGraphics, cards: GalaxyMenuCards) -> GalaxyMenuView:
	var view := GalaxyMenuView.new()
	view._graphics = graphics
	view._cards = cards
	view._font = graphics.font(cards.font)
	view._paddle_war = GalaxyPaddleWarView.create(graphics, cards)
	view._online_pages = GalaxyOnlinePageView.create(graphics, view._font)
	return view


## The panel as [param menus] shows it now.
func draw(menus: GalaxyMenuController) -> Image:
	_image = Image.create_empty(
		GalaxyWindow.SCREEN_SIZE.x, GalaxyWindow.SCREEN_SIZE.y, false, Image.FORMAT_RGBA8
	)
	_image.fill(Color.BLACK)
	var menu := menus.top()
	if menu == null:
		return _image
	var coop := menus as GalaxyCoopMenuController
	if coop != null and coop.shows_online_page():
		return _online_pages.draw(coop)
	if menu.kind == GalaxyMenuController.PADDLE_WAR:
		return _draw_paddle_war(menus.paddle_war())
	var below := menus.below()
	if below != null and below.kind == GalaxyMenuController.PADDLE_WAR:
		# Paddle War's end: its field stays behind the dialog.
		_image = _paddle_war.finish(menus.paddle_war()).duplicate() as Image
		_dialog(menu.header)
		return _image
	_picture(_graphics.picture(_cards.watch), Vector2i.ZERO)
	match menu.kind:
		MenuController.MESSAGE, GalaxyMenuController.CONFIRM:
			# The card stays behind the watch's dotted screen.
			if below != null:
				_card(below, menus, menus.depth() - 1)
			_dialog(menu.header)
		MenuController.PRESS_KEY:
			_card(menus.below(), menus, menus.depth() - 1)
		_:
			_card(menu, menus, menus.depth())
	return _image


## Paddle War: a new game starts its picture anew, then it changes as the
## original's screen does.
func _draw_paddle_war(game: GalaxyPaddleWar) -> Image:
	if game != _paddle_game:
		_paddle_game = game
		return _paddle_war.start(game).duplicate() as Image
	return _paddle_war.update(game).duplicate() as Image


func _card(menu: Menu, menus: GalaxyMenuController, depth: int) -> void:
	var kind := menu.kind
	if kind == GalaxyMenuController.SLOT_NAME:
		menu = menus.below()
		kind = menu.kind
	var card := _cards.card(kind)
	if card.picture >= 0:
		_line(TITLE_LINE_Y, BRIGHT)
		_picture(_graphics.picture(card.picture), TITLE_AT)
	elif not menu.header.is_empty():
		_line(TITLE_LINE_Y, BRIGHT)
		_text(menu.header[0], Vector2i(TITLE_AT.x, TITLE_LINE_Y - _font.height), BRIGHT)
	_footer(menus, depth)
	var left := ceili(float(ITEMS_AT.x + card.offset.x) / BYTE) * BYTE
	if kind in [MenuController.SLOTS_LOAD, MenuController.SLOTS_SAVE]:
		_slots(menu, menus, Vector2i(left, ITEMS_AT.y + card.offset.y))
	else:
		_rows(menu, menus, Vector2i(left, ITEMS_AT.y + card.offset.y))


func _footer(menus: GalaxyMenuController, depth: int) -> void:
	var typing := menus.top().kind == GalaxyMenuController.SLOT_NAME
	var left_text := "Type name" if typing else "Arrows move"
	var right_text := "Enter accepts" if typing else "Enter selects"
	var bottom_text := "ESC to quit" if depth <= 1 else "ESC to back out"
	_line(FOOTER_LINE_Y, BRIGHT)
	_text(left_text, Vector2i(FOOTER_LEFT, FOOTER_Y), NORMAL)
	_text(right_text, Vector2i(FOOTER_RIGHT - _font.text_width(right_text), FOOTER_Y), NORMAL)
	var middle := SCREEN_AT.x + (SCREEN_SIZE.x - _font.text_width(bottom_text)) / 2
	_text(bottom_text, Vector2i(middle, FOOTER_Y + _font.height + 1), NORMAL)


## The choices of an ordinary card, scrolled so the cursor is shown.
func _rows(menu: Menu, menus: GalaxyMenuController, at: Vector2i) -> void:
	var first := clampi(menu.cursor - MAX_ROWS + 1, 0, maxi(0, menu.items.size() - MAX_ROWS))
	var y := at.y
	var waiting := menus.top().kind == MenuController.PRESS_KEY
	for index in range(first, mini(menu.items.size(), first + MAX_ROWS)):
		var item := menu.items[index]
		var label := item.label
		if label.begins_with(GalaxyMenuController.GAP):
			y += ROW
			label = label.substr(GalaxyMenuController.GAP.length())
		var selected := index == menu.cursor
		_bar(Rect2i(ROW_BAR_LEFT, y, ROW_BAR_WIDTH, ROW), BACKGROUND)
		var checked := menus.is_checked(menu, index) or item.id != GalaxyMenuPages.RADIO
		_icon(item, selected and (menus.cursor_shown or waiting), checked, Vector2i(at.x, y))
		var color := BRIGHT if selected and item.enabled else NORMAL
		var parts := label.split(GalaxyMenuController.VALUE_SEPARATOR)
		_text(parts[0], Vector2i(at.x, y) + TEXT_SHIFT, color)
		if parts.size() > 1:
			var blink := waiting and selected
			_key_box(parts[1], Vector2i(at.x, y), color, blink, menus.cursor_shown)
		y += ROW


## [param checked]: false for a choice of a Sound or Music card that is
## not the checked one.
func _icon(item: Menu.Item, selected: bool, checked: bool, at: Vector2i) -> void:
	var tile := ICON
	if not item.enabled:
		tile = ICON_DISABLED_SELECTED if selected else ICON_DISABLED
	elif not checked:
		tile = ICON_UNCHECKED_SELECTED if selected else ICON_UNCHECKED
	elif selected:
		tile = ICON_SELECTED
	_picture(_graphics.tile8(tile), at)


## A key's name in its box; while a new key is waited for the box is empty
## with a blinking cursor.
func _key_box(key_name: String, at: Vector2i, color: int, waiting: bool, cursor: bool) -> void:
	var needed := KEY_TEXT_X - KEY_BOX_X + _font.text_width(key_name) + KEY_TEXT_MARGIN
	var room := SCREEN_AT.x + SCREEN_SIZE.x - (at.x + KEY_BOX_X)
	var width := clampi(needed, KEY_BOX_WIDTH, room)
	var box := Rect2i(at.x + KEY_BOX_X, at.y, width, ROW)
	# Seen in v1.0: the box has the colour of its text.
	_bar(box, color)
	_bar(box.grow(-1), BACKGROUND)
	if not waiting:
		_text(key_name, Vector2i(at.x + KEY_TEXT_X, at.y + TEXT_SHIFT.y), color)
	elif cursor:
		_picture(_graphics.tile8(KEY_CURSOR_TILE), Vector2i(at.x + KEY_CURSOR_X, at.y))


## The save slots: a box each, the name in it.
func _slots(menu: Menu, menus: GalaxyMenuController, at: Vector2i) -> void:
	var typing := menus.top().kind == GalaxyMenuController.SLOT_NAME
	for index in menu.items.size():
		var item := menu.items[index]
		var top_left := Vector2i(at.x, at.y + SLOT_ROW * index)
		var selected := index == menu.cursor
		var color := BRIGHT if selected else NORMAL
		# The box is the slot's icon: it blinks with the cursor.
		var lit := selected and (menus.cursor_shown or typing)
		_frame(Rect2i(top_left, SLOT_SIZE + Vector2i.ONE), BRIGHT if lit else NORMAL)
		_bar(Rect2i(top_left + Vector2i(1, 2), SLOT_SIZE - Vector2i(2, 2)), BACKGROUND)
		if typing and selected:
			var typed := menus.typed_save_name
			_text(typed, top_left + SLOT_TEXT, BRIGHT)
			if menus.cursor_shown:
				var cursor_x := _font.text_width(typed) + TYPING_CURSOR_SHIFT
				_text(
					String.chr(TYPING_CURSOR), top_left + SLOT_TEXT + Vector2i(cursor_x, 0), BRIGHT
				)
		elif item.label.is_empty():
			_text(EMPTY, top_left + Vector2i(EMPTY_TEXT_X, SLOT_TEXT.y), color)
		else:
			_text(item.label, top_left + SLOT_TEXT, color)


## A question or a message (Omni USL_CtlDialog): the first line, a rule,
## the others.
func _dialog(lines: PackedStringArray) -> void:
	var screen := _graphics.masked_picture(_cards.watch_screen)
	# The original puts pictures on whole bytes (seen: from x 72).
	_picture(screen, Vector2i(SCREEN_AT.x / BYTE * BYTE, SCREEN_AT.y))
	var widest := 0
	for line in lines:
		widest = maxi(widest, _font.text_width(line))
	var line_height := _font.height
	var size := Vector2i(widest + DIALOG_EXTRA_WIDTH, line_height * (lines.size() + 2))
	var at := SCREEN_AT + (SCREEN_SIZE - size) / 2
	_bar(Rect2i(at, size + Vector2i.ONE), BACKGROUND)
	_frame(Rect2i(at - Vector2i.ONE, size + Vector2i(3, 3)), BRIGHT)
	var y := at.y + line_height + 1
	for index in lines.size():
		var line := lines[index]
		var x := at.x + (size.x - _font.text_width(line)) / 2
		_text(line, Vector2i(x, y), BRIGHT if index == 0 else NORMAL)
		if index == 0:
			y += line_height * 2 - 1
			_bar(Rect2i(at.x + DIALOG_RULE_INSET, y, size.x - 2 * DIALOG_RULE_INSET + 1, 1), BRIGHT)
			y += 2
		else:
			y += line_height


func _line(y: int, color: int) -> void:
	_bar(Rect2i(LINE_LEFT, y, LINE_RIGHT - LINE_LEFT + 1, 1), color)


func _frame(rect: Rect2i, color: int) -> void:
	_bar(Rect2i(rect.position, Vector2i(rect.size.x, 1)), color)
	_bar(Rect2i(rect.position.x, rect.end.y - 1, rect.size.x, 1), color)
	_bar(Rect2i(rect.position, Vector2i(1, rect.size.y)), color)
	_bar(Rect2i(rect.end.x - 1, rect.position.y, 1, rect.size.y), color)


func _bar(rect: Rect2i, color: int) -> void:
	_image.fill_rect(rect, EgaPalette.color(color))


func _text(text: String, at: Vector2i, color: int) -> void:
	if text.is_empty():
		return
	var picture := _font.render(text, EgaPalette.color(color))
	_image.blend_rect(picture, Rect2i(Vector2i.ZERO, picture.get_size()), at)


func _picture(picture: Image, at: Vector2i) -> void:
	if picture == null:
		return
	if picture.get_format() != Image.FORMAT_RGBA8:
		picture = picture.duplicate() as Image
		picture.convert(Image.FORMAT_RGBA8)
	_image.blend_rect(picture, Rect2i(Vector2i.ZERO, picture.get_size()), at)
