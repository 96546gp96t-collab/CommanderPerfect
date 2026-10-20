class_name GalaxyStoryScroller
extends RefCounted
## The story text of a Galaxy episode's title loop, scrolling away into the
## distance over a picture (Omni `ck_inter.c`: CK_DrawStarWars,
## CK_PrepareSWUpdate, CK_ScrollSWText; facts and numbers only):
##   - the text is printed in the large font, each line centred on a strip
##     336 pixels wide, from y 1 down; its characters are the font's own
##     numbers (capitals from 32, small letters from 58, a few signs after);
##   - every screen row shows one row of that strip, squeezed to a width
##     that shrinks from 320 pixels at the bottom by 0xB33/2048 pixel a row
##     going up, rows further up stepping further through the strip;
##   - the strip moves one row every 4 tics, until it has moved its height
##     and 400 more;
##   - where the text lies only the text's colour bit is written: inside the
##     squeezed rows the picture loses its bright colours, the text is white;
##     the picture's own colours there are the original's palette for this
##     part (magenta shows dark grey).
## [GalaxyTitleLayer] draws it with a shader from [method row_table].

const STRIP_WIDTH := 336
const SCREEN_SIZE := Vector2i(320, 200)
## 1/2048 pixel, the scroller's unit.
const UNIT_SHIFT := 11
const BOTTOM_WIDTH := 320
const WIDTH_STEP := 0xB33
const TICS_PER_ROW := 4
const EXTRA_ROWS := 400
const FIRST_ROW := 1
const TEXT_COLOR := Color.WHITE
## The palette of this part, per colour of the picture (EGA numbers).
const PICTURE_COLORS: PackedInt32Array = [0, 1, 2, 3, 4, 8, 6, 7, 15, 15, 15, 15, 15, 15, 15, 15]
const BRIGHT_BIT := 8
const CAPITAL_A := 0x41
const CAPITAL_Z := 0x5A
const SMALL_A := 0x61
const SMALL_Z := 0x7A
const CAPITAL_SHIFT := 33
const SMALL_SHIFT := 39
const NEWLINE := 0x0A
## The signs the font has, and the number each prints as; anything else
## prints as a full stop.
const SIGNS := {0x2E: 0x54, 0x2C: 0x55, 0x2D: 0x56, 0x22: 0x57, 0x20: 0x58, 0x21: 0x59, 0x27: 0x5A}
const FULL_STOP := 0x54

## The text printed on the strip, white on black.
var strip: Image
## How many rows of the strip hold text.
var strip_height := 0
## The picture behind it as shown outside and inside the squeezed rows.
var outside: Image
var inside: Image


## The scroller for [param text] in [param font] over [param picture].
static func create(text: String, font: GalaxyFont, picture: Image) -> GalaxyStoryScroller:
	var scroller := GalaxyStoryScroller.new()
	scroller._print_strip(text, font)
	scroller._colour_picture(picture)
	return scroller


## How long the whole scroll takes, in tics.
func total_tics() -> int:
	return (strip_height + EXTRA_ROWS + 1) * TICS_PER_ROW


## How far the strip has moved after [param tics] tics.
static func distance_after(tics: int) -> int:
	return tics / TICS_PER_ROW


## [param text] in the font's own character numbers.
static func translate(text: String) -> String:
	var out := ""
	for index in text.length():
		var character := text.unicode_at(index)
		if character >= CAPITAL_A and character <= CAPITAL_Z:
			character -= CAPITAL_SHIFT
		elif character >= SMALL_A and character <= SMALL_Z:
			character -= SMALL_SHIFT
		elif character != NEWLINE:
			character = SIGNS.get(character, FULL_STOP)
		out += String.chr(character)
	return out


## Per screen row (bottom row 199 first in the loop, stored by row): the
## width in pixels, the strip row it starts at (behind the scroll), and the
## step between pixels in 1/2048 pixel. As an image of 1 × 200 float
## pixels (red, green, blue) for the shader.
static func row_table() -> Image:
	var table := Image.create_empty(1, SCREEN_SIZE.y, false, Image.FORMAT_RGBF)
	var width := BOTTOM_WIDTH << UNIT_SHIFT
	var strip_row := 0
	for row in range(SCREEN_SIZE.y - 1, -1, -1):
		var pixels := ((width / 2) >> UNIT_SHIFT) * 2
		var step := (STRIP_WIDTH << UNIT_SHIFT) / maxi(pixels, 1)
		table.set_pixel(0, row, Color(pixels, strip_row >> UNIT_SHIFT, step))
		strip_row += step
		width -= WIDTH_STEP
	return table


func _print_strip(text: String, font: GalaxyFont) -> void:
	var lines := text.split("\n")
	if text.ends_with("\n"):
		lines.resize(lines.size() - 1)
	var height := font.height if font != null else 0
	strip_height = FIRST_ROW + lines.size() * height
	strip = Image.create_empty(STRIP_WIDTH, maxi(strip_height, 1), false, Image.FORMAT_RGBA8)
	strip.fill(Color.BLACK)
	if font == null:
		return
	var y := FIRST_ROW
	for line in lines:
		var printed := translate(line)
		var picture := font.render(printed, TEXT_COLOR)
		var x := (STRIP_WIDTH - font.text_width(printed)) / 2
		strip.blend_rect(picture, Rect2i(Vector2i.ZERO, picture.get_size()), Vector2i(x, y))
		y += height


func _colour_picture(picture: Image) -> void:
	outside = Image.create_empty(SCREEN_SIZE.x, SCREEN_SIZE.y, false, Image.FORMAT_RGBA8)
	inside = Image.create_empty(SCREEN_SIZE.x, SCREEN_SIZE.y, false, Image.FORMAT_RGBA8)
	if picture == null:
		return
	for y in mini(picture.get_height(), SCREEN_SIZE.y):
		for x in mini(picture.get_width(), SCREEN_SIZE.x):
			var index := maxi(GalaxyEga.index_of(picture.get_pixel(x, y)), 0)
			outside.set_pixel(x, y, EgaPalette.color(PICTURE_COLORS[index]))
			inside.set_pixel(x, y, EgaPalette.color(PICTURE_COLORS[index & (BRIGHT_BIT - 1)]))
