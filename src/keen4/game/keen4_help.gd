class_name Keen4Help
extends GalaxyHelp
## Keen 4's help (F1), as v1.0 shows it (seen in the original, D8; Omni
## `ck_text.c`: ShowHelp, HelpScreens; facts only), and v1.4 (D13): the
## shared [GalaxyHelp] by Keen 4's rules (since milestone E13):
##   - the menu: the help picture at (96, 8) on light grey and the pointing
##     hand beside the topic, 24 pixels apart: ComputerWrist, The Game, The
##     Story, Order Info, About Id; up and down choose (not past the ends),
##     Enter, jump or pogo open the topic, Escape leaves the help;
##   - a topic: its text's pages ([GalaxyTextPages], [GalaxyPageLayout]) on
##     light grey, "pg 1 of 13" at the bottom right; left, up and page up go
##     back, right, down and page down on, not past the first or last page;
##     Escape goes back to the menu, where the hand still points at it;
##   - v1.4 draws the same on red inside a frame ([GalaxyPageFrame]): the
##     menu with its plain bottom edge, a page with the bar at the bottom
##     and "pg 1 of 15" at (218, 186) in light red (seen in v1.4).
## The pictures are counted from the start of the picture range, the same
## in v1.0 and v1.4; the texts by their place in the text range (v1.0's
## order: help, story, keys, about Id, end, not in the demo, ordering).

const MENU_PICTURE := 0
const POINTER_PICTURE := 39
## The text of each topic, in the menu's order.
const TOPIC_TEXTS: PackedInt32Array = [0, 2, 1, 6, 3]


## The help of [param graphics] by Keen 4's rules (or [param game_rules]).
static func create(graphics: GalaxyGraphics, game_rules: GalaxyGameRules = null) -> Keen4Help:
	var help := Keen4Help.new()
	help.set_up(graphics, game_rules if game_rules != null else Keen4Episode.game_rules())
	return help
