class_name MenuController
extends Node
## The menus of the game, shown in the [GameWindow]: the main menu, the save
## slots, the controls, the options, the story, short messages and asking
## for a name for the high score table. Menus stack: Escape goes back one.
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

const CHOICE_RESUME := &"resume"
const CHOICE_NEW_GAME := &"new_game"
const CHOICE_LOAD := &"load"
const CHOICE_SAVE := &"save"
const CHOICE_HIGH_SCORES := &"high_scores"
const CHOICE_TITLE := &"title"
const CHOICE_QUIT := &"quit"

const MAIN := &"main"
const SLOTS_LOAD := &"slots_load"
const SLOTS_SAVE := &"slots_save"
const OVERWRITE := &"overwrite"
const CONTROLS := &"controls"
const PRESS_KEY := &"press_key"
const OPTIONS := &"options"
const STORY := &"story"
const MESSAGE := &"message"
const NAME := &"name"

## Characters per line and lines per page of the story, as for the end text.
const TEXT_WIDTH := EndingSequence.TEXT_WIDTH
const TEXT_LINES := EndingSequence.TEXT_LINES
const PAGE_KEYS: Dictionary[Key, int] = {KEY_PAGEUP: -TEXT_LINES, KEY_PAGEDOWN: TEXT_LINES}
const FIRST_PRINTABLE := 32
const LAST_PRINTABLE := 126

var window: GameWindow
var saves := SaveGames.new()
var settings := UserSettings.new()
## The story, laid out for the window; empty when STORYTXT.CK1 is missing.
var story := PackedStringArray()
var _stack: Array[Menu] = []
var _seconds := 0.0
var _story_offset := 0
## The slot waiting for "overwrite?" to be answered.
var _pending_slot := 0
## The action waiting for its new key.
var _pending_action := ""
var _typed_name := ""
var _place_word := ""


func is_open() -> bool:
	return not _stack.is_empty()


## The main menu. [param in_game] adds "Return to game" and "Save game";
## saving is only possible when [param can_save] (on the world map).
func open_main(in_game: bool, can_save: bool) -> void:
	_stack.clear()
	var menu := Menu.create(MAIN, ["     MAIN MENU"])
	if in_game:
		menu.add("Return to Game", CHOICE_RESUME)
	menu.add("New Game", CHOICE_NEW_GAME)
	menu.add("Continue Game", SLOTS_LOAD)
	if in_game:
		menu.add("Save Game", SLOTS_SAVE if can_save else &"save_not_here")
	if not story.is_empty():
		menu.add("Story", STORY)
	menu.add("High Scores", CHOICE_HIGH_SCORES)
	menu.add("Controls", CONTROLS)
	menu.add("Options", OPTIONS)
	if in_game:
		menu.add("Quit to Title", CHOICE_TITLE)
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
			_pick_control(item.id)
		OPTIONS:
			_toggle_option(item.id)


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


func _controls_menu() -> Menu:
	var menu := Menu.create(CONTROLS, ["  CONTROLS", "  Pick one to change it"])
	for action: String in KeyBindings.ACTIONS:
		menu.add(
			"%-7s %s" % [KeyBindings.ACTIONS[action], KeyBindings.describe(action)],
			StringName(action)
		)
	menu.add("Reset to defaults", &"reset")
	return menu


func _pick_control(id: StringName) -> void:
	if id == &"reset":
		KeyBindings.reset()
		_refresh_controls()
		return
	_pending_action = String(id)
	_push(
		(
			Menu
			. create(
				PRESS_KEY,
				[
					"Press the new key for",
					"%s, or Escape." % KeyBindings.ACTIONS[_pending_action].to_upper(),
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
	if not KeyBindings.can_bind(key.physical_keycode):
		return
	KeyBindings.bind(_pending_action, key.physical_keycode)
	settings.save()
	_pop()
	_refresh_controls()


## Rebuilds the controls menu so that it shows the new keys.
func _refresh_controls() -> void:
	var cursor := _top().cursor
	_stack[-1] = _controls_menu()
	_top().cursor = cursor
	settings.save()
	_redraw()


func _options_menu() -> Menu:
	var display := settings.display
	var menu := Menu.create(OPTIONS, ["  OPTIONS"])
	menu.add("Sound        " + _on_off(settings.sound_enabled), &"sound")
	menu.add(
		"Widescreen   " + _on_off(display.aspect == DisplaySettings.Aspect.WIDESCREEN),
		&"widescreen"
	)
	menu.add("4:3 pixels   " + _on_off(display.correct_pixel_aspect), &"pixels")
	return menu


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
