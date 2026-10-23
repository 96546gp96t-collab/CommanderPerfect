class_name Keen4FrontScreen
extends RefCounted
## What Keen 4 shows around its games is the shared [GalaxyFrontScreen]
## since milestone E13 ([Keen4View] on [GalaxyOnlineScreen]); this class
## keeps the names Keen 4's tests and tools know: the front's kinds, the
## intro's two words and the original's high-score table.

## The front's kinds are the shared front screen's (an enum by its old
## name, so the name keeps the enum's casing).
# gdlint: ignore=constant-name
const Front = GalaxyFrontScreen.Front
## The misc chunks with the two words of the intro.
const LEFT_WORD_MISC := 1
const RIGHT_WORD_MISC := 2


## The original's table from the player's program.
static func default_high_scores(data: GalaxyData) -> Array[GalaxyHighScores.Entry]:
	return GalaxyHighScoreBoard.defaults(data, Keen4Episode.game_rules())
