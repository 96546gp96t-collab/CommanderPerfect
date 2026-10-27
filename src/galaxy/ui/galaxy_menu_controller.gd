class_name GalaxyMenuController
extends MenuController
## The control panel of a Galaxy episode (the menu on Keen's wrist watch;
## Omni `id_us_2.c`, `ck_us_2.c`: US_RunCards and the cards; facts only),
## on top of the shared [MenuController]: its stack of menus, the keys of
## one player (KEY_SET, PRESS_KEY) and the display settings (OPTIONS) are
## the shared ones; the cards, the keys and the dialogs are the original's:
##   - main card: New Game, Load Game, Save Game, Configure, Return to Game
##     (Return to Demo out of a game), End Game, Paddle War, Quit; Save and
##     End only in a game; the cursor starts on Return to Game in a game, on
##     New Game otherwise; Quit asks "REALLY QUIT?", and C there chooses
##     another game (ours: back to the start screen);
##   - the cursor stops at the ends and can rest on a choice that cannot be
##     picked (Omni US_SelectNextItem); a letter puts it on the choice that
##     starts with it; Enter, jump or pogo picks; Escape backs out, and on
##     the main card asks "REALLY QUIT?";
##   - New Game: Easy, Normal, Hard, the cursor on Normal; in a game "YOU'RE
##     IN A GAME" first;
##   - Load and Save: [member slot_count] boxes; saving asks for a name in
##     the box (Enter keeps it, empty: "Untitled") and stays on the card;
##   - Configure: Sound and Music (a choice of one, checked at once; Omni
##     US_ITEM_Radio), Options (the score box and the shared display
##     settings), Keyboard (the shared keys; ours: at its end Buttons, the
##     controller buttons), Reset Keys (and buttons);
##   - Paddle War ([GalaxyPaddleWar]): [method run_paddle_war] plays its
##     tics, Escape leaves it, the end says who won;
##   - dialogs ([constant MenuController.MESSAGE], [constant CONFIRM]): Y
##     (or jump) says yes, anything else no.
## The picture is drawn by [GalaxyMenuView] whenever [signal redrawn] says
## so; the cursor's icon blinks every 35 tics ([method advance]).

## The panel must be drawn again.
signal redrawn
## A sound must be played (Paddle War's; the episode's sound names).
signal sound_requested(name: StringName)

## The choices of the Sound card.
enum SoundChoice { OFF, PC, ADLIB, QUIET_ADLIB }

## Kinds of menus (besides the shared ones).
const NEW_GAME := &"new_game_card"
const CONFIGURE := &"configure"
const SOUND_CARD := &"sound_card"
const MUSIC_CARD := &"music_card"
const PADDLE_WAR := &"paddle_war"
## A save's name being typed into its box.
const SLOT_NAME := &"slot_name"
## A question: Y says yes.
const CONFIRM := &"confirm"
## New choices: end the game being played; the score box was switched
## (value 1 on, 0 off).
const CHOICE_END_GAME := &"end_game"
const CHOICE_SCORE_BOX := &"score_box"
## The sound or the music was switched (value: [enum SoundChoice], 0/1).
const CHOICE_SOUND := &"sound"
const CHOICE_MUSIC := &"music"
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
## The confirmations (Omni USL_ConfirmComm).
const BACK_OUT_LINE := "ESC TO BACK OUT"
## Quit (ours: the third line; C chooses another game).
const QUIT_LINES: PackedStringArray = [
	"REALLY QUIT?", "PRESS Y TO QUIT", "PRESS C TO CHOOSE GAME", BACK_OUT_LINE
]
const CHOOSE_GAME_KEY := KEY_C
const END_LINES: PackedStringArray = [
	"REALLY END CURRENT GAME?", "PRESS Y TO END IT", BACK_OUT_LINE
]
const NEW_GAME_LINES: PackedStringArray = [
	"YOU'RE IN A GAME", "PRESS Y FOR NEW GAME", BACK_OUT_LINE
]
const LOAD_LINES: PackedStringArray = ["YOU'RE IN A GAME", "PRESS Y TO LOAD GAME", BACK_OUT_LINE]
const PRESS_ANY_KEY := "Press any key"
## Paddle War's end (Omni ck_str_paddleWar*).
const PADDLE_WON_LINES: PackedStringArray = ["You won!", PRESS_ANY_KEY]
const PADDLE_LOST_LINES: PackedStringArray = ["You lost!", PRESS_ANY_KEY]

## The cards that keep their cursor from one visit to the next (seen in
## v1.0 for Configure; Omni keeps every card's selectedItem); the main
## card, New Game and the Sound and Music cards set theirs anew.
const REMEMBERED_CARDS: Array[StringName] = [CONFIGURE, OPTIONS, KEY_SET]

## The saved games.
var slots := GalaxySaveSlots.new()
## Whether a game is being played (the menu was opened from one).
var in_game := false
## Whether the score box is shown (Keen 4's own setting).
var score_box := true
## The checked choices of the Sound and Music cards.
var sound_choice := SoundChoice.ADLIB
var music_on := true
## Gives Paddle War its random numbers (0-255); unset: Godot's.
var random: Callable
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
## Paddle War while it is played.
var _paddle_war: GalaxyPaddleWar
## The cursor each remembered card had when it was left.
var _cursors: Dictionary[StringName, int] = {}
## The Options card shows the score box's old state until its message is
## gone (seen in v1.0).
var _options_stale := false


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
	_main_menu = GalaxyMenuPages.main.bind(in_game)
	_push(_main_menu.call())


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


## Paddle War while its card is open (also under its end's dialog), else
## null.
func paddle_war() -> GalaxyPaddleWar:
	for menu in _stack:
		if menu.kind == PADDLE_WAR:
			return _paddle_war
	return null


## Plays [param tics] tics of Paddle War with Keen's paddle going
## [param left] or [param right]; at the end the winner is told.
func run_paddle_war(tics: int, left: bool, right: bool) -> void:
	var game := paddle_war()
	if game == null or _top().kind != PADDLE_WAR:
		return
	game.advance(tics, left, right)
	if game.is_done():
		# The original asks before it draws the last tic's ball and paddles.
		show_message(PADDLE_WON_LINES if game.keen_won() else PADDLE_LOST_LINES)
	else:
		_redraw()


## Whether choice [param index] of [param menu] (a Sound or Music card) is
## the checked one.
func is_checked(menu: Menu, index: int) -> bool:
	match menu.kind:
		SOUND_CARD:
			return index == sound_choice
		MUSIC_CARD:
			return index == int(music_on)
		OptionsPages.LANGUAGES:
			return index == Languages.available().keys().find(settings.language)
	return false


## Whether F1 may open the help: on a card, not in a dialog, while a name
## or a key is typed, or in Paddle War (Omni: only US_RunCards takes F1).
func allows_help() -> bool:
	return (
		is_open()
		and not (
			_top().kind
			in [CONFIRM, MESSAGE, SLOT_NAME, PRESS_KEY, PRESS_BUTTON, NEW_BUTTON, PADDLE_WAR]
		)
	)


## The cursor's icon blinks with the game's clock.
func advance(tics: int) -> void:
	if not is_open() or _top().kind == PADDLE_WAR:
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
				_answer_key(event)
		PADDLE_WAR:
			# The paddle follows the held keys ([method run_paddle_war]).
			if event.is_action_pressed("ui_cancel"):
				_pop()
		MESSAGE:
			if not event.is_echo():
				_close_message()
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
		SOUND_CARD:
			sound_choice = item.value as SoundChoice
			chosen.emit(CHOICE_SOUND, item.value)
			_redraw()
		MUSIC_CARD:
			music_on = item.value != 0
			chosen.emit(CHOICE_MUSIC, item.value)
			_redraw()
		OptionsPages.LANGUAGES:
			# Checked at once, as the Sound card's choices are.
			_set_language(Languages.available().keys()[item.value])
			_relabel_stack()
			_redraw()
		_:
			super(menu, item)


func _pick_main(id: StringName) -> void:
	match id:
		NEW_GAME:
			_push(GalaxyMenuPages.new_game())
		SLOTS_LOAD, SLOTS_SAVE:
			_push(GalaxyMenuPages.slots(id, slots))
		CONFIGURE:
			_push(_configure_card())
		CHOICE_END_GAME:
			if _unsaved:
				_confirm(END_LINES, CHOICE_END_GAME)
			else:
				_choose(CHOICE_END_GAME, 0)
		CHOICE_QUIT:
			_confirm(QUIT_LINES, CHOICE_QUIT)
		PADDLE_WAR:
			_start_paddle_war()
		_:
			_choose(id, 0)


func _start_paddle_war() -> void:
	_paddle_war = GalaxyPaddleWar.create(random if random.is_valid() else _godot_random)
	_paddle_war.sound_played.connect(sound_requested.emit)
	_push(Menu.create(PADDLE_WAR))


static func _godot_random() -> int:
	return randi() & GalaxyWorld.RANDOM_MASK


func _pick_configure(item: Menu.Item) -> void:
	match item.id:
		SOUND_CARD:
			_push(GalaxyMenuPages.radio(SOUND_CARD, GalaxyMenuPages.SOUND_LABELS, sound_choice))
		MUSIC_CARD:
			_push(GalaxyMenuPages.radio(MUSIC_CARD, GalaxyMenuPages.MUSIC_LABELS, int(music_on)))
		OPTIONS:
			_push(_options_menu())
		KEY_SET:
			_key_set = 0
			_push(GalaxyMenuPages.keys())
		&"reset":
			KeyBindings.reset()
			ButtonBindings.reset()
			settings.save()
			show_message(["All keys are as they were", PRESS_ANY_KEY])


func _options_menu() -> Menu:
	return GalaxyMenuPages.options(settings, score_box)


func _configure_card() -> Menu:
	return GalaxyMenuPages.configure()


func _key_set_menu() -> Menu:
	return GalaxyMenuPages.keys()


func _button_set_menu() -> Menu:
	return GalaxyMenuPages.buttons(_button_set)


func _slots_menu(kind: StringName, _header: PackedStringArray) -> Menu:
	return GalaxyMenuPages.slots(kind, slots)


func _toggle_option(id: StringName) -> void:
	if id == OptionsPages.LANGUAGE:
		_push(GalaxyMenuPages.languages(settings.language))
		return
	if id != &"score_box":
		super(id)
		return
	score_box = not score_box
	chosen.emit(CHOICE_SCORE_BOX, int(score_box))
	# The card behind the message still shows the old state (seen in v1.0).
	_options_stale = true
	show_message(["Score box now " + ("on" if score_box else "off"), PRESS_ANY_KEY])


## Every card on the stack again, in the language now in use, with its
## cursor where it was.
func _relabel_stack() -> void:
	for index in _stack.size():
		var old := _stack[index]
		var made: Menu = null
		match old.kind:
			MAIN:
				made = _main_menu.call() if _main_menu.is_valid() else null
			CONFIGURE:
				made = _configure_card()
			OPTIONS:
				made = _options_menu()
			OptionsPages.LANGUAGES:
				made = GalaxyMenuPages.languages(settings.language)
		if made != null:
			made.cursor = old.cursor
			_stack[index] = made


## A message goes on a key: Paddle War's end goes back to the main card; the
## Options card shows the score box as it is now.
func _close_message() -> void:
	_stack.pop_back()
	if is_open() and _top().kind == PADDLE_WAR:
		_stack.pop_back()
	if is_open() and _options_stale and _top().kind == OPTIONS:
		_replace_top(_options_menu())
	_options_stale = false
	if is_open():
		_redraw()
	else:
		close_all()


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
	_replace_top(GalaxyMenuPages.slots(SLOTS_SAVE, slots))
	_top().cursor = slot - 1
	_redraw()


## Asks [param lines]; yes: the panel closes with [param choice].
func _confirm(lines: PackedStringArray, choice: StringName, value := 0) -> void:
	_confirm_choice = choice
	_confirm_value = value
	_push(Menu.create(CONFIRM, lines))


## Y or jump says yes; on the quit question C chooses another game; any
## other key backs out.
func _answer_key(event: InputEvent) -> void:
	_pop()
	var key := event as InputEventKey
	if _is_yes(event):
		_choose(_confirm_choice, _confirm_value)
	elif (
		_confirm_choice == CHOICE_QUIT
		and key != null
		and (key.physical_keycode == CHOOSE_GAME_KEY or key.keycode == CHOOSE_GAME_KEY)
	):
		_choose(CHOICE_CHOOSE_GAME, 0)


## Closes the panel and tells the game what was chosen.
func _choose(id: StringName, value: int) -> void:
	_stack.clear()
	closed.emit()
	chosen.emit(id, value)


## A remembered card comes back with its cursor where it was.
func _push(menu: Menu) -> void:
	if menu.kind in REMEMBERED_CARDS and _cursors.has(menu.kind):
		menu.cursor = clampi(_cursors[menu.kind], 0, maxi(0, menu.items.size() - 1))
	super(menu)


func _pop() -> void:
	if is_open() and _top().kind in REMEMBERED_CARDS:
		_cursors[_top().kind] = _top().cursor
	super()


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
