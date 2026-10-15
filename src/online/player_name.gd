class_name PlayerName
extends RefCounted
## The name a player shows to the other one: what he typed, his Steam name,
## or what arrives over the network from a stranger. Only plain printable
## characters, no longer than a name in the high score table, so that it
## fits the game font and the windows.

const MAX_LENGTH := HighScores.MAX_NAME_LENGTH
const FIRST_PRINTABLE := 32
const LAST_PRINTABLE := 126
## Shown when nothing usable is left.
const FALLBACK := "Keen"


## [param raw] with every other character left out, trimmed and cut to
## length; [constant FALLBACK] when nothing is left.
static func clean(raw: String) -> String:
	var kept := ""
	for index in raw.length():
		var code := raw.unicode_at(index)
		if code >= FIRST_PRINTABLE and code <= LAST_PRINTABLE:
			kept += String.chr(code)
	kept = kept.strip_edges().left(MAX_LENGTH).strip_edges()
	return kept if not kept.is_empty() else FALLBACK
