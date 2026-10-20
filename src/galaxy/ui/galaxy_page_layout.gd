class_name GalaxyPageLayout
extends RefCounted
## Lays out and draws one page of a [GalaxyTextPages] text on a 320 × 200
## picture, the way the original lays out its help and end pages (Omni
## `ck_text.c`: PageLayout, HandleWord, HandleCommand; facts only; seen in
## Keen 4 v1.0, D8):
##   - 18 lines of 10 pixels from y 10, each from x 10 to 310; words are
##     put on a line while they fit, a space after a word is 7 pixels, a
##     newline goes to the next line; after the 18th line the page is full;
##   - a picture ([code]^G[/code]) goes at its place with x rounded down to
##     8 pixels; the lines it covers give it room: text keeps 8 pixels away
##     on its right side when its middle is left of 160, on its left side
##     otherwise;
##   - [code]^T[/code]: the page so far is shown for its pause, then the
##     picture is drawn (no room is made); [code]^L[/code] moves the next
##     word to a line and x; [code]^C[/code] sets the colour; [code]^B[/code]
##     fills a bar with the background colour.
## The result is a list of [Stage]s: what the screen shows and for how long
## (the last stage stays until the reader goes on).


## One picture of the page and how long it is shown before the next.
class Stage:
	extends RefCounted
	var image: Image
	## Tics; 0 for the last stage (shown until a key).
	var tics := 0


const SCREEN_SIZE := Vector2i(320, 200)
const LINE_COUNT := 18
const LINE_HEIGHT := 10
const FIRST_LINE_Y := 10
const LEFT := 10
const RIGHT := 310
const SPACE_WIDTH := 7
const PICTURE_ALIGN := 8
const PICTURE_MARGIN := 8
const MIDDLE := 160
const SPACE := 0x20
const COMMAND_NUMBERS := {
	0x47: 3,  # G: y, x, picture
	0x54: 4,  # T: y, x, picture, tics
	0x4C: 2,  # L: y, x
	0x42: 4,  # B: y, x, width, height
}

## The colour (EGA index) the page is filled with.
var background := 7
## The colour of text before a ^C.
var default_color := 8
## The chunk number of the first picture: ^G numbers are chunk numbers.
var first_picture_chunk := 0
var _graphics: GalaxyGraphics
var _font: GalaxyFont
var _image: Image
var _stages: Array[Stage] = []
var _text: PackedByteArray
var _at := 0
var _stop := 0
var _line := 0
var _x := LEFT
var _y := FIRST_LINE_Y
var _color := Color.BLACK
var _line_starts := PackedInt32Array()
var _line_ends := PackedInt32Array()
var _full := false


static func create(graphics: GalaxyGraphics, font_index: int) -> GalaxyPageLayout:
	var layout := GalaxyPageLayout.new()
	layout._graphics = graphics
	layout._font = graphics.font(font_index)
	layout.first_picture_chunk = graphics.ranges.picture_start
	return layout


## Page [param index] of [param pages] drawn; its stages in order.
func lay_out(pages: GalaxyTextPages, index: int) -> Array[Stage]:
	_stages = []
	_image = Image.create_empty(SCREEN_SIZE.x, SCREEN_SIZE.y, false, Image.FORMAT_RGBA8)
	_image.fill(EgaPalette.color(background))
	if index < 0 or index >= pages.page_count() or _font == null:
		_finish()
		return _stages
	_text = pages.bytes
	_at = pages.page_starts[index]
	_stop = pages.page_end(index)
	_line = 0
	_x = LEFT
	_y = FIRST_LINE_Y
	_full = false
	_color = EgaPalette.color(default_color)
	_line_starts.resize(LINE_COUNT)
	_line_ends.resize(LINE_COUNT)
	_line_starts.fill(LEFT)
	_line_ends.fill(RIGHT)
	while not _full and _at < _stop:
		var character := _text[_at]
		if character == GalaxyTextPages.CARET:
			_command()
		elif character <= SPACE:
			_at += 1
			if character == GalaxyTextPages.NEWLINE:
				_new_line()
		else:
			_word()
	_finish()
	return _stages


## Text in the page's font at [param at] in [param color] (the page
## numbers of the help).
func print_at(text: String, at: Vector2i, color: int) -> void:
	if _font != null and _image != null:
		_draw_text(text, at, EgaPalette.color(color))


func _finish() -> void:
	var last := Stage.new()
	last.image = _image
	_stages.append(last)


func _command() -> void:
	var letter := GalaxyTextPages.command_at(_text, _at)
	_at += 2
	if letter == GalaxyTextPages.PAGE or letter == GalaxyTextPages.END:
		_full = true
		return
	if letter == 0x43:
		_set_color()
		return
	if not COMMAND_NUMBERS.has(letter):
		return
	var found := GalaxyTextPages.numbers_at(_text, _at, COMMAND_NUMBERS[letter])
	_at = GalaxyTextPages.line_end(_text, found[-1])
	match letter:
		0x47:
			_picture(found[1], found[0], found[2], true)
		0x54:
			var shown := Stage.new()
			shown.image = _image.duplicate() as Image
			shown.tics = found[3]
			_stages.append(shown)
			_picture(found[1], found[0], found[2], false)
		0x4C:
			_line = clampi((found[0] - FIRST_LINE_Y) / LINE_HEIGHT, 0, LINE_COUNT - 1)
			_y = _line * LINE_HEIGHT + FIRST_LINE_Y
			_x = found[1]
		0x42:
			var bar := Rect2i(found[1], found[0], found[2], found[3])
			_image.fill_rect(bar, EgaPalette.color(background))


## ^C and one hex digit: the colour of the text after it.
func _set_color() -> void:
	if _at >= _text.size():
		return
	var digit := String.chr(_text[_at])
	_at += 1
	if digit.is_valid_hex_number():
		_color = EgaPalette.color(digit.hex_to_int())


## Picture of chunk [param chunk] at ([param x], [param y]); with
## [param wraps] the lines it covers leave room for it.
func _picture(x: int, y: int, chunk: int, wraps: bool) -> void:
	var index := chunk - first_picture_chunk
	var picture := _graphics.picture(index)
	if picture == null:
		push_error("A text page asks for chunk %d, which is no picture." % chunk)
		return
	if picture.get_format() != Image.FORMAT_RGBA8:
		picture = picture.duplicate() as Image
		picture.convert(Image.FORMAT_RGBA8)
	var left := x - posmod(x, PICTURE_ALIGN)
	_image.blit_rect(picture, Rect2i(Vector2i.ZERO, picture.get_size()), Vector2i(left, y))
	if not wraps:
		return
	var size := picture.get_size()
	var middle := x + size.x / 2
	var first := maxi((y - FIRST_LINE_Y) / LINE_HEIGHT, 0)
	var last := mini((y + size.y - FIRST_LINE_Y) / LINE_HEIGHT, LINE_COUNT - 1)
	for line in range(first, last + 1):
		if middle > MIDDLE:
			_line_ends[line] = x - PICTURE_MARGIN
		else:
			_line_starts[line] = x + size.x + PICTURE_MARGIN
	if _line_starts[_line] > _x:
		_x = _line_starts[_line]


func _word() -> void:
	var start := _at
	_at += 1
	while _at < _text.size() and _text[_at] > SPACE:
		_at += 1
	var word := _text.slice(start, _at).get_string_from_ascii()
	var width := _font.text_width(word)
	while _line_ends[_line] < _x + width:
		_new_line()
		if _full:
			return
	_draw_text(word, Vector2i(_x, _y), _color)
	_x += width
	while _at < _text.size() and _text[_at] == SPACE:
		_x += SPACE_WIDTH
		_at += 1


func _new_line() -> void:
	_line += 1
	if _line == LINE_COUNT:
		_full = true
		return
	_x = _line_starts[_line]
	_y += LINE_HEIGHT


func _draw_text(text: String, at: Vector2i, color: Color) -> void:
	var picture := _font.render(text, color)
	_image.blend_rect(picture, Rect2i(Vector2i.ZERO, picture.get_size()), at)
