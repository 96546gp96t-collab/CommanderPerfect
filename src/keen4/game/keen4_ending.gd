class_name Keen4Ending
extends GalaxyEnding
## Keen 4's end: the pages of the end text after the eighth rescue (Omni
## `ck_text.c`: help_endgame; facts only; seen in the original, D8), the
## shared [GalaxyEnding] by Keen 4's rules (since milestone E13):
##   - each page is laid out like a help page, without a page number
##     ([GalaxyPageLayout]): on light grey in v1.0, on red inside the frame
##     with its plain bottom edge in v1.4
##     ([method GalaxyHelp.page_layout]); a page with timed pictures shows
##     them one after the other (their pauses in tics), keys do nothing
##     meanwhile;
##   - then an arrow at the bottom right blinks, dim and bright, 70 tics
##     each (seen: about 1 s); a key goes to the next page;
##   - after the last page the end is over (the high scores follow).
## The arrows are pictures counted from the start of the picture range
## (16 × 16 in v1.0, 16 × 8 in v1.4, at the same place); the text is the
## fifth of the text range (the same in v1.0 and v1.4).

const END_TEXT := 4
const ARROW_DIM := 41
const ARROW_BRIGHT := 42


## The end pages of [param graphics] by Keen 4's rules (or
## [param game_rules]), of text [param text].
static func create(
	graphics: GalaxyGraphics, game_rules: GalaxyGameRules = null, text: int = END_TEXT
) -> Keen4Ending:
	var ending := Keen4Ending.new()
	ending.set_up(graphics, game_rules if game_rules != null else Keen4Episode.game_rules(), text)
	return ending
