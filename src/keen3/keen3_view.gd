class_name Keen3View
extends Keen3EndingScreen
## The Keen 3 game screen that the start screen opens. [GameScreen] draws it
## as it draws Keen 1 and 2: the World viewport, the graphics (original,
## xBRZ or HD, F5), widescreen with the HUD ([Keen3Hud], with the ankh
## time), the camera, and short messages. This plays a game of Keen 3 with
## [Keen3LevelPlay].
##
## There is no title or menu yet (milestone C8): the start screen, and
## [code]-- --game=3[/code] with or without [code]--level=80[/code], start a
## new game on the world map (milestone C6) with "Keens Left";
## [code]--level=N[/code] (1-16) starts that level, after which the map
## comes. A level that is done, or a death, brings Keen back to the map;
## after the last life GAME OVER, then the start screen. Level 16 starts
## with Mortimer's messages and has his Mangling Machine; when it is won the
## ending follows ([Keen3EndingScreen], milestone C7), then GAME OVER and
## the start screen. [code]-- --game=3 --ending[/code] starts the ending at
## once. Escape goes back to the start screen at once.
##
## On the map the view moves as the original's ([Keen3MapScroll], with the
## camera exactly on it), Messie swims ([Keen3Messie], drawn as an actor),
## and the ship shows one of its four messages at random. The status key
## opens the status screen ([Keen3StatusScreen]) on the map and in a level;
## the game stands still while it, or any other window, is open, and any
## key closes it.
##
## The border of every level (2 cells, tile 245, an "OH no!" picture) is
## never drawn: [LevelMap] only draws the playable area and the camera never
## scrolls past it; a level narrower than the view gets black bars.
##
## Cheats for testing, as in Keen 1 and 2: Shift+N / Shift+P go to the next
## or previous level (from the map: level 1 / level 16), Shift+I gives every
## item, Shift+G toggles god mode.

const NOT_PLAYABLE_MESSAGE := "Keen 3 has no level %d"
## The window of the ship's messages: 32x6 cells, the prompt in the last row
## (Choco).
const SHIP_WINDOW := Vector2i(32, 6)

## The game being played; null when the files could not be read.
var play: Keen3LevelPlay
## Whether any key closes the open window (the status screen, the ship).
var _any_key_closes := false


func _ready() -> void:
	# The start screen asks every game to open its main menu; Keen 3 has
	# none yet (milestone C8).
	GameLaunch.take_menu_request()
	_set_up_screen()
	_set_up_effects()
	_data = _load_data()
	if _data == null:
		return
	play = Keen3LevelPlay.create(files, _properties)
	play.level_started.connect(_on_level_started)
	play.map_started.connect(_on_map_started)
	play.life_lost.connect(_show_lives)
	play.game_over.connect(_show_game_over)
	play.won.connect(_start_ending)
	var arguments := OS.get_cmdline_user_args()
	var first := Keen2LevelPlay.requested_level(arguments)
	if arguments.has(GameLaunch.ENDING_OPTION):
		play.new_game()
		_progress = play.progress
		_start_ending()
	elif first == 0 or first == Keen3Files.WORLD_MAP_LEVEL:
		_start_game()
	elif Keen3LevelPlay.is_playable(first):
		_progress = play.progress
		_start_level(first)
	else:
		_show_message(NOT_PLAYABLE_MESSAGE % first)
		_start_game()


func _process(delta: float) -> void:
	_message_time_left -= delta
	if _graphics_loader != null and _graphics_loader.poll():
		_apply_graphics()
	_count_down_window(delta)
	_keep_view_size()
	# The game waits while a window ("Keens Left", the status screen) is
	# open, and while Mortimer speaks.
	if _is_mortimer_speaking():
		_run_mortimer(delta)
	elif _mode in [Mode.MAP, Mode.LEVEL] and not _window.visible:
		_run_ticks(delta)
	elif _mode == Mode.ENDING:
		_run_ending(delta)
	elif _mode == Mode.GAME_OVER:
		_count_down_leaving(delta)
	_move_camera_anchor()
	_update_backdrops()
	_update_effects()
	_update_status()


func _unhandled_input(event: InputEvent) -> void:
	if _handle_display_keys(event):
		pass
	elif _is_mortimer_speaking():
		if not event.is_action_pressed("menu") and not _is_button(event):
			return
		_skip_mortimer()
	elif event.is_action_pressed("menu"):
		_leave()
	elif _mode == Mode.ENDING:
		# Any key goes on, but up and down scroll the end text.
		if not _is_any_press(event) or _is_scroll_key(event):
			return
		_keen3_ending.confirm()
	elif _mode == Mode.GAME_OVER:
		if not _is_any_press(event):
			return
		_leave()
	elif _window.visible and _any_key_closes:
		if not _is_any_press(event):
			return
		_close_window()
	elif event.is_action_pressed("status") and _mode in [Mode.MAP, Mode.LEVEL]:
		_show_status()
	elif _window.visible and _buttons_close_window and _is_button(event):
		_close_window()
	elif _mode not in [Mode.MAP, Mode.LEVEL] or not _handle_cheat_keys(event):
		return
	get_viewport().set_input_as_handled()


## Up or down, which scroll the end text.
static func _is_scroll_key(event: InputEvent) -> bool:
	return event.is_action_pressed("move_up") or event.is_action_pressed("move_down")


## A new game on the world map, with "Keens Left".
func _start_game() -> void:
	play.new_game()
	# The HUD and the cheats look at GameScreen's progress.
	_progress = play.progress
	_god_mode = false
	if play.start_map():
		_show_lives(play.inventory.lives)
	else:
		_show_error("The world map could not be read from %s." % files.directory)


## Runs the ticks for [param delta] seconds and shows the result.
func _run_ticks(delta: float) -> void:
	_time_left = minf(_time_left + delta, KeenPhysics.MAX_TICKS_PER_FRAME * KeenPhysics.TICK)
	if _session != null:
		var views: Array[Rect2] = [_own_view()]
		_session.view_rects = views
	var mode := _mode
	while _time_left >= KeenPhysics.TICK and _mode == mode and not _window.visible:
		_time_left -= KeenPhysics.TICK
		play.step(KeenInput.from_actions())
		if _mode == mode:
			_show_sprites()
	_place_sprites(_time_left / KeenPhysics.TICK)


func _show_sprites() -> void:
	if _mode == Mode.LEVEL:
		_keen.show_body(_session.keen)
		_actor_layer.show_actors(_session.actors)
	elif _mode == Mode.MAP:
		_keen.show_on_map(_map_session.keen)
		_actor_layer.show_actors(_map_actors())


## What moves on the map besides Keen: Messie.
func _map_actors() -> Array[Actor]:
	var actors: Array[Actor] = []
	var messie := play.map_session.messie if play.map_session != null else null
	if messie != null:
		actors.append(messie)
	return actors


func _start_level(number: int) -> void:
	if not play.start(number):
		_show_error("Level %d could not be read from %s." % [number, files.directory])


## Shows the level that [member play] has just started.
func _on_level_started(number: int) -> void:
	_clear_screen()
	_level_number = number
	_level = play.level
	_session = play.session
	_session.tile_changed.connect(_level_map.set_tile)
	_session.sound_played.connect(_sounds.play)
	play.session.keen3_sound_played.connect(_play_keen3_sound)
	play.session.border_flashed.connect(_flash_border)
	_session.set_invincible(_god_mode)
	_level_map.show_level(_level, _properties)
	_mode = Mode.LEVEL
	_frame_camera()
	_apply_backdrop()
	_keen.show_body(_session.keen)
	_follow(_keen)
	_camera.follow_exactly(false)
	# Drawn at once: Mortimer speaks over the level with its sprites.
	_show_sprites()
	_place_sprites(1.0)
	if number == Keen3Files.LAST_LEVEL:
		_start_mortimer()


## Shows the world map that [member play] has just started: the done levels
## have their sign already. The camera follows the map's own view.
func _on_map_started() -> void:
	_clear_screen()
	_level_number = Keen3Files.WORLD_MAP_LEVEL
	_level = play.level
	_map_session = play.map_session
	_map_session.tile_changed.connect(_level_map.set_tile)
	_map_session.sound_played.connect(_sounds.play)
	_map_session.ship_used.connect(_show_ship_message)
	_level_map.show_level(_level, _properties)
	_mode = Mode.MAP
	_frame_camera()
	_apply_backdrop()
	_show_sprites()
	_follow(_keen)
	_camera.follow_exactly(true)
	_move_camera_anchor()
	_camera.reset_smoothing()


func _clear_screen() -> void:
	_actor_layer.clear()
	_close_window()
	_time_left = 0.0
	_session = null
	_map_session = null


## On the map the camera shows the map's own view; elsewhere as
## [GameScreen] has it.
func _move_camera_anchor() -> void:
	if _mode != Mode.MAP or play == null or play.map_session == null:
		super._move_camera_anchor()
		return
	var blend := _time_left / KeenPhysics.TICK if _settings.smooth_motion else 1.0
	_camera_anchor.position = play.map_session.scroll.center(blend)


## Gives the map the view's size, which changes with widescreen (F2).
func _keep_view_size() -> void:
	if play == null:
		return
	play.view_size = Vector2(_settings.game_size())
	if play.map_session != null:
		play.map_session.set_view_size(play.view_size)


## The status screen, over the map or the level, until a key closes it.
func _show_status() -> void:
	var ankh_seconds := 0
	var body := _session.keen as Keen3Body if _session != null else null
	if body != null:
		ankh_seconds = body.ankh_seconds()
	var window := _window as Keen3Window
	if window == null:
		return
	Keen3StatusScreen.fill(window, play.inventory, ankh_seconds, _data.status_lines)
	_stay_until_a_key()


## One of the ship's four messages at random, until a key closes it.
func _show_ship_message() -> void:
	if _data.ship_messages.is_empty():
		return
	var lines: PackedStringArray = _data.ship_messages.pick_random()
	_window.open(SHIP_WINDOW)
	for row in lines.size():
		_window.put_text(Vector2i(0, row), lines[row])
	_window.put_text(Vector2i(0, SHIP_WINDOW.y - 1), _data.ship_prompt)
	_stay_until_a_key()


## The open window stays until any key closes it (not by itself, as "Keens
## Left" does).
func _stay_until_a_key() -> void:
	_window_time_left = 0.0
	_buttons_close_window = false
	_any_key_closes = true


func _close_window() -> void:
	super._close_window()
	_any_key_closes = false


## The HUD as [GameScreen] shows it, but never with Keen 1's ship parts, and
## in a level with the ankh time.
func _update_hud() -> void:
	_hud.visible = (
		_settings.aspect == DisplaySettings.Aspect.WIDESCREEN
		and _mode in [Mode.MAP, Mode.LEVEL]
		and not _menus.is_open()
	)
	if not _hud.visible:
		return
	_hud.show_inventory(_progress.inventory)
	var keen_3_hud := _hud as Keen3Hud
	if keen_3_hud == null:
		return
	var body := _session.keen as Keen3Body if _session != null else null
	if body != null:
		keen_3_hud.show_ankh_time(body.is_protected(), body.ankh_seconds())
	else:
		keen_3_hud.show_ankh_time(false, 0)


## The cheats; returns whether [param event] was one.
func _handle_cheat_keys(event: InputEvent) -> bool:
	if event.is_action_pressed("cheat_items"):
		_progress.inventory.give_everything()
		_show_message("Cheat: all keycards and a full raygun")
	elif event.is_action_pressed("cheat_god"):
		_god_mode = not _god_mode
		if _session != null:
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
## From the map, the next level is level 1 and the previous one level 16.
func _neighbor_level(offset: int) -> int:
	if _mode != Mode.LEVEL:
		return Keen3Files.FIRST_LEVEL if offset > 0 else Keen3Files.LAST_LEVEL
	var count := Keen3Files.LAST_LEVEL - Keen3Files.FIRST_LEVEL + 1
	return Keen3Files.FIRST_LEVEL + posmod(_level_number - Keen3Files.FIRST_LEVEL + offset, count)
