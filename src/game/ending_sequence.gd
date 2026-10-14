class_name EndingSequence
extends RefCounted
## The end of the game, once Keen has all four ship parts, in fixed ticks.
## Only the logic; [LevelView] shows what [member stage] asks for.
##
##   AT_SHIP             on the world map, Keen stands next to his ship and
##                       repairs it (a message)
##   FLIGHT_HOME         the ship flies from Mars to Earth (map 81)
##   AT_HOME             the picture of Keen's house (FINALE.CK1) with the
##                       conversation, one message per button press
##   FLIGHT_TO_MOTHERSHIP  the ship flies up to the Vorticon mothership
##   END_TEXT            ENDTEXT.CK1, scrolled with up and down
##   FINISHED            the view starts a new game
## A button (jump, pogo, fire or Enter) moves on from a message or the text.

## Emitted when the stage, message or text position changes: the view then
## redraws the window and loads the right map.
signal changed

enum Stage { AT_SHIP, FLIGHT_HOME, AT_HOME, FLIGHT_TO_MOTHERSHIP, END_TEXT, FINISHED }

## The light in the bedroom window during the conversation at home: on when
## the parents come in (message [constant LIGHT_ON_MESSAGE], counting from
## 0), off again at "Goodnight, dear." ([constant LIGHT_OFF_MESSAGE]).
const WINDOW_ON_BITMAP := "WINDON"
const WINDOW_OFF_BITMAP := "WINDOFF"
const LIGHT_ON_MESSAGE := 2
const LIGHT_OFF_MESSAGE := 5
## Where the window bitmaps go on the picture, in pixels.
const WINDOW_POSITION := Vector2(80, 0)
## Characters per line and lines per page of the end text, inside the
## border of a 320x200 screen.
const TEXT_WIDTH := 38
const TEXT_LINES := 23
## Ticks between two lines while up or down is held.
const SCROLL_TICKS := 4

var stage := Stage.AT_SHIP
var texts: EndingTexts
var flight: ShipFlight
## Which message of the conversation at home is shown.
var home_message := 0
## The end text, laid out for [constant TEXT_WIDTH] columns.
var end_text := PackedStringArray()
## First line of the end text that is shown.
var text_offset := 0
var _confirm_was_held := true
var _scroll_timer := 0


## [param end_text_data] is the contents of ENDTEXT.CK1.
static func create(ending_texts: EndingTexts, end_text_data: PackedByteArray) -> EndingSequence:
	var ending := EndingSequence.new()
	ending.texts = ending_texts
	ending.end_text = TextDocument.layout(end_text_data, TEXT_WIDTH)
	return ending


## Advances one tick. [param confirm_held] is true while one of the buttons
## that move on is held; [param vertical] scrolls the end text.
func step(confirm_held: bool, vertical := 0) -> void:
	var confirmed := confirm_held and not _confirm_was_held
	_confirm_was_held = confirm_held
	match stage:
		Stage.FLIGHT_HOME, Stage.FLIGHT_TO_MOTHERSHIP:
			flight.step()
			if flight.is_finished():
				_next_stage()
		Stage.END_TEXT:
			_scroll(vertical)
			if confirmed:
				_next_stage()
		Stage.AT_SHIP, Stage.AT_HOME:
			if confirmed:
				confirm()


## Moves on from the message or text that is shown (also for Enter).
func confirm() -> void:
	match stage:
		Stage.AT_SHIP, Stage.END_TEXT:
			_next_stage()
		Stage.AT_HOME:
			home_message += 1
			if home_message >= texts.home_messages.size():
				_next_stage()
			else:
				changed.emit()


## The lines of the window that is open, or none.
func window_lines() -> PackedStringArray:
	match stage:
		Stage.AT_SHIP:
			return texts.returns_to_ship
		Stage.AT_HOME:
			return texts.home_messages[home_message]
		Stage.END_TEXT:
			return end_text.slice(text_offset, text_offset + TEXT_LINES)
	return PackedStringArray()


## The bitmap that shows the bedroom window, or "" for the picture as it is.
func window_bitmap() -> String:
	if stage != Stage.AT_HOME or home_message < LIGHT_ON_MESSAGE:
		return ""
	return WINDOW_ON_BITMAP if home_message < LIGHT_OFF_MESSAGE else WINDOW_OFF_BITMAP


## The map that is shown: the world map, space, or none (picture or text).
func map_number() -> int:
	match stage:
		Stage.AT_SHIP:
			return GameFiles.WORLD_MAP_LEVEL
		Stage.FLIGHT_HOME, Stage.FLIGHT_TO_MOTHERSHIP:
			return GameFiles.ENDING_LEVEL
	return 0


func is_finished() -> bool:
	return stage == Stage.FINISHED


func _next_stage() -> void:
	stage = (stage + 1) as Stage
	match stage:
		Stage.FLIGHT_HOME:
			flight = ShipFlight.to_earth()
		Stage.AT_HOME:
			home_message = 0
		Stage.FLIGHT_TO_MOTHERSHIP:
			flight = ShipFlight.to_mothership()
		Stage.END_TEXT:
			text_offset = 0
	changed.emit()


func _scroll(vertical: int) -> void:
	if vertical == 0:
		_scroll_timer = 0
		return
	if _scroll_timer > 0:
		_scroll_timer -= 1
		return
	_scroll_timer = SCROLL_TICKS
	var last := maxi(0, end_text.size() - TEXT_LINES)
	var offset := clampi(text_offset + vertical, 0, last)
	if offset != text_offset:
		text_offset = offset
		changed.emit()
