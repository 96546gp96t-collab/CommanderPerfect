extends Control
## The game screen as of milestone 3: Keen walks, jumps and pogo-jumps
## through a level, followed by a smoothly scrolling camera. On the world map
## and the special maps, where Keen cannot play yet, the player looks around
## freely instead.
##
## The level is rendered at its original resolution into the World viewport.
## That picture is then stretched to fit the window, see [DisplaySettings].
##
## Command-line option: [code]-- --level=N[/code] starts in level N
## (80 is the world map).

const LEVEL_OPTION := "--level="
const DEFAULT_LEVEL := 1
const MISSING_DATA_MESSAGE := (
	"Keen 1 data not found. Put the files in game_data/keen1 "
	+ "(see game_data/README.md) or start with: -- --data-dir=PATH"
)

var _files: GameFiles
var _level_numbers := PackedInt32Array()
var _level_index := 0
var _level: LevelData
var _properties: TileProperties
var _settings := DisplaySettings.new()

@onready var _screen: TextureRect = %Screen
@onready var _world: SubViewport = %World
@onready var _level_map: LevelMap = %LevelMap
@onready var _free_look: FreeLook = %FreeLook
@onready var _keen: Keen = %Keen
@onready var _camera: LevelCamera = %Camera
@onready var _status_label: Label = %StatusLabel
@onready var _help_label: Label = %HelpLabel


func _ready() -> void:
	resized.connect(_fit_screen)
	_screen.texture = _world.get_texture()
	_apply_display_settings()

	_files = GameFiles.locate()
	if _files == null:
		_show_error(MISSING_DATA_MESSAGE)
		return
	var graphics := EgaGraphics.load_from(_files)
	if graphics == null:
		_show_error("The game files in %s could not be read." % _files.directory)
		return
	_level_numbers = _files.level_numbers()
	if _level_numbers.is_empty():
		_show_error("There are no levels in %s." % _files.directory)
		return

	_properties = TileProperties.load_from(_files, graphics.tiles.size())
	if _properties == null:
		_show_error("The tile properties in %s could not be read." % GameFiles.EXECUTABLE)
		return

	_level_map.tile_set = LevelTileSet.build(graphics)
	_keen.set_graphics(graphics)
	_keen.died.connect(_on_keen_died)
	_level_index = maxi(0, _level_numbers.find(_requested_level()))
	_load_level()


func _unhandled_input(event: InputEvent) -> void:
	if _level_numbers.is_empty():
		return
	if event.is_action_pressed("next_level"):
		_select_level(_level_index + 1)
	elif event.is_action_pressed("previous_level"):
		_select_level(_level_index - 1)
	elif event.is_action_pressed("toggle_widescreen"):
		_settings.aspect = (
			DisplaySettings.Aspect.WIDESCREEN
			if _settings.aspect == DisplaySettings.Aspect.ORIGINAL
			else DisplaySettings.Aspect.ORIGINAL
		)
		_apply_display_settings()
	elif event.is_action_pressed("toggle_pixel_aspect"):
		_settings.correct_pixel_aspect = not _settings.correct_pixel_aspect
		_apply_display_settings()
	elif event.is_action_pressed("toggle_help"):
		_help_label.visible = not _help_label.visible
	else:
		return
	get_viewport().set_input_as_handled()


func _requested_level() -> int:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with(LEVEL_OPTION) and argument.trim_prefix(LEVEL_OPTION).is_valid_int():
			return argument.trim_prefix(LEVEL_OPTION).to_int()
	return DEFAULT_LEVEL


func _show_error(message: String) -> void:
	_status_label.text = message
	_help_label.visible = false
	push_error(message)


## Wraps around, so the next level after the last one is the first.
func _select_level(index: int) -> void:
	_level_index = posmod(index, _level_numbers.size())
	_load_level()


func _load_level() -> void:
	var file_name := GameFiles.level_file_name(_level_numbers[_level_index])
	_level = LevelData.parse(_files.read(file_name))
	if _level == null:
		_level_map.clear()
		_follow(_free_look)
		_status_label.text = "%s could not be read." % file_name
		return

	_level_map.show_level(_level, _properties)
	_frame_camera()
	var start := _start_cell()
	if GameFiles.is_playable_level(_level_numbers[_level_index]):
		_keen.enter_level(
			LevelCollision.create(_level, _properties), Vector2(start * EgaGraphics.TILE_SIZE)
		)
		_follow(_keen)
	else:
		_free_look.move_to((Vector2(start) + Vector2(0.5, 0.5)) * EgaGraphics.TILE_SIZE)
		_follow(_free_look)
	_update_status()


## The cell where Keen starts, or the top left of the level if it has none.
func _start_cell() -> Vector2i:
	var cell := _level.find_info(LevelData.PLAYER_START_INFO)
	if cell.x < 0:
		cell = _level.playable_rect().position
	return cell


## Makes the camera follow [param target]: Keen or the free-look point. The
## other one is switched off.
func _follow(target: Node2D) -> void:
	var playing := target == _keen
	_keen.visible = playing
	_keen.set_process(playing)
	_free_look.set_process(not playing)
	_camera.reparent(target, false)
	_camera.position = KeenPhysics.SPRITE_SIZE / 2.0 if playing else Vector2.ZERO
	_camera.use_dead_zone(playing)
	_camera.reset_smoothing()


func _on_keen_died() -> void:
	_camera.reset_smoothing()


func _apply_display_settings() -> void:
	_world.size = _settings.game_size()
	_fit_screen()
	if _level != null:
		_frame_camera()
		_update_status()


func _frame_camera() -> void:
	var view_size := _settings.game_size()
	var area := LevelMap.playable_pixels(_level)
	_camera.frame(area, view_size)
	_free_look.bounds = LevelCamera.center_range(LevelCamera.limits_for(area, view_size), view_size)
	_free_look.move_to(_free_look.position)


func _fit_screen() -> void:
	var rect := _settings.fit_rect(size)
	_screen.position = rect.position
	_screen.size = rect.size


func _update_status() -> void:
	var number := _level_numbers[_level_index]
	var game_size := _settings.game_size()
	_status_label.text = (
		"%s (%d x %d cells)   %s %d x %d, %s pixels"
		% [
			GameFiles.level_title(number),
			_level.width,
			_level.height,
			_settings.aspect_name(),
			game_size.x,
			game_size.y,
			"4:3 monitor" if _settings.correct_pixel_aspect else "square",
		]
	)
