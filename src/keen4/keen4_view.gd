class_name Keen4View
extends Keen4LevelScreen
## The Keen 4 game screen that the start screen opens (milestones D3-D6).
## It opens level 1, or map N with [code]-- --game=4 --level=N[/code] (0 is
## the world map, 1-17 the levels, 18 the Megarocket, 19 the high-score
## map).
##
## In a map where Keen stands (the levels, the Megarocket, the high-score
## map) he is played ([Keen4LevelSession]) on the original's clock
## ([GalaxyClock], 35 logic frames a second): the view follows him by the
## original's rules ([GalaxyCamera]) and the score box ([GalaxyScoreBox]) is
## the HUD. In the Well of Wishes (17) Keen swims. Until the world map
## exists (D7) the game goes on like this: walking out of a level, rescuing
## a council member or taking the wetsuit opens the next level (1-17, then 1
## again), a death starts the level again (one life less), and without
## lives left the start screen returns.
## Message boxes (the council, the janitor, Lindsey, the wetsuit;
## [Keen4Messages]) stop the game and wait for a key each, as the
## original's; the rescued council members and the wetsuit are kept in
## [Keen4Progress] for the world map (D7) and the end (D8).
## On the world map (D7) Keen still stands and the movement keys look
## around, as in D3: the point they move is where Keen would be, and the
## view follows it by the same rules.
##
## Keys: the shared ones (arrows, jump, pogo, fire); Escape back to the
## start screen; Shift+N / Shift+P the next or previous map; F1-F6 as in
## Keen 1-3 (help line, widescreen, pixel shape, full screen, graphics:
## original or xBRZ, smooth motion).

const NOT_A_MAP_MESSAGE := "Keen 4 has no map %d"
## The last level of the round before the world map exists (D7): after the
## Well of Wishes (17) level 1 follows.
const LAST_PLAYED_LEVEL := 17
const GAME_OVER_MESSAGE := "Game over"
## After the eighth rescue (the end comes in D8).
const ALL_RESCUED_MESSAGE := "All eight council members are rescued"

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
## The rescued council members, the wetsuit, the levels done.
var _progress := Keen4Progress.new()
var _messages: Keen4Messages
## The message screens still to show (the first is on the screen), and
## what follows the last.
var _screens: Array[Image] = []
var _after_screens := Callable()
var _window_sprite := Sprite2D.new()

@onready var _score_box: GalaxyScoreBox = %ScoreBox


func _ready() -> void:
	# Picking the game on the start screen asks for its menu; there is none
	# yet (D10), so the request is taken here and not left for the next game.
	GameLaunch.take_menu_request()
	_set_up_screen()
	if not _load_data():
		return
	_score_box.use_graphics(_data.graphics, Keen4Sprites.OBJECTS[&"SCOREBOX"])
	_messages = Keen4Messages.create(_data)
	_window_sprite.centered = false
	_window_sprite.visible = false
	_score_box.get_parent().add_child(_window_sprite)
	_show_level(_requested_map())


func _process(delta: float) -> void:
	_message_time_left -= delta
	if _scaled != null and _scaled.poll():
		_apply_graphics()
	# A message box stops the game until a key is pressed.
	var frames := _clock.advance(delta) if _screens.is_empty() else 0
	for frame in frames:
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
	if not _screens.is_empty():
		if _is_new_press(event):
			get_viewport().set_input_as_handled()
			_next_screen()
		return
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


func progress() -> Keen4Progress:
	return _progress


## Whether a message box is on the screen (the game waits for a key).
func shows_message() -> bool:
	return not _screens.is_empty()


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
	_played = Keen4LevelSession.start(
		_data, map, _inventory, randi() & GalaxyWorld.RANDOM_MASK, GalaxyDifficulty.DEFAULT, number
	)
	if _played != null:
		_played.player.god_mode = _god_mode
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
	var asked := _played.take_conversation()
	if asked == Keen4Lindsey.MESSAGE:
		_show_screens(_messages.lindsey(_map_number), Callable())
	elif asked == Keen4Council.JANITOR:
		_show_screens(_messages.janitor(), Callable())
	if _played.is_done():
		_finish_level()
	elif _played.is_lost():
		_inventory.lives -= 1
		if _inventory.lives < 0:
			_show_message(GAME_OVER_MESSAGE)
			_leave()
		else:
			_show_level(_map_number)
	else:
		return not _screens.is_empty()
	return true


## The level is done: a rescue or the wetsuit shows its messages first;
## then the next level.
func _finish_level() -> void:
	_progress.mark_done(_map_number)
	match _played.ending():
		Keen4Council.RESCUED:
			var before := _progress.rescue()
			_show_screens(_messages.council(_map_number, before), _after_rescue)
		Keen4Wetsuit.TAKEN:
			_progress.wetsuit = true
			_show_screens(_messages.wetsuit(), _show_next_level)
		_:
			_show_next_level()


func _after_rescue() -> void:
	if _progress.all_rescued():
		_show_message(ALL_RESCUED_MESSAGE)
	_show_next_level()


func _show_next_level() -> void:
	_show_level(_next_level())


## The level after this one; after the last (and after the Megarocket and
## the high-score map) the first again.
func _next_level() -> int:
	if _map_number >= Keen4Episode.FIRST_LEVEL and _map_number < LAST_PLAYED_LEVEL:
		return _map_number + 1
	return Keen4Episode.FIRST_LEVEL


## Shows [param screens] one by one, each until a key is pressed; then
## [param then] (when valid).
func _show_screens(screens: Array[Image], then: Callable) -> void:
	if screens.is_empty():
		if then.is_valid():
			then.call()
		return
	_screens = screens
	_after_screens = then
	_put_screen()


func _next_screen() -> void:
	_screens.pop_front()
	if not _screens.is_empty():
		_put_screen()
		return
	_window_sprite.visible = false
	var then := _after_screens
	_after_screens = Callable()
	if then.is_valid():
		then.call()


## The first screen, in the middle of the picture (also in widescreen).
func _put_screen() -> void:
	_window_sprite.texture = ImageTexture.create_from_image(_screens[0])
	var width := _settings.game_size().x
	_window_sprite.position = Vector2((width - GalaxyWindow.SCREEN_SIZE.x) / 2, 0)
	_window_sprite.visible = true


## A key or button just pressed (the original waits for a new press).
static func _is_new_press(event: InputEvent) -> bool:
	var key := event as InputEventKey
	if key != null:
		return key.pressed and not key.echo
	var button := event as InputEventJoypadButton
	return button != null and button.pressed


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
				_played.player.god_mode = _god_mode
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
