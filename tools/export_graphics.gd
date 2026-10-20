extends SceneTree
## Saves all decoded graphics and level previews as PNG files.
##
## Useful for checking the decoders, and as input for upscalers such as
## Real-ESRGAN later on. The output is derived from the original game data, so
## it is ignored by git and must not be shared.
##
## Usage:
##   godot --headless --path . --script res://tools/export_graphics.gd --
##       [--out=PATH] [--game=2|3|4]
##
## Without --out the files are written to the exported/ folder of the project
## (exported/keen2/ for Keen 2, chosen with --game=2; exported/keen3/ for
## Keen 3, chosen with --game=3; exported/keen4/ for Keen 4, chosen with
## --game=4, which has files of another kind: see [method _export_galaxy]).

const OUT_OPTION := "--out="
const DEFAULT_OUT := "res://exported"
const KEEN_2_DEFAULT_OUT := "res://exported/keen2"
const KEEN_3_DEFAULT_OUT := "res://exported/keen3"
const KEEN_4_DEFAULT_OUT := "res://exported/keen4"
## Keen 4's tile sets are laid out as wide as TED5 shows them.
const GALAXY_ATLAS_COLUMNS := 18
const TILE_ATLAS_COLUMNS := 16
const FONT_ATLAS_COLUMNS := 32
const FONT_SAMPLE := "ABCDEFGHIJKLMNOPQRSTUVWXYZ abcdefghijklmnopqrstuvwxyz 0123456789"


func _initialize() -> void:
	quit(0 if _export() else 1)


func _export() -> bool:
	var game := GameLaunch.game_number(OS.get_cmdline_user_args())
	if game == 4:
		return _export_galaxy()
	var keen_2 := game == 2
	var keen_3 := game == 3
	var files: GameFiles
	if keen_3:
		files = Keen3Files.locate()
	else:
		files = Keen2Files.locate() if keen_2 else GameFiles.locate()
	if files == null:
		if keen_3:
			push_error("No Keen 3 game data found. See game_data/README.md.")
		elif keen_2:
			push_error("No Keen 2 game data found. See game_data/README.md.")
		else:
			push_error("No Keen 1 game data found. See game_data/README.md.")
		return false
	var graphics := EgaGraphics.load_from(files, files.extension)
	if graphics == null:
		return false

	var out := _output_directory(_default_out(game))
	for folder in ["sprites", "bitmaps", "levels"]:
		DirAccess.make_dir_recursive_absolute(out.path_join(folder))

	graphics.create_tile_atlas(TILE_ATLAS_COLUMNS).save_png(out.path_join("tiles.png"))
	graphics.create_font_atlas(FONT_ATLAS_COLUMNS).save_png(out.path_join("font.png"))
	for i in graphics.sprites.size():
		var file_name := "%03d_%s.png" % [i, graphics.header.sprites[i].name]
		graphics.sprites[i].save_png(out.path_join("sprites").path_join(file_name))
	for i in graphics.bitmaps.size():
		var file_name := "%02d_%s.png" % [i, graphics.header.bitmaps[i].name]
		graphics.bitmaps[i].save_png(out.path_join("bitmaps").path_join(file_name))
	for number in files.level_numbers():
		var level := LevelData.parse(files.read(files.level_file(number)))
		if level != null:
			var image := LevelImageBuilder.build(level, graphics)
			image.save_png(out.path_join("levels").path_join("level%02d.png" % number))
	var finale := FinaleImage.load_from(files, _finale_name(game))
	if finale != null:
		finale.save_png(out.path_join("bitmaps").path_join("finale.png"))

	print("Exported graphics to %s" % out)
	return true


## Keen 4: both tile sets, every sprite, picture and masked picture, the
## fonts, and every map with its three planes.
func _export_galaxy() -> bool:
	var files := Keen4Files.locate()
	if files == null:
		push_error("No Keen 4 game data found. See game_data/README.md.")
		return false
	var data := Keen4Episode.load_data(files)
	if data == null:
		return false
	var graphics := data.graphics
	var out := _output_directory(KEEN_4_DEFAULT_OUT)
	for folder in ["sprites", "pictures", "maps", "fonts"]:
		DirAccess.make_dir_recursive_absolute(out.path_join(folder))
	graphics.tile_atlas(false, GALAXY_ATLAS_COLUMNS).save_png(out.path_join("tiles_back.png"))
	graphics.tile_atlas(true, GALAXY_ATLAS_COLUMNS).save_png(out.path_join("tiles_fore.png"))
	for i in graphics.ranges.sprite_count:
		_save(graphics.sprite(i), out.path_join("sprites/%03d.png" % i))
	for i in graphics.ranges.picture_count:
		_save(graphics.picture(i), out.path_join("pictures/%03d.png" % i))
	for i in graphics.ranges.masked_picture_count:
		_save(graphics.masked_picture(i), out.path_join("pictures/masked_%d.png" % i))
	for i in graphics.ranges.font_count:
		var font := graphics.font(i)
		if font != null:
			_save(font.render(FONT_SAMPLE, Color.WHITE), out.path_join("fonts/font%d.png" % i))
	for number in data.maps.map_count():
		var map := data.maps.load_map(number) if data.maps.has_map(number) else null
		if map != null:
			_save(GalaxyMapImage.build(map, graphics), out.path_join("maps/map%02d.png" % number))
	print("Exported graphics to %s" % out)
	return true


func _save(image: Image, path: String) -> void:
	if image != null:
		image.save_png(path)


## Where game [param game] (1, 2 or 3) is exported without --out.
func _default_out(game: int) -> String:
	match game:
		2:
			return KEEN_2_DEFAULT_OUT
		3:
			return KEEN_3_DEFAULT_OUT
	return DEFAULT_OUT


## The finale picture of game [param game] (1, 2 or 3).
func _finale_name(game: int) -> String:
	match game:
		2:
			return Keen2Files.FINALE
		3:
			return Keen3Files.FINALE
	return FinaleImage.FILE_NAME


func _output_directory(default_out: String) -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with(OUT_OPTION):
			return argument.trim_prefix(OUT_OPTION)
	return ProjectSettings.globalize_path(default_out)
