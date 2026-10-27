class_name Keen4View
extends GalaxyOnlineScreen
## The Keen 4 game screen that the start screen opens (milestones D3-D10;
## since milestone E13 on the shared Galaxy game: [GalaxyOnlineScreen] on
## [GalaxyJoinedScreen], [GalaxyCoopScreen], [GalaxyMenuScreen],
## [GalaxyFrontScreen] and [GalaxyFlowScreen], with Keen 4's numbers from
## [method Keen4Episode.game_rules]), and what only Keen 4 does
## (docs/keen4/architecture.md, "The flow of Keen 4"; Omni
## `ck_game.c:CK_GameLoop`, facts only):
##   - it starts with the title loop (intro, story, demos, high scores); a
##     key opens the control panel (new game on Easy, Normal or Hard on the
##     world map, with the box "Keen enters the Shadowlands"; load, save,
##     configure, end game, choose game, quit; F1: the help);
##     [code]-- --game=4 --level=N[/code] opens map N at once (0 the world
##     map, 1-17 the levels, 18 the Megarocket, 19 the high-score map);
##   - on the world map jump, pogo or fire on an entrance: "One moment",
##     then the level's "Keen enters ..." box with Keen counting down, a
##     fade, and the level; in water without the wetsuit "I can't swim!";
##   - walking out of a level, the Foot, a rescue or the wetsuit: the level
##     is done (rescue and wetsuit boxes first); back on the map with its
##     box, at the place he entered, the level's flag thrown (the Foot: he
##     flies); Lindsey and the janitor show their messages on the way;
##   - a death: one life less and the box "You didn't make it past …"
##     with Try Again (the level again) or Exit to Shadowlands (the map);
##     with no life left "Game Over!", then the high scores;
##   - after the eighth rescue (or the cheat E+N+D) the end pages, then the
##     name typed in on the high-score table, the high scores and the title
##     loop again; B+A+T gives the gems, 99 charges and a life.
## Keen 4 keeps its own ways where the Galaxy game later went another
## (the flags of [GalaxyGameRules] that its rules switch off: the music
## plays on through the boxes, a loaded level is replayed with its sounds,
## only the world's sounds go online, ...).
##
## Keys: the shared ones (arrows, jump, pogo, fire); Enter the status
## window; F1 the help; Escape the control panel; Shift+N / Shift+P
## the next or previous map; Shift+G god mode and Shift+I all gems and
## 99 charges (Keen 1-3's testing cheats, D13.2); Shift+S the sound and
## Shift+M the music; Shift+F1 and F2-F6 as in
## Keen 1-3 (help line, widescreen, pixel shape, full screen, graphics:
## original or xBRZ, smooth motion).

## The testing cheats' messages, worded as in Keen 1-3.
const GOD_MODE_MESSAGE := "Cheat: god mode %s"
const EVERYTHING_MESSAGE := "Cheat: all four gems and 99 stunner charges"
## Taking the wetsuit, the game stands still until its sound ("foot
## appear", 1.05 seconds) has played, then shows Keen's box; the exit sound
## comes after the box (seen in the original, D13: 1.9 seconds with the
## pictures loading; Omni CK4_ShowWetsuitMessage, SD_WaitSoundDone).
const WETSUIT_SOUND_TICS := 73

## The messages of the council, Lindsey, the janitor and the wetsuit.
var _messages: Keen4Messages
## Keen 4's own settings (the score box, the quiet AdLib sounds).
var _keen4_settings: GalaxySettings:
	get:
		return _galaxy_settings


func _init() -> void:
	rules = Keen4Episode.game_rules()


func _ready() -> void:
	# Picking the game on the start screen asks for its menu; Keen 4 starts
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
	var names := _box_names as Keen4BoxNames.GameNames
	_messages = Keen4NamedMessages.create_named(_data, names.keen_4)
	names.messages = _messages
	var requested := _requested_map()
	if requested < 0:
		_start_title_loop()
	else:
		_show_level(requested)


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


## The rescued council members, the wetsuit, the levels done, the map.
func progress() -> Keen4Progress:
	return _game_progress as Keen4Progress


func _new_inventory() -> GalaxyInventory:
	return Keen4Inventory.new_game()


func _new_progress() -> GalaxyProgress:
	return Keen4Progress.new()


func _new_status_window() -> GalaxyStatusWindow:
	return Keen4StatusWindow.create(_data, rules)


func _new_session(map: GalaxyMap, number: int, random_start: int) -> GalaxyLevelSession:
	return Keen4LevelSession.start_level(
		_data, rules, map, _inventory, random_start, _difficulty, number
	)


func _new_map_session(map: GalaxyMap, random_start: int) -> GalaxyMapSession:
	return Keen4MapSession.start_map(_data, rules, map, _game_progress, random_start)


func _new_saved_game() -> GalaxySavedGame:
	return Keen4SavedGame.new(rules)


func _new_box_names() -> GalaxyBoxNames:
	return Keen4BoxNames.GameNames.new()


func _new_online_state() -> GalaxyOnlineState:
	return Keen4OnlineState.GameState.new()


## Keen 4's boxes ("I can't swim!" too) under Keen 4's names.
func _new_named_boxes() -> GalaxyGameBoxes:
	return Keen4NamedBoxes.create_named(_data, (_box_names as Keen4BoxNames.GameNames).keen_4)


## Only the world map's song is rendered first (Keen 4's order, D9).
func _first_song_maps() -> PackedInt32Array:
	return PackedInt32Array([rules.world_map])


## On the world map: "I can't swim!" in water without the wetsuit, then
## an entrance taken.
func _after_map_frame() -> void:
	if _on_map.take_conversation() == Keen4MapKeen.CANT_SWIM:
		_show_screens([(_boxes as Keen4GameBoxes).cant_swim()], Callable())
	super()


## In a level: Lindsey's and the janitor's messages, then done or lost.
func _after_level_frame() -> void:
	var asked := _played.take_conversation()
	if asked == Keen4Lindsey.MESSAGE:
		# Her message stops the music; the map's song starts again after it
		# (Omni CK4_ShowPrincessMessage).
		_stop_music()
		_show_screens(_messages.lindsey(_map_number), _play_map_song.bind(_map_number))
	elif asked == Keen4Council.JANITOR:
		_play_council_song()
		_show_screens(_messages.janitor(), _play_map_song.bind(_map_number))
	super()


## The level is done (Omni CK_GameLoop): its flag will be thrown (the
## Foot: Keen flies); a rescue or the wetsuit shows its boxes first; then
## the map.
func _after_level_done(finished: GalaxyLevelSession) -> void:
	var ending := finished.ending()
	var keen_4 := progress()
	keen_4.foot_flight = ending == Keen4Inchworm.FOOT_ENDING
	match ending:
		Keen4Council.RESCUED:
			_play_sound(&"level_exit")
			_play_council_song()
			var before := keen_4.rescue()
			_show_screens(_messages.council(_map_number, before), _after_rescue)
		Keen4Wetsuit.TAKEN:
			keen_4.wetsuit = true
			_queue.add(null, WETSUIT_SOUND_TICS)
			_show_screens(_messages.wetsuit(), _exit_to_map)
		_:
			_exit_to_map()


func _after_rescue() -> void:
	if progress().all_rescued():
		_start_end_pages()
	else:
		_back_to_map()


## The end pages (after the eighth rescue).
func _start_end_pages() -> void:
	_start_ending(rules.end_text)


## The council's (and the janitor's) song (Omni ck4_specialMusic).
func _play_council_song() -> void:
	_audio.start_song(Keen4Sounds.COUNCIL_SONG)


## E+N+D (Omni CK_PlayLoop, CK_CheckKeys): the game ends as a rescue of the
## eighth council member here.
func _cheat_end() -> void:
	var map := _map_number
	_played = null
	_on_map = null
	var keen_4 := progress()
	keen_4.rescued = Keen4Progress.COUNCIL_COUNT - 1
	if rules.is_level(map):
		keen_4.mark_done(map)
	var before := keen_4.rescue()
	_play_council_song()
	_show_screens(_messages.council(map, before), _start_end_pages)


## The table keeps the council members rescued beside the score.
func _high_score_count() -> int:
	return progress().rescued


## A demo plays on Normal without changing the game's difficulty (as Keen
## 4 did before milestone E13).
func _begin_demo(high_scores_shown: bool) -> void:
	var kept := _difficulty
	_difficulty = GalaxyDifficulty.DEFAULT
	super(high_scores_shown)
	_difficulty = kept


## The name typed in on map 19 (as Keen 4 did before milestone E13: the
## map is played with an inventory of its own; the song of the map last
## shown plays on).
func _begin_name_entry(place: int) -> void:
	_title_layer.clear()
	var map := _data.maps.load_map(rules.high_score_map)
	var session := Keen4LevelSession.start_level(
		_data, rules, map, Keen4Inventory.new_game(), 0, GalaxyDifficulty.DEFAULT, map.number
	)
	_play(session, map)
	_score_box.visible = false
	# The original draws only the map's tiles behind the table here (seen).
	_objects.visible = false
	_show_board(map)
	_board.start_typing(place)
	_front = Front.NAME_ENTRY


## Shift+N and Shift+P: the next or previous map; Shift+G and Shift+I:
## the testing cheats of Keen 1-3 ([method _handle_cheat_keys]); Shift+S
## the sound (AdLib, PC speaker, off) and Shift+M the music.
func _handle_map_keys(event: InputEvent) -> bool:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or not key.shift_pressed:
		return false
	if _handle_cheat_keys(event):
		return true
	var step := 0
	match key.keycode:
		KEY_N:
			step = 1
		KEY_P:
			step = -1
		KEY_S:
			_show_message(_audio.next_mode(_user_settings))
			_user_settings.save()
			return true
		KEY_M:
			_show_message(_audio.toggle_music(_user_settings))
			_user_settings.save()
			return true
		_:
			return false
	var count := rules.last_map + 1
	_show_level(posmod(_map_number + step, count))
	return true


## Keen 1-3's testing cheats on their shared keys (D13.2), with their
## messages: Shift+G god mode, as the original's debug key F10+G (nothing
## kills Keen but falling out of the level, D5), anywhere in a game;
## Shift+I all four gems and 99 charges, in a level and on the world map.
## Both go into a saved level's frames. Returns whether it was one.
func _handle_cheat_keys(event: InputEvent) -> bool:
	if event.is_action_pressed("cheat_god"):
		_toggle_god_mode()
	elif event.is_action_pressed("cheat_items") and (_played != null or _on_map != null):
		Keen4Cheats.give_everything(_inventory)
		_record_event(GalaxySavedGame.Event.EVERYTHING)
		_update_score_box()
		_show_message(Lang.text(EVERYTHING_MESSAGE))
	else:
		return false
	return true


func _toggle_god_mode() -> void:
	_god_mode = not _god_mode
	if _played != null:
		_played.player.god_mode = _god_mode
		if _played.partner != null:
			_played.partner.god_mode = _god_mode
		_record_event(
			GalaxySavedGame.Event.GOD_MODE_ON if _god_mode else GalaxySavedGame.Event.GOD_MODE_OFF
		)
	_show_message(Lang.text(GOD_MODE_MESSAGE) % Lang.text("on" if _god_mode else "off"))


## The map asked for with --level=N, or -1 (a new game).
static func _requested_map() -> int:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with(GameLaunch.LEVEL_OPTION):
			return argument.trim_prefix(GameLaunch.LEVEL_OPTION).to_int()
	return -1


func _realistic_grade() -> RealisticGrade:
	return RealisticGrade.keen4()


func _realistic_light_tiles() -> Dictionary[int, RealisticLights.Kind]:
	return Keen4Lights.foreground()


func _realistic_back_light_tiles() -> Dictionary[int, RealisticLights.Kind]:
	return Keen4Lights.background()
