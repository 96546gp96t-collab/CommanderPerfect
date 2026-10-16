class_name DisplaySettings
extends RefCounted
## How the game picture is shaped: how many game pixels are visible, and how
## that picture is stretched to fit the window.
##
## The original runs at 320x200 on a 4:3 monitor, so its pixels are 1.2 times
## taller than wide. With [member correct_pixel_aspect] on, the picture is
## stretched the same way; with it off, pixels are square.
##
## [constant Aspect.ORIGINAL] shows exactly what the original showed.
## [constant Aspect.WIDESCREEN] keeps the same height and shows more of the
## level on the sides, enough to fill a 16:9 screen.
##
## The extras are off by default, so that the game looks like the original:
## [member graphics] picks the original pixels, xBRZ or the player's own HD
## graphics, and [member smooth_motion] draws everything in between the
## ticks (see docs/graphics.md).

enum Aspect { ORIGINAL, WIDESCREEN }
enum Graphics { ORIGINAL, XBRZ, HD }

const ORIGINAL_SIZE := Vector2i(320, 200)
const ORIGINAL_PIXEL_ASPECT := 1.2  # (4 / 3) / (320 / 200)
const WIDESCREEN_RATIO := 16.0 / 9.0

const GRAPHICS_NAMES: Array[String] = ["original", "xbrz", "hd"]

var aspect := Aspect.WIDESCREEN
var correct_pixel_aspect := true
var graphics := Graphics.ORIGINAL
var smooth_motion := false
## Whether levels that have a picture of their own show it behind them
## instead of their plain background (see [BackdropPictures]). Only in
## widescreen: the original picture stays as it was.
var backgrounds := true


## Size of the visible part of the level, in game pixels.
func game_size() -> Vector2i:
	if aspect == Aspect.ORIGINAL:
		return ORIGINAL_SIZE
	var width := ORIGINAL_SIZE.y * pixel_aspect() * WIDESCREEN_RATIO
	# Even, so that the view has a center on a whole pixel.
	return Vector2i(roundi(width / 2.0) * 2, ORIGINAL_SIZE.y)


## Height of one game pixel relative to its width.
func pixel_aspect() -> float:
	return ORIGINAL_PIXEL_ASPECT if correct_pixel_aspect else 1.0


## Shape of the picture on screen, before scaling it to the window.
func display_size() -> Vector2:
	var size := Vector2(game_size())
	return Vector2(size.x, size.y * pixel_aspect())


## The largest rectangle with the shape of [method display_size] that fits in
## [param window_size], centered.
func fit_rect(window_size: Vector2) -> Rect2:
	var shape := display_size()
	var scale := minf(window_size.x / shape.x, window_size.y / shape.y)
	var size := shape * scale
	return Rect2((window_size - size) / 2.0, size)


func aspect_name() -> String:
	return "original" if aspect == Aspect.ORIGINAL else "widescreen"


## Whether the picture is drawn exactly like the original: game pixels on
## whole positions, nothing in between.
## Whether pictures behind the levels are shown now.
func shows_backgrounds() -> bool:
	return backgrounds and aspect == Aspect.WIDESCREEN


func is_original_picture() -> bool:
	return graphics == Graphics.ORIGINAL and not smooth_motion


## Makes [param viewport] draw a view of [param game_size] game pixels at
## [param render_scale] screen pixels per game pixel. With
## [param smooth_textures] (scaled graphics) textures are drawn smoothly;
## the original pixels stay sharp.
static func set_up_viewport(
	viewport: SubViewport, game_size: Vector2i, render_scale: int, smooth_textures: bool
) -> void:
	viewport.size_2d_override = game_size
	viewport.size_2d_override_stretch = true
	if viewport.size != game_size * render_scale:
		viewport.size = game_size * render_scale
	# Snapping works in game pixels: right for the original picture, but it
	# would undo smooth motion on a larger viewport.
	viewport.snap_2d_transforms_to_pixel = render_scale == 1
	viewport.snap_2d_vertices_to_pixel = render_scale == 1
	viewport.canvas_item_default_texture_filter = (
		Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
		if smooth_textures
		else Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	)


static func graphics_name(style: Graphics) -> String:
	return GRAPHICS_NAMES[style]


## The graphics called [param style_name] (as [method graphics_name] gives
## it), or the original ones for an unknown name.
static func graphics_named(style_name: String) -> Graphics:
	var index := GRAPHICS_NAMES.find(style_name)
	return Graphics.ORIGINAL if index < 0 else index as Graphics
