class_name GalaxyOnlinePageView
extends RefCounted
## Draws the online pages of the Galaxy control panel (ours, milestone D12:
## hosting, joining, typing a name, an address or a password;
## [GalaxyCoopMenuController]). They hold more text than the watch's small
## screen, so they are a framed box in the middle of the picture, in the
## panel's font and colours: the page's lines (the first bright), then its
## choices, the one under the cursor bright with the cursor's icon.

## How far the text stays from the frame, and the gap before the choices.
const MARGIN := Vector2i(8, 6)
const CHOICE_GAP := 4
## The choices are indented by the icon's width.
const ICON_WIDTH := 8
const LINE_GAP := 1
const MAX_WIDTH := 312

var _graphics: GalaxyGraphics
var _font: GalaxyFont
var _image: Image


static func create(graphics: GalaxyGraphics, font: GalaxyFont) -> GalaxyOnlinePageView:
	var view := GalaxyOnlinePageView.new()
	view._graphics = graphics
	view._font = font
	return view


## The page on top of [param menus], on a 320 × 200 picture.
func draw(menus: GalaxyCoopMenuController) -> Image:
	_image = Image.create_empty(
		GalaxyWindow.SCREEN_SIZE.x, GalaxyWindow.SCREEN_SIZE.y, false, Image.FORMAT_RGBA8
	)
	_image.fill(Color.BLACK)
	var menu := menus.top()
	if menu == null:
		return _image
	var lines := menus.text_lines() if menu.kind == MenuController.TEXT else menu.header
	var line_height := _font.height + LINE_GAP
	var width := 0
	for line in lines:
		width = maxi(width, _font.text_width(line))
	for item in menu.items:
		width = maxi(width, ICON_WIDTH + _font.text_width(item.label))
	var choices_height := menu.items.size() * line_height
	if not menu.items.is_empty():
		choices_height += CHOICE_GAP
	var size := Vector2i(
		mini(width + 2 * MARGIN.x, MAX_WIDTH),
		lines.size() * line_height + choices_height + 2 * MARGIN.y
	)
	var at := (GalaxyWindow.SCREEN_SIZE - size) / 2
	_bar(Rect2i(at, size), GalaxyMenuView.BACKGROUND)
	_frame(Rect2i(at, size), GalaxyMenuView.BRIGHT)
	var y := at.y + MARGIN.y
	for index in lines.size():
		var typed := menu.kind == MenuController.TEXT and index == lines.size() - 1
		var bright := index == 0 or typed
		_text(lines[index], Vector2i(at.x + MARGIN.x, y), bright)
		y += line_height
	y += CHOICE_GAP
	for index in menu.items.size():
		var item := menu.items[index]
		var selected := index == menu.cursor and item.enabled
		if selected and menus.cursor_shown:
			_picture(_graphics.tile8(GalaxyMenuView.ICON_SELECTED), Vector2i(at.x + MARGIN.x, y))
		_text(item.label, Vector2i(at.x + MARGIN.x + ICON_WIDTH, y), selected)
		y += line_height
	return _image


func _text(text: String, at: Vector2i, bright: bool) -> void:
	if text.is_empty():
		return
	var color := GalaxyMenuView.BRIGHT if bright else GalaxyMenuView.NORMAL
	var picture := _font.render(text, EgaPalette.color(color))
	_image.blend_rect(picture, Rect2i(Vector2i.ZERO, picture.get_size()), at)


func _picture(picture: Image, at: Vector2i) -> void:
	if picture == null:
		return
	if picture.get_format() != Image.FORMAT_RGBA8:
		picture = picture.duplicate() as Image
		picture.convert(Image.FORMAT_RGBA8)
	_image.blend_rect(picture, Rect2i(Vector2i.ZERO, picture.get_size()), at)


func _bar(rect: Rect2i, color: int) -> void:
	_image.fill_rect(rect, EgaPalette.color(color))


func _frame(rect: Rect2i, color: int) -> void:
	_bar(Rect2i(rect.position, Vector2i(rect.size.x, 1)), color)
	_bar(Rect2i(rect.position.x, rect.end.y - 1, rect.size.x, 1), color)
	_bar(Rect2i(rect.position, Vector2i(1, rect.size.y)), color)
	_bar(Rect2i(rect.end.x - 1, rect.position.y, 1, rect.size.y), color)
