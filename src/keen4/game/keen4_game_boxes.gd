class_name Keen4GameBoxes
extends GalaxyGameBoxes
## The boxes of Keen 4 between the levels (milestone D7; Omni `ck_game.c`:
## CK_BeginCacheBox, CK_UpdateCacheBox, CK_TryAgainMenu, CK_GameOver,
## CK_GameLoop's "One moment"; `ck4_misc.c:CK4_ShowCantSwimMessage`; facts
## only; seen in the original, D7): the shared [GalaxyGameBoxes] by Keen
## 4's rules (since milestone E13: entering a map, "One moment", the box
## after a death, "Game Over!", "PAUSED"), and Keen 4's own:
##   - "I can't swim!" (Keen talking on the right, the text 12 down: seen
##     in the original, D7; Omnispeak 6), the sixth of the council
##     messages.

## "I can't swim!" goes this far down (seen in the original, D7); Keen
## talking is this many pictures from the end of the picture range.
const CANT_SWIM_DOWN := 12
const KEEN_TALK_FROM_END := 10
## The council messages: "I can't swim!" is the sixth (files, v1.0).
const CANT_SWIM_MESSAGE := 5

var _council := PackedStringArray()


## The boxes of [param data] by Keen 4's rules (or [param game_rules]);
## into [param into] when given (a subclass: [Keen4NamedBoxes]).
static func create(
	data: GalaxyData, game_rules: GalaxyGameRules = null, into: GalaxyGameBoxes = null
) -> Keen4GameBoxes:
	var boxes: Keen4GameBoxes = into if into is Keen4GameBoxes else Keen4GameBoxes.new()
	GalaxyGameBoxes.create(
		data, game_rules if game_rules != null else Keen4Episode.game_rules(), boxes
	)
	boxes._council = data.executable.messages(Keen4Episode.COUNCIL_MESSAGES)
	return boxes


## "I can't swim!" (Omni CK4_ShowCantSwimMessage).
func cant_swim() -> Image:
	var window := _window()
	window.open_centred(WINDOW_CELLS)
	var right := WINDOW_CELLS.x * GalaxyWindow.CELL - PICTURE_WIDTH
	window.draw_picture(_picture(KEEN_TALK_FROM_END), Vector2i(right, 0))
	window.narrow(0, PICTURE_WIDTH)
	window.skip(CANT_SWIM_DOWN)
	var said := _text(_council, CANT_SWIM_MESSAGE)
	window.print_centred(
		GalaxyTexts.run_text(
			_rules.text_names, Keen4Episode.COUNCIL_MESSAGES, CANT_SWIM_MESSAGE, said
		)
	)
	return window.image()
