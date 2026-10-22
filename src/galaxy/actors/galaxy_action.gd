class_name GalaxyAction
extends RefCounted
## One action (state) of a Galaxy object, as the original keeps them
## (docs/keen4/research.md §3): which sprite it shows facing left and right,
## how its timer and velocity work ([enum Type]), whether leftover tics
## carry into the next action ([member protect]), whether the object stays
## on the ground ([member stick_to_ground]), and three functions given by
## name: [member think] (what it does), [member contact] (when it touches
## another object) and [member react] (after the tile collision; for Keen
## the checks for landing and falling). [member next] follows when the
## timer runs out; without one the object is removed.
##
## The numbers of each action come from Omnispeak's action tables
## (`data/keen4/ACTION.CK4`, marked (Omni)); the functions are methods of
## the object's own class, called by name ([GalaxyWorld]). An episode
## writes its tables as rows ([method table_from]) with sprite names that
## its own sprite list resolves.

## How the timer and velocity work (Omni AT_*).
##   - STEP: when the timer runs out, move once by the velocity and think.
##   - SLIDE: move velocity × tics every frame; think when the timer ends.
##   - THINK: think every frame; no timer, no velocity.
##   - STEP_THINK: think every frame; at the end of the timer as STEP.
##   - SLIDE_THINK: think every frame and move as SLIDE.
enum Type { STEP, SLIDE, THINK, STEP_THINK, SLIDE_THINK }

## A sprite field that leaves the object's sprite as it is.
const KEEP_SPRITE := -1
## A sprite field that hides the object (its sprite becomes none).
const NO_SPRITE := -2
## A row of [method table_from] is one line of words, in this order:
## name, left sprite, right sprite, type ([constant TYPE_WORDS]), flags
## ("p" protect, "s" stick to ground, "-" neither), timer, velocity x,
## velocity y, think, contact, react, next. Think, contact and react are
## method names without their prefix ([code]_think_[/code],
## [code]_contact_[/code], [code]_react_[/code]); "-" is none. A sprite is a
## name from the episode's sprite list, "-" to keep the sprite, "x" to hide
## it.
const TYPE_WORDS: Dictionary[String, Type] = {
	"step": Type.STEP,
	"slide": Type.SLIDE,
	"think": Type.THINK,
	"step+": Type.STEP_THINK,
	"slide+": Type.SLIDE_THINK,
}
const NONE_WORD := "-"
const HIDE_WORD := "x"
const ROW_WORDS := 12
const PROTECT_FLAG := "p"
const STICK_FLAG := "s"

var name := &""
var left_sprite := KEEP_SPRITE
var right_sprite := KEEP_SPRITE
var type := Type.STEP
## Leftover tics of the action before may run this action to its end in
## the same frame. Without it, an action reached with as many leftover tics
## as its timer (or more) never ends in that frame: the rest is lost (Omni
## protectAnimation).
var protect := false
## The object never walks off a ledge: it is pushed onto the floor every
## move, and kept where it was when there is none.
var stick_to_ground := false
## Tics; 0 is "never runs out".
var timer := 0
## Units per tic (SLIDE) or per step (STEP), times the object's direction.
var velocity := Vector2i.ZERO
## Method names on the object; empty for none.
var think := &""
var contact := &""
var react := &""
## The action after this one; null removes the object. Held weakly: the
## actions of a table form loops, and the table holds them all.
var next: GalaxyAction:
	get:
		return _next.get_ref() as GalaxyAction if _next != null else null
	set(action):
		_next = weakref(action) if action != null else null
var _next: WeakRef


## The actions described by [param rows] (see above), by name, with every
## [member next] linked; [param sprites] turns sprite names into sprites.
## A row that cannot be read is reported and left out.
static func table_from(
	rows: PackedStringArray, sprites: Dictionary[StringName, int]
) -> Dictionary[StringName, GalaxyAction]:
	var actions: Dictionary[StringName, GalaxyAction] = {}
	var next_names: Dictionary[StringName, String] = {}
	for row in rows:
		var words := row.split(" ", false)
		if words.size() != ROW_WORDS or not TYPE_WORDS.has(words[3]):
			push_error("Action row cannot be read: %s" % row)
			continue
		var action := GalaxyAction.new()
		action.name = words[0]
		action.left_sprite = _sprite(words[1], sprites)
		action.right_sprite = _sprite(words[2], sprites)
		action.type = TYPE_WORDS[words[3]]
		action.protect = words[4].contains(PROTECT_FLAG)
		action.stick_to_ground = words[4].contains(STICK_FLAG)
		action.timer = words[5].to_int()
		action.velocity = Vector2i(words[6].to_int(), words[7].to_int())
		action.think = _method("_think_", words[8])
		action.contact = _method("_contact_", words[9])
		action.react = _method("_react_", words[10])
		actions[action.name] = action
		next_names[action.name] = words[11]
	for action_name in next_names:
		var next_name := next_names[action_name]
		if next_name == NONE_WORD:
			continue
		if not actions.has(StringName(next_name)):
			push_error("Action %s: no action %s follows." % [action_name, next_name])
			continue
		actions[action_name].next = actions[StringName(next_name)]
	return actions


## The sprite an object facing [param direction] shows in this action once
## it runs (Omni CK_RunAction, CK_SetAction2): the right sprite facing
## right, otherwise the left one; [param current] when the action keeps it.
func sprite_facing(direction: int, current: int) -> int:
	if right_sprite == KEEP_SPRITE:
		return current
	var sprite := right_sprite if direction > 0 else left_sprite
	return -1 if sprite == NO_SPRITE else sprite


## Whether the action moves by its velocity every frame.
func slides() -> bool:
	return type == Type.SLIDE or type == Type.SLIDE_THINK


## Whether it thinks every frame (and not only when its timer ends).
func thinks_every_frame() -> bool:
	return type in [Type.THINK, Type.STEP_THINK, Type.SLIDE_THINK]


static func _sprite(word: String, sprites: Dictionary[StringName, int]) -> int:
	if word == NONE_WORD:
		return KEEP_SPRITE
	if word == HIDE_WORD:
		return NO_SPRITE
	if not sprites.has(StringName(word)):
		push_error("No sprite %s." % word)
		return NO_SPRITE
	return sprites[StringName(word)]


static func _method(prefix: String, word: String) -> StringName:
	return &"" if word == NONE_WORD else StringName(prefix + word)
