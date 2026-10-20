class_name Keen4View
extends Keen4LevelScreen
## The Keen 4 game screen that the start screen opens (milestones D3-D4).
## It opens level 1, or map N with [code]-- --game=4 --level=N[/code] (0 is
## the world map, 1-17 the levels, 18 the Megarocket, 19 the high-score
## map).
##
## In a map where Keen stands (the levels, the Megarocket, the high-score
## map) he is played ([Keen4LevelSession]) on the original's clock
## ([GalaxyClock], 35 logic frames a second): the view follows him by the
## original's rules ([GalaxyCamera]) and the score box ([GalaxyScoreBox]) is
## the HUD. Until the world map exists (D7) the game goes on like this:
## walking out of a level opens the next one (1-16, then 1 again), a death
## starts the level again (one life less), and without lives left the
## start screen returns.
## On the world map and in the Well of Wishes (D6, D7) Keen still stands and
## the movement keys look around, as in D3: the point they move is where
## Keen would be, and the view follows it by the same rules.
##
## Keys: the shared ones (arrows, jump, pogo, fire); Escape back to the
## start screen; Shift+N / Shift+P the next or previous map; F1-F6 as in
## Keen 1-3 (help line, widescreen, pixel shape, full screen, graphics:
## original or xBRZ, smooth motion).

const NOT_A_MAP_MESSAGE := "Keen 4 has no map %d"
## The last level Keen walks through: the Well of Wishes (17) is swum (D6),
## so after 16 level 1 follows for now.
const LAST_WALKING_LEVEL := 16
const GAME_OVER_MESSAGE := "Game over"

var _clock := GalaxyClock.new()
var _start: Keen4Start
var _keen_item: GalaxyObjectLayer.Item
## The map shown now (its number, also when it could not be read).
var _map_number := Keen4Episode.FIRST_LEVEL
## Where the free-look point was when the view was last placed.
var _looked_at := Vector2.INF
## What Keen carries from level to level.
var _inventory := Keen4Inventory.new_game()
## The level being played; null where Keen only stands.
var _played: Keen4LevelSession
## The view's top left, in pixels, frame by frame (smooth motion).
var _view_motion := Interpolation.new()

@onready var _score_box: GalaxyScoreBox = %ScoreBox


func _ready() -> void:
	# Picking the game on the start screen asks for its menu; there is none
	# yet (D10), so the request is taken here and not left for the next game.
	GameLaunch.take_menu_request()
	_set_up_screen()
	if not _load_data():
		return
	_score_box.use_graphics(_data.graphics, Keen4Sprites.OBJECTS[&"SCOREBOX"])
	_show_level(_requested_map())


func _process(delta: float) -> void:
	_message_time_left -= delta
	if _scaled != null and _scaled.poll():
		_apply_graphics()
	for frame in _clock.advance(delta):
		var tics := _clock.run_frame()
		if _played != null:
			_played.run_frame(KeenInput.from_actions(), tics, _clock.tic)
		_galaxy_map.animate(tics)
		# A level that ends starts another one (with its own clock).
		if _played != null and _after_frame():
			break
	if _played == null:
		_follow_free_look()
	_objects.place(_clock.blend(), _settings.smooth_motion)
	_place_smooth_view()
	_update_backdrops()
	_update_status()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_leave()
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


## The level being played, or null.
func session() -> Keen4LevelSession:
	return _played


func inventory() -> Keen4Inventory:
	return _inventory


## Shows map [param number]: played when Keen stands in it, otherwise with
## Keen standing still at his start and the view on him.
func _show_level(number: int) -> void:
	_map_number = number
	# A fresh copy: playing changes the map's tiles.
	var map := _data.maps.load_map(number) if _data.maps.has_map(number) else null
	if map == null:
		_show_message(NOT_A_MAP_MESSAGE % number)
		return
	_start = Keen4Start.find(map)
	_objects.clear()
	_keen_item = null
	_played = Keen4LevelSession.start(_data, map, _inventory, randi() & GalaxyWorld.RANDOM_MASK)
	if _played != null:
		_played.keen.god_mode = _god_mode
		_play(map)
	else:
		_look_at(map)
	_score_box.visible = _played != null
	_free_look.set_process(_played == null)
	_update_score_box()


func _play(map: GalaxyMap) -> void:
	_mode = Mode.LEVEL
	_clock.start_level()
	_galaxy_camera = _played.camera
	_show_map(map, _level_sprites())
	_played.world.tile_writer = func(cell: Vector2i, tile: int) -> void:
		_galaxy_map.set_tile(GalaxyMap.Layer.FOREGROUND, cell, tile)
	_objects.show_objects(_played.world.objects)
	_frame_view()
	_view_motion.move_to(Vector2(_camera_anchor.position))
	_view_motion.snap()


## A map where Keen does not play yet: he stands, the keys look around (D3).
func _look_at(map: GalaxyMap) -> void:
	_mode = Mode.LOOK
	_clock.reset()
	_galaxy_camera = GalaxyCamera.for_map(
		Vector2i(map.width, map.height),
		GalaxyCamera.blocks_in(map, Keen4Episode.COLUMN_BLOCK_INFO, true),
		GalaxyCamera.blocks_in(map, Keen4Episode.ROW_BLOCK_INFO, false)
	)
	var sprites := PackedInt32Array()
	if _start.kind != Keen4Start.Kind.NONE:
		sprites.append(_start.sprite)
	_show_map(map, sprites)
	if _start.kind != Keen4Start.Kind.NONE:
		_keen_item = _objects.add(_start.sprite, _start.position, Keen4Start.PRIORITY)
	_centre_view()


## After a logic frame of a played level: draw it, then what comes next.
## Returns whether the level ended.
func _after_frame() -> bool:
	_objects.show_objects(_played.world.objects)
	_frame_view()
	_view_motion.move_to(Vector2(_camera_anchor.position))
	_update_score_box()
	if _played.is_done():
		_show_level(_next_level())
	elif _played.is_lost():
		_inventory.lives -= 1
		if _inventory.lives < 0:
			_show_message(GAME_OVER_MESSAGE)
			_leave()
		else:
			_show_level(_map_number)
	else:
		return false
	return true


## The level after this one; after the last one Keen walks through (and
## after the Megarocket and the high-score map) the first again.
func _next_level() -> int:
	if _map_number >= Keen4Episode.FIRST_LEVEL and _map_number < LAST_WALKING_LEVEL:
		return _map_number + 1
	return Keen4Episode.FIRST_LEVEL


func _leave() -> void:
	set_process(false)
	get_tree().change_scene_to_file.call_deferred(GameLaunch.LAUNCHER_SCENE)


func _update_score_box() -> void:
	_score_box.show_numbers(_inventory.score, _inventory.lives, _inventory.shots)


## With smooth motion the view moves between the logic frames too.
func _place_smooth_view() -> void:
	if _played == null or not _settings.smooth_motion:
		return
	_camera_anchor.position = _view_motion.at(_clock.blend(), true)
	_camera.reset_smoothing()


## Every sprite a played level can show (for xBRZ): Keen's, the items'
## (both frames), the shots'.
func _level_sprites() -> PackedInt32Array:
	var sprites: Dictionary[int, bool] = {}
	for sprite in Keen4Sprites.all().values():
		sprites[sprite] = true
	for sprite in Keen4Sprites.ITEM_FIRST_FRAMES:
		sprites[sprite + 1] = true
	return PackedInt32Array(sprites.keys())


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


## Shift+N and Shift+P: the next or previous map; Shift+G: god mode, as
## the original's debug key F10+G (nothing kills Keen, D5).
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
		KEY_G:
			_god_mode = not _god_mode
			if _played != null:
				_played.keen.god_mode = _god_mode
			return true
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
