extends SceneTree
## Saves all decoded graphics and level previews as PNG files.
##
## Useful for checking the decoders, and as input for upscalers such as
## Real-ESRGAN later on. The output is derived from the original game data, so
## it is ignored by git and must not be shared.
##
## Usage:
##   godot --headless --path . --script res://tools/export_graphics.gd -- [--out=PATH] [--game=2]
##
## Without --out the files are written to the exported/ folder of the project
## (exported/keen2/ for Keen 2, chosen with --game=2).

const OUT_OPTION := "--out="
const DEFAULT_OUT := "res://exported"
const KEEN_2_DEFAULT_OUT := "res://exported/keen2"
const TILE_ATLAS_COLUMNS := 16
const FONT_ATLAS_COLUMNS := 32


func _initialize() -> void:
	quit(0 if _export() else 1)


func _export() -> bool:
	var keen_2 := GameLaunch.wants_keen_2(OS.get_cmdline_user_args())
	var files := Keen2Files.locate() if keen_2 else GameFiles.locate()
	if files == null:
		if keen_2:
			push_error("No Keen 2 game data found. See game_data/README.md.")
		else:
			push_error("No Keen 1 game data found. See game_data/README.md.")
		return false
	var graphics := EgaGraphics.load_from(files, files.extension)
	if graphics == null:
		return false

	var out := _output_directory(KEEN_2_DEFAULT_OUT if keen_2 else DEFAULT_OUT)
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
	var finale := FinaleImage.load_from(
		files, Keen2Files.FINALE if keen_2 else FinaleImage.FILE_NAME
	)
	if finale != null:
		finale.save_png(out.path_join("bitmaps").path_join("finale.png"))

	print("Exported graphics to %s" % out)
	return true


func _output_directory(default_out: String) -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with(OUT_OPTION):
			return argument.trim_prefix(OUT_OPTION)
	return ProjectSettings.globalize_path(default_out)
