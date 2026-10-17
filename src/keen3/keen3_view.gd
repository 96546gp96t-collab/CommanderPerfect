class_name Keen3View
extends Keen3SceneScreen
## The Keen 3 game screen that the start screen opens. [GameScreen] draws it
## as it draws Keen 1 and 2: the World viewport, the graphics (original,
## xBRZ or HD, F5), widescreen with the HUD ([Keen3Hud], with the ankh
## time), the camera that follows Keen, and short messages. This plays Keen
## 3's levels with [Keen3LevelPlay].
##
## For now (milestone C3) there is no title, menu or world map: the game
## starts in level 1, or in the level given with [code]-- --level=N[/code]
## (1-16). The exit leads to the next level; after level 16 the start screen
## comes back. A death costs a life and starts the level again with "Keens
## Left"; after the last life GAME OVER, then the start screen. Escape goes
## back to it at once.
##
## The border of every level (2 cells, tile 245, an "OH no!" picture) is
## never drawn: [LevelMap] only draws the playable area and the camera never
## scrolls past it; a level narrower than the view gets black bars.
##
## Cheats for testing, as in Keen 1 and 2: Shift+N / Shift+P go to the next
## or previous level, Shift+I gives every item, Shift+G toggles god mode.

const NOT_PLAYABLE_MESSAGE := "Keen 3 has no level %d"
const FINISHED_MESSAGE := "That was the last level"
## Seconds after the last level before the start screen comes back, unless
## a key is pressed.
const FINISHED_SECONDS := 4.0

## The levels being played; null when the files could not be read.
var play: Keen3LevelPlay


func _ready() -> void:
	# The start screen asks every game to open its main menu; Keen 3 has
	# none yet (milestone C8).
	GameLaunch.take_menu_request()
	_set_up_screen()
	if _load_data() == null:
		return
	_progress.inventory = Keen3Inventory.new()
	play = Keen3LevelPlay.create(files, _properties, _progress.inventory)
	play.level_started.connect(_on_level_started)
	play.life_lost.connect(_show_lives)
	play.game_over.connect(_show_game_over)
	play.finished.connect(_leave_after.bind(FINISHED_MESSAGE, FINISHED_SECONDS))
	var first := Keen2LevelPlay.requested_level(OS.get_cmdline_user_args())
	if first != 0 and not Keen3LevelPlay.is_playable(first):
		_show_message(NOT_PLAYABLE_MESSAGE % first)
		first = 0
	_start_level(first if first != 0 else Keen3Files.FIRST_LEVEL)


func _process(delta: float) -> void:
	_message_time_left -= delta
	if _graphics_loader != null and _graphics_loader.poll():
		_apply_graphics()
	_count_down_window(delta)
	# The game waits while a window ("Keens Left") is open.
	if _mode == Mode.LEVEL and not _window.visible:
		_run_ticks(delta)
	elif _mode == Mode.GAME_OVER:
		_count_down_leaving(delta)
	_move_camera_anchor()
	_update_backdrops()
	_update_status()


func _unhandled_input(event: InputEvent) -> void:
	if _handle_display_keys(event):
		pass
	elif event.is_action_pressed("menu"):
		_leave()
	elif _mode == Mode.GAME_OVER:
		if not _is_any_press(event):
			return
		_leave()
	elif _window.visible and _buttons_close_window and _is_button(event):
		_close_window()
	elif _mode != Mode.LEVEL or not _handle_cheat_keys(event):
		return
	get_viewport().set_input_as_handled()


## Runs the ticks for [param delta] seconds and shows the result.
func _run_ticks(delta: float) -> void:
	_time_left = minf(_time_left + delta, KeenPhysics.MAX_TICKS_PER_FRAME * KeenPhysics.TICK)
	var views: Array[Rect2] = [_own_view()]
	_session.view_rects = views
	while _time_left >= KeenPhysics.TICK and _mode == Mode.LEVEL and not _window.visible:
		_time_left -= KeenPhysics.TICK
		play.step(KeenInput.from_actions())
		_show_sprites()
	_place_sprites(_time_left / KeenPhysics.TICK)


func _show_sprites() -> void:
	_keen.show_body(_session.keen)
	_actor_layer.show_actors(_session.actors)


func _start_level(number: int) -> void:
	if not play.start(number):
		_show_error("Level %d could not be read from %s." % [number, files.directory])


## Shows the level that [member play] has just started.
func _on_level_started(number: int) -> void:
	_actor_layer.clear()
	_close_window()
	_time_left = 0.0
	_level_number = number
	_level = play.level
	_session = play.session
	_session.tile_changed.connect(_level_map.set_tile)
	_session.sound_played.connect(_sounds.play)
	play.session.keen3_sound_played.connect(_play_keen3_sound)
	_session.set_invincible(_god_mode)
	_level_map.show_level(_level, _properties)
	_mode = Mode.LEVEL
	_frame_camera()
	_apply_backdrop()
	_keen.show_body(_session.keen)
	_follow(_keen)


## The HUD as [GameScreen] shows it, but never with Keen 1's ship parts, and
## with the ankh time.
func _update_hud() -> void:
	_hud.visible = (
		_settings.aspect == DisplaySettings.Aspect.WIDESCREEN
		and _mode == Mode.LEVEL
		and not _menus.is_open()
	)
	if not _hud.visible:
		return
	_hud.show_inventory(_progress.inventory)
	var keen_3_hud := _hud as Keen3Hud
	var body := _session.keen as Keen3Body if _session != null else null
	if keen_3_hud != null and body != null:
		keen_3_hud.show_ankh_time(body.is_protected(), body.ankh_seconds())


## The cheats; returns whether [param event] was one.
func _handle_cheat_keys(event: InputEvent) -> bool:
	if event.is_action_pressed("cheat_items"):
		_progress.inventory.give_everything()
		_show_message("Cheat: all keycards and a full raygun")
	elif event.is_action_pressed("cheat_god"):
		_god_mode = not _god_mode
		_session.set_invincible(_god_mode)
		_show_message("Cheat: god mode " + ("on" if _god_mode else "off"))
	elif event.is_action_pressed("next_level"):
		_start_level(_neighbor_level(1))
	elif event.is_action_pressed("previous_level"):
		_start_level(_neighbor_level(-1))
	else:
		return false
	return true


## The level [param offset] places after the current one; wraps around.
func _neighbor_level(offset: int) -> int:
	var count := Keen3Files.LAST_LEVEL - Keen3Files.FIRST_LEVEL + 1
	return Keen3Files.FIRST_LEVEL + posmod(_level_number - Keen3Files.FIRST_LEVEL + offset, count)
