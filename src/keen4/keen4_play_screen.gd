class_name Keen4PlayScreen
extends Keen4LevelScreen
## A Keen 4 map being played on the shared [GameScreen] ([Keen4View] adds
## what comes next): a level ([Keen4LevelSession]) or the world map
## ([Keen4MapSession]) on the original's clock ([GalaxyClock], 35 logic
## frames a second), the view following Keen by the original's rules
## ([GalaxyCamera]), the score box ([GalaxyScoreBox]) as the HUD, and over
## the game:
##   - the queue of boxes and fades ([GalaxyScreenQueue]): message boxes
##     that wait for a key, the box while a map "loads", the fade to the
##     next map; the game stands still while it runs;
##   - the status window ([Keen4StatusWindow]) that drops down and rises
##     again ([GalaxyStatusDrop]).
## Every box is drawn with the original pixels in the middle of the
## picture (also in widescreen), over everything.
## A map without a Keen to play is only shown, the keys looking around (as
## in D3). The sounds and the music are [Keen4Audio]'s: every map plays its
## song, the objects play their sounds through their world.

## The pictures of the status window: the window, the arm, the strap.
enum StatusPart { WINDOW, ARM, STRAP }

var _clock := GalaxyClock.new()
var _start: Keen4Start
var _keen_item: GalaxyObjectLayer.Item
## The map shown now (its number, also when it could not be read).
var _map_number := Keen4Episode.FIRST_LEVEL
## Where the free-look point was when the view was last placed.
var _looked_at := Vector2.INF
## What Keen carries from level to level.
var _inventory := Keen4Inventory.new_game()
## The level being played; null where none is.
var _played: Keen4LevelSession
## The world map being played; null where it is not.
var _on_map: Keen4MapSession
## The view's top left, in pixels, frame by frame (smooth motion).
var _view_motion := Interpolation.new()
## The rescued council members, the wetsuit, the levels done, the map.
var _game_progress := Keen4Progress.new()
var _difficulty := GalaxyDifficulty.DEFAULT
var _messages: Keen4Messages
var _boxes: Keen4GameBoxes
var _status: Keen4StatusWindow
var _queue := GalaxyScreenQueue.new()
var _window_sprite := Sprite2D.new()
var _status_drop: GalaxyStatusDrop
var _status_sprites: Array[Sprite2D] = []
var _audio := Keen4Audio.new()

@onready var _score_box: GalaxyScoreBox = %ScoreBox


## After the files are read: the score box, the boxes and the sprites
## that show them, the sounds (rendered in the background).
func _set_up_play() -> void:
	add_child(_audio)
	_audio.load_sounds(_data, _user_settings)
	_score_box.use_graphics(_data.graphics, Keen4Sprites.OBJECTS[&"SCOREBOX"])
	_messages = Keen4Messages.create(_data)
	_boxes = Keen4GameBoxes.create(_data)
	_status = Keen4StatusWindow.create(_data)
	for sprite: Sprite2D in [_window_sprite, Sprite2D.new(), Sprite2D.new(), Sprite2D.new()]:
		sprite.centered = false
		sprite.visible = false
		_score_box.get_parent().add_child(sprite)
		if sprite != _window_sprite:
			_status_sprites.append(sprite)


func _process(delta: float) -> void:
	_message_time_left -= delta
	if _scaled != null and _scaled.poll():
		_apply_graphics()
	var frames := _clock.advance(delta) if _data != null else 0
	for frame in frames:
		var tics := _clock.run_frame()
		if _status_drop != null:
			_advance_status(tics)
		elif not _queue.is_empty():
			_waiting(tics)
			if _queue.advance(tics):
				_show_step()
		elif _run_frame(tics):
			break
	if _mode == Mode.LOOK:
		_follow_free_look()
	_objects.place(_clock.blend(), _settings.smooth_motion)
	_place_overlays()
	_place_smooth_view()
	_update_backdrops()
	_update_status()


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


## The world map being played, or null.
func map_session() -> Keen4MapSession:
	return _on_map


func inventory() -> Keen4Inventory:
	return _inventory


func progress() -> Keen4Progress:
	return _game_progress


## Whether a box or a fade is on the screen (the game waits).
func shows_message() -> bool:
	return not _queue.is_empty()


## The steps still to show.
func queue() -> GalaxyScreenQueue:
	return _queue


## Whether the status window is on the screen.
func shows_status() -> bool:
	return _status_drop != null


## One logic frame of what is played; returns whether it ended (or a box
## stopped it).
func _run_frame(tics: int) -> bool:
	if _played != null:
		_played.run_frame(_frame_input(tics), tics, _clock.tic)
	elif _on_map != null:
		_on_map.run_frame(_frame_input(tics), tics, _clock.tic)
	else:
		return false
	_galaxy_map.animate(tics)
	_objects.show_objects(_played_world().objects)
	_frame_view()
	_view_motion.move_to(Vector2(_camera_anchor.position))
	_update_score_box()
	return _after_frame()


## What Keen is steered by in a frame of [param tics] tics: the keys
## ([Keen4FrontScreen]: a demo's recorded input).
func _frame_input(_tics: int) -> KeenInput:
	return KeenInput.from_actions()


## What follows a frame ([Keen4View]); returns whether the frames stop.
func _after_frame() -> bool:
	return not _queue.is_empty()


## Called every frame while the queue waits ([Keen4View] blinks a choice).
func _waiting(_tics: int) -> void:
	pass


## The world being played.
func _played_world() -> GalaxyWorld:
	if _played != null:
		return _played.world
	return _on_map.world if _on_map != null else null


## Plays [param session] in [param map].
func _play(session: Keen4LevelSession, map: GalaxyMap) -> void:
	_played = session
	_on_map = null
	_played.player.god_mode = _god_mode
	_start_playing(map, _played.camera, _played.world)


## Plays the world map [param session].
func _play_map(session: Keen4MapSession) -> void:
	_on_map = session
	_played = null
	_start_playing(session.map, session.camera, session.world)


func _start_playing(map: GalaxyMap, camera: GalaxyCamera, world: GalaxyWorld) -> void:
	_mode = Mode.LEVEL
	_clock.start_level()
	_galaxy_camera = camera
	_show_map(map, _level_sprites())
	world.tile_writer = func(cell: Vector2i, tile: int) -> void:
		_galaxy_map.set_tile(GalaxyMap.Layer.FOREGROUND, cell, tile)
	world.back_tile_writer = func(cell: Vector2i, tile: int) -> void:
		_galaxy_map.set_tile(GalaxyMap.Layer.BACKGROUND, cell, tile)
	world.sound_player = _audio.play
	_audio.play_map_song(_map_number)
	_objects.show_objects(world.objects)
	_frame_view()
	_view_motion.move_to(Vector2(_camera_anchor.position))
	_view_motion.snap()
	_score_box.visible = true
	_free_look.set_process(false)
	_update_score_box()


## A map where Keen does not play: he stands, the keys look around (D3).
func _look_at(map: GalaxyMap) -> void:
	_played = null
	_on_map = null
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
	_score_box.visible = false
	_free_look.set_process(true)


## Shows [param screens] one by one, each until a key is pressed; then
## [param then] (when valid).
func _show_screens(screens: Array[Image], then: Callable) -> void:
	for screen in screens:
		_queue.add_box(screen)
	_after_queue(then)


## Runs [param then] once the queue is done (at once when it is empty).
func _after_queue(then: Callable) -> void:
	if _queue.is_empty():
		if then.is_valid():
			then.call()
		return
	_queue.then = then
	_show_step()


## The queue's step on the screen: its picture and brightness.
func _show_step() -> void:
	var step := _queue.current()
	var image: Image = step.image if step != null else null
	_window_sprite.visible = image != null
	if image != null:
		_window_sprite.texture = ImageTexture.create_from_image(image)
	_screen.modulate = Color(1, 1, 1) * (step.brightness if step != null else 1.0)
	_screen.modulate.a = 1.0
	_place_overlays()


## The status window drops down (Enter).
func _open_status() -> void:
	if _status == null:
		return
	var level := _played.difficulty if _played != null else _difficulty
	var pictures: Array[Image] = [
		_status.window(_map_number, _inventory, _game_progress, level),
		_status.arm(),
		_status.strap(),
	]
	for part in pictures.size():
		var picture := pictures[part]
		_status_sprites[part].texture = (
			ImageTexture.create_from_image(picture) if picture != null else null
		)
	_status_drop = GalaxyStatusDrop.new()
	_audio.play(&"status_down")
	_place_overlays()


func _advance_status(tics: int) -> void:
	_status_drop.advance(tics)
	if _status_drop.is_gone():
		_status_drop = null
	_place_overlays()


## The boxes and the status window in the middle of the picture, also
## after F2.
func _place_overlays() -> void:
	var left := (_settings.game_size().x - GalaxyWindow.SCREEN_SIZE.x) / 2.0
	_window_sprite.position = Vector2(left, 0)
	var dropping := _status_drop != null
	for part in _status_sprites.size():
		_status_sprites[part].visible = dropping
	if not dropping:
		return
	var shift := Vector2(left, _status_drop.shift())
	# The window is drawn on a whole screen; the arm and the strap are only
	# their own pictures.
	_status_sprites[StatusPart.WINDOW].position = shift
	_status_sprites[StatusPart.ARM].position = Vector2(Keen4StatusWindow.ARM_AT) + shift
	_status_sprites[StatusPart.STRAP].position = Vector2(Keen4StatusWindow.STRAP_AT) + shift
	_status_sprites[StatusPart.ARM].visible = _status_drop.shows_arm()
	_status_sprites[StatusPart.STRAP].visible = _status_drop.shows_strap()


## A key or button just pressed (the original waits for a new press).
static func _is_new_press(event: InputEvent) -> bool:
	var key := event as InputEventKey
	if key != null:
		return key.pressed and not key.echo
	var button := event as InputEventJoypadButton
	return button != null and button.pressed


func _update_score_box() -> void:
	_score_box.show_numbers(_inventory.score, _inventory.lives, _inventory.shots)


## With smooth motion the view moves between the logic frames too.
func _place_smooth_view() -> void:
	if (_played == null and _on_map == null) or not _settings.smooth_motion:
		return
	_camera_anchor.position = _view_motion.at(_clock.blend(), true)
	_camera.reset_smoothing()


## Every sprite a played map can show (for xBRZ): Keen's, the items'
## (both frames), the shots', the world map's.
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
