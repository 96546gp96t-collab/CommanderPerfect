class_name ScaledGraphics
extends RefCounted
## The game graphics at a higher resolution: every font character, tile,
## bitmap and sprite, and the picture of Keen's house, [member factor] times
## as large as the original. Made by xBRZ ([method with_xbrz]) or read from
## the player's own HD graphics ([HdPack]).
##
## [GraphicsTextures] draws them at their original size, so the game never
## needs to know which graphics it is showing.

var factor := 1
var style := DisplaySettings.Graphics.ORIGINAL
var font_chars: Array[Image] = []
var tiles: Array[Image] = []
var bitmaps: Array[Image] = []
var sprites: Array[Image] = []
## The picture of Keen's house; null when FINALE.CK1 could not be read.
var finale: Image


## [param graphics] and [param finale_image] (may be null) scaled
## [param scale_factor] times with [XbrzScaler], one image after the other.
## [GraphicsLoader] does the same spread over all processor cores.
static func with_xbrz(
	graphics: EgaGraphics, finale_image: Image, scale_factor: int
) -> ScaledGraphics:
	var images: Array[Image] = []
	for image in originals(graphics, finale_image):
		images.append(XbrzScaler.scale(image, scale_factor))
	return from_images(graphics, finale_image, images, scale_factor)


## Every original image in one list: font characters, tiles, bitmaps,
## sprites and (when there is one) the picture of Keen's house.
static func originals(graphics: EgaGraphics, finale_image: Image) -> Array[Image]:
	var images: Array[Image] = []
	images.append_array(graphics.font_chars)
	images.append_array(graphics.tiles)
	images.append_array(graphics.bitmaps)
	images.append_array(graphics.sprites)
	if finale_image != null:
		images.append(finale_image)
	return images


## xBRZ graphics from [param images], the scaled versions of
## [method originals] in the same order.
static func from_images(
	graphics: EgaGraphics, finale_image: Image, images: Array[Image], scale_factor: int
) -> ScaledGraphics:
	var scaled := ScaledGraphics.new()
	scaled.factor = scale_factor
	scaled.style = DisplaySettings.Graphics.XBRZ
	var start := 0
	for part: String in ["font_chars", "tiles", "bitmaps", "sprites"]:
		var count: int = graphics.get(part).size()
		scaled.get(part).assign(images.slice(start, start + count))
		start += count
	if finale_image != null and start < images.size():
		scaled.finale = images[start]
	return scaled


## Whether there is a scaled image for every original one.
func matches(graphics: EgaGraphics) -> bool:
	return (
		font_chars.size() == graphics.font_chars.size()
		and tiles.size() == graphics.tiles.size()
		and bitmaps.size() == graphics.bitmaps.size()
		and sprites.size() == graphics.sprites.size()
	)


## The scaled version of [param processed], an image made from an original
## one (such as a tile with its background made transparent).
## [param scaled_base] is the scaled version of that original image. xBRZ
## simply scales the result again; HD graphics keep their own colors and
## take the transparency from xBRZ.
func derive(processed: Image, scaled_base: Image) -> Image:
	var smooth := XbrzScaler.scale(processed, factor)
	if style == DisplaySettings.Graphics.XBRZ or scaled_base == null:
		return smooth
	var result := scaled_base.duplicate() as Image
	result.convert(Image.FORMAT_RGBA8)
	if result.get_size() != smooth.get_size():
		return smooth
	for y in result.get_height():
		for x in result.get_width():
			var color := result.get_pixel(x, y)
			color.a = minf(color.a, smooth.get_pixel(x, y).a)
			result.set_pixel(x, y, color)
	return result
