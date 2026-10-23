class_name Keen4HighScoreBoard
extends RefCounted
## Keen 4's high-score table drawn over map 19 is the shared
## [GalaxyHighScoreBoard] by Keen 4's rules since milestone E13 (Omni
## `ck_inter.c`: CK_OverlayHighScores, CK_SubmitHighScore; seen in the
## original, D8): eight rows 16 pixels apart from y 51 of the view, the
## name from x 24, one council-member tile (8×8 tile 71) per rescued member
## from x 152, the score right-aligned at x 296, XOR 15 over the map. This
## class keeps the names Keen 4's tests know.


## The table of [param scores] over [param map]'s view at [param origin],
## by Keen 4's rules.
static func create(
	graphics: GalaxyGraphics, scores: GalaxyHighScores, map: GalaxyMap, origin: Vector2i
) -> GalaxyHighScoreBoard:
	return GalaxyHighScoreBoard.create(graphics, Keen4Episode.game_rules(), scores, map, origin)


## [param score] in the font's own score digits.
static func score_text(score: int) -> String:
	return GalaxyHighScoreBoard.score_text(score)
