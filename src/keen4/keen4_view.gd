class_name Keen4View
extends Control
## What the start screen opens for Keen 4 until it can be played (D3 and
## later): Keen and "Keen 4 - coming soon" from the player's own files, and
## the name of the level asked for with [code]--level=N[/code]. Enter or
## Escape go back to the start screen. Without the files it says where they
## go.

const TITLE := "Keen 4 - coming soon"
const HINT := "Enter or Escape: back to the start screen"
const MISSING_FILES := (
	"The files of Keen 4 were not found. Put them in %s "
	+ "(see game_data/README.md), or start with -- --game=4 --data-dir-keen4=PATH."
)
## Keen and the title are drawn this many screen pixels per game pixel.
const PIXEL_SCALE := 4
const TITLE_COLOR := Color.WHITE
const BACKGROUND_COLOR := Color.BLACK
const GAP := 24

var _layout := VBoxContainer.new()
var _lines := PackedStringArray()


func _ready() -> void:
	# Picking the game on the start screen asks for its menu; there is none
	# yet, so the request is taken here and not left for the next game.
	GameLaunch.take_menu_request()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = BACKGROUND_COLOR
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	_layout.alignment = BoxContainer.ALIGNMENT_CENTER
	_layout.add_theme_constant_override("separation", GAP)
	_layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_layout)
	var files := Keen4Files.locate()
	var data := Keen4Episode.load_data(files) if files != null else null
	if data == null:
		_add_line(MISSING_FILES % Keen4Files.SUBFOLDER)
	else:
		_add_pictures(data)
		var level := _level_option()
		var names := data.executable.level_names()
		if level >= 0 and level < names.size():
			_add_line("Level %d: %s" % [level, GalaxyExeTexts.one_line(names[level])])
	_add_line(HINT)


## The lines of text on the screen, from the top.
func lines() -> PackedStringArray:
	return _lines


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		get_tree().change_scene_to_file.call_deferred(GameLaunch.LAUNCHER_SCENE)


func _add_pictures(data: GalaxyData) -> void:
	var keen := data.graphics.sprite(Keen4Episode.KEEN_WALK_RIGHT_SPRITE)
	if keen != null:
		_add_picture(keen)
	var font := data.graphics.font(Keen4Episode.MENU_FONT)
	if font != null:
		_add_picture(font.render(TITLE, TITLE_COLOR))
	else:
		_add_line(TITLE)


func _add_picture(image: Image) -> void:
	var picture := TextureRect.new()
	picture.texture = ImageTexture.create_from_image(image)
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.custom_minimum_size = Vector2(image.get_size() * PIXEL_SCALE)
	_layout.add_child(picture)


func _add_line(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_layout.add_child(label)
	_lines.append(text)


## The level asked for with --level=N, or -1.
static func _level_option() -> int:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with(GameLaunch.LEVEL_OPTION):
			return argument.trim_prefix(GameLaunch.LEVEL_OPTION).to_int()
	return -1
