class_name MenuController
extends Node
## The menus of the game, shown in the [GameWindow]: the main menu, the save
## slots, the controls, the options, the story, short messages and asking
## for a name for the high score table. Menus stack: Escape goes back one.
##
## For playing online ([member online]): hosting or joining by IP or through
## Steam, typing a name, an address or a password, and leaving again. What
## the main menu offers depends on whether this player hosts or joined.
##
## What a menu does to the game (a new game, loading, quitting) is left to
## the game screen through [signal chosen]; the controls and options are
## changed here and stored straight away.
##
## While [method is_open] the game screen hands every input event to
## [method handle_input] and stands still.

## The player picked [param id] (see the CHOICE_ constants); [param value] is
## the save slot where that matters.
signal chosen(id: StringName, value: int)
## The display or sound settings changed; the game screen applies them.
signal settings_changed
## The player typed a name for the high score table and pressed Enter.
signal name_entered(player_name: String)
## The last menu closed.
signal closed
## The player wants the list of his friends' games on Steam (again).
signal steam_games_wanted

const CHOICE_RESUME := &"resume"
## A second player joins, or leaves when two are playing.
const CHOICE_SECOND_PLAYER := &"second_player"
const CHOICE_NEW_GAME := &"new_game"
const CHOICE_LOAD := &"load"
const CHOICE_SAVE := &"save"
const CHOICE_HIGH_SCORES := &"high_scores"
const CHOICE_TITLE := &"title"
const CHOICE_QUIT := &"quit"
## Back to the start screen, to choose another game.
const CHOICE_CHOOSE_GAME := &"choose_game"
## Online: host (value 0 by IP, 1 through Steam; see [member host_password]),
## join by IP ([member join_address], [member join_password]), join a
## friend's game on Steam (value: its place in the list), stop hosting or
## leave the host's game.
const CHOICE_HOST := &"host"
const CHOICE_JOIN_IP := &"join_ip"
const CHOICE_JOIN_STEAM := &"join_steam"
const CHOICE_LEAVE_ONLINE := &"leave_online"
const HOST_BY_IP := 0
const HOST_THROUGH_STEAM := 1

const MAIN := &"main"
const SLOTS_LOAD := &"slots_load"
const SLOTS_SAVE := &"slots_save"
const OVERWRITE := &"overwrite"
const CONTROLS := &"controls"
const KEY_SET := &"key_set"
const PRESS_KEY := &"press_key"
const OPTIONS := &"options"
const STORY := &"story"
const MESSAGE := &"message"
const NAME := &"name"
const ONLINE := &"online"
const HOST_SETUP := &"host_setup"
const STEAM_GAMES := &"steam_games"
const TEXT := &"text"
## What a text being typed is for.
const TEXT_PLAYER_NAME := &"player_name"
const TEXT_ADDRESS := &"address"
const TEXT_PASSWORD := &"password"
const TEXT_STEAM_PASSWORD := &"steam_password"
const PASSWORD_LENGTH := 20
const ADDRESS_LENGTH := 32

## Characters per line and lines per page of the story, as for the end text.
const TEXT_WIDTH := EndingSequence.TEXT_WIDTH
const TEXT_LINES := EndingSequence.TEXT_LINES
const PAGE_KEYS: Dictionary[Key, int] = {KEY_PAGEUP: -TEXT_LINES, KEY_PAGEDOWN: TEXT_LINES}
## How the options menu names the graphics, in the order of
## [enum DisplaySettings.Graphics].
const GRAPHICS_LABELS: Array[String] = ["ORIGINAL", "XBRZ", "HD"]
const FIRST_PRINTABLE := 32
const LAST_PRINTABLE := 126

var window: GameWindow
var saves := SaveGames.new()
var settings := UserSettings.new()
## The story, laid out for the window; empty when STORYTXT.CK1 is missing.
var story := PackedStringArray()
## Whether the player has made HD graphics, so that they can be picked.
var hd_available := false
## Online: see [OnlineMenuInfo]. The game screen fills it in before it
## opens the main menu.
var online := OnlineMenuInfo.new()
## What the player chose for hosting and joining, read by the game screen
## after [signal chosen].
var host_password := ""
var host_locked := true
var join_address := ""
var join_password := ""
var _stack: Array[Menu] = []
var _seconds := 0.0
var _story_offset := 0
## The slot waiting for "overwrite?" to be answered.
var _pending_slot := 0
## The action waiting for its new key.
var _pending_action := ""
## The set of keys shown in the key set menu: 0 for one player, 1 and 2 for
## the players when two play.
var _key_set := 0
var _typed_name := ""
var _place_word := ""
## Online: the kind of host being set up, the text being typed and what it
## is for, and the choice to continue with once the player has a name.
var _host_kind := HOST_BY_IP
var _typed_text := ""
var _text_purpose := &""
var _after_name := &""
var _steam_pick := 0


func is_open() -> bool:
	return not _stack.is_empty()


## The main menu. [param in_game] adds "Return to game", "Save game" and
## adding or removing the second player ([param two_players] says whether
## two are playing now); saving is only possible when [param can_save] (on
## the world map).
func open_main(in_game: bool, can_save: bool, two_players := false) -> void:
	_stack.clear()
	if online.role == OnlineMenuInfo.Role.CLIENT:
		_push(_joined_menu(in_game))
		return
	var menu := Menu.create(MAIN, ["     MAIN MENU"])
	if in_game:
		menu.add("Return to Game", CHOICE_RESUME)
		if online.role == OnlineMenuInfo.Role.OFFLINE:
			menu.add("Remove Player 2" if two_players else "Add Player 2", CHOICE_SECOND_PLAYER)
	menu.add("New Game", CHOICE_NEW_GAME)
	menu.add("Continue Game", SLOTS_LOAD)
	menu.add("Online Game", ONLINE)
	if in_game:
		menu.add("Save Game", SLOTS_SAVE if can_save else &"save_not_here")
	if not story.is_empty():
		menu.add("Story", STORY)
	menu.add("High Scores", CHOICE_HIGH_SCORES)
	menu.add("Controls", CONTROLS)
	menu.add("Options", OPTIONS)
	if in_game:
		menu.add("Quit to Title", CHOICE_TITLE)
	menu.add("Choose Game", CHOICE_CHOOSE_GAME)
	menu.add("Quit", CHOICE_QUIT)
	_push(menu)


## A message that any key closes.
func show_message(lines: PackedStringArray) -> void:
	_push(Menu.create(MESSAGE, lines))


## Asks for a name for place [param place_word] ("first") of the high
## score table.
func ask_name(place_word: String) -> void:
	_stack.clear()
	_typed_name = ""
	_place_word = place_word
	_push(Menu.create(NAME))


func close_all() -> void:
	_stack.clear()
	window.close()
	closed.emit()


func _process(delta: float) -> void:
	if not is_open():
		return
	var cursor_before := MenuView.cursor_char(_seconds)
	_seconds += delta
	if MenuView.cursor_char(_seconds) != cursor_before:
		_redraw()


## Handles one input event while a menu is open.
func handle_input(event: InputEvent) -> void:
	if not is_open() or not event.is_pressed():
		return
	match _top().kind:
		PRESS_KEY:
			_handle_new_key(event)
		NAME:
			_handle_name_key(event)
		TEXT:
			_handle_text_key(event)
		STORY:
			_handle_story_key(event)
		MESSAGE:
			if not event.is_echo():
				_pop()
		_:
			_handle_menu_key(event)


func _handle_menu_key(event: InputEvent) -> void:
	var menu := _top()
	if _is_up(event):
		menu.move(-1)
		_redraw()
	elif _is_down(event):
		menu.move(1)
		_redraw()
	elif event.is_echo():
		return
	elif event.is_action_pressed("ui_cancel"):
		_pop()
	elif _is_confirm(event) and menu.current() != null:
		_pick(menu, menu.current())
	elif menu.kind in [SLOTS_LOAD, SLOTS_SAVE] and event is InputEventKey:
		# The original picks a slot with the number keys.
		var slot: int = event.physical_keycode - KEY_0
		if slot >= 1 and slot <= SaveGames.SLOT_COUNT and menu.items[slot - 1].enabled:
			_pick(menu, menu.items[slot - 1])


func _pick(menu: Menu, item: Menu.Item) -> void:
	match menu.kind:
		MAIN:
			_pick_main(item.id)
		SLOTS_LOAD:
			close_all()
			chosen.emit(CHOICE_LOAD, item.value)
		SLOTS_SAVE:
			if saves.exists(item.value):
				_pending_slot = item.value
				_push(
					(
						Menu
						. create(OVERWRITE, ["That game position", "already exists!"])
						. add("Overwrite it", &"yes")
						. add("Keep it", &"no")
					)
				)
			else:
				_save(item.value)
		OVERWRITE:
			_pop()
			if item.id == &"yes":
				_save(_pending_slot)
		CONTROLS:
			_pick_key_set(item)
		KEY_SET:
			_pick_control(item.id)
		OPTIONS:
			_toggle_option(item.id)
		ONLINE:
			_pick_online(item.id)
		HOST_SETUP:
			_pick_host_setup(item.id)
		STEAM_GAMES:
			_pick_steam_game(item)


func _pick_main(id: StringName) -> void:
	match id:
		SLOTS_LOAD:
			_push(_slots_menu(SLOTS_LOAD, ["  Continue which game?"]))
		SLOTS_SAVE:
			_push(_slots_menu(SLOTS_SAVE, ["  Save in which position?"]))
		&"save_not_here":
			show_message(["You can only save the", "game on the world map.", "", "   Press a key"])
		STORY:
			_story_offset = 0
			_push(Menu.create(STORY))
		CONTROLS:
			_push(_controls_menu())
		OPTIONS:
			_push(_options_menu())
		ONLINE:
			_push(_online_menu())
		_:
			close_all()
			chosen.emit(id, 0)


func _save(slot: int) -> void:
	chosen.emit(CHOICE_SAVE, slot)
	_stack.clear()
	show_message(
		["Game saved in position %d." % slot, "Continue it from the main", "menu.  Press a key"]
	)


func _slots_menu(kind: StringName, header: PackedStringArray) -> Menu:
	var menu := Menu.create(kind, header)
	for slot in range(1, SaveGames.SLOT_COUNT + 1):
		var summary := saves.summary(slot)
		var label := "%d  %s" % [slot, summary if not summary.is_empty() else "-"]
		menu.add(label, &"slot", slot, kind == SLOTS_SAVE or not summary.is_empty())
	return menu


## The keys for playing alone, and for each of two players.
func _controls_menu() -> Menu:
	var menu := Menu.create(CONTROLS, ["  CONTROLS"])
	menu.add("One player", KEY_SET, 0)
	menu.add("Two players: player 1", KEY_SET, 1)
	menu.add("Two players: player 2", KEY_SET, 2)
	menu.add("Reset to defaults", &"reset")
	return menu


func _pick_key_set(item: Menu.Item) -> void:
	if item.id == &"reset":
		KeyBindings.reset()
		settings.save()
		show_message(["All keys are back as", "they were.  Press a key"])
		return
	_key_set = item.value
	_push(_key_set_menu())


## The keys of one set (see [member _key_set]); pick one to change it.
func _key_set_menu() -> Menu:
	var title := "  ONE PLAYER" if _key_set == 0 else "  PLAYER %d OF TWO" % _key_set
	var menu := Menu.create(KEY_SET, [title, "  Pick one to change it"])
	var actions: Dictionary = (
		KeyBindings.ACTIONS if _key_set == 0 else KeyBindings.PLAYER_ACTIONS[_key_set - 1]
	)
	for action: String in actions:
		menu.add("%-7s %s" % [actions[action], KeyBindings.describe(action)], StringName(action))
	return menu


func _pick_control(id: StringName) -> void:
	_pending_action = String(id)
	_push(
		(
			Menu
			. create(
				PRESS_KEY,
				[
					"Press the new key for",
					"%s, or Escape." % KeyBindings.action_name(_pending_action).to_upper(),
				]
			)
		)
	)


func _handle_new_key(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or key.is_echo():
		return
	if key.physical_keycode == KEY_ESCAPE:
		_pop()
		return
	var code := KeyBindings.code_of(key)
	if not KeyBindings.can_bind(code):
		return
	KeyBindings.bind(_pending_action, code)
	settings.save()
	_pop()
	_refresh_controls()


## Rebuilds the menu of the key set so that it shows the new keys.
func _refresh_controls() -> void:
	var cursor := _top().cursor
	_stack[-1] = _key_set_menu()
	_top().cursor = cursor
	settings.save()
	_redraw()


func _options_menu() -> Menu:
	var display := settings.display
	var menu := Menu.create(OPTIONS, ["  OPTIONS"])
	menu.add("Sound         " + _on_off(settings.sound_enabled), &"sound")
	menu.add(
		"Widescreen    " + _on_off(display.aspect == DisplaySettings.Aspect.WIDESCREEN),
		&"widescreen"
	)
	menu.add("4:3 pixels    " + _on_off(display.correct_pixel_aspect), &"pixels")
	menu.add("Full screen   " + _on_off(settings.fullscreen), &"fullscreen")
	menu.add("Smooth motion " + _on_off(display.smooth_motion), &"smooth_motion")
	# Pictures behind the levels only go with widescreen.
	var widescreen := display.aspect == DisplaySettings.Aspect.WIDESCREEN
	menu.add(
		"Backgrounds   " + (_on_off(display.backgrounds) if widescreen else "-"),
		&"backgrounds",
		0,
		widescreen
	)
	menu.add("Graphics      " + GRAPHICS_LABELS[display.graphics], &"graphics")
	return menu


## The graphics after [param current] when the player switches; HD only
## when the player has made them ([param with_hd]).
static func next_graphics(
	current: DisplaySettings.Graphics, with_hd: bool
) -> DisplaySettings.Graphics:
	var next := (current + 1) % DisplaySettings.Graphics.size() as DisplaySettings.Graphics
	if next == DisplaySettings.Graphics.HD and not with_hd:
		next = DisplaySettings.Graphics.ORIGINAL
	return next


func _toggle_option(id: StringName) -> void:
	var display := settings.display
	match id:
		&"sound":
			settings.sound_enabled = not settings.sound_enabled
		&"widescreen":
			display.aspect = (
				DisplaySettings.Aspect.ORIGINAL
				if display.aspect == DisplaySettings.Aspect.WIDESCREEN
				else DisplaySettings.Aspect.WIDESCREEN
			)
		&"pixels":
			display.correct_pixel_aspect = not display.correct_pixel_aspect
		&"fullscreen":
			settings.fullscreen = not settings.fullscreen
		&"smooth_motion":
			display.smooth_motion = not display.smooth_motion
		&"backgrounds":
			display.backgrounds = not display.backgrounds
		&"graphics":
			display.graphics = next_graphics(display.graphics, hd_available)
	settings.save()
	settings_changed.emit()
	var cursor := _top().cursor
	_stack[-1] = _options_menu()
	_top().cursor = cursor
	_redraw()


func _handle_story_key(event: InputEvent) -> void:
	var step := 0
	if _is_up(event):
		step = -1
	elif _is_down(event):
		step = 1
	elif event is InputEventKey and PAGE_KEYS.has(event.physical_keycode):
		step = PAGE_KEYS[event.physical_keycode]
	elif not event.is_echo() and (_is_confirm(event) or event.is_action_pressed("ui_cancel")):
		_pop()
		return
	var last := maxi(0, story.size() - TEXT_LINES)
	_story_offset = clampi(_story_offset + step, 0, last)
	_redraw()


func _handle_name_key(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null:
		return
	if key.physical_keycode == KEY_ENTER or key.physical_keycode == KEY_KP_ENTER:
		if not key.is_echo():
			_stack.clear()
			window.close()
			name_entered.emit(_typed_name.strip_edges())
		return
	if key.physical_keycode == KEY_BACKSPACE:
		_typed_name = _typed_name.left(-1)
	elif (
		key.unicode >= FIRST_PRINTABLE
		and key.unicode <= LAST_PRINTABLE
		and _typed_name.length() < HighScores.MAX_NAME_LENGTH
	):
		_typed_name += String.chr(key.unicode)
	_redraw()


func _push(menu: Menu) -> void:
	_stack.append(menu)
	_redraw()


func _pop() -> void:
	_stack.pop_back()
	if _stack.is_empty():
		close_all()
	else:
		_redraw()


func _top() -> Menu:
	return _stack[-1]


func _redraw() -> void:
	if not is_open():
		return
	var menu := _top()
	window.at_bottom = false
	match menu.kind:
		STORY:
			window.show_lines(story.slice(_story_offset, _story_offset + TEXT_LINES), TEXT_WIDTH)
		NAME:
			_show_name_entry()
		TEXT:
			_show_text_entry()
		_:
			MenuView.fill(window, menu, _seconds)


func _show_name_entry() -> void:
	var cursor := String.chr(MenuView.cursor_char(_seconds))
	(
		window
		. show_lines(
			[
				"   CONGRATULATIONS!",
				"",
				"You got %s place!" % _place_word,
				"",
				"Enter your name:",
				_typed_name + cursor,
			],
			HighScores.MAX_NAME_LENGTH + 8
		)
	)


static func _is_up(event: InputEvent) -> bool:
	return event.is_action_pressed("ui_up", true) or event.is_action_pressed("move_up", true)


static func _is_down(event: InputEvent) -> bool:
	return event.is_action_pressed("ui_down", true) or event.is_action_pressed("move_down", true)


static func _is_confirm(event: InputEvent) -> bool:
	return event.is_action_pressed("ui_accept") or event.is_action_pressed("jump")


static func _on_off(on: bool) -> String:
	return "ON" if on else "OFF"


## Shows the friends' games found on Steam; the list is rebuilt when it is
## on the screen.
func show_steam_games(lines: PackedStringArray, locked: Array[bool]) -> void:
	online.steam_games = lines
	online.steam_locked = locked
	if is_open() and _top().kind == STEAM_GAMES:
		var cursor := _top().cursor
		_stack[-1] = _steam_games_menu()
		_top().cursor = mini(cursor, _top().items.size() - 1)
		_redraw()


## Rebuilds the online menu when it is on the screen, after something
## changed (someone joined, the public address was found).
func refresh_online() -> void:
	if is_open() and _top().kind == ONLINE:
		var cursor := _top().cursor
		_stack[-1] = _online_menu()
		_top().cursor = mini(cursor, _top().items.size() - 1)
		_redraw()


## The main menu of a player who joined someone else's game: the host
## decides about new games, loading and saving.
func _joined_menu(in_game: bool) -> Menu:
	var title := "  %s'S GAME" % online.partner_name.to_upper()
	var menu := Menu.create(MAIN, [title])
	if in_game:
		menu.add("Return to Game", CHOICE_RESUME)
	menu.add("Leave Game", CHOICE_LEAVE_ONLINE)
	if not story.is_empty():
		menu.add("Story", STORY)
	menu.add("Controls", CONTROLS)
	menu.add("Options", OPTIONS)
	menu.add("Quit", CHOICE_QUIT)
	return menu


## Hosting or joining; while hosting, how others can join and stopping.
func _online_menu() -> Menu:
	var menu := Menu.create(ONLINE, ["  ONLINE GAME"])
	if online.role == OnlineMenuInfo.Role.HOST:
		menu.header.append_array(online.host_lines)
		var partner := online.partner_name
		menu.header.append(
			"Playing with " + partner if not partner.is_empty() else "Nobody joined yet"
		)
		menu.add("Stop Hosting", CHOICE_LEAVE_ONLINE)
	else:
		menu.add("Host via Steam", &"host_steam")
		menu.add("Host via IP", &"host_ip")
		menu.add("Join via Steam", &"join_steam")
		menu.add("Join via IP", &"join_ip")
	var player_name := settings.online_name if not settings.online_name.is_empty() else "-"
	menu.add("Your Name: " + player_name, &"name")
	return menu


func _pick_online(id: StringName) -> void:
	match id:
		CHOICE_LEAVE_ONLINE:
			close_all()
			chosen.emit(CHOICE_LEAVE_ONLINE, 0)
		&"host_steam":
			_open_host_setup(HOST_THROUGH_STEAM)
		&"host_ip":
			_with_name(&"host_ip")
		&"join_steam":
			_push(_steam_games_menu())
			steam_games_wanted.emit()
		&"join_ip":
			_with_name(&"join_ip")
		&"name":
			_after_name = &""
			_ask_text(TEXT_PLAYER_NAME, settings.online_name)


## Over IP the other player sees the name this player typed: the first time
## he is asked for it, and then the menu goes on with [param next].
func _with_name(next: StringName) -> void:
	if settings.online_name.is_empty():
		_after_name = next
		_ask_text(TEXT_PLAYER_NAME, "")
	else:
		_continue_online(next)


func _continue_online(next: StringName) -> void:
	match next:
		&"host_ip":
			_open_host_setup(HOST_BY_IP)
		&"join_ip":
			_ask_text(TEXT_ADDRESS, settings.online_address)


## Over IP a password is on by default: the address may be known to anyone.
## Through Steam only friends see the game, so it is off.
func _open_host_setup(kind: int) -> void:
	_host_kind = kind
	host_locked = kind == HOST_BY_IP
	host_password = OnlineMenuInfo.make_password()
	_push(_host_setup_menu())


func _host_setup_menu() -> Menu:
	var by_ip := _host_kind == HOST_BY_IP
	var header := PackedStringArray(["  HOST VIA IP" if by_ip else "  HOST VIA STEAM"])
	if by_ip:
		header.append("UDP port %d" % OnlineProtocol.GAME_PORT)
	else:
		header.append("Only your Steam friends")
		header.append("can see the game.")
	header.append("Password: " + (host_password if host_locked else "none"))
	var menu := Menu.create(HOST_SETUP, header)
	menu.add("Start Hosting", &"start")
	menu.add("Password      " + _on_off(host_locked), &"lock")
	menu.add("New Password", &"new_password", 0, host_locked)
	return menu


func _pick_host_setup(id: StringName) -> void:
	match id:
		&"start":
			close_all()
			chosen.emit(CHOICE_HOST, _host_kind)
			return
		&"lock":
			host_locked = not host_locked
		&"new_password":
			host_password = OnlineMenuInfo.make_password()
	var cursor := _top().cursor
	_stack[-1] = _host_setup_menu()
	_top().cursor = cursor
	_redraw()


func _steam_games_menu() -> Menu:
	var menu := Menu.create(STEAM_GAMES, ["  JOIN VIA STEAM", "Your friends' games:"])
	for index in online.steam_games.size():
		menu.add(online.steam_games[index], &"game", index)
	if online.steam_games.is_empty():
		menu.add("(none found)", &"none", 0, false)
	menu.add("Look Again", &"refresh")
	return menu


func _pick_steam_game(item: Menu.Item) -> void:
	if item.id == &"refresh":
		steam_games_wanted.emit()
		return
	_steam_pick = item.value
	var locked := item.value < online.steam_locked.size() and online.steam_locked[item.value]
	if locked:
		_ask_text(TEXT_STEAM_PASSWORD, "")
		return
	join_password = ""
	close_all()
	chosen.emit(CHOICE_JOIN_STEAM, _steam_pick)


func _ask_text(purpose: StringName, start: String) -> void:
	_text_purpose = purpose
	_typed_text = start
	_push(Menu.create(TEXT))


func _handle_text_key(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null:
		return
	if key.physical_keycode == KEY_ESCAPE:
		if not key.is_echo():
			_pop()
		return
	if key.physical_keycode == KEY_ENTER or key.physical_keycode == KEY_KP_ENTER:
		if not key.is_echo():
			_finish_text(_typed_text.strip_edges())
		return
	if key.physical_keycode == KEY_BACKSPACE:
		_typed_text = _typed_text.left(-1)
	elif _fits_text(key.unicode):
		_typed_text += String.chr(key.unicode)
	_redraw()


## Whether character [param code] may be typed into the text being asked.
func _fits_text(code: int) -> bool:
	if code < FIRST_PRINTABLE or code > LAST_PRINTABLE:
		return false
	match _text_purpose:
		TEXT_PLAYER_NAME:
			return _typed_text.length() < PlayerName.MAX_LENGTH
		TEXT_ADDRESS:
			var character := String.chr(code)
			return (
				_typed_text.length() < ADDRESS_LENGTH
				and (
					character.is_valid_identifier()
					or character in ".:-"
					or character.is_valid_int()
				)
			)
	return _typed_text.length() < PASSWORD_LENGTH


func _finish_text(text: String) -> void:
	match _text_purpose:
		TEXT_PLAYER_NAME:
			if text.is_empty():
				return
			settings.online_name = PlayerName.clean(text)
			settings.save()
			_pop()
			if _after_name.is_empty():
				refresh_online()
			else:
				var next := _after_name
				_after_name = &""
				_continue_online(next)
		TEXT_ADDRESS:
			if text.is_empty():
				return
			join_address = text
			settings.online_address = text
			settings.save()
			_stack[-1] = Menu.create(TEXT)
			_text_purpose = TEXT_PASSWORD
			_typed_text = ""
			_redraw()
		TEXT_PASSWORD:
			join_password = text
			close_all()
			chosen.emit(CHOICE_JOIN_IP, 0)
		TEXT_STEAM_PASSWORD:
			join_password = text
			close_all()
			chosen.emit(CHOICE_JOIN_STEAM, _steam_pick)


func _show_text_entry() -> void:
	var lines: PackedStringArray
	var width := PASSWORD_LENGTH + 2
	match _text_purpose:
		TEXT_PLAYER_NAME:
			lines = ["  YOUR NAME", "", "The other player sees", "this name.", ""]
		TEXT_ADDRESS:
			lines = ["  JOIN VIA IP", "", "The host's address:", ""]
			width = ADDRESS_LENGTH + 2
		_:
			lines = ["  PASSWORD", "", "The host's password", "(empty if none):", ""]
	lines.append(_typed_text + String.chr(MenuView.cursor_char(_seconds)))
	window.show_lines(lines, width)
