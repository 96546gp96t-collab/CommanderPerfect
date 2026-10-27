class_name GameTexts
extends RefCounted
## The texts of a game's own files that a language can translate, by their
## names ("keen1.hint.2"), as read from the player's files: what
## tools/language_template.gd writes out for a translator, and what the
## tests check every translation against. Each game keeps its own list
## (Keen1Texts, ...); the place that shows a text asks [Lang] for it by the
## same name.
##
## The English texts are the player's own and never go into git; only the
## translations in `languages/` do (the user's exception, 26-10-2026).


## Name -> English text of every translatable text of game [param game]
## (1-5) in the player's files; empty when they are missing.
static func catalog(game: int) -> Dictionary[String, String]:
	var texts: Dictionary[String, String] = {}
	match game:
		4:
			texts = GalaxyTexts.catalog_of(Keen4Episode.game_rules())
		5:
			texts = GalaxyTexts.catalog_of(Keen5Episode.game_rules())
		_:
			pass
	return texts
