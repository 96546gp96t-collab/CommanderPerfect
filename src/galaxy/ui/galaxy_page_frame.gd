class_name GalaxyPageFrame
extends RefCounted
## The border around the text pages of later releases (Keen 4 v1.4; Omni
## `ck_text.c`: PageLayout, ShowHelp; facts only; seen in the original
## v1.4, D13): five pictures in a row of the picture range, the top (320 ×
## 8) at (0, 0), the left and right sides (8 × 192) at (0, 8) and (312, 8),
## and at the bottom either the bar of a help page (304 × 24, "PAGE / ESC
## EXITS" and a box for the page number) at (8, 176) or a plain edge (304 ×
## 8) at (8, 192). v1.0 has none of these pictures and draws its pages
## without a border.
##
## The pictures are recognised by their sizes ([method find]), never by
## their chunk numbers.

enum Piece { TOP, LEFT, RIGHT, STATUS_BOTTOM, BOTTOM }

## The size and the place of each piece, in [enum Piece]'s order.
const SIZES: Array[Vector2i] = [
	Vector2i(320, 8), Vector2i(8, 192), Vector2i(8, 192), Vector2i(304, 24), Vector2i(304, 8)
]
const PLACES: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(0, 8), Vector2i(312, 8), Vector2i(8, 176), Vector2i(8, 192)
]

## The picture of the first piece (the top); the others follow it.
var first_picture := 0
var _graphics: GalaxyGraphics


## The frame whose top is picture [param first] of [param graphics], or
## null when the pictures from there do not have the frame's sizes.
static func find(graphics: GalaxyGraphics, first: int) -> GalaxyPageFrame:
	if first < 0 or first + SIZES.size() > graphics.ranges.picture_count:
		return null
	for piece in SIZES.size():
		if graphics.picture_size(first + piece) != SIZES[piece]:
			return null
	var frame := GalaxyPageFrame.new()
	frame.first_picture = first
	frame._graphics = graphics
	return frame


## Draws the frame on [param image] (320 × 200); [param with_status] puts
## the help's bar at the bottom instead of the plain edge.
func draw(image: Image, with_status: bool) -> void:
	var bottom := Piece.STATUS_BOTTOM if with_status else Piece.BOTTOM
	for piece: Piece in [Piece.TOP, Piece.LEFT, Piece.RIGHT, bottom]:
		var picture := _graphics.picture(first_picture + piece)
		if picture == null:
			continue
		if picture.get_format() != image.get_format():
			picture = picture.duplicate() as Image
			picture.convert(image.get_format())
		image.blit_rect(picture, Rect2i(Vector2i.ZERO, picture.get_size()), PLACES[piece])
