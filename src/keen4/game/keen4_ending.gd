class_name Keen4Ending
extends RefCounted
## Keen 4's end: the pages of the end text after the eighth rescue (Omni
## `ck_text.c`: help_endgame; facts only; seen in the original, D8):
##   - each page is laid out like a help page on light grey, without a page
##     number ([GalaxyPageLayout]); a page with timed pictures shows them one
##     after the other (their pauses in tics), keys do nothing meanwhile;
##   - then an arrow at the bottom right blinks, dim and bright, 70 tics
##     each (seen: about 1 s); a key goes to the next page;
##   - after the last page the end is over (the high scores follow).
## The arrows are pictures counted from the start of the picture range; the
## text is the fifth of the text range.

const END_TEXT := 4
const ARROW_DIM := 41
const ARROW_BRIGHT := 42
const ARROW_AT := Vector2i(296, 184)
const ARROW_TICS := 70
const BACKGROUND := 7

var page := 0
var _graphics: GalaxyGraphics
var _layout: GalaxyPageLayout
var _pages: GalaxyTextPages
var _stages: Array[GalaxyPageLayout.Stage] = []
var _stage := 0
var _stage_tics := 0
var _arrow_tics := 0


static func create(graphics: GalaxyGraphics) -> Keen4Ending:
	var ending := Keen4Ending.new()
	ending._graphics = graphics
	ending._layout = GalaxyPageLayout.create(graphics, Keen4Episode.MENU_FONT)
	ending._layout.background = BACKGROUND
	ending._pages = GalaxyTextPages.parse(graphics.text(END_TEXT))
	ending._lay_out()
	return ending


func page_count() -> int:
	return _pages.page_count()


func is_done() -> bool:
	return page >= page_count()


## Whether the page is whole and waits for a key (the arrow blinks).
func waits() -> bool:
	return not is_done() and _stage == _stages.size() - 1


## Lets [param tics] tics pass; returns whether the screen changed.
func advance(tics: int) -> bool:
	if is_done():
		return false
	if waits():
		var before := _arrow_bright()
		_arrow_tics += tics
		return _arrow_bright() != before
	_stage_tics += tics
	var changed := false
	while _stage < _stages.size() - 1 and _stage_tics >= _stages[_stage].tics:
		_stage_tics -= _stages[_stage].tics
		_stage += 1
		changed = true
	return changed


## A key: the next page when this one waits; returns whether it was taken.
func press() -> bool:
	if not waits():
		return false
	page += 1
	if not is_done():
		_lay_out()
	return true


## The screen as it is now.
func screen() -> Image:
	if _stages.is_empty():
		return null
	var image := _stages[mini(_stage, _stages.size() - 1)].image
	if not waits():
		return image
	image = image.duplicate() as Image
	var arrow := _graphics.picture(ARROW_BRIGHT if _arrow_bright() else ARROW_DIM)
	if arrow != null:
		if arrow.get_format() != Image.FORMAT_RGBA8:
			arrow = arrow.duplicate() as Image
			arrow.convert(Image.FORMAT_RGBA8)
		image.blit_rect(arrow, Rect2i(Vector2i.ZERO, arrow.get_size()), ARROW_AT)
	return image


func _arrow_bright() -> bool:
	return (_arrow_tics / ARROW_TICS) % 2 == 1


func _lay_out() -> void:
	_stages = _layout.lay_out(_pages, page)
	_stage = 0
	_stage_tics = 0
	_arrow_tics = 0
