class_name Keen4Help
extends RefCounted
## Keen 4's help (F1), as v1.0 shows it (seen in the original, D8; Omni
## `ck_text.c`: ShowHelp, HelpScreens; facts only):
##   - the menu: the help picture at (96, 8) on light grey and the pointing
##     hand beside the topic, 24 pixels apart: ComputerWrist, The Game, The
##     Story, Order Info, About Id; up and down choose (not past the ends),
##     Enter, jump or pogo open the topic, Escape leaves the help;
##   - a topic: its text's pages ([GalaxyTextPages], [GalaxyPageLayout]) on
##     light grey, "pg 1 of 13" at the bottom right; left, up and page up go
##     back, right, down and page down on, not past the first or last page;
##     Escape goes back to the menu, where the hand still points at it.
## The pictures are counted from the start of the picture range, the same
## in v1.0 and v1.4; the texts by their place in the text range (v1.0's
## order: help, story, keys, about Id, end, not in the demo, ordering).

enum Action { UP, DOWN, BACK_PAGE, NEXT_PAGE, OPEN, ESCAPE }

const MENU_PICTURE := 0
const POINTER_PICTURE := 39
const MENU_AT := Vector2i(96, 8)
const POINTER_LEFT := 48
const POINTER_TOP := 48
const POINTER_STEP := 24
## The text of each topic, in the menu's order.
const TOPIC_TEXTS: PackedInt32Array = [0, 2, 1, 6, 3]
const BACKGROUND := 7
const PAGE_NUMBER_AT := Vector2i(248, 190)
const PAGE_NUMBER_COLOR := 8
const PAGE_NUMBER := "pg %d of %d"

var topic := 0
## The page shown (0 is the first); -1 while the menu is shown.
var page := -1
var _graphics: GalaxyGraphics
var _layout: GalaxyPageLayout
var _pages: GalaxyTextPages


static func create(graphics: GalaxyGraphics) -> Keen4Help:
	var help := Keen4Help.new()
	help._graphics = graphics
	help._layout = GalaxyPageLayout.create(graphics, Keen4Episode.MENU_FONT)
	help._layout.background = BACKGROUND
	return help


func in_menu() -> bool:
	return page < 0


func page_count() -> int:
	return _pages.page_count() if _pages != null else 0


## Does [param action]; returns whether the help stays open.
func act(action: Action) -> bool:
	if in_menu():
		match action:
			Action.UP:
				topic = maxi(topic - 1, 0)
			Action.DOWN:
				topic = mini(topic + 1, TOPIC_TEXTS.size() - 1)
			Action.OPEN:
				_pages = GalaxyTextPages.parse(_graphics.text(TOPIC_TEXTS[topic]))
				page = 0
			Action.ESCAPE:
				return false
		return true
	match action:
		Action.UP, Action.BACK_PAGE:
			page = maxi(page - 1, 0)
		Action.DOWN, Action.NEXT_PAGE:
			page = mini(page + 1, page_count() - 1)
		Action.ESCAPE:
			page = -1
	return true


## The screen as it is now.
func screen() -> Image:
	if in_menu():
		return _menu()
	var stages := _layout.lay_out(_pages, page)
	_layout.print_at(PAGE_NUMBER % [page + 1, page_count()], PAGE_NUMBER_AT, PAGE_NUMBER_COLOR)
	return stages[-1].image


func _menu() -> Image:
	var image := Image.create_empty(
		GalaxyPageLayout.SCREEN_SIZE.x, GalaxyPageLayout.SCREEN_SIZE.y, false, Image.FORMAT_RGBA8
	)
	image.fill(EgaPalette.color(BACKGROUND))
	_blit(image, MENU_PICTURE, MENU_AT)
	_blit(image, POINTER_PICTURE, Vector2i(POINTER_LEFT, POINTER_TOP + topic * POINTER_STEP))
	return image


func _blit(image: Image, index: int, at: Vector2i) -> void:
	var picture := _graphics.picture(index)
	if picture == null:
		return
	if picture.get_format() != Image.FORMAT_RGBA8:
		picture = picture.duplicate() as Image
		picture.convert(Image.FORMAT_RGBA8)
	image.blit_rect(picture, Rect2i(Vector2i.ZERO, picture.get_size()), at)
