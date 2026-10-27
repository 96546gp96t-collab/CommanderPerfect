class_name Lang
extends RefCounted
## The language the game speaks, for every game at once. English is the
## game as it is: every text then comes back unchanged, so the original
## stays exactly as it was. In another language a text without a
## translation stays English, so a language that is not finished still
## works.
##
## Three kinds of text go through here:
##   [method text]   the engine's own texts (menus, messages), by their
##                   English words
##   [method game]   texts from the game files, by a name
##                   ("keen1.hint.2"), because their English words differ
##                   between versions of a game
##   [method alien]  the English of a sign in the alien alphabet
## The original fonts have no accented letters, so translations are folded
## to plain letters ([method fold]). A character the fonts draw as a picture
## (code 128 and up, such as Keen 3's red labels) is written "\xNN" in a
## language file.

## Accented letters and what the original fonts draw instead.
const FOLDS: Dictionary[String, String] = {
	"à": "a",
	"á": "a",
	"â": "a",
	"ã": "a",
	"ä": "a",
	"å": "a",
	"æ": "ae",
	"ç": "c",
	"è": "e",
	"é": "e",
	"ê": "e",
	"ë": "e",
	"ì": "i",
	"í": "i",
	"î": "i",
	"ï": "i",
	"ñ": "n",
	"ò": "o",
	"ó": "o",
	"ô": "o",
	"õ": "o",
	"ö": "o",
	"ø": "o",
	"ù": "u",
	"ú": "u",
	"û": "u",
	"ü": "u",
	"ý": "y",
	"ÿ": "y",
	"ß": "ss",
	"À": "A",
	"Á": "A",
	"Â": "A",
	"Ã": "A",
	"Ä": "A",
	"Å": "A",
	"Æ": "AE",
	"Ç": "C",
	"È": "E",
	"É": "E",
	"Ê": "E",
	"Ë": "E",
	"Ì": "I",
	"Í": "I",
	"Î": "I",
	"Ï": "I",
	"Ñ": "N",
	"Ò": "O",
	"Ó": "O",
	"Ô": "O",
	"Õ": "O",
	"Ö": "O",
	"Ø": "O",
	"Ù": "U",
	"Ú": "U",
	"Û": "U",
	"Ü": "U",
	"Ý": "Y",
	"‘": "'",
	"’": "'",
	"“": '"',
	"”": '"',
	"–": "-",
	"—": "-",
	"…": "...",
	"«": '"',
	"»": '"',
	"¡": "!",
	"¿": "?",
}
## Highest character the original fonts can draw as a letter.
const LAST_PLAIN := 126
const UNKNOWN := "?"
const ESCAPE := "\\x"
const ESCAPE_DIGITS := 2

## The language in use; null for English.
static var _language: LanguageFile = null
static var _code := Languages.ENGLISH
## Engine texts asked for in a language that has no translation for them
## (for the tests and the template tool).
static var missing: Dictionary[String, bool] = {}


## Switches to the language [param code] from [param search]; an unknown
## or empty code (or one without files) is English.
static func use(code: String, search: PackedStringArray = Languages.folders()) -> void:
	_language = Languages.load_language(code, search)
	_code = code if _language != null else Languages.ENGLISH


## Switches to [param language] itself (tests); null is English.
static func use_file(language: LanguageFile, code := "test") -> void:
	_language = language
	_code = code if language != null else Languages.ENGLISH


## The code of the language in use ("en", "nl", ...).
static func code() -> String:
	return _code


static func is_english() -> bool:
	return _language == null


## The engine text [param english] in the language in use.
static func text(english: String) -> String:
	if _language == null or english.is_empty():
		return english
	var translated: String = _language.texts.get(english, "")
	if translated.is_empty():
		missing[english] = true
		return english
	return fold(translated)


## Each of [param english] through [method text].
static func texts(english: PackedStringArray) -> PackedStringArray:
	if _language == null:
		return english
	var translated := PackedStringArray()
	for line in english:
		translated.append(text(line))
	return translated


## The text from the game files named [param id]; [param english] (as read
## from the files) when there is no translation.
static func game(id: String, english: String) -> String:
	if _language == null or not _language.game.has(id):
		return english
	return fold(_language.game[id])


## Like [method game] for a text of several lines.
static func game_lines(id: String, english: PackedStringArray) -> PackedStringArray:
	if _language == null or not _language.game.has(id):
		return english
	return fold(_language.game[id]).split("\n")


## Whether the language in use translates the game text [param id].
static func has_game(id: String) -> bool:
	return _language != null and _language.game.has(id)


## The alien sign that reads [param english] in the language in use.
static func alien(english: String) -> String:
	if _language == null:
		return english
	return fold(_language.alien.get(english, english))


## [param translated] with accented letters made plain, what the original
## fonts cannot draw as [constant UNKNOWN], and "\xNN" as character NN.
static func fold(translated: String) -> String:
	var plain := ""
	var index := 0
	while index < translated.length():
		var character := translated[index]
		var hex := translated.substr(index + ESCAPE.length(), ESCAPE_DIGITS)
		if translated.substr(index, ESCAPE.length()) == ESCAPE and hex.is_valid_hex_number():
			plain += String.chr(hex.hex_to_int())
			index += ESCAPE.length() + ESCAPE_DIGITS
			continue
		if translated.unicode_at(index) <= LAST_PLAIN:
			plain += character
		else:
			plain += FOLDS.get(character, UNKNOWN)
		index += 1
	return plain
