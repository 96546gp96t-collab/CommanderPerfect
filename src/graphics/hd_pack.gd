class_name HdPack
extends RefCounted
## The player's own HD graphics: the game graphics upscaled by Real-ESRGAN on
## the player's computer (tools/make_hd_graphics.sh). They are derived from
## the original game files, so they stay next to those files and are never
## shared.
##
## [method write_sheets] puts all graphics on a few large sheets
## ([GraphicsSheet]); the upscaler turns each sheet into a larger one with
## the same name in the folder [constant FOLDER] next to the game files, and
## [method load_from] cuts the images out again. The transparency of the
## sprites travels on its own sheet, because upscalers handle color best.

const FOLDER := "hd"
const FONT := "font"
const TILES := "tiles"
const BITMAPS := "bitmaps"
const SPRITES := "sprites"
const SPRITE_MASKS := "sprites_mask"
const FINALE := "finale"
const EXTENSION := ".png"
## Mask values below this are fully transparent, above the upper one fully
## visible; in between the upscaled edge is kept soft.
const MASK_LOW := 0.3
const MASK_HIGH := 0.7
const CHANNELS := 4


## The folder with the HD graphics for the game files in [param files].
static func folder_of(files: GameFiles) -> String:
	return files.directory.path_join(FOLDER)


## Whether the player has made HD graphics for these game files.
static func exists(files: GameFiles) -> bool:
	return FileAccess.file_exists(folder_of(files).path_join(TILES + EXTENSION))


## Writes the sheets to upscale into [param directory]. Returns false (and
## says why) when that fails.
static func write_sheets(graphics: EgaGraphics, finale: Image, directory: String) -> bool:
	DirAccess.make_dir_recursive_absolute(directory)
	var sheets := {
		FONT: GraphicsSheet.pack(graphics.font_chars),
		TILES: GraphicsSheet.pack(graphics.tiles),
		BITMAPS: GraphicsSheet.pack(graphics.bitmaps),
		SPRITES: GraphicsSheet.pack(graphics.sprites),
		SPRITE_MASKS: GraphicsSheet.pack_masks(graphics.sprites),
	}
	if finale != null:
		sheets[FINALE] = GraphicsSheet.pack([finale] as Array[Image])
	for sheet_name: String in sheets:
		var path := directory.path_join(sheet_name + EXTENSION)
		var error: Error = sheets[sheet_name].image.save_png(path)
		if error != OK:
			push_error("Could not write %s: %s" % [path, error_string(error)])
			return false
	return true


## The HD graphics for [param graphics] and [param finale] (may be null), or
## null (with the reason) when they are missing or do not fit these game
## files. Reading takes a moment; meant for a worker thread.
static func load_from(files: GameFiles, graphics: EgaGraphics, finale: Image) -> ScaledGraphics:
	var folder := folder_of(files)
	var scaled := ScaledGraphics.new()
	scaled.style = DisplaySettings.Graphics.HD
	scaled.factor = _factor(folder, TILES, graphics.tiles)
	if scaled.factor < 1:
		return null
	scaled.font_chars = _read(folder, FONT, graphics.font_chars, scaled.factor)
	scaled.tiles = _read(folder, TILES, graphics.tiles, scaled.factor)
	scaled.bitmaps = _read(folder, BITMAPS, graphics.bitmaps, scaled.factor)
	scaled.sprites = _read(folder, SPRITES, graphics.sprites, scaled.factor)
	var masks := _read(folder, SPRITE_MASKS, graphics.sprites, scaled.factor)
	if not scaled.matches(graphics) or masks.size() != scaled.sprites.size():
		return null
	for i in scaled.sprites.size():
		scaled.sprites[i] = apply_mask(scaled.sprites[i], masks[i])
	if finale != null:
		var finales := _read(folder, FINALE, [finale] as Array[Image], scaled.factor)
		scaled.finale = finales[0] if finales.size() == 1 else null
	return scaled


## [param color] with the brightness of [param mask] as its transparency,
## turned from the soft edge of an upscaled mask into a slightly firmer one.
static func apply_mask(color: Image, mask: Image) -> Image:
	var result := color.duplicate() as Image
	result.convert(Image.FORMAT_RGBA8)
	var gray := mask.duplicate() as Image
	gray.convert(Image.FORMAT_RGBA8)
	var data := result.get_data()
	var mask_data := gray.get_data()
	for pixel in data.size() / CHANNELS:
		var level := mask_data[pixel * CHANNELS] / 255.0
		data[pixel * CHANNELS + 3] = roundi(smoothstep(MASK_LOW, MASK_HIGH, level) * 255.0)
	return Image.create_from_data(
		result.get_width(), result.get_height(), false, Image.FORMAT_RGBA8, data
	)


## How many times larger the upscaled sheet [param sheet_name] is than the
## one made from [param images]; 0 when it is missing or not a whole
## multiple.
static func _factor(folder: String, sheet_name: String, images: Array[Image]) -> int:
	var path := folder.path_join(sheet_name + EXTENSION)
	var scaled := Image.load_from_file(path)
	if scaled == null:
		push_error("The HD graphics in %s could not be read." % folder)
		return 0
	var original := GraphicsSheet.size_for(GraphicsSheet.sizes_of(images))
	var factor := scaled.get_width() / original.x
	if factor < 1 or scaled.get_size() != original * factor:
		push_error(
			(
				"%s is %s; expected a multiple of %s. Make the HD graphics again."
				% [path, scaled.get_size(), original]
			)
		)
		return 0
	return factor


static func _read(
	folder: String, sheet_name: String, images: Array[Image], factor: int
) -> Array[Image]:
	var path := folder.path_join(sheet_name + EXTENSION)
	var scaled := Image.load_from_file(path)
	var original := GraphicsSheet.size_for(GraphicsSheet.sizes_of(images))
	if scaled == null or scaled.get_size() != original * factor:
		push_error("%s is missing or does not fit the game files." % path)
		return []
	var rects := GraphicsSheet.layout(GraphicsSheet.sizes_of(images))
	return GraphicsSheet.cut(scaled, rects, factor)
