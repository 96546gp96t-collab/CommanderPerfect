extends SceneTree
## Writes the texts of one game's files ([method GameTexts.catalog]) as a
## language file to start a translation from: every name with its English
## as a "@text" block, ready to be copied into `languages/<code>/` and
## translated. The output holds the original's texts, so it goes to a
## git-ignored folder and never into git.
##
## Usage:
##   godot --headless --path . --script res://tools/language_template.gd -- --game=N [--out=PATH]
## N is 1-5; PATH defaults to exported/languages/keenN.txt (a folder gets
## keenN.txt in it). Characters the text file cannot show plainly (the
## hard break 0x1F, the font's pictures from 0x80 on) are written "\xNN",
## the way a language file writes them.

const GAME_OPTION := "--game="
const OUT_OPTION := "--out="
const DEFAULT_FOLDER := "res://exported/languages"
const FILE_NAME := "keen%d.txt"
const FIRST_GAME := 1
const LAST_GAME := 5
const LAST_PLAIN := 126
const FIRST_PLAIN := 32
const HEADER := """# The texts of Keen %d's files, to translate (see src/language/language_file.gd).
# Translate between each @text line and its @end; keep the names. A box of
# fixed size keeps its number of lines, and each line no longer than here.
# This file holds the original texts: never put it in git.
"""


func _initialize() -> void:
	var game := 0
	var out := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with(GAME_OPTION):
			game = argument.trim_prefix(GAME_OPTION).to_int()
		elif argument.begins_with(OUT_OPTION):
			out = argument.trim_prefix(OUT_OPTION)
	if game < FIRST_GAME or game > LAST_GAME:
		printerr("Usage: --game=N (1-5) [--out=PATH]")
		quit(1)
		return
	var texts := GameTexts.catalog(game)
	if texts.is_empty():
		printerr("No texts found: are the files of Keen %d in game_data?" % game)
		quit(1)
		return
	var path := _output_path(out, game)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		printerr("Could not write %s." % path)
		quit(1)
		return
	file.store_string(template(game, texts))
	file.close()
	print("Wrote %d texts to %s" % [texts.size(), ProjectSettings.globalize_path(path)])
	quit(0)


## The language file for [param texts] of game [param game].
static func template(game: int, texts: Dictionary[String, String]) -> String:
	var lines := PackedStringArray([HEADER % game])
	for id in texts:
		lines.append("@text %s" % id)
		lines.append(escaped(texts[id]))
		lines.append("@end")
		lines.append("")
	return "\n".join(lines)


## [param text] with every character but the plain ones and line ends as
## "\xNN".
static func escaped(text: String) -> String:
	var result := ""
	for index in text.length():
		var code := text.unicode_at(index)
		if text[index] == "\n" or (code >= FIRST_PLAIN and code <= LAST_PLAIN):
			result += text[index]
		else:
			result += "\\x%02X" % code
	return result


static func _output_path(out: String, game: int) -> String:
	if out.is_empty():
		return DEFAULT_FOLDER.path_join(FILE_NAME % game)
	if DirAccess.dir_exists_absolute(out) or out.ends_with("/"):
		return out.path_join(FILE_NAME % game)
	return out
