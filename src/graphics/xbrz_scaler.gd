class_name XbrzScaler
extends RefCounted
## Scales pixel art up by a whole factor in the style of xBRZ: edges that run
## diagonally through the pixels get smooth lines, while straight edges and
## flat areas stay exactly as they are.
##
## Our own implementation of the idea behind xBRZ (see docs/graphics.md):
##   1. For every 2x2 square of source pixels, compare how alike the colors
##      are along both diagonals of the surrounding 4x4 pixels. When one
##      diagonal clearly forms a line, the two pixels on the other diagonal
##      get the corner that touches that line marked for blending.
##   2. Each marked corner is then blended with the color across the line.
##      The neighbours decide the shape of that line: a small cut off the
##      corner, a 45 degree line, a shallow or a steep line (1:2), or both.
## The blended part of every output pixel is its covered area, found by
## sampling, so any factor works.
##
## Meant for images with few colors (the 16 EGA colors plus transparency):
## the distance between every pair of colors is worked out once.

enum Blend { NONE, NORMAL, DOMINANT }
## The shapes of the blended part of a corner.
enum Shape { CORNER, DIAGONAL, SHALLOW, STEEP, SHALLOW_AND_STEEP }

## Colors closer than this (on a 0-255 scale) count as equal.
const EQUAL_COLOR_TOLERANCE := 30.0
## How much more alike one diagonal has to be than the other for its line to
## always be blended as a line (instead of only when the neighbours agree).
const DOMINANT_DIRECTION_THRESHOLD := 3.6
## How much more alike one direction has to be for a shallow or steep line.
const STEEP_DIRECTION_THRESHOLD := 2.2
## Weight of the two pixels in the middle of a diagonal.
const CENTER_WEIGHT := 4.0
const LUMA_WEIGHT := 1.0
## Share of red and blue in the brightness (ITU-R BT.2020).
const LUMA_RED := 0.2627
const LUMA_BLUE := 0.0593
## Most colors an image may have; the distance table grows with its square.
const MAX_COLORS := 256
## Pixels of source border copied around the image, for the 4x4 kernel.
const BORDER := 2
const CHANNELS := 4
## Corner of a pixel, as bit position of its blend type in the corner byte.
const BOTTOM_RIGHT := 0
const BOTTOM_LEFT := 2
const TOP_LEFT := 4
const TOP_RIGHT := 6
const BLEND_MASK := 3
## Samples per side when working out how much of an output pixel a line
## covers.
const SAMPLES := 4

## The lines, as a half plane a*u + b*v >= t inside the pixel (u to the
## right, v down, both 0-1, with the blended corner at (1, 1)).
## A cut off the corner with the same area as the 21% xBRZ uses at 2x.
const CORNER_LINE := Vector3(1.0, 1.0, 1.676)
## From the middle of the right side to the middle of the bottom side.
const DIAGONAL_LINE := Vector3(1.0, 1.0, 1.5)
## From the bottom left corner to the middle of the right side.
const SHALLOW_LINE := Vector3(0.5, 1.0, 1.0)
## From the top right corner to the middle of the bottom side.
const STEEP_LINE := Vector3(1.0, 0.5, 1.0)

## Per factor, then per [enum Shape]: the output pixels (numbered row by
## row within one source pixel, corner at the bottom right) that the shape
## covers, and how much of each it covers. Shared by all threads.
static var _shapes_by_factor: Dictionary[int, Array] = {}
static var _shapes_lock := Mutex.new()

var _width := 0
var _height := 0
var _padded_width := 0
## Color index of every pixel, with a border of [constant BORDER] copied
## edge pixels around the image.
var _indices := PackedInt32Array()
## The colors, as RGBA bytes.
var _colors: Array[PackedByteArray] = []
## Distance between colors i and j at i * color count + j.
var _distances := PackedFloat32Array()
## The blend type of each of the four corners of every pixel.
var _corners := PackedByteArray()
## The shapes at the factor being scaled to, from [member _shapes_by_factor].
var _shape_pixels: Array = []
var _shape_covers: Array = []


## [param image] scaled up [param factor] times. The result is RGBA8.
static func scale(image: Image, factor: int) -> Image:
	var source := image.duplicate() as Image
	source.convert(Image.FORMAT_RGBA8)
	var result := source.duplicate() as Image
	result.resize(
		source.get_width() * factor, source.get_height() * factor, Image.INTERPOLATE_NEAREST
	)
	if factor <= 1:
		return result
	if source.is_invisible() or _is_one_color(source):
		return result
	var scaler := XbrzScaler.new()
	if not scaler._read(source):
		push_error(
			"xBRZ: the image has more than %d colors; scaled without smoothing." % MAX_COLORS
		)
		return result
	scaler._find_corners()
	var data := result.get_data()
	scaler._measure_shapes(factor)
	scaler._blend_all(data, factor)
	return Image.create_from_data(
		result.get_width(), result.get_height(), false, Image.FORMAT_RGBA8, data
	)


## Whether every pixel of [param image] has the same color: then there is
## nothing to smooth.
static func _is_one_color(image: Image) -> bool:
	var data := image.get_data()
	var first := data.decode_u32(0)
	for offset in range(CHANNELS, data.size(), CHANNELS):
		if data.decode_u32(offset) != first:
			return false
	return true


## Distance between two RGBA colors (bytes), on a 0-255 scale. Fully
## transparent colors are all the same; a difference in transparency counts
## fully.
static func color_distance(first: PackedByteArray, second: PackedByteArray) -> float:
	var alpha_first := first[3] / 255.0
	var alpha_second := second[3] / 255.0
	if alpha_first == 0.0 and alpha_second == 0.0:
		return 0.0
	var red := float(first[0] - second[0])
	var green := float(first[1] - second[1])
	var blue := float(first[2] - second[2])
	var luma := LUMA_RED * red + (1.0 - LUMA_RED - LUMA_BLUE) * green + LUMA_BLUE * blue
	var chroma_blue := 0.5 / (1.0 - LUMA_BLUE) * (blue - luma)
	var chroma_red := 0.5 / (1.0 - LUMA_RED) * (red - luma)
	var color := sqrt(pow(LUMA_WEIGHT * luma, 2) + pow(chroma_blue, 2) + pow(chroma_red, 2))
	return minf(alpha_first, alpha_second) * color + 255.0 * absf(alpha_first - alpha_second)


## Builds the color indices and the distance table. Returns false when the
## image has too many colors.
func _read(source: Image) -> bool:
	_width = source.get_width()
	_height = source.get_height()
	_padded_width = _width + 2 * BORDER
	var data := source.get_data()
	var lookup: Dictionary[int, int] = {}
	var pixel_indices := PackedInt32Array()
	pixel_indices.resize(_width * _height)
	for pixel in _width * _height:
		var offset := pixel * CHANNELS
		var key := data.decode_u32(offset)
		if data[offset + 3] == 0:
			key = 0  # every transparent pixel is the same color
		if not lookup.has(key):
			if lookup.size() >= MAX_COLORS:
				return false
			lookup[key] = _colors.size()
			_colors.append(data.slice(offset, offset + CHANNELS))
		pixel_indices[pixel] = lookup[key]
	_indices.resize(_padded_width * (_height + 2 * BORDER))
	for y in _height + 2 * BORDER:
		var source_y := clampi(y - BORDER, 0, _height - 1)
		for x in _padded_width:
			var source_x := clampi(x - BORDER, 0, _width - 1)
			_indices[y * _padded_width + x] = pixel_indices[source_y * _width + source_x]
	var count := _colors.size()
	_distances.resize(count * count)
	for i in count:
		for j in count:
			_distances[i * count + j] = color_distance(_colors[i], _colors[j])
	return true


## The color index at [param x], [param y]; may be up to [constant BORDER]
## pixels outside the image.
func _at(x: int, y: int) -> int:
	return _indices[(y + BORDER) * _padded_width + x + BORDER]


func _distance(first: int, second: int) -> float:
	return _distances[first * _colors.size() + second]


func _equal(first: int, second: int) -> bool:
	return _distance(first, second) < EQUAL_COLOR_TOLERANCE


## Step 1: marks the corners to blend, looking at every 2x2 square
##   . b c .
##   e f g h      f is at (x, y)
##   i j k l
##   . n o .
func _find_corners() -> void:
	_corners.resize(_width * _height)
	_corners.fill(0)
	# Read straight from the arrays: this loop runs for every pixel.
	var indices := _indices
	var distances := _distances
	var count := _colors.size()
	var row := _padded_width
	for y in range(-1, _height):
		var start := (y + BORDER) * row + BORDER
		for x in range(-1, _width):
			var at := start + x
			var f := indices[at]
			var g := indices[at + 1]
			var j := indices[at + row]
			var k := indices[at + row + 1]
			# Flat, or an edge that runs straight along the pixels.
			if (f == g and j == k) or (f == j and g == k):
				continue
			var along_jg := (
				distances[indices[at + row - 1] * count + f]
				+ distances[f * count + indices[at - row + 1]]
				+ distances[indices[at + 2 * row] * count + k]
				+ distances[k * count + indices[at + 2]]
				+ CENTER_WEIGHT * distances[j * count + g]
			)
			var along_fk := (
				distances[indices[at - 1] * count + j]
				+ distances[j * count + indices[at + 2 * row + 1]]
				+ distances[indices[at - row] * count + g]
				+ distances[g * count + indices[at + row + 2]]
				+ CENTER_WEIGHT * distances[f * count + k]
			)
			if along_jg < along_fk:
				var blend := _blend_type(along_jg, along_fk)
				if f != g and f != j:
					_mark(x, y, BOTTOM_RIGHT, blend)
				if k != j and k != g:
					_mark(x + 1, y + 1, TOP_LEFT, blend)
			elif along_fk < along_jg:
				var blend := _blend_type(along_fk, along_jg)
				if j != f and j != k:
					_mark(x, y + 1, TOP_RIGHT, blend)
				if g != f and g != k:
					_mark(x + 1, y, BOTTOM_LEFT, blend)


static func _blend_type(line: float, across: float) -> Blend:
	return Blend.DOMINANT if DOMINANT_DIRECTION_THRESHOLD * line < across else Blend.NORMAL


func _mark(x: int, y: int, corner: int, blend: Blend) -> void:
	if x < 0 or y < 0 or x >= _width or y >= _height:
		return
	_corners[y * _width + x] |= blend << corner


func _corner(x: int, y: int, direction: Vector2i) -> int:
	var bits := _corners[y * _width + x]
	return (bits >> _corner_bit(direction)) & BLEND_MASK


static func _corner_bit(direction: Vector2i) -> int:
	if direction.y > 0:
		return BOTTOM_RIGHT if direction.x > 0 else BOTTOM_LEFT
	return TOP_RIGHT if direction.x > 0 else TOP_LEFT


## Step 2: blends every marked corner into [param data], the image already
## scaled up [param factor] times without smoothing.
func _blend_all(data: PackedByteArray, factor: int) -> void:
	for y in _height:
		for x in _width:
			if _corners[y * _width + x] == 0:
				continue
			for direction: Vector2i in [
				Vector2i(1, 1), Vector2i(-1, 1), Vector2i(-1, -1), Vector2i(1, -1)
			]:
				if _corner(x, y, direction) != Blend.NONE:
					_blend_corner(data, factor, x, y, direction)


## Blends the corner of pixel ([param x], [param y]) in [param direction].
## The neighbours are named as if that corner is the bottom right one:
##   a b c
##   d e f
##   g h i
func _blend_corner(data: PackedByteArray, factor: int, x: int, y: int, direction: Vector2i) -> void:
	var dx := direction.x
	var dy := direction.y
	var b := _at(x, y - dy)
	var c := _at(x + dx, y - dy)
	var d := _at(x - dx, y)
	var e := _at(x, y)
	var f := _at(x + dx, y)
	var g := _at(x - dx, y + dy)
	var h := _at(x, y + dy)
	var i := _at(x + dx, y + dy)
	var color := f if _distance(e, f) <= _distance(e, h) else h
	var shape := Shape.CORNER
	if _blends_as_line(x, y, direction, [c, e, f, g, h, i]):
		var across_fg := _distance(f, g)
		var across_hc := _distance(h, c)
		var shallow := STEEP_DIRECTION_THRESHOLD * across_fg <= across_hc and e != g and d != g
		var steep := STEEP_DIRECTION_THRESHOLD * across_hc <= across_fg and e != c and b != c
		if shallow and steep:
			shape = Shape.SHALLOW_AND_STEEP
		elif shallow:
			shape = Shape.SHALLOW
		elif steep:
			shape = Shape.STEEP
		else:
			shape = Shape.DIAGONAL
	_paint(data, factor, Vector2i(x, y), direction, shape, _colors[color])


## Whether the corner gets a full line, not just a small cut. Not when a
## neighbouring corner of the same pixel blends too (a lone pixel), nor for
## the inside of an L shape.
func _blends_as_line(x: int, y: int, direction: Vector2i, kernel: Array) -> bool:
	var c: int = kernel[0]
	var e: int = kernel[1]
	var f: int = kernel[2]
	var g: int = kernel[3]
	var h: int = kernel[4]
	var i: int = kernel[5]
	if _corner(x, y, direction) == Blend.DOMINANT:
		return true
	if _corner(x, y, Vector2i(direction.x, -direction.y)) != Blend.NONE and not _equal(e, g):
		return false
	if _corner(x, y, Vector2i(-direction.x, direction.y)) != Blend.NONE and not _equal(e, c):
		return false
	return not (
		not _equal(e, i) and _equal(g, h) and _equal(h, i) and _equal(i, f) and _equal(f, c)
	)


## Looks up which output pixels each [enum Shape] covers at
## [param factor], working it out the first time.
func _measure_shapes(factor: int) -> void:
	_shapes_lock.lock()
	if not _shapes_by_factor.has(factor):
		_shapes_by_factor[factor] = _shapes_at(factor)
	var shapes: Array = _shapes_by_factor[factor]
	_shapes_lock.unlock()
	_shape_pixels = shapes[0]
	_shape_covers = shapes[1]


static func _shapes_at(factor: int) -> Array:
	var all_pixels: Array[PackedInt32Array] = []
	var all_covers: Array[PackedFloat32Array] = []
	var shape_lines: Array[Array] = [
		[CORNER_LINE], [DIAGONAL_LINE], [SHALLOW_LINE], [STEEP_LINE], [SHALLOW_LINE, STEEP_LINE]
	]
	for lines in shape_lines:
		var pixels := PackedInt32Array()
		var covers := PackedFloat32Array()
		for local_y in factor:
			for local_x in factor:
				var typed_lines: Array[Vector3] = []
				typed_lines.assign(lines)
				var cover := _coverage(local_x, local_y, factor, typed_lines)
				if cover > 0.0:
					pixels.append(local_y * factor + local_x)
					covers.append(cover)
		all_pixels.append(pixels)
		all_covers.append(covers)
	return [all_pixels, all_covers]


## Mixes [param color] into the output pixels of [param source_pixel] that
## [param shape] covers (in the frame where the corner in [param direction]
## is the bottom right one).
func _paint(
	data: PackedByteArray,
	factor: int,
	source_pixel: Vector2i,
	direction: Vector2i,
	shape: Shape,
	color: PackedByteArray
) -> void:
	var out_width := _width * factor
	var pixels: PackedInt32Array = _shape_pixels[shape]
	var covers: PackedFloat32Array = _shape_covers[shape]
	for n in pixels.size():
		var local_x := pixels[n] % factor
		var local_y := pixels[n] / factor
		var out_x := local_x if direction.x > 0 else factor - 1 - local_x
		var out_y := local_y if direction.y > 0 else factor - 1 - local_y
		var pixel := (source_pixel.y * factor + out_y) * out_width + source_pixel.x * factor + out_x
		_mix(data, pixel * CHANNELS, color, covers[n])


## How much of output pixel ([param local_x], [param local_y]) lies beyond
## any of [param lines], from 0 to 1.
static func _coverage(local_x: int, local_y: int, factor: int, lines: Array[Vector3]) -> float:
	var low := Vector2(local_x, local_y) / factor
	var high := Vector2(local_x + 1, local_y + 1) / factor
	var any_partial := false
	for line in lines:
		var lowest := line.x * low.x + line.y * low.y
		var highest := line.x * high.x + line.y * high.y
		if lowest >= line.z:
			return 1.0
		if highest > line.z:
			any_partial = true
	if not any_partial:
		return 0.0
	var inside := 0
	for sample_y in SAMPLES:
		for sample_x in SAMPLES:
			var u := low.x + (sample_x + 0.5) / (SAMPLES * factor)
			var v := low.y + (sample_y + 0.5) / (SAMPLES * factor)
			for line in lines:
				if line.x * u + line.y * v >= line.z:
					inside += 1
					break
	return float(inside) / (SAMPLES * SAMPLES)


## Mixes [param color] into the pixel at [param offset] for [param amount],
## weighing the colors by their opacity.
static func _mix(data: PackedByteArray, offset: int, color: PackedByteArray, amount: float) -> void:
	var alpha_old := data[offset + 3] / 255.0 * (1.0 - amount)
	var alpha_new := color[3] / 255.0 * amount
	var alpha := alpha_old + alpha_new
	if alpha <= 0.0:
		data[offset + 3] = 0
		return
	for channel in 3:
		var mixed := (data[offset + channel] * alpha_old + color[channel] * alpha_new) / alpha
		data[offset + channel] = roundi(mixed)
	data[offset + 3] = roundi(alpha * 255.0)
