class_name Keen4View
extends Keen4LevelScreen
## The Keen 4 game screen that the start screen opens (milestone D3): one
## map of Keen 4 drawn as the original draws it, with Keen standing still
## at his start; he cannot move yet (D4). It opens level 1, or map N with
## [code]-- --game=4 --level=N[/code] (0 is the world map, 1-17 the
## levels, 18 the Megarocket, 19 the high-score map).
##
## The view is placed by the original's rules ([GalaxyCamera]): on Keen,
## off the map's border and the scroll blocks. The movement keys look
## around ([FreeLook]): the point they move is where Keen would be, and the
## view follows it by the same rules, so it never shows what lies beyond a
## scroll block and jumps across one as the original's view does. The
## animated tiles run on the original's clock ([GalaxyClock], 35 logic
## frames a second).
##
## Keys: Escape back to the start screen; Shift+N / Shift+P the next or
## previous map; F1-F6 as in Keen 1-3 (help line, widescreen, pixel shape,
## full screen, graphics: original or xBRZ, smooth motion).

const NOT_A_MAP_MESSAGE := "Keen 4 has no map %d"

var _clock := GalaxyClock.new()
var _start: Keen4Start
var _keen_item: GalaxyObjectLayer.Item
## The map shown now (its number, also when it could not be read).
var _map_number := Keen4Episode.FIRST_LEVEL
## Where the free-look point was when the view was last placed.
var _looked_at := Vector2.INF


func _ready() -> void:
	# Picking the game on the start screen asks for its menu; there is none
	# yet (D10), so the request is taken here and not left for the next game.
	GameLaunch.take_menu_request()
	_set_up_screen()
	_mode = Mode.LOOK
	if not _load_data():
		return
	_show_level(_requested_map())


func _process(delta: float) -> void:
	_message_time_left -= delta
	if _scaled != null and _scaled.poll():
		_apply_graphics()
	for frame in _clock.advance(delta):
		_galaxy_map.animate(_clock.run_frame())
	_follow_free_look()
	_objects.place(_clock.blend(), _settings.smooth_motion)
	_update_backdrops()
	_update_status()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		get_tree().change_scene_to_file.call_deferred(GameLaunch.LAUNCHER_SCENE)
	elif _handle_display_keys(event) or _handle_map_keys(event):
		get_viewport().set_input_as_handled()


## The map that is shown now.
func map_number() -> int:
	return _map_number


## Where Keen starts in the map shown now.
func start() -> Keen4Start:
	return _start


## The camera rules of the map shown now.
func galaxy_camera() -> GalaxyCamera:
	return _galaxy_camera


## Shows map [param number] with Keen at his start and the view on him.
func _show_level(number: int) -> void:
	_map_number = number
	var map := _data.maps.load_map(number) if _data.maps.has_map(number) else null
	if map == null:
		_show_message(NOT_A_MAP_MESSAGE % number)
		return
	_clock.reset()
	_galaxy_camera = GalaxyCamera.for_map(
		Vector2i(map.width, map.height),
		GalaxyCamera.blocks_in(map, Keen4Episode.COLUMN_BLOCK_INFO, true),
		GalaxyCamera.blocks_in(map, Keen4Episode.ROW_BLOCK_INFO, false)
	)
	_start = Keen4Start.find(map)
	_objects.clear()
	_keen_item = null
	var sprites := PackedInt32Array()
	if _start.kind != Keen4Start.Kind.NONE:
		sprites.append(_start.sprite)
	_show_map(map, sprites)
	if _start.kind != Keen4Start.Kind.NONE:
		_keen_item = _objects.add(_start.sprite, _start.position, Keen4Start.PRIORITY)
	_centre_view()


## The view on Keen, as the original puts it when a level starts (Omni
## CK_CentreCamera); the free-look point goes where he is.
func _centre_view() -> void:
	var x := _start.position.x
	var feet := _start.position.y
	if _keen_item != null:
		var info := _data.graphics.sprite_infos[_start.sprite]
		feet += info.box_bottom
	_galaxy_camera.centre_on(x, feet, _start.is_world_map(), _start.position.y)
	_free_look.bounds = _look_bounds()
	_free_look.move_to(_view_centre())
	_looked_at = _free_look.position
	_frame_view()


## Places the view on the free-look point once it has moved.
func _follow_free_look() -> void:
	if _galaxy_camera == null or _free_look.position == _looked_at:
		return
	_looked_at = _free_look.position
	var half := Vector2(GalaxyCamera.VIEW_PIXELS) / 2.0
	var top_left := ((_looked_at - half) * GalaxyCamera.UNITS_PER_PIXEL).floor()
	_galaxy_camera.reposition(Vector2i(top_left))
	_frame_view()


## The middle of the original's view now, in pixels.
func _view_centre() -> Vector2:
	return Vector2(_galaxy_camera.view_pixels()) + Vector2(GalaxyCamera.VIEW_PIXELS) / 2.0


## Where the free-look point may go: the middle of every view inside the
## map's border.
func _look_bounds() -> Rect2:
	var border := GalaxyCamera.BORDER_TILES * GalaxyCamera.TILE_PIXELS
	var size := Vector2(_map.width, _map.height) * GalaxyCamera.TILE_PIXELS
	var view := Vector2(GalaxyCamera.VIEW_TILES * GalaxyCamera.TILE_PIXELS)
	var half := Vector2(GalaxyCamera.VIEW_PIXELS) / 2.0
	return Rect2(Vector2(border, border) + half, size - 2.0 * Vector2(border, border) - view)


## Shift+N and Shift+P: the next or previous map.
func _handle_map_keys(event: InputEvent) -> bool:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or not key.shift_pressed:
		return false
	var step := 0
	match key.keycode:
		KEY_N:
			step = 1
		KEY_P:
			step = -1
		_:
			return false
	if _data != null:
		var count := Keen4Episode.LAST_MAP + 1
		_show_level(posmod(_map_number + step, count))
	return true


## Messages in the middle; with the help (F1) the map's name and the
## graphics above them.
func _update_status() -> void:
	_help_label.visible = _show_help
	if _data == null:
		return
	var lines := PackedStringArray()
	if _show_help:
		lines.append(StatusLine.picture_text(_map_title(), _settings))
	if _message_time_left > 0.0:
		lines.append(_message)
	_status_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_LEFT if _show_help else HORIZONTAL_ALIGNMENT_CENTER
	)
	_status_label.text = "\n".join(lines)


func _map_title() -> String:
	var names := _data.executable.level_names()
	if _map_number >= 0 and _map_number < names.size():
		return "Map %d: %s" % [_map_number, GalaxyExeTexts.one_line(names[_map_number])]
	return "Map %d" % _map_number


## The map asked for with --level=N, or level 1.
static func _requested_map() -> int:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with(GameLaunch.LEVEL_OPTION):
			return argument.trim_prefix(GameLaunch.LEVEL_OPTION).to_int()
	return Keen4Episode.FIRST_LEVEL
