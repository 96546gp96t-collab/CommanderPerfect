class_name Keen5View
extends Control
## The Keen 5 screen that the start screen opens, for now (milestone E2):
## Keen 5's files are read and shown as a "coming soon" picture in the
## game's own font, with Keen standing in his own sprite. With
## [code]-- --game=5 --level=N[/code] the picture names map N, from the
## program's own list of level names. Escape or Enter goes back to the
## start screen.
## The game itself comes in milestone E3 and later (docs/keen5/roadmap.md).

const SCREEN_SIZE := Vector2i(320, 200)
## The original's pixels are taller than wide: 320 × 200 fills a 4:3 screen.
const SCREEN_ASPECT := 4.0 / 3.0
const BACKGROUND_COLOR := 0
const TITLE_COLOR := 14
const NAME_COLOR := 15
const HINT_COLOR := 7
const TITLE := "Keen 5 - coming soon"
const MAP_TITLE := "Map %d:"
const NOT_A_MAP_MESSAGE := "Keen 5 has no map %d"
const HINT := "Esc or Enter: back to the start screen"
## Rows of the picture: Keen's feet, the title, the map's name, the hint.
const KEEN_BOTTOM := 80
const TITLE_TOP := 92
const NAME_TOP := 116
const HINT_BOTTOM := 192
const LINE_GAP := 2
const MISSING_DATA_MESSAGE := (
	"Keen 5 data not found. Put the files in game_data/keen5 "
	+ "(see game_data/README.md) or start with: -- --game=5 --data-dir-keen5=PATH"
)

var _data: GalaxyData
var _screen := TextureRect.new()
var _message := Label.new()


func _ready() -> void:
	# The start screen asks for the game's menu; there is none yet, so the
	# request is taken here and not left for the next game.
	GameLaunch.take_menu_request()
	_build()
	var files := Keen5Files.locate()
	_data = Keen5Episode.load_data(files) if files != null else null
	if _data == null:
		_message.text = MISSING_DATA_MESSAGE
		push_error(MISSING_DATA_MESSAGE)
		return
	var image := picture(_data, requested_map(OS.get_cmdline_user_args()))
	_screen.texture = ImageTexture.create_from_image(image)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		get_tree().change_scene_to_file.call_deferred(GameLaunch.LAUNCHER_SCENE)


## The map that [param arguments] ask for with --level=N, or -1.
static func requested_map(arguments: PackedStringArray) -> int:
	for argument in arguments:
		if argument.begins_with(GameLaunch.LEVEL_OPTION):
			return argument.trim_prefix(GameLaunch.LEVEL_OPTION).to_int()
	return -1


## The "coming soon" picture of [param data]; with a [param map] of 0 or
## more also that map's name (or that there is no such map).
static func picture(data: GalaxyData, map: int) -> Image:
	var image := Image.create_empty(SCREEN_SIZE.x, SCREEN_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(EgaPalette.color(BACKGROUND_COLOR))
	var keen := data.graphics.sprite(Keen5Episode.KEEN_STAND_RIGHT_SPRITE)
	if keen != null:
		var left := (SCREEN_SIZE.x - keen.get_width()) / 2
		_blend(image, keen, Vector2i(left, KEEN_BOTTOM - keen.get_height()))
	var font := data.graphics.font(Keen5Episode.MENU_FONT)
	if font == null:
		return image
	_print_lines(image, font, [TITLE], TITLE_TOP, TITLE_COLOR)
	if map >= 0:
		_print_lines(image, font, map_lines(data, map), NAME_TOP, NAME_COLOR)
	_print_lines(image, font, [HINT], HINT_BOTTOM - font.height, HINT_COLOR)
	return image


## The lines that name [param map]: "Map N:" and its name from the program
## (a name may have several lines); a message when there is no such map.
static func map_lines(data: GalaxyData, map: int) -> PackedStringArray:
	var names := data.executable.level_names()
	if map >= names.size():
		return PackedStringArray([NOT_A_MAP_MESSAGE % map])
	var lines := PackedStringArray([MAP_TITLE % map])
	lines.append_array(names[map].split(GalaxyExeTexts.NEWLINE))
	return lines


func _build() -> void:
	var background := ColorRect.new()
	background.color = EgaPalette.color(BACKGROUND_COLOR)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var frame := AspectRatioContainer.new()
	frame.ratio = SCREEN_ASPECT
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(frame)
	_screen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_screen.stretch_mode = TextureRect.STRETCH_SCALE
	_screen.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.add_child(_screen)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_message)


## Prints [param lines] centred, one under the other from row [param top].
static func _print_lines(
	image: Image, font: GalaxyFont, lines: PackedStringArray, top: int, color_index: int
) -> void:
	var y := top
	for line in lines:
		var text := font.render(line, EgaPalette.color(color_index))
		_blend(image, text, Vector2i((SCREEN_SIZE.x - text.get_width()) / 2, y))
		y += font.height + LINE_GAP


static func _blend(image: Image, part: Image, at: Vector2i) -> void:
	image.blend_rect(part, Rect2i(Vector2i.ZERO, part.get_size()), at)
