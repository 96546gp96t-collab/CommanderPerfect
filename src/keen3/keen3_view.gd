class_name Keen3View
extends Keen3OnlineScreen
## The Keen 3 game screen that the start screen opens. [GameScreen] draws it
## as it draws Keen 1 and 2: the World viewport, the graphics (original,
## xBRZ or HD, F5), widescreen with the HUD ([Keen3Hud], with the ankh
## time), the camera, and short messages. This plays a game of Keen 3 with
## [Keen3LevelPlay]. In widescreen, with the option on, a level with sky
## can show a picture behind it (milestone C9, [Keen3BackdropPictures]).
## Smooth motion (F6) needs nothing of its own: every sprite is an [Actor]
## or Keen, and the map's view blends between its last two corners.
##
## The screen starts on the title (milestone C8, [Keen3MenuScreen]; from the
## start screen with the main menu open), or with
## [code]-- --game=3 --level=N[/code] in level N (1-16), after which the map
## comes; [code]--level=80[/code] starts a new game on the map. A game
## starts on the world map (milestone C6) with "Keens Left". A level that is
## done, or a death, brings Keen back to the map; after the last life GAME
## OVER, then the high scores. Level 16 starts with Mortimer's messages and
## has his Mangling Machine; when it is won the ending follows
## ([Keen3EndingScreen], milestone C7), then GAME OVER and the high scores.
## [code]-- --game=3 --ending[/code] starts the ending at once. Escape opens
## the main menu (while Mortimer speaks it skips him).
##
## On the map the view moves as the original's ([Keen3MapScroll], with the
## camera exactly on it), Messie swims ([Keen3Messie], drawn as an actor),
## and the ship shows one of its four messages at random. The status key
## opens the status screen ([Keen3StatusScreen]) on the map and in a level;
## the game stands still while it, any other window or a menu is open, and
## any key closes it.
##
## The border of every level (2 cells, tile 245, an "OH no!" picture) is
## never drawn: [LevelMap] only draws the playable area and the camera never
## scrolls past it; a level narrower than the view gets black bars.
##
## Two players (milestone C10, [Keen3OnlineScreen]): F7 or the menu adds
## player 2 on the keyboard, with the split screen in a level; or one hosts
## and the other joins online. Online the game never stands still for a
## window or a menu; the player who joined sees the host's game (mode
## REMOTE).
##
## Cheats for testing, as in Keen 1 and 2: Shift+N / Shift+P go to the next
## or previous level (from the map: level 1 / level 16), Shift+I gives every
## item, Shift+G toggles god mode.

const NOT_PLAYABLE_MESSAGE := "Keen 3 has no level %d"
## The window of the ship's messages: 32x6 cells, the prompt in the last row
## (Choco).
const SHIP_WINDOW := Vector2i(32, 6)

## The buttons of two players on one keyboard, which also skip Mortimer and
## close "Keens Left".
const PLAYER_BUTTONS: Array[String] = [
	"p1_jump", "p1_pogo", "p1_fire", "p2_jump", "p2_pogo", "p2_fire"
]

## Whether any key closes the open window (the status screen, the ship).
var _any_key_closes := false


func _ready() -> void:
	# Picked on the start screen: straight on to the main menu.
	var wants_menu := GameLaunch.take_menu_request()
	_set_up_screen()
	_set_up_effects()
	_set_up_menus()
	_connect_online()
	_data = _load_data()
	if _data == null:
		return
	_set_up_texts()
	_set_up_online_data()
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
	elif first == Keen3Files.WORLD_MAP_LEVEL:
		_start_game(null)
	elif Keen3LevelPlay.is_playable(first):
		_progress = play.progress
		_start_level(first)
	else:
		if first != 0:
			_show_message(NOT_PLAYABLE_MESSAGE % first)
		_show_title()
		if wants_menu:
			_open_main_menu()


func _process(delta: float) -> void:
	_message_time_left -= delta
	if _graphics_loader != null and _graphics_loader.poll():
		_apply_graphics()
	_keep_view_size()
	# The game stands still while a menu is open, unless two play online.
	if _menus.is_open() and not _online.is_together():
		_update_effects()
		_update_status()
		return
	_count_down_window(delta)
	_count_down_screen(delta)
	# The game waits while a window ("Keens Left", the status screen) is
	# open (not online), and while Mortimer speaks.
	if _is_mortimer_speaking():
		_run_mortimer(delta)
		# The host's level waits too, but the joined player sees its Keens.
		if _mode == Mode.REMOTE:
			_run_remote(delta)
	elif _mode in [Mode.MAP, Mode.LEVEL] and not _window_pauses():
		_run_ticks(delta)
	elif _mode == Mode.REMOTE:
		_run_remote(delta)
	elif _mode == Mode.ENDING:
		_run_ending(delta)
	_second_player.update(delta)
	_move_camera_anchor()
	_update_backdrops()
	_update_effects()
	_point_arrow()
	_update_status()


func _unhandled_input(event: InputEvent) -> void:
	if play == null:
		# Without the files there is only the message: Escape goes back.
		if event.is_action_pressed("menu"):
			_leave()
		return
	if _menus.is_open():
		_menus.handle_input(event)
	elif _handle_display_keys(event):
		pass
	elif _is_mortimer_speaking():
		if not event.is_action_pressed("menu") and not _is_any_players_button(event):
			return
		_skip_mortimer()
	elif _mode in [Mode.TITLE, Mode.HIGH_SCORES, Mode.GAME_OVER]:
		if not _is_any_press(event):
			return
		_on_screen_key()
	elif event.is_action_pressed("menu"):
		_open_main_menu()
	elif _mode == Mode.ENDING:
		# Any key goes on, but up and down scroll the end text.
		if not _is_any_press(event) or _is_scroll_key(event):
			return
		_keen3_ending.confirm()
	elif _window.visible and _any_key_closes:
		if not _is_any_press(event):
			return
		_close_window()
	elif event.is_action_pressed("status") and _mode in [Mode.MAP, Mode.LEVEL, Mode.REMOTE]:
		_show_status()
	elif _handle_joined_input(event):
		pass
	elif event.is_action_pressed("toggle_second_player") and _mode in [Mode.MAP, Mode.LEVEL]:
		_toggle_second_player()
	elif _window.visible and _buttons_close_window and _is_any_players_button(event):
		_close_window()
	elif _mode not in [Mode.MAP, Mode.LEVEL] or not _handle_cheat_keys(event):
		return
	get_viewport().set_input_as_handled()


## Jump, pogo or fire of playing alone or of either of two players.
static func _is_any_players_button(event: InputEvent) -> bool:
	if _is_button(event):
		return true
	for action in PLAYER_BUTTONS:
		if event.is_action_pressed(action):
			return true
	return false


## Up or down, which scroll the end text.
static func _is_scroll_key(event: InputEvent) -> bool:
	return event.is_action_pressed("move_up") or event.is_action_pressed("move_down")


## A new game (or [param game], a loaded one) on the world map, with
## "Keens Left".
func _start_game(game: Keen3Progress) -> void:
	play.new_game(game)
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
		_session.view_rects = _view_rects()
	var mode := _mode
	while _time_left >= KeenPhysics.TICK and _mode == mode and not _window_pauses():
		_time_left -= KeenPhysics.TICK
		play.step_players(_inputs())
		if _mode == mode:
			_send_tick()
			_show_sprites()
	_place_sprites(_time_left / KeenPhysics.TICK)


## Whether the open window stops the game: not online, where nothing
## pauses.
func _window_pauses() -> bool:
	return _window.visible and not _online.is_together()


func _show_sprites() -> void:
	if _mode == Mode.LEVEL:
		_keen.show_body(_session.keen)
		_second_player.show_body()
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
	_session.tile_changed.connect(_on_game_tile_changed)
	_session.sound_played.connect(_play_game_sound)
	play.session.keen3_sound_played.connect(_on_keen3_sound)
	play.session.border_flashed.connect(_on_border_flashed)
	_session.set_invincible(_god_mode)
	_level_map.show_level(_level, _properties)
	_mode = Mode.LEVEL
	_frame_camera()
	_apply_backdrop()
	_keen.show_body(_session.keen)
	_follow(_keen)
	_camera.follow_exactly(false)
	_add_second_keen()
	_announce_scene()
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
	_map_session.tile_changed.connect(_on_game_tile_changed)
	_map_session.sound_played.connect(_play_game_sound)
	_map_session.ship_used.connect(_on_ship_used)
	_level_map.show_level(_level, _properties)
	_mode = Mode.MAP
	_frame_camera()
	_apply_backdrop()
	_show_sprites()
	_follow(_keen)
	_camera.follow_exactly(true)
	_move_camera_anchor()
	_camera.reset_smoothing()
	_announce_scene()


## On the map the camera shows the map's own view (for the player who
## joined, the host's view); elsewhere as [GameScreen] has it.
func _move_camera_anchor() -> void:
	var blend := _time_left / KeenPhysics.TICK if _settings.smooth_motion else 1.0
	if _mode == Mode.REMOTE and _remote.kind == OnlineMessages.Scene.MAP:
		var center := _remote_view_center(blend)
		if center.is_finite():
			_camera_anchor.position = center
		return
	if _mode != Mode.MAP or play == null or play.map_session == null:
		super._move_camera_anchor()
		return
	_camera_anchor.position = play.map_session.scroll.center(blend)


## Gives the map the view's size, which changes with widescreen (F2).
func _keep_view_size() -> void:
	if play == null:
		return
	play.view_size = Vector2(_settings.game_size())
	if play.map_session != null:
		play.map_session.set_view_size(play.view_size)


## The status screen, over the map or the level, until a key closes it. With
## two players on one keyboard it shows the ankh time of each; for the
## player who joined, his own Keen's.
func _show_status() -> void:
	var window := _window as Keen3Window
	if window == null:
		return
	var ankh_seconds := _ankh_seconds_of(0)
	var partner_seconds := _ankh_seconds_of(1) if _second_player.is_split_screen() else -1
	var inventory := play.inventory
	if _mode == Mode.REMOTE:
		ankh_seconds = maxi(_remote_ankh_seconds(), 0)
		inventory = _progress.inventory
	var lines := _data.status_lines
	Keen3StatusScreen.fill(window, inventory, ankh_seconds, lines, partner_seconds)
	_stay_until_a_key()


## The ankh time of player [param player]'s Keen in a level; 0 elsewhere.
func _ankh_seconds_of(player: int) -> int:
	if _session == null or player >= _session.keens.size():
		return 0
	var body := _session.keens[player] as Keen3Body
	return body.ankh_seconds() if body != null else 0


## The ship speaks: one of its four messages at random, for the other
## player too.
func _on_ship_used() -> void:
	if _data.ship_messages.is_empty():
		return
	var index := randi() % _data.ship_messages.size()
	_send_event(OnlineMessages.Event.SHIP_MESSAGE, index)
	_show_ship_message(index)


## The ship's message [param index], until a key closes it.
func _show_ship_message(index: int) -> void:
	if index < 0 or index >= _data.ship_messages.size():
		return
	var lines := Lang.game_lines(Keen3Texts.SHIP % (index + 1), _data.ship_messages[index])
	_window.open(SHIP_WINDOW)
	for row in lines.size():
		_window.put_text(Vector2i(0, row), lines[row])
	var prompt := Lang.game(Keen3Texts.SHIP_PROMPT, _data.ship_prompt)
	_window.put_text(Vector2i(0, SHIP_WINDOW.y - 1), prompt)
	_stay_until_a_key()


## The open window stays until any key closes it (not by itself, as "Keens
## Left" does); online, where nothing waits, it also closes by itself.
func _stay_until_a_key() -> void:
	_window_time_left = 0.0
	_buttons_close_window = false
	_any_key_closes = true
	_close_by_itself_online()


func _close_window() -> void:
	super._close_window()
	_any_key_closes = false


## The HUD as [GameScreen] shows it, but never with Keen 1's ship parts, and
## in a level with the ankh time: of each Keen with two players on one
## keyboard, of his own Keen for the player who joined.
func _update_hud() -> void:
	_hud.visible = (
		_settings.aspect == DisplaySettings.Aspect.WIDESCREEN
		and _mode in [Mode.MAP, Mode.LEVEL, Mode.REMOTE]
		and not _menus.is_open()
	)
	if not _hud.visible:
		return
	_hud.show_inventory(_progress.inventory)
	var keen_3_hud := _hud as Keen3Hud
	if keen_3_hud == null:
		return
	if _mode == Mode.REMOTE:
		keen_3_hud.show_ankh_time(_remote_ankh_seconds() >= 0, _remote_ankh_seconds())
		return
	var players := 2 if _second_player.is_split_screen() else 1
	var times := PackedInt32Array()
	for player in players:
		var body: Keen3Body = null
		if _session != null and player < _session.keens.size():
			body = _session.keens[player] as Keen3Body
		times.append(body.ankh_seconds() if body != null and body.is_protected() else -1)
	keen_3_hud.show_ankh_times(times)


## The cheats; returns whether [param event] was one. Not for the player
## who joined an online game.
func _handle_cheat_keys(event: InputEvent) -> bool:
	if _joined_online:
		return false
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


func _realistic_grade() -> RealisticGrade:
	return RealisticGrade.keen3()


func _realistic_light_tiles() -> Dictionary[int, RealisticLights.Kind]:
	return Keen3Lights.tiles()
