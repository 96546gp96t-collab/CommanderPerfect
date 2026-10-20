class_name GalaxyMenuController
extends MenuController
## The control panel of a Galaxy episode (the menu on Keen's wrist watch;
## Omni `id_us_2.c`, `ck_us_2.c`: US_RunCards and the cards; facts only),
## on top of the shared [MenuController]: its stack of menus, the keys of
## one player (KEY_SET, PRESS_KEY) and the display settings (OPTIONS) are
## the shared ones; the cards, the keys and the dialogs are the original's:
##   - main card: New Game, Load Game, Save Game, Configure, Return to Game
##     (Return to Demo out of a game), End Game, Choose Game (ours: back to
##     the start screen), Quit; Save and End only in a game; the cursor
##     starts on Return to Game in a game, on New Game otherwise;
##   - the cursor stops at the ends and can rest on a choice that cannot be
##     picked (Omni US_SelectNextItem); a letter puts it on the choice that
##     starts with it; Enter, jump or pogo picks; Escape backs out, and on
##     the main card asks "REALLY QUIT?";
##   - New Game: Easy, Normal, Hard, the cursor on Normal; in a game "YOU'RE
##     IN A GAME" first;
##   - Load and Save: [member slot_count] boxes; saving asks for a name in
##     the box (Enter keeps it, empty: "Untitled") and stays on the card;
##   - Configure: Options (the score box and the shared display settings),
##     Keyboard (the shared keys), Reset Keys;
##   - dialogs ([constant MenuController.MESSAGE], [constant CONFIRM]): Y
##     (or jump) says yes, anything else no.
## The picture is drawn by [GalaxyMenuView] whenever [signal redrawn] says
## so; the cursor's icon blinks every 35 tics ([method advance]).

## The panel must be drawn again.
signal redrawn

## Kinds of menus (besides the shared ones).
const NEW_GAME := &"new_game_card"
const CONFIGURE := &"configure"
## A save's name being typed into its box.
const SLOT_NAME := &"slot_name"
## A question: Y says yes.
const CONFIRM := &"confirm"
## New choices: end the game being played; the score box was switched
## (value 1 on, 0 off).
const CHOICE_END_GAME := &"end_game"
const CHOICE_SCORE_BOX := &"score_box"
## The cursor's icon is shown and hidden this many tics (Omni US_RunCards).
const BLINK_TICS := 35
## A save's name: at most 32 characters (Omni US_LineInput).
const SAVE_NAME_LENGTH := 32
const UNTITLED := "Untitled"
## A label starting with this leaves an empty row before it (Omni
## US_IS_Gap).
const GAP := "\n"
## Between a choice and its value (a key's name) in a label.
const VALUE_SEPARATOR := "\t"
## Between the keys of an action in [method KeyBindings.describe].
const KEY_NAME_SEPARATOR := ", "
## The confirmations (Omni USL_ConfirmComm).
const BACK_OUT_LINE := "ESC TO BACK OUT"
const QUIT_LINES: PackedStringArray = ["REALLY QUIT?", "PRESS Y TO QUIT", BACK_OUT_LINE]
const END_LINES: PackedStringArray = [
	"REALLY END CURRENT GAME?", "PRESS Y TO END IT", BACK_OUT_LINE
]
const NEW_GAME_LINES: PackedStringArray = [
	"YOU'RE IN A GAME", "PRESS Y FOR NEW GAME", BACK_OUT_LINE
]
const LOAD_LINES: PackedStringArray = ["YOU'RE IN A GAME", "PRESS Y TO LOAD GAME", BACK_OUT_LINE]
const PRESS_ANY_KEY := "Press any key"
const DIFFICULTY_LABELS: PackedStringArray = [
	"BEGIN EASY GAME", "BEGIN NORMAL GAME", "BEGIN HARD GAME"
]

## The saved games.
var slots := GalaxySaveSlots.new()
## Whether a game is being played (the menu was opened from one).
var in_game := false
## Whether the score box is shown (Keen 4's own setting).
var score_box := true
## The name being typed for a save.
var typed_save_name := ""
## Whether the cursor's icon is shown (it blinks).
var cursor_shown := true
var _blink_tics := 0
## Nothing was saved since the menu opened in a game (Omni game_unsaved):
## ending, loading or starting a game asks first.
var _unsaved := false
## What a confirmation does when the answer is yes.
var _confirm_choice := &""
var _confirm_value := 0


func _ready() -> void:
	# The cursor blinks on the game's clock ([method advance]), not on
	# MenuController's timer.
	set_process(false)


## The main card. [param game_running]: a game is played (Save Game, End
## Game, Return to Game); [param _can_save] and [param _two_players] are
## the shared signature's (a Galaxy game can be saved anywhere).
func open_main(game_running: bool, _can_save := true, _two_players := false) -> void:
	_stack.clear()
	in_game = game_running
	_unsaved = game_running
	var menu := Menu.create(MAIN)
	menu.add("NEW GAME", NEW_GAME)
	menu.add("LOAD GAME", SLOTS_LOAD)
	menu.add("SAVE GAME", SLOTS_SAVE, 0, in_game)
	menu.add("CONFIGURE", CONFIGURE)
	menu.add("RETURN TO GAME" if in_game else "RETURN TO DEMO", CHOICE_RESUME)
	menu.add("END GAME", CHOICE_END_GAME, 0, in_game)
	menu.add("CHOOSE GAME", CHOICE_CHOOSE_GAME)
	menu.add("QUIT", CHOICE_QUIT)
	menu.cursor = 4 if in_game else 0
	_push(menu)


## The menu on top; null when the panel is closed.
func top() -> Menu:
	return _stack[-1] if is_open() else null


## The menu under the top one (the card under a dialog); null when there
## is none.
func below() -> Menu:
	return _stack[-2] if _stack.size() > 1 else null


## How many menus are open (1: the main card, "ESC to quit").
func depth() -> int:
	return _stack.size()


## The cursor's icon blinks with the game's clock.
func advance(tics: int) -> void:
	if not is_open():
		return
	_blink_tics += tics
	if _blink_tics >= BLINK_TICS:
		_blink_tics %= BLINK_TICS
		cursor_shown = not cursor_shown
		redrawn.emit()


func close_all() -> void:
	_stack.clear()
	closed.emit()


func handle_input(event: InputEvent) -> void:
	if not is_open() or not event.is_pressed():
		return
	_blink_tics = 0
	cursor_shown = true
	match _top().kind:
		SLOT_NAME:
			_handle_slot_name_key(event)
		CONFIRM:
			if not event.is_echo():
				_answer(_is_yes(event))
		_:
			super(event)


func _handle_menu_key(event: InputEvent) -> void:
	var menu := _top()
	if _is_up(event) or _is_down(event):
		menu.cursor = clampi(menu.cursor + (-1 if _is_up(event) else 1), 0, menu.items.size() - 1)
		_redraw()
	elif event.is_echo():
		return
	elif event.is_action_pressed("ui_cancel"):
		if _stack.size() == 1:
			_confirm(QUIT_LINES, CHOICE_QUIT)
		else:
			_pop()
	elif _is_pick(event):
		var item := menu.current()
		if item != null:
			_pick(menu, item)
	elif event is InputEventKey:
		_jump_to(menu, (event as InputEventKey).unicode)


## A letter or digit puts the cursor on the choice that starts with it.
func _jump_to(menu: Menu, character: int) -> void:
	if character <= 0:
		return
	var wanted := String.chr(character).to_upper()
	if menu.kind in [SLOTS_LOAD, SLOTS_SAVE]:
		# The slots are picked by their number (Omni: the keys 1-6).
		var slot := wanted.to_int() if wanted.is_valid_int() else 0
		if slot >= 1 and slot <= menu.items.size():
			menu.cursor = slot - 1
			_redraw()
		return
	for index in menu.items.size():
		if menu.items[index].label.strip_edges().begins_with(wanted):
			menu.cursor = index
			_redraw()
			return


func _pick(menu: Menu, item: Menu.Item) -> void:
	match menu.kind:
		MAIN:
			_pick_main(item.id)
		NEW_GAME:
			if in_game and _unsaved:
				_confirm(NEW_GAME_LINES, CHOICE_NEW_GAME, item.value)
			else:
				_choose(CHOICE_NEW_GAME, item.value)
		SLOTS_LOAD:
			if in_game and _unsaved:
				_confirm(LOAD_LINES, CHOICE_LOAD, item.value)
			else:
				_choose(CHOICE_LOAD, item.value)
		SLOTS_SAVE:
			typed_save_name = slots.name_of(item.value)
			var typing := Menu.create(SLOT_NAME)
			typing.add("", SLOT_NAME, item.value)
			_push(typing)
		CONFIGURE:
			_pick_configure(item)
		_:
			super(menu, item)


func _pick_main(id: StringName) -> void:
	match id:
		NEW_GAME:
			var menu := Menu.create(NEW_GAME)
			for level in DIFFICULTY_LABELS.size():
				menu.add(DIFFICULTY_LABELS[level], &"level", level)
			menu.cursor = GalaxyDifficulty.Level.NORMAL
			_push(menu)
		SLOTS_LOAD, SLOTS_SAVE:
			_push(_slots_menu(id, []))
		CONFIGURE:
			_push(_configure_menu())
		CHOICE_END_GAME:
			if _unsaved:
				_confirm(END_LINES, CHOICE_END_GAME)
			else:
				_choose(CHOICE_END_GAME, 0)
		CHOICE_QUIT:
			_confirm(QUIT_LINES, CHOICE_QUIT)
		_:
			_choose(id, 0)


## The slots: empty ones cannot be loaded; the cursor starts on the first.
func _slots_menu(kind: StringName, header: PackedStringArray) -> Menu:
	var menu := Menu.create(kind, header)
	for slot in range(1, slots.count + 1):
		var saved := slots.name_of(slot)
		menu.add(saved, &"slot", slot, kind == SLOTS_SAVE or not saved.is_empty())
	menu.cursor = 0
	return menu


func _configure_menu() -> Menu:
	var menu := Menu.create(CONFIGURE)
	menu.add("OPTIONS", OPTIONS)
	menu.add(GAP + "KEYBOARD", KEY_SET)
	menu.add("RESET KEYS", &"reset")
	return menu


func _pick_configure(item: Menu.Item) -> void:
	match item.id:
		OPTIONS:
			_push(_options_menu())
		KEY_SET:
			_key_set = 0
			_push(_key_set_menu())
		&"reset":
			KeyBindings.reset()
			settings.save()
			show_message(["All keys are as they were", PRESS_ANY_KEY])


## The keys of one player: the action, and its key in a box.
func _key_set_menu() -> Menu:
	var menu := Menu.create(KEY_SET)
	for action: String in KeyBindings.ACTIONS:
		var label: String = KeyBindings.ACTIONS[action].to_upper()
		# The original's box holds one key: the first (the one that changes).
		var key_name := KeyBindings.describe(action).get_slice(KEY_NAME_SEPARATOR, 0).capitalize()
		menu.add(label + VALUE_SEPARATOR + key_name, StringName(action))
	return menu


## Keen 4's score box and the shared display settings, as the original
## names its options ("SCORE BOX (ON)").
func _options_menu() -> Menu:
	var display := settings.display
	var widescreen := display.aspect == DisplaySettings.Aspect.WIDESCREEN
	var menu := Menu.create(OPTIONS)
	menu.add("SCORE BOX " + _state(score_box), &"score_box")
	menu.add("WIDESCREEN " + _state(widescreen), &"widescreen")
	menu.add("4:3 PIXELS " + _state(display.correct_pixel_aspect), &"pixels")
	menu.add("FULL SCREEN " + _state(settings.fullscreen), &"fullscreen")
	menu.add("SMOOTH MOTION " + _state(display.smooth_motion), &"smooth_motion")
	menu.add("BACKGROUNDS " + _state(display.backgrounds), &"backgrounds", 0, widescreen)
	menu.add("GRAPHICS (%s)" % GRAPHICS_LABELS[display.graphics], &"graphics")
	return menu


func _toggle_option(id: StringName) -> void:
	if id != &"score_box":
		super(id)
		return
	score_box = not score_box
	chosen.emit(CHOICE_SCORE_BOX, int(score_box))
	_replace_top(_options_menu())
	show_message(["Score box now " + ("on" if score_box else "off"), PRESS_ANY_KEY])


## Typing a save's name (Omni US_LineInput): Enter keeps it, Escape
## leaves the slot as it was.
func _handle_slot_name_key(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null:
		return
	if key.physical_keycode == KEY_ESCAPE:
		if not key.is_echo():
			_pop()
		return
	if key.physical_keycode == KEY_ENTER or key.physical_keycode == KEY_KP_ENTER:
		if not key.is_echo():
			_finish_save()
		return
	if key.physical_keycode == KEY_BACKSPACE:
		typed_save_name = typed_save_name.left(-1)
	elif (
		key.unicode >= FIRST_PRINTABLE
		and key.unicode <= LAST_PRINTABLE
		and typed_save_name.length() < SAVE_NAME_LENGTH
	):
		typed_save_name += String.chr(key.unicode)
	_redraw()


## The game is saved in the slot being named; the panel stays on the save
## card, which shows the new name.
func _finish_save() -> void:
	typed_save_name = typed_save_name.strip_edges()
	if typed_save_name.is_empty():
		typed_save_name = UNTITLED
	var slot := _top().items[0].value
	_stack.pop_back()
	chosen.emit(CHOICE_SAVE, slot)
	_unsaved = false
	_replace_top(_slots_menu(SLOTS_SAVE, []))
	_top().cursor = slot - 1
	_redraw()


## Asks [param lines]; yes: the panel closes with [param choice].
func _confirm(lines: PackedStringArray, choice: StringName, value := 0) -> void:
	_confirm_choice = choice
	_confirm_value = value
	_push(Menu.create(CONFIRM, lines))


func _answer(yes: bool) -> void:
	_pop()
	if yes:
		_choose(_confirm_choice, _confirm_value)


## Closes the panel and tells the game what was chosen.
func _choose(id: StringName, value: int) -> void:
	_stack.clear()
	closed.emit()
	chosen.emit(id, value)


func _redraw() -> void:
	if is_open():
		redrawn.emit()


## Y, or jump (Omni USL_CtlDialog: jump is yes, pogo is no).
static func _is_yes(event: InputEvent) -> bool:
	var key := event as InputEventKey
	if key != null and key.physical_keycode == KEY_Y:
		return true
	return event.is_action_pressed("jump")


static func _is_pick(event: InputEvent) -> bool:
	return _is_confirm(event) or event.is_action_pressed("pogo")


static func _state(on: bool) -> String:
	return "(ON)" if on else "(OFF)"
