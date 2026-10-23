extends "res://tests/test_case.gd"
## Keen 4's help pages as each release draws them, without the player's
## files (milestone E13): since Keen 4 plays on the shared Galaxy game, its
## help is [GalaxyHelp] by Keen 4's rules, and the v1.4 way (red inside the
## frame of five pictures from picture 74) is the same code path as Keen
## 5's. [code]test_keen4_v14[/code] checks it with a real v1.4 copy and
## skips without one; this suite keeps the path tested with a made-up set
## of pictures: with the frame's pictures the menu is red inside the frame,
## the frame's top picture at the top and the page numbers in light red;
## without them (v1.0) it is light grey with dark grey text.

const PICTURE_COUNT := 80
const FRAME_PICTURE := Keen4Episode.PAGE_FRAME_PICTURE
const MENU_SIZE := Vector2i(128, 120)
const POINTER_SIZE := Vector2i(24, 16)
const RED := 4
const LIGHT_GREY := 7
const DARK_GREY := 8
const YELLOW := 14
const INSIDE := Vector2i(150, 190)
const TOP_COLOR := Color8(85, 255, 85)
const PIXELS_PER_BYTE := 8


func test_the_v1_4_help_is_red_inside_the_frame() -> void:
	var help := Keen4Help.create(_graphics(true))
	var menu := help.screen()
	assert_equal(menu.get_pixelv(INSIDE), EgaPalette.color(RED), "the menu on red")
	assert_equal(menu.get_pixel(5, 3), TOP_COLOR, "the frame's top picture at the top")
	var layout := GalaxyHelp.page_layout(_graphics(true), Keen4Episode.game_rules())
	assert_true(layout.frame != null, "the frame found from picture 74 by its sizes")
	assert_equal(layout.background, RED, "red pages")
	assert_equal(layout.default_color, YELLOW, "yellow text")


func test_the_v1_0_help_is_light_grey() -> void:
	var help := Keen4Help.create(_graphics(false))
	assert_equal(help.screen().get_pixelv(INSIDE), EgaPalette.color(LIGHT_GREY), "light grey")
	var layout := GalaxyHelp.page_layout(_graphics(false), Keen4Episode.game_rules())
	assert_true(layout.frame == null, "no frame in v1.0")
	assert_equal(layout.background, LIGHT_GREY, "grey pages")
	assert_equal(layout.default_color, DARK_GREY, "dark grey text")


## Pictures as a release has them: the help menu (0), the pointer (39)
## and, with [param framed], the frame's five pictures from 74 in their
## sizes ([constant GalaxyPageFrame.SIZES]); v1.0 has other pictures there.
static func _graphics(framed: bool) -> GalaxyGraphics:
	var graphics := GalaxyGraphics.new()
	graphics.ranges = GalaxyChunkRanges.new()
	graphics.ranges.picture_count = PICTURE_COUNT
	var sizes := PackedInt32Array()
	sizes.resize(PICTURE_COUNT * 2)
	var shown: Dictionary[int, Vector2i] = {
		Keen4Help.MENU_PICTURE: MENU_SIZE, Keen4Help.POINTER_PICTURE: POINTER_SIZE
	}
	for piece in GalaxyPageFrame.SIZES.size():
		shown[FRAME_PICTURE + piece] = (
			GalaxyPageFrame.SIZES[piece] if framed else Vector2i(PIXELS_PER_BYTE, 1)
		)
	for picture in shown:
		var size := shown[picture]
		sizes[picture * 2] = size.x / PIXELS_PER_BYTE
		sizes[picture * 2 + 1] = size.y
		var image := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
		image.fill(TOP_COLOR if picture == FRAME_PICTURE else Color.BLACK)
		graphics._cache["picture:%d" % picture] = image
	graphics._picture_sizes = sizes
	return graphics
