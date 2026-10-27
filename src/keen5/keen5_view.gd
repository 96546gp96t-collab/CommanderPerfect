class_name Keen5View
extends GalaxyOnlineScreen
## The Keen 5 game screen that the start screen opens (milestones E3-E11):
## the shared Galaxy game ([GalaxyOnlineScreen] on [GalaxyJoinedScreen],
## [GalaxyCoopScreen], [GalaxyMenuScreen], [GalaxyFrontScreen] and
## [GalaxyFlowScreen], with Keen 5's numbers from
## [method Keen5Episode.game_rules]) and what only Keen 5 does
## (docs/keen5/gameplay.md, "The flow of a game", "The title loop", "The
## end", "The control panel"):
##   - it starts with the title loop (the intro, demo 0, the story, demo 1,
##     the high scores on map 15, demo 2, demo 3); a key opens the control
##     panel (new game on Easy, Normal or Hard; load, save in
##     [code]user://keen5/saves[/code] ([Keen5SavedGame]), configure,
##     Paddle War, end game, quit or choose another game);
##     [code]-- --game=5 --level=N[/code] opens map N at once (0 the
##     world map, 1-13 the levels, 15 the high-score map; 14 does not
##     exist);
##   - a new game starts on the world map, the Omegamatic
##     ([Keen5MapSession]: teleporters, elevators, the shafts), behind its
##     "Keen enters ..." box;
##   - a level entered from the map: "One moment", its box with the
##     count-down, the level; done by a door, its fuse or the door to
##     Korath III it counts 1 or 14 ([Keen5Progress]); after a fuse the
##     fuse message ([Keen5Messages]); then back on the map, behind the
##     map's box, at the place he entered, or after the door to Korath III
##     on Korath III with the box "Keen steps out onto Korath III";
##   - the QED destroyed (map 12) or E+N+D: the end pages (the secret end
##     when the Korath III fuse was broken), then the name typed in on the
##     high-score table, the high scores and the title loop again;
##   - a death: one life less and the box with Try Again and Exit to
##     Armageddon; with no life left the galaxy explodes
##     ([Keen5GalaxyExplosion]), then the high scores;
##   - Enter: the status window with the keycard ([Keen5StatusWindow]); on
##     Korath III it names Korath III's base; F1 the help; B+A+T the gems,
##     99 charges, a life and the keycard;
##   - two players (milestone E11; docs/keen5/gameplay.md, "Two players",
##     "Online"): F7 or the panel's Two Players card on one keyboard, split
##     screen, the keycard, the fuses and the lives shared, on the world
##     map one Keen that both steer and that rides the teleporters and
##     elevators for both; online with Keen 5's id, the fuse message and
##     the Korath III box named for the joiner ([Keen5BoxNames]), Keen 5's
##     numbers in every snapshot ([Keen5OnlineState]).
## The sounds and songs are Keen 5's ([Keen5Sounds], milestone E8): every
## map its own song, the story, the help, the end and game over theirs; the
## fuse message waits for the level-exit sound to end.
##
## Keys: the shared ones (arrows, jump, pogo, fire); Enter the status
## window; F1 the help; F7 player 2; Escape the control panel (not while a ride on the
## world map holds the game); Shift+N / Shift+P the
## next or previous map; Shift+S the sound (AdLib, PC speaker, off) and
## Shift+M the music, stored in the shared settings (as Keen 4's);
## Shift+G god mode and Shift+I all four gems, the
## keycard and 99 charges (Keen 1-4's testing cheats); Shift+F1 the help
## line; F2-F6 as in Keen 1-4 (widescreen, pixel shape, full screen,
## graphics: original or xBRZ, smooth motion). [code]--random-seed=N[/code]
## makes the random start of every map repeatable (the regression
## pictures).

## The testing cheats' messages, worded as in Keen 1-4.
const GOD_MODE_MESSAGE := "Cheat: god mode %s"
const EVERYTHING_MESSAGE := "Cheat: all four gems, the keycard and 99 stunner charges"
## Shift+I gives at least this many charges (as Keen 4's).
const CHEAT_SHOTS := GalaxySavedGame.EVERYTHING_SHOTS
## Keen's place on the world map below this row is Korath III (Omni
## CK_LoadLevel: his box's top tile beyond row 100).
const KORATH_ROW := Keen5MapSession.KORATH_ROW
const RANDOM_SEED_OPTION := "--random-seed="

var _messages: Keen5Messages


func _init() -> void:
	rules = Keen5Episode.game_rules()


func _ready() -> void:
	# Picking the game on the start screen asks for its menu; Keen 5 starts
	# with its title loop as the original (a key opens the menu), so the
	# request is taken here and not left for the next game.
	GameLaunch.take_menu_request()
	_set_up_screen()
	if not _load_data():
		return
	_set_up_play()
	_set_up_flow()
	_set_up_front()
	_set_up_panel()
	_set_up_coop()
	_set_up_online()
	_messages = Keen5NamedMessages.create_named(_data, _box_names)
	(_box_names as Keen5BoxNames).messages = _messages
	var arguments := OS.get_cmdline_user_args()
	var random_seed := requested_seed(arguments)
	if random_seed >= 0:
		seed(random_seed)
	var requested := requested_map(arguments)
	if requested >= 0:
		_show_level(requested)
	else:
		_start_title_loop()


func _unhandled_input(event: InputEvent) -> void:
	if _is_help_key(event):
		if not _box_waits():
			get_viewport().set_input_as_handled()
			_open_help()
			return
	elif _handle_display_keys(event):
		get_viewport().set_input_as_handled()
		return
	if _data == null:
		return
	if _front_input(event) or _flow_input(event):
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_escape()
	elif _handle_map_keys(event):
		get_viewport().set_input_as_handled()


## The seed of the random starts that [param arguments] ask for with
## --random-seed=N, or -1.
static func requested_seed(arguments: PackedStringArray) -> int:
	for argument in arguments:
		if argument.begins_with(RANDOM_SEED_OPTION):
			return argument.trim_prefix(RANDOM_SEED_OPTION).to_int()
	return -1


## The map that [param arguments] ask for with --level=N, or -1.
static func requested_map(arguments: PackedStringArray) -> int:
	for argument in arguments:
		if argument.begins_with(GameLaunch.LEVEL_OPTION):
			return argument.trim_prefix(GameLaunch.LEVEL_OPTION).to_int()
	return -1


func _new_inventory() -> GalaxyInventory:
	return Keen5Inventory.new_game()


func _new_progress() -> GalaxyProgress:
	return Keen5Progress.new()


func _new_status_window() -> GalaxyStatusWindow:
	return Keen5StatusWindow.create_keen5(_data, rules)


func _new_session(map: GalaxyMap, number: int, random_start: int) -> GalaxyLevelSession:
	return Keen5LevelSession.start_level(
		_data, rules, map, _inventory, random_start, _difficulty, number
	)


func _new_map_session(map: GalaxyMap, random_start: int) -> GalaxyMapSession:
	return Keen5MapSession.start_map(_data, rules, map, _game_progress, random_start)


func _new_saved_game() -> GalaxySavedGame:
	return Keen5SavedGame.new(rules)


func _new_box_names() -> GalaxyBoxNames:
	return Keen5BoxNames.new()


func _new_online_state() -> GalaxyOnlineState:
	return Keen5OnlineState.new()


## The joiner reads the secret end when the host broke Korath III's fuse
## (the levels done come with every snapshot).
func _remote_end_text() -> int:
	return end_text()


## A ride on the world map (a teleporter, an elevator's door, the flight
## in it) holds the game: a save could not put Keen back into it, so the
## panel waits until it is over (the original's own loops take no key).
func _panel_waits() -> bool:
	if _on_map == null:
		return false
	var session := _on_map as Keen5MapSession
	return session.rides() or (session.keen as Keen5MapKeen).is_flying()


## The world map's box says "Keen steps out onto Korath III" when Keen
## will stand there (Omni CK_LoadLevel).
func _loading_box(number: int) -> Array[Image]:
	if number == rules.world_map and _steps_onto_korath():
		return _boxes.loading_game_text(Keen5Episode.KORATH_TEXT)
	return super(number)


func _steps_onto_korath() -> bool:
	var keen_5 := _game_progress as Keen5Progress
	if keen_5.korath_arrival:
		return true
	return GalaxyUnits.to_tile(keen_5.map_position.y) > KORATH_ROW


## On Korath III the status window's location is its base, level 13's
## name, not the world map's (seen in the original, E6).
func _status_map() -> int:
	if _on_map != null and GalaxyUnits.to_tile(_on_map.keen.position.y) > KORATH_ROW:
		return Keen5Progress.KORATH_LEVEL
	return super()


## What the level counts as: 1, 14 by its fuse, 15 by the QED
## ([method Keen5LevelSession.result]).
func _done_value(finished: GalaxyLevelSession) -> int:
	return (finished as Keen5LevelSession).result()


## After a level (Omni CK_GameLoop): the QED's end shows the end pages;
## a fuse shows its message first; the door to Korath III puts Keen there;
## then the exit sound and the map.
func _after_level_done(finished: GalaxyLevelSession) -> void:
	var session := finished as Keen5LevelSession
	match session.result():
		Keen5LevelSession.DONE_BY_QED:
			_game_progress.mark_done(_map_number, 0)
			_start_ending(end_text())
		Keen5LevelSession.DONE_BY_FUSE:
			_play_sound(&"level_exit")
			_show_fuse_message(_back_to_map)
		_:
			(_game_progress as Keen5Progress).korath_arrival = session.left_for_korath()
			_exit_to_map()


## The end's text (Omni help_endgame): the secret end when Korath III's
## level was done by its fuse.
func end_text() -> int:
	if (_game_progress as Keen5Progress).korath_fuse_broken():
		return rules.secret_end_text
	return rules.end_text


## No life left (Omni CK_GameLoop): the galaxy explodes, then the high
## scores.
func _game_over() -> void:
	_start_scene(Keen5GalaxyExplosion.from_data(_data), _game_ended)


## E+N+D (Omni CK_PlayLoop): the QED counts as destroyed, the end follows
## at once.
func _cheat_end() -> void:
	_queue.clear()
	_start_ending(end_text())


## B+A+T: Keen 5 adds the keycard (Omni CK_ItemCheat).
func _give_items() -> void:
	(_inventory as Keen5Inventory).keycard = true
	super()


## The two screens after a fuse, each 30 tics before a key counts (Omni
## CK5_FuseMessage); then [param then]. First the game stands still until
## the sound playing (the level's exit) is over (Omni SD_WaitSoundDone).
func _show_fuse_message(then: Callable) -> void:
	var sound_left := _audio.remaining_tics()
	if sound_left > 0:
		_queue.add(null, sound_left)
	for screen in _messages.fuse(_map_number):
		_queue.add(screen, Keen5Messages.KEY_WAIT_TICS)
		_queue.add_box(screen)
	_after_queue(then)


## Shift+N and Shift+P: the next or previous map (over the missing one);
## Shift+S and Shift+M: the sound and the music; Shift+G and Shift+I: the
## testing cheats. Returns whether it was one.
func _handle_map_keys(event: InputEvent) -> bool:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or not key.shift_pressed:
		return false
	if event.is_action_pressed("cheat_god"):
		_toggle_god_mode()
		return true
	if event.is_action_pressed("cheat_items") and (_played != null or _on_map != null):
		_give_everything()
		return true
	if _handle_sound_keys(key.keycode):
		return true
	var step := 0
	match key.keycode:
		KEY_N:
			step = 1
		KEY_P:
			step = -1
		_:
			return false
	if _data != null:
		_show_level(_next_map(_map_number, step))
	return true


## Shift+S: the next sound setting (AdLib, PC speaker, off); Shift+M: the
## music on or off; each said and stored in the shared settings at once
## (as Keen 4's before its menus). Returns whether [param keycode] was one.
func _handle_sound_keys(keycode: Key) -> bool:
	match keycode:
		KEY_S:
			_show_message(_audio.next_mode(_user_settings))
		KEY_M:
			_show_message(_audio.toggle_music(_user_settings))
		_:
			return false
	_user_settings.save()
	return true


## The map [param step] (1 or -1) from [param number] that exists, round
## from the last to the world map.
func _next_map(number: int, step: int) -> int:
	var count := rules.last_map + 1
	var next := posmod(number + step, count)
	while not _data.maps.has_map(next) and next != number:
		next = posmod(next + step, count)
	return next


## Shift+G: god mode, as the original's debug key F10+G (nothing kills Keen
## but falling out of the level).
func _toggle_god_mode() -> void:
	_god_mode = not _god_mode
	if _played != null:
		_played.player.god_mode = _god_mode
		_record_event(
			GalaxySavedGame.Event.GOD_MODE_ON if _god_mode else GalaxySavedGame.Event.GOD_MODE_OFF
		)
	_show_message(Lang.text(GOD_MODE_MESSAGE) % Lang.text("on" if _god_mode else "off"))


## Shift+I in a level or on the map: all four gems, the keycard and at
## least 99 charges ([method Keen5SavedGame.give_everything]; kept among a
## saved level's frames).
func _give_everything() -> void:
	_new_saved_game().give_everything(_inventory)
	_record_event(GalaxySavedGame.Event.EVERYTHING)
	_update_score_box()
	_show_message(Lang.text(EVERYTHING_MESSAGE))


func _realistic_grade() -> RealisticGrade:
	return RealisticGrade.keen5()


func _realistic_light_tiles() -> Dictionary[int, RealisticLights.Kind]:
	return Keen5Lights.foreground()


func _alien_sign_tables() -> Array[AlienSignTables.Table]:
	return [AlienSignTables.keen5_background(), AlienSignTables.keen5_foreground()]


func _realistic_back_light_tiles() -> Dictionary[int, RealisticLights.Kind]:
	return Keen5Lights.background()
