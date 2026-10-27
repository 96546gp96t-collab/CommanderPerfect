class_name GalaxyMenuPages
extends RefCounted
## The cards of a Galaxy control panel as lists of choices (Omni
## `ck_us_2.c`: the US_CardItem tables; facts only, and seen in Keen 4
## v1.0), for [GalaxyMenuController]: the main card, New Game, the save
## slots, Configure, Sound and Music, the keys, the controller buttons
## (ours), the options and the languages (ours). Every label is built in
## the language in use ([Lang]); English stays the original's words.

## The main card's choices, in the original's order.
const MAIN_LABELS: PackedStringArray = [
	"NEW GAME",
	"LOAD GAME",
	"SAVE GAME",
	"CONFIGURE",
	"RETURN TO GAME",
	"END GAME",
	"PADDLE WAR",
	"QUIT",
]
const RETURN_TO_DEMO := "RETURN TO DEMO"
## The main card's cursor starts on Return to Game in a game.
const RETURN_ROW := 4
const DIFFICULTY_LABELS: PackedStringArray = [
	"BEGIN EASY GAME", "BEGIN NORMAL GAME", "BEGIN HARD GAME"
]
## The Sound and Music cards (seen in v1.0), in the order of their values
## ([enum GalaxyMenuController.SoundChoice]; music: off, on).
const SOUND_LABELS: PackedStringArray = [
	"NO SOUND EFFECTS", "PC SPEAKER", "ADLIB/SOUNDBLASTER", "QUIET ADLIB/SOUNDBLASTER"
]
const MUSIC_LABELS: PackedStringArray = ["NO MUSIC", "ADLIB/SOUNDBLASTER"]
## The id of a choice on a Sound or Music card.
const RADIO := &"radio"
## Between the keys of an action in [method KeyBindings.describe].
const KEY_NAME_SEPARATOR := ", "
## Ours: the row at the end of a keys card that leads to the controller
## buttons of the same set, and the title of that card.
const BUTTONS_LABEL := "BUTTONS"
const BUTTONS_TITLES: PackedStringArray = ["BUTTONS", "PLAYER 1 BUTTONS", "PLAYER 2 BUTTONS"]


## The main card; Save Game and End Game only in a game.
static func main(in_game: bool) -> Menu:
	var ids: Array[StringName] = [
		GalaxyMenuController.NEW_GAME,
		MenuController.SLOTS_LOAD,
		MenuController.SLOTS_SAVE,
		GalaxyMenuController.CONFIGURE,
		MenuController.CHOICE_RESUME,
		GalaxyMenuController.CHOICE_END_GAME,
		GalaxyMenuController.PADDLE_WAR,
		MenuController.CHOICE_QUIT,
	]
	var menu := Menu.create(MenuController.MAIN)
	for index in ids.size():
		var label := MAIN_LABELS[index]
		if ids[index] == MenuController.CHOICE_RESUME and not in_game:
			label = RETURN_TO_DEMO
		label = Lang.text(label)
		var only_in_game := (
			ids[index] in [MenuController.SLOTS_SAVE, GalaxyMenuController.CHOICE_END_GAME]
		)
		menu.add(label, ids[index], 0, in_game or not only_in_game)
	menu.cursor = RETURN_ROW if in_game else 0
	return menu


## Easy, Normal, Hard; the cursor on Normal (seen in v1.0).
static func new_game() -> Menu:
	var menu := Menu.create(GalaxyMenuController.NEW_GAME)
	for level in DIFFICULTY_LABELS.size():
		menu.add(Lang.text(DIFFICULTY_LABELS[level]), &"level", level)
	menu.cursor = GalaxyDifficulty.Level.NORMAL
	return menu


## The slots: empty ones cannot be loaded; the cursor starts on the first.
static func slots(kind: StringName, saves: GalaxySaveSlots) -> Menu:
	var menu := Menu.create(kind)
	for slot in range(1, saves.count + 1):
		var saved := saves.name_of(slot)
		menu.add(saved, &"slot", slot, kind == MenuController.SLOTS_SAVE or not saved.is_empty())
	menu.cursor = 0
	return menu


static func configure() -> Menu:
	var menu := Menu.create(GalaxyMenuController.CONFIGURE)
	menu.add(Lang.text("SOUND"), GalaxyMenuController.SOUND_CARD)
	menu.add(Lang.text("MUSIC"), GalaxyMenuController.MUSIC_CARD)
	menu.add(Lang.text("OPTIONS"), MenuController.OPTIONS)
	menu.add(GalaxyMenuController.GAP + Lang.text("KEYBOARD"), MenuController.KEY_SET)
	menu.add(Lang.text("RESET KEYS"), &"reset")
	return menu


## A card of choices of which one is checked; the cursor starts on it
## (Omni USL_CheckCardItem).
static func radio(kind: StringName, labels: PackedStringArray, checked: int) -> Menu:
	var menu := Menu.create(kind)
	for index in labels.size():
		menu.add(labels[index], RADIO, index)
	menu.cursor = checked
	return menu


## The keys of one player: the action, and its key in a box. With
## [param key_set] 1 or 2 the keys of that player when two play (D12).
static func keys(key_set := 0) -> Menu:
	var menu := Menu.create(MenuController.KEY_SET)
	var actions: Dictionary = (
		KeyBindings.ACTIONS if key_set <= 0 else KeyBindings.PLAYER_ACTIONS[key_set - 1]
	)
	for action: String in actions:
		var label := Lang.text(actions[action].to_upper())
		# The original's box holds one key: the first (the one that changes).
		var key_name := KeyBindings.describe(action).get_slice(KEY_NAME_SEPARATOR, 0).capitalize()
		menu.add(label + GalaxyMenuController.VALUE_SEPARATOR + key_name, StringName(action))
	menu.add(Lang.text(BUTTONS_LABEL), MenuController.BUTTON_SET, maxi(0, key_set))
	return menu


## Ours: the controller buttons of one set (0 playing alone, 1 or 2 a
## player of two), each action with its first button in a box, as the keys
## have; a card without a title picture, so its title is its first line.
static func buttons(button_set: int) -> Menu:
	var menu := Menu.create(MenuController.BUTTON_SET, [Lang.text(BUTTONS_TITLES[button_set])])
	var actions: Dictionary = (
		KeyBindings.ACTIONS if button_set == 0 else KeyBindings.PLAYER_ACTIONS[button_set - 1]
	)
	for action: String in actions:
		var label := Lang.text(actions[action].to_upper())
		var button_name := ButtonBindings.describe(action).get_slice(KEY_NAME_SEPARATOR, 0)
		menu.add(label + GalaxyMenuController.VALUE_SEPARATOR + button_name, StringName(action))
	return menu


## Keen 4's score box and the shared display settings, as the original
## names its options ("SCORE BOX (ON)").
static func options(settings: UserSettings, score_box: bool) -> Menu:
	var display := settings.display
	var widescreen := display.aspect == DisplaySettings.Aspect.WIDESCREEN
	var menu := Menu.create(MenuController.OPTIONS)
	menu.add(_named("SCORE BOX", _state(score_box)), &"score_box")
	menu.add(_named("WIDESCREEN", _state(widescreen)), &"widescreen")
	menu.add(_named("4:3 PIXELS", _state(display.correct_pixel_aspect)), &"pixels")
	menu.add(_named("FULL SCREEN", _state(settings.fullscreen)), &"fullscreen")
	menu.add(_named("SMOOTH MOTION", _state(display.smooth_motion)), &"smooth_motion")
	menu.add(_named("BACKGROUNDS", _state(display.backgrounds)), &"backgrounds", 0, widescreen)
	var graphics := Lang.text(MenuController.GRAPHICS_LABELS[display.graphics])
	menu.add(_named("GRAPHICS", "(%s)" % graphics), &"graphics")
	var lighting := Lang.text(MenuController.LIGHTING_LABELS[int(display.realistic)])
	menu.add(_named("LIGHTING", "(%s)" % lighting), &"realistic")
	menu.add(_named("ALIEN TEXT", _state(settings.alien_text)), &"alien_text")
	var language := OptionsPages.language_name(settings.language).to_upper()
	menu.add(_named("LANGUAGE", "(%s)" % language), OptionsPages.LANGUAGE)
	return menu


## Ours: the languages as a card of choices, the one in use checked; a card
## without a title picture, so its title is its first line.
static func languages(current: String) -> Menu:
	var available := Languages.available()
	var names := PackedStringArray()
	for code: String in available:
		names.append(Lang.fold(available[code]).to_upper())
	var menu := radio(OptionsPages.LANGUAGES, names, maxi(0, available.keys().find(current)))
	menu.header = PackedStringArray([Lang.text("LANGUAGE")])
	return menu


static func _state(on: bool) -> String:
	return "(%s)" % Lang.text("ON" if on else "OFF")


## An option's name in the language in use, then its value.
static func _named(english: String, value: String) -> String:
	return Lang.text(english) + " " + value
