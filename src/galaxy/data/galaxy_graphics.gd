class_name GalaxyGraphics
extends RefCounted
## Everything in EGAGRAPH, decoded only when asked for and kept afterwards:
## decoding all of it takes seconds in GDScript, and the start screen needs
## one sprite. Indices count inside each range ([GalaxyChunkRanges]),
## never chunk numbers.
##
## The pictures are stored a plane at a time: blue, green, red, intensity
## (checked against Keen 4 v1.0). Masked pictures, sprites and foreground
## tiles have a mask plane first (a set bit is see-through), then the four
## colour planes. See docs/keen4/file-formats.md.

const PLANE_COUNT := 4
const TILE8_SIZE := 8
const TILE16_SIZE := 16
const PIXELS_PER_BYTE := 8

var file: GalaxyGraphicsFile
var ranges: GalaxyChunkRanges
var sprite_infos: Array[GalaxySpriteInfo] = []
## Width in bytes and height of every picture, then of every masked picture.
var _picture_sizes := PackedInt32Array()
var _masked_picture_sizes := PackedInt32Array()
var _cache: Dictionary[String, Variant] = {}


## The graphics of the episode, with the chunk offsets and dictionary of
## [param headers]. Null when EGAGRAPH is missing or does not add up.
static func load_from(
	files: GameFiles, episode: GalaxyEpisode, headers: GalaxyHeaders
) -> GalaxyGraphics:
	var data := files.read(episode.file_name("EGAGRAPH"))
	if data.is_empty():
		return null
	return create(
		GalaxyGraphicsFile.create(data, headers.graphics_offsets, headers.graphics_dictionary),
		episode
	)


## The graphics in [param graphics_file]; null when its ranges do not add up.
static func create(graphics_file: GalaxyGraphicsFile, episode: GalaxyEpisode) -> GalaxyGraphics:
	var ranges := GalaxyChunkRanges.from_file(graphics_file, episode)
	if ranges == null:
		return null
	var graphics := GalaxyGraphics.new()
	graphics.file = graphics_file
	graphics.ranges = ranges
	graphics._picture_sizes = _sizes(graphics_file.expand(GalaxyChunkRanges.PICTURE_TABLE))
	graphics._masked_picture_sizes = _sizes(
		graphics_file.expand(GalaxyChunkRanges.MASKED_PICTURE_TABLE)
	)
	graphics.sprite_infos = GalaxySpriteInfo.parse_table(
		graphics_file.expand(GalaxyChunkRanges.SPRITE_TABLE)
	)
	return graphics


## The size of picture [param index] in pixels.
func picture_size(index: int) -> Vector2i:
	return _size_in(_picture_sizes, index)


## Picture [param index] (title screens, help pictures, ...); null outside
## the range.
func picture(index: int) -> Image:
	if index < 0 or index >= ranges.picture_count:
		return null
	return _cached("picture", index, _decode_picture.bind(index))


## Masked picture [param index]; null outside the range.
func masked_picture(index: int) -> Image:
	if index < 0 or index >= ranges.masked_picture_count:
		return null
	return _cached("masked_picture", index, _decode_masked_picture.bind(index))


## Sprite [param index] with its mask; null outside the range. Its origin
## and hit box are in [member sprite_infos].
func sprite(index: int) -> Image:
	if index < 0 or index >= ranges.sprite_count:
		return null
	return _cached("sprite", index, _decode_sprite.bind(index))


## 8×8 tile [param index] ([param masked]: one of the masked 8×8 tiles).
func tile8(index: int, masked := false) -> Image:
	var count := ranges.masked_tile8_count if masked else ranges.tile8_count
	if index < 0 or index >= count:
		return null
	var kind := "masked_tile8" if masked else "tile8"
	return _cached(kind, index, _decode_tile8.bind(index, masked))


## 16×16 background tile [param index]; null outside the set, and for a
## tile that is never drawn (an empty chunk).
func back_tile(index: int) -> Image:
	if index < 0 or index >= ranges.back_tile_count:
		return null
	return _cached("back_tile", index, _decode_tile16.bind(index, false))


## 16×16 foreground tile [param index] with its mask; null outside the set
## and for an empty tile.
func fore_tile(index: int) -> Image:
	if index < 0 or index >= ranges.fore_tile_count:
		return null
	return _cached("fore_tile", index, _decode_tile16.bind(index, true))


## Font [param index]; null outside the range.
func font(index: int) -> GalaxyFont:
	if index < 0 or index >= ranges.font_count:
		return null
	return _cached(
		"font",
		index,
		func() -> GalaxyFont: return GalaxyFont.parse(file.expand(ranges.font_start + index))
	)


## The bytes of text [param index] (help, story, ...; with the ^P/^G
## mark-up); empty outside the range.
func text(index: int) -> PackedByteArray:
	if index < 0 or index >= ranges.text_count:
		return PackedByteArray()
	return file.expand(ranges.text_start + index)


## The bytes of demo [param index]: its map number, its length, the input.
func demo(index: int) -> PackedByteArray:
	if index < 0 or index >= ranges.demo_count:
		return PackedByteArray()
	return file.expand(ranges.demo_start + index)


## The bytes of misc chunk [param index] (text screens, intro tables).
func misc(index: int) -> PackedByteArray:
	if index < 0 or index >= ranges.misc_count:
		return PackedByteArray()
	return file.expand(ranges.misc_start + index)


## All background tiles ([param fore] false) or all foreground tiles in
## one image, [param columns] tiles wide; empty tiles stay see-through.
func tile_atlas(fore: bool, columns: int) -> Image:
	var count := ranges.fore_tile_count if fore else ranges.back_tile_count
	var rows := ceili(float(count) / columns)
	var atlas := Image.create_empty(
		columns * TILE16_SIZE, maxi(1, rows) * TILE16_SIZE, false, Image.FORMAT_RGBA8
	)
	var whole := Rect2i(0, 0, TILE16_SIZE, TILE16_SIZE)
	for index in count:
		var tile := fore_tile(index) if fore else back_tile(index)
		if tile != null:
			var cell := Vector2i(index % columns, index / columns) * TILE16_SIZE
			atlas.blit_rect(tile, whole, cell)
	return atlas


func _decode_picture(index: int) -> Image:
	var size := _size_in(_picture_sizes, index)
	var data := file.expand(ranges.picture_start + index)
	return _planar_image(data, size.x / PIXELS_PER_BYTE, size.y, false)


func _decode_masked_picture(index: int) -> Image:
	var size := _size_in(_masked_picture_sizes, index)
	var data := file.expand(ranges.masked_picture_start + index)
	return _planar_image(data, size.x / PIXELS_PER_BYTE, size.y, true)


func _decode_sprite(index: int) -> Image:
	var info := sprite_infos[index]
	var data := file.expand(ranges.sprite_start + index)
	return _planar_image(data, info.width_in_bytes, info.height, true)


func _decode_tile8(index: int, masked: bool) -> Image:
	var chunk := ranges.masked_tile8_chunk if masked else ranges.tile8_chunk
	var all: PackedByteArray = _cached(
		"tile8_chunk", chunk, func() -> PackedByteArray: return file.expand_whole(chunk)
	)
	var tile_bytes := (
		GalaxyChunkRanges.TILE8_MASKED_BYTES if masked else GalaxyChunkRanges.TILE8_BYTES
	)
	var data := all.slice(index * tile_bytes, (index + 1) * tile_bytes)
	return _planar_image(data, TILE8_SIZE / PIXELS_PER_BYTE, TILE8_SIZE, masked)


func _decode_tile16(index: int, fore: bool) -> Image:
	var chunk := (ranges.fore_tile_start if fore else ranges.back_tile_start) + index
	if file.is_empty(chunk):
		return null
	var length := GalaxyChunkRanges.FORE_TILE_BYTES if fore else GalaxyChunkRanges.BACK_TILE_BYTES
	var data := file.expand_fixed(chunk, length)
	return _planar_image(data, TILE16_SIZE / PIXELS_PER_BYTE, TILE16_SIZE, fore)


## An image from planes stored one after another: [param masked] means a
## mask plane comes first. Null when [param data] is too short.
static func _planar_image(
	data: PackedByteArray, width_in_bytes: int, height: int, masked: bool
) -> Image:
	var plane_size := width_in_bytes * height
	var planes := PLANE_COUNT + (1 if masked else 0)
	if plane_size <= 0 or data.size() < plane_size * planes:
		return null
	var first := plane_size if masked else 0
	var starts := PackedInt32Array()
	for plane in PLANE_COUNT:
		starts.append(first + plane * plane_size)
	var colors := EgaPlanarDecoder.decode_colors(data, starts, width_in_bytes, height)
	var mask := PackedByteArray()
	if masked:
		mask = EgaPlanarDecoder.decode_single_plane(data, 0, width_in_bytes, height)
	return EgaPalette.create_image(colors, width_in_bytes * PIXELS_PER_BYTE, height, mask)


static func _sizes(table: PackedByteArray) -> PackedInt32Array:
	var sizes := PackedInt32Array()
	for index in table.size() / 2:
		sizes.append(table.decode_u16(index * 2))
	return sizes


static func _size_in(sizes: PackedInt32Array, index: int) -> Vector2i:
	if index < 0 or index * 2 + 1 >= sizes.size():
		return Vector2i.ZERO
	return Vector2i(sizes[index * 2] * PIXELS_PER_BYTE, sizes[index * 2 + 1])


func _cached(kind: String, index: int, decode: Callable) -> Variant:
	var key := "%s:%d" % [kind, index]
	if not _cache.has(key):
		_cache[key] = decode.call()
	return _cache[key]
