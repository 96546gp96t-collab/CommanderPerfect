class_name GalaxyHelp
extends RefCounted
## The help (F1) of a Galaxy episode (made from Keen 4's [Keen4Help],
## milestone E7; Omni `ck_text.c`: ShowHelp, HelpScreens; facts only; seen
## in Keen 4 v1.0 and v1.4, D8 and D13, and Keen 5 v1.4, E7):
##   - the menu: the help picture at (96, 8) and the pointing hand beside
##     the topic, 24 pixels apart (five topics); up and down choose (not past
##     the ends), Enter, jump or pogo open the topic, Escape leaves the help;
##   - a topic: its text's pages ([GalaxyTextPages], [GalaxyPageLayout]),
##     "pg 1 of 13" at the bottom right; left, up and page up go back,
##     right, down and page down on, not past the first or last page; Escape
##     goes back to the menu, where the hand still points at it;
##   - without the frame's pictures (Keen 4 v1.0) on light grey, the number
##     at (248, 190) in dark grey; with them (later releases) on red inside
##     the frame ([GalaxyPageFrame]), the menu with its plain bottom edge, a
##     page with the bar at the bottom and the number at (218, 186) in light
##     red.
## The pictures and the topics' texts are the rules'
## ([member GalaxyGameRules.help_menu_picture] and the fields after it).

enum Action { UP, DOWN, BACK_PAGE, NEXT_PAGE, OPEN, ESCAPE }

const MENU_AT := Vector2i(96, 8)
const POINTER_LEFT := 48
const POINTER_TOP := 48
const POINTER_STEP := 24
const PAGE_NUMBER_AT := Vector2i(248, 190)
const PAGE_NUMBER_COLOR := 8
const FRAMED_PAGE_NUMBER_AT := Vector2i(218, 186)
const FRAMED_PAGE_NUMBER_COLOR := 12
const PAGE_NUMBER := "pg %d of %d"
## The pages' colours without and with the frame (Keen 4, D8 and D13).
const PAGE_BACKGROUND := 7
const PAGE_TEXT_COLOR := 8
const FRAMED_PAGE_BACKGROUND := 4
const FRAMED_PAGE_TEXT_COLOR := 14

var topic := 0
## The page shown (0 is the first); -1 while the menu is shown.
var page := -1
var _graphics: GalaxyGraphics
var _rules: GalaxyGameRules
var _layout: GalaxyPageLayout
var _pages: GalaxyTextPages


static func create(graphics: GalaxyGraphics, game_rules: GalaxyGameRules) -> GalaxyHelp:
	var help := GalaxyHelp.new()
	help._graphics = graphics
	help._rules = game_rules
	help._layout = page_layout(graphics, game_rules)
	help._layout.frame_status = true
	return help


## The layout of the episode's help and end pages: framed when the
## episode's files have the frame's pictures.
static func page_layout(graphics: GalaxyGraphics, game_rules: GalaxyGameRules) -> GalaxyPageLayout:
	var layout := GalaxyPageLayout.create(graphics, game_rules.menu_font)
	layout.frame = GalaxyPageFrame.find(graphics, game_rules.page_frame_picture)
	var framed := layout.frame != null
	layout.background = FRAMED_PAGE_BACKGROUND if framed else PAGE_BACKGROUND
	layout.default_color = FRAMED_PAGE_TEXT_COLOR if framed else PAGE_TEXT_COLOR
	return layout


func in_menu() -> bool:
	return page < 0


func topic_count() -> int:
	return _rules.help_topic_texts.size()


func page_count() -> int:
	return _pages.page_count() if _pages != null else 0


## Does [param action]; returns whether the help stays open.
func act(action: Action) -> bool:
	if in_menu():
		match action:
			Action.UP:
				topic = maxi(topic - 1, 0)
			Action.DOWN:
				topic = mini(topic + 1, topic_count() - 1)
			Action.OPEN:
				_pages = GalaxyTextPages.parse(_graphics.text(_rules.help_topic_texts[topic]))
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
	var number := PAGE_NUMBER % [page + 1, page_count()]
	if _layout.frame != null:
		_layout.print_at(number, FRAMED_PAGE_NUMBER_AT, FRAMED_PAGE_NUMBER_COLOR)
	else:
		_layout.print_at(number, PAGE_NUMBER_AT, PAGE_NUMBER_COLOR)
	return stages[-1].image


func _menu() -> Image:
	var image := Image.create_empty(
		GalaxyPageLayout.SCREEN_SIZE.x, GalaxyPageLayout.SCREEN_SIZE.y, false, Image.FORMAT_RGBA8
	)
	image.fill(EgaPalette.color(_layout.background))
	if _layout.frame != null:
		_layout.frame.draw(image, false)
	_blit(image, _rules.help_menu_picture, MENU_AT)
	_blit(
		image,
		_rules.help_pointer_picture,
		Vector2i(POINTER_LEFT, POINTER_TOP + topic * POINTER_STEP)
	)
	return image


func _blit(image: Image, index: int, at: Vector2i) -> void:
	var picture := _graphics.picture(index)
	if picture == null:
		return
	if picture.get_format() != Image.FORMAT_RGBA8:
		picture = picture.duplicate() as Image
		picture.convert(Image.FORMAT_RGBA8)
	image.blit_rect(picture, Rect2i(Vector2i.ZERO, picture.get_size()), at)
