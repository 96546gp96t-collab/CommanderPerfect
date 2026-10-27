class_name OptionsPages
extends RefCounted
## The options menu of Keen 1-3 and the list of languages it leads to, for
## [MenuController]. Each row is a name and its value, lined up in two
## columns as wide as the longest name of the language in use needs.

## Where the values start in English; a language with longer names moves
## them further right.
const VALUE_COLUMN := 14
## The options menu row that leads to the list of languages, and that list.
const LANGUAGE := &"language"
const LANGUAGES := &"languages"


## The options: sound and display settings, the extras, alien signs and the
## language; Keen 1's extra levels only when [param with_extra_levels].
static func options(settings: UserSettings, with_extra_levels: bool) -> Menu:
	var display := settings.display
	var widescreen := display.aspect == DisplaySettings.Aspect.WIDESCREEN
	var rows: Array[Array] = [
		["Sound", on_off(settings.sound_enabled), &"sound", true],
		["Widescreen", on_off(widescreen), &"widescreen", true],
		["4:3 pixels", on_off(display.correct_pixel_aspect), &"pixels", true],
		["Full screen", on_off(settings.fullscreen), &"fullscreen", true],
		["Smooth motion", on_off(display.smooth_motion), &"smooth_motion", true],
		# Pictures behind the levels only go with widescreen.
		[
			"Backgrounds",
			on_off(display.backgrounds) if widescreen else "-",
			&"backgrounds",
			widescreen
		],
		[
			"Graphics",
			Lang.text(MenuController.GRAPHICS_LABELS[display.graphics]),
			&"graphics",
			true
		],
		[
			"Lighting",
			Lang.text(MenuController.LIGHTING_LABELS[int(display.realistic)]),
			&"realistic",
			true
		],
	]
	if with_extra_levels:
		rows.append(["Extra levels", on_off(settings.extra_levels), &"extra_levels", true])
	rows.append(["Alien text", alien_state(settings.alien_text), &"alien_text", true])
	rows.append(["Language", language_name(settings.language), LANGUAGE, true])
	var column := VALUE_COLUMN
	for row in rows:
		column = maxi(column, Lang.text(row[0]).length() + 1)
	var menu := Menu.create(MenuController.OPTIONS, ["  " + Lang.text("OPTIONS")])
	for row in rows:
		menu.add(Lang.text(row[0]).rpad(column) + row[1], row[2], 0, row[3])
	return menu


## Every language that can be picked, the cursor on [param current].
static func languages(current: String) -> Menu:
	var menu := Menu.create(LANGUAGES, ["  " + Lang.text("LANGUAGE")])
	var available := Languages.available()
	for code: String in available:
		menu.add(Lang.fold(available[code]), StringName(code))
		if code == current:
			menu.cursor = menu.items.size() - 1
	return menu


## The name of the language [param code] as the list shows it.
static func language_name(code: String) -> String:
	return Lang.fold(Languages.available().get(code, Languages.ENGLISH_NAME))


static func on_off(on: bool) -> String:
	return Lang.text("ON" if on else "OFF")


## Whether alien signs show their translation.
static func alien_state(translated: bool) -> String:
	return Lang.text("TRANSLATED" if translated else "ORIGINAL")
