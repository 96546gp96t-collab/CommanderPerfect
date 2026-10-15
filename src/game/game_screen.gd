class_name GameScreen
extends Control
## What [LevelView] has on the screen, and how it is drawn: the World
## viewport stretched over the window with every game pixel the same size
## ([DisplaySettings]), the graphics (original, xBRZ or HD), full screen or
## a window, the camera's limits, the status line and the [Hud], short
## messages and the [GameWindow]. The keys F1-F6 change how it looks.
##
## [LevelView] extends it with what happens in the game; the mode (what is
## shown) and the state that the drawing needs live here.

## What is on the screen; see [LevelView].
enum Mode { NONE, TITLE, HIGH_SCORES, MAP, LEVEL, GAME_OVER, ENDING, LOOK, REMOTE }

## Seconds a message such as "Level 3 completed!" stays on the screen.
const MESSAGE_SECONDS := 3.0
## The largest number of screen pixels per game pixel that the World
## viewport uses.
const MAX_RENDER_SCALE := 8
const EVEN_PIXELS_SHADER := preload("res://src/graphics/even_pixels.gdshader")
const GRAPHICS_TITLES := StatusLine.GRAPHICS_TITLES
const MISSING_HD_MESSAGE := "No HD graphics yet: make them with tools/make_hd_graphics.sh"

var _mode := Mode.NONE
var _graphics: EgaGraphics
## The map or level on the screen, and its data.
var _level_number := 0
var _level: LevelData
var _user_settings := UserSettings.new()
var _settings := _user_settings.display
var _progress := GameProgress.new()
var _ending: EndingSequence
## Shown below the status for [constant MESSAGE_SECONDS].
var _message := ""
var _message_time_left := 0.0
## Counts down while a window that closes by itself is open: "Keens Left",
## and online every window of the game.
var _window_time_left := 0.0
## Whether jump, pogo or fire close the open window (the map messages);
## otherwise only Enter does.
var _buttons_close_window := false
var _god_mode := false
var _sounds := SoundPlayer.new()
var _menus := MenuController.new()
var _textures: GraphicsTextures
var _graphics_loader: GraphicsLoader
## The picture of Keen's house; null when FINALE.CK1 could not be read.
var _finale_image: Image
## Whether the line with the keys is shown while playing; hidden until F1
## asks for it.
var _show_help := false
## Whether this player is in someone else's online game.
var _joined_online := false

@onready var _screen: TextureRect = %Screen
@onready var _world: SubViewport = %World
@onready var _level_map: LevelMap = %LevelMap
@onready var _free_look: FreeLook = %FreeLook
@onready var _keen: Keen = %Keen
@onready var _mark: SpriteView = %Mark
@onready var _actor_layer: ActorLayer = %ActorLayer
@onready var _camera: LevelCamera = %Camera
@onready var _camera_anchor: Node2D = %CameraAnchor
@onready var _world_2: SubViewport = %World2
@onready var _second_player: TwoPlayerView = %TwoPlayers
@onready var _pictures: PictureLayer = %Pictures
@onready var _hud: Hud = %Hud
@onready var _picture: Sprite2D = %Picture
@onready var _window_light: Sprite2D = %WindowLight
@onready var _window: GameWindow = %Window
@onready var _status_label: Label = %StatusLabel
@onready var _help_label: Label = %HelpLabel
@onready var _online: OnlinePlay = %Online
@onready var _remote: RemoteGame = %Remote


## Puts the sprites [param blend] of the way from the previous tick to the
## last one, when motion is smooth; otherwise on the last one.
func _place_sprites(blend: float) -> void:
	var smooth := _settings.smooth_motion
	_keen.place(blend, smooth)
	_second_player.place(blend, smooth)
	_mark.place(blend, smooth)
	_actor_layer.place(blend, smooth)


## What this player sees, in level pixels.
func _own_view() -> Rect2:
	var view_size := Vector2(_settings.game_size())
	return Rect2(_camera.get_screen_center_position() - view_size / 2.0, view_size)


## F1-F6: the help line, widescreen, the shape of the pixels, full screen,
## the graphics and smooth motion. Returns whether [param event] was one of
## them.
func _handle_display_keys(event: InputEvent) -> bool:
	if event.is_action_pressed("toggle_fullscreen"):
		_user_settings.fullscreen = not _is_fullscreen()
		_apply_window_mode()
	elif event.is_action_pressed("toggle_widescreen"):
		_settings.aspect = (
			DisplaySettings.Aspect.WIDESCREEN
			if _settings.aspect == DisplaySettings.Aspect.ORIGINAL
			else DisplaySettings.Aspect.ORIGINAL
		)
	elif event.is_action_pressed("toggle_pixel_aspect"):
		_settings.correct_pixel_aspect = not _settings.correct_pixel_aspect
	elif event.is_action_pressed("toggle_graphics"):
		_settings.graphics = MenuController.next_graphics(_settings.graphics, _menus.hd_available)
		_show_message(GRAPHICS_TITLES[_settings.graphics])
		_apply_graphics()
	elif event.is_action_pressed("toggle_smooth_motion"):
		_settings.smooth_motion = not _settings.smooth_motion
		_show_message("Smooth motion " + ("on" if _settings.smooth_motion else "off"))
	elif event.is_action_pressed("toggle_help"):
		_show_help = not _show_help
		return true
	else:
		return false
	_apply_display_settings()
	_user_settings.save()
	return true


## Switches to the graphics the settings ask for. xBRZ and HD graphics are
## made on a worker thread the first time; until they are ready the current
## graphics stay.
func _apply_graphics() -> void:
	if _textures == null:
		return
	var style := _settings.graphics
	if style == DisplaySettings.Graphics.ORIGINAL:
		_use_graphics(null)
		return
	var scaled := _graphics_loader.fetch(style)
	if scaled != null:
		_use_graphics(scaled)
	elif _graphics_loader.has_failed(style):
		_show_message(MISSING_HD_MESSAGE)
		_settings.graphics = DisplaySettings.Graphics.ORIGINAL
		_use_graphics(null)
	elif _graphics_loader.is_busy():
		_show_message("Preparing %s..." % GRAPHICS_TITLES[style])


func _use_graphics(scaled: ScaledGraphics) -> void:
	if _textures.scaled == scaled:
		return
	_textures.use_scaled(scaled)
	_level_map.use_tile_set(LevelTileSet.build(_graphics, _textures))
	_keen.refresh()
	_second_player.refresh()
	_mark.refresh()
	_actor_layer.refresh()
	_window.queue_redraw()
	_hud.queue_redraw()
	_pictures.queue_redraw()
	if _picture.visible:
		_show_picture(true)
	_fit_screen()


## Full screen or a window, as the settings say.
func _apply_window_mode() -> void:
	if _user_settings.fullscreen == _is_fullscreen():
		return
	DisplayServer.window_set_mode(
		(
			DisplayServer.WINDOW_MODE_FULLSCREEN
			if _user_settings.fullscreen
			else DisplayServer.WINDOW_MODE_WINDOWED
		)
	)


## Whether the window fills the screen now. The player can also change that
## with the green button of the Mac window.
static func _is_fullscreen() -> bool:
	return (
		DisplayServer.window_get_mode()
		in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
	)


## Shows or hides the picture of Keen's house, with the light in the
## bedroom window as the conversation asks.
func _show_picture(shown: bool) -> void:
	_picture.visible = shown
	if not shown:
		return
	_picture.texture = _textures.finale(_finale_image)
	_picture.position.x = floorf((_settings.game_size().x - FinaleImage.SIZE.x) / 2.0)
	var bitmap := _ending.window_bitmap()
	_window_light.visible = not bitmap.is_empty()
	if not bitmap.is_empty():
		_window_light.texture = _textures.bitmap(bitmap)
		_window_light.position = EndingSequence.WINDOW_POSITION


func _apply_display_settings() -> void:
	_online.set_view_size(_settings.game_size())
	_window.view_size = _settings.game_size()
	_hud.view_size = _settings.game_size()
	_hud.queue_redraw()
	_window.queue_redraw()
	_fit_screen()
	if _level != null:
		_frame_camera()
	if _picture != null and _picture.visible:
		_show_picture(true)


func _frame_camera() -> void:
	var view_size := _settings.game_size()
	var area := LevelMap.playable_pixels(_level)
	_camera.frame(area, view_size)
	_second_player.frame(area, view_size)
	_free_look.bounds = LevelCamera.center_range(LevelCamera.limits_for(area, view_size), view_size)
	_free_look.move_to(_free_look.position)


func _fit_screen() -> void:
	var rect := _settings.fit_rect(size)
	_screen.position = rect.position
	_screen.size = rect.size
	var game_size := _settings.game_size()
	var render_scale := 1
	if not _settings.is_original_picture():
		render_scale = clampi(ceili(rect.size.y / game_size.y), 2, MAX_RENDER_SCALE)
	var smooth_textures := _textures != null and _textures.scaled != null
	for viewport: SubViewport in [_world, _world_2]:
		DisplaySettings.set_up_viewport(viewport, game_size, render_scale, smooth_textures)


func _show_message(text: String) -> void:
	_message = text
	_message_time_left = MESSAGE_SECONDS


func _show_error(message: String) -> void:
	_status_label.text = message
	_help_label.visible = false
	push_error(message)


func _on_settings_changed() -> void:
	_sounds.set_enabled(_user_settings.sound_enabled)
	_online.sound_enabled = _user_settings.sound_enabled
	_apply_window_mode()
	_apply_graphics()
	_apply_display_settings()


func _close_window() -> void:
	# Online the game goes on behind a menu, which has the window then.
	if _menus.is_open():
		return
	_window.close()
	_window_time_left = 0.0
	_buttons_close_window = false


func _count_down_window(delta: float) -> void:
	if _window_time_left <= 0.0:
		return
	_window_time_left -= delta
	if _window_time_left <= 0.0:
		_close_window()


func _update_status() -> void:
	var playing := _mode in [Mode.MAP, Mode.LEVEL, Mode.LOOK, Mode.REMOTE]
	_help_label.visible = _show_help and playing and not _menus.is_open()
	_update_hud()
	if _level == null:
		return
	# A menu has the screen to itself.
	if _menus.is_open():
		_status_label.text = ""
		return
	# With the HUD in the corners, only messages are shown, in the middle.
	_status_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER if _hud.visible else HORIZONTAL_ALIGNMENT_LEFT
	)
	if _hud.visible or (not playing and _mode != Mode.ENDING):
		var notes := PackedStringArray()
		if _hud.visible and _god_mode:
			notes.append("GOD MODE")
		if _joined_online and _mode in [Mode.TITLE, Mode.HIGH_SCORES]:
			notes.append("Waiting for %s to start a game" % _online.partner_name())
		if _message_time_left > 0.0:
			notes.append(_message)
		_status_label.text = "\n".join(notes)
		return
	var title := "Ending" if _mode == Mode.ENDING else GameFiles.level_title(_level_number)
	var lines := PackedStringArray([StatusLine.picture_text(title, _settings)])
	if _mode in [Mode.MAP, Mode.LEVEL]:
		var inventory := StatusLine.inventory_text(_progress.inventory)
		lines.append(inventory + ("   GOD MODE" if _god_mode else ""))
	if _message_time_left > 0.0:
		lines.append(_message)
	_status_label.text = "\n".join(lines)


## The HUD is for widescreen, while Keen is on the map or in a level.
func _update_hud() -> void:
	_hud.visible = (
		_settings.aspect == DisplaySettings.Aspect.WIDESCREEN
		and _mode in [Mode.MAP, Mode.LEVEL, Mode.REMOTE]
		and not _menus.is_open()
	)
	if _hud.visible:
		_hud.show_inventory(_progress.inventory)
