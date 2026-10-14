extends SceneTree
## Writes the sheets that Real-ESRGAN upscales into HD graphics: all font
## characters, tiles, bitmaps and sprites (and the transparency of the
## sprites) on a few large images, see [HdPack]. tools/make_hd_graphics.sh
## runs this, then the upscaler.
##
## The sheets are derived from the original game data, so they are ignored by
## git and must not be shared.
##
## Usage:
##   godot --headless --path . --script res://tools/export_hd_sheets.gd -- --out=PATH

const OUT_OPTION := "--out="


func _initialize() -> void:
	quit(0 if _export() else 1)


func _export() -> bool:
	var out := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with(OUT_OPTION):
			out = argument.trim_prefix(OUT_OPTION)
	if out.is_empty():
		push_error("Say where the sheets go: -- --out=PATH")
		return false
	var files := GameFiles.locate()
	if files == null:
		push_error("No Keen 1 game data found. See game_data/README.md.")
		return false
	var graphics := EgaGraphics.load_from(files)
	if graphics == null:
		return false
	if not HdPack.write_sheets(graphics, FinaleImage.load_from(files), out):
		return false
	print("Wrote the sheets for %s to %s" % [files.directory, out])
	print("HD graphics go to %s" % HdPack.folder_of(files))
	return true
