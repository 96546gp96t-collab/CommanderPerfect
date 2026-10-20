class_name GalaxyMenuPages
extends RefCounted
## The cards of a Galaxy control panel as lists of choices (Omni
## `ck_us_2.c`: the US_CardItem tables; facts only, and seen in Keen 4
## v1.0), for [GalaxyMenuController]: the main card, New Game, the save
## slots, Configure, Sound and Music, the keys and the options.

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
		menu.add(DIFFICULTY_LABELS[level], &"level", level)
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
	menu.add("SOUND", GalaxyMenuController.SOUND_CARD)
	menu.add("MUSIC", GalaxyMenuController.MUSIC_CARD)
	menu.add("OPTIONS", MenuController.OPTIONS)
	menu.add(GalaxyMenuController.GAP + "KEYBOARD", MenuController.KEY_SET)
	menu.add("RESET KEYS", &"reset")
	return menu


## A card of choices of which one is checked; the cursor starts on it
## (Omni USL_CheckCardItem).
static func radio(kind: StringName, labels: PackedStringArray, checked: int) -> Menu:
	var menu := Menu.create(kind)
	for index in labels.size():
		menu.add(labels[index], RADIO, index)
	menu.cursor = checked
	return menu


## The keys of one player: the action, and its key in a box.
static func keys() -> Menu:
	var menu := Menu.create(MenuController.KEY_SET)
	for action: String in KeyBindings.ACTIONS:
		var label: String = KeyBindings.ACTIONS[action].to_upper()
		# The original's box holds one key: the first (the one that changes).
		var key_name := KeyBindings.describe(action).get_slice(KEY_NAME_SEPARATOR, 0).capitalize()
		menu.add(label + GalaxyMenuController.VALUE_SEPARATOR + key_name, StringName(action))
	return menu


## Keen 4's score box and the shared display settings, as the original
## names its options ("SCORE BOX (ON)").
static func options(settings: UserSettings, score_box: bool) -> Menu:
	var display := settings.display
	var widescreen := display.aspect == DisplaySettings.Aspect.WIDESCREEN
	var menu := Menu.create(MenuController.OPTIONS)
	menu.add("SCORE BOX " + _state(score_box), &"score_box")
	menu.add("WIDESCREEN " + _state(widescreen), &"widescreen")
	menu.add("4:3 PIXELS " + _state(display.correct_pixel_aspect), &"pixels")
	menu.add("FULL SCREEN " + _state(settings.fullscreen), &"fullscreen")
	menu.add("SMOOTH MOTION " + _state(display.smooth_motion), &"smooth_motion")
	menu.add("BACKGROUNDS " + _state(display.backgrounds), &"backgrounds", 0, widescreen)
	menu.add("GRAPHICS (%s)" % MenuController.GRAPHICS_LABELS[display.graphics], &"graphics")
	return menu


static func _state(on: bool) -> String:
	return "(ON)" if on else "(OFF)"
