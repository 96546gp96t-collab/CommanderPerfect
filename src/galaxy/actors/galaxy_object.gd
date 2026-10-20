class_name GalaxyObject
extends RefCounted
## One thing that moves in a Galaxy level (Keen, a shot, an item, an
## enemy): its position and velocity in units ([GalaxyUnits]), the action
## it runs ([GalaxyAction]), the sprite it shows and the hit box that
## sprite gives it, and what the tile collision found on each side
## ([GalaxyClip]). The [GalaxyWorld] runs its actions; an object's think,
## contact and react functions are methods of its own class, named in its
## actions.
##
## The sides found by the tile collision keep the original's meaning (Omni
## topTI, bottomTI, leftTI, rightTI), each the value of that side of the
## tile that was hit, 0 for nothing:
##   - [member top_hit]: the top of a tile it stands on (1 flat, 2-7 a
##     slope, 8-15 deadly, [constant ON_PLATFORM] a platform);
##   - [member bottom_hit]: the bottom of a tile above it (17 a pole hole);
##   - [member left_hit]: the left side of a tile its right edge ran into;
##   - [member right_hit]: the right side of a tile its left edge ran into.

## How the object collides with the tiles.
##   - NONE: not at all (Keen on a pole, items, the dying Keen);
##   - NORMAL: floors, slopes and ceilings under the middle of its box,
##     walls at its sides (Omni CLIP_normal);
##   - SIMPLE: a fixed box that is never inside a wall (Omni CLIP_simple:
##     swimmers and flyers).
enum Clip { NONE, NORMAL, SIMPLE }
## When it runs (Omni OBJ_*): INACTIVE asleep, ACTIVE awake (falls asleep
## far from the view), ALWAYS always awake, ON_SCREEN_ONLY removed once it
## is far from the view.
enum Activity { INACTIVE, ACTIVE, ALWAYS, ON_SCREEN_ONLY }

## No sprite: the object is not drawn and has no hit box.
const NO_SPRITE := -1
## The [member top_hit] of an object standing on a platform (Omni 0x19).
const ON_PLATFORM := 0x19


## A second sprite drawn with the object (Omni
## RF_AddSpriteDrawUsing16BitOffset): the stars over a stunned creature.
class Overlay:
	extends RefCounted
	var sprite := NO_SPRITE
	## From the object's position, in units.
	var offset := Vector2i.ZERO
	var priority := 3


## The hit box in units and the tiles it covers (Omni clipRects).
class Box:
	extends RefCounted
	var left := 0
	var top := 0
	var right := 0
	var bottom := 0
	## The middle column, in units.
	var middle := 0
	var tile_left := 0
	var tile_top := 0
	var tile_right := 0
	var tile_bottom := 0
	var tile_middle := 0

	func copy() -> Box:
		var box := Box.new()
		box.left = left
		box.top = top
		box.right = right
		box.bottom = bottom
		box.middle = middle
		box.tile_left = tile_left
		box.tile_top = tile_top
		box.tile_right = tile_right
		box.tile_bottom = tile_bottom
		box.tile_middle = tile_middle
		return box

	## Whether this box overlaps [param other] (edges touching do not).
	func overlaps(other: Box) -> bool:
		return (
			right > other.left and left < other.right and top < other.bottom and bottom > other.top
		)


## The world it is in; held weakly, as the world holds its objects.
var world: GalaxyWorld:
	get:
		return _world.get_ref() as GalaxyWorld if _world != null else null
	set(new_world):
		_world = weakref(new_world) if new_world != null else null
## Where the object is, in units; the sprite and the box are relative to it.
var position := Vector2i.ZERO
## Units per tic.
var velocity := Vector2i.ZERO
## Its facing: -1 left / up, 1 right / down, 0 none (Omni xDirection,
## yDirection). An action's velocity is multiplied by it.
var direction := Vector2i(1, 1)
var action: GalaxyAction
## Tics spent in the action so far.
var action_timer := 0
## Frames in which its think is skipped (Omni timeUntillThink).
var think_delay := 0
var sprite := NO_SPRITE
## Its drawing priority, 0-3 ([GalaxyObjectLayer]).
var priority := 1
var clip := Clip.NORMAL
var activity := Activity.ACTIVE
## Moved or changed since its react last ran (Omni "visible").
var needs_react := true
var removed := false
var box := Box.new()
var top_hit := 0
var bottom_hit := 0
var left_hit := 0
var right_hit := 0
## How far it moved in this frame, in units (Omni deltaPosX/Y).
var moved := Vector2i.ZERO
## The move its action and think ask for in this frame, before the tile
## collision (Omni ck_nextX/Y).
var step := Vector2i.ZERO
## The player's object gets two extra floor and ceiling checks at the box's
## leading corner (Omni CK_PhysKeenClipDown/Up).
var clips_like_keen := false
## The box of a [constant Clip.SIMPLE] object, in units from its position.
var simple_box_size := Vector2i.ZERO
## The sprite is drawn this far from [member position] (the Berkeloid
## floats up and down; its box does not).
var draw_offset := Vector2i.ZERO
## Not drawn, though its sprite gives it a box (Omni: an object without a
## draw function, the dart gun).
var hidden := false
## Sprites drawn with this one ([Overlay]).
var overlays: Array[Overlay] = []
var _world: WeakRef


## Starts [param new_action] for an object placed in the world (Omni
## CK_SetAction): its sprite, then its box at the place it is.
func start(new_action: GalaxyAction) -> void:
	action = new_action
	if new_action.right_sprite != GalaxyAction.KEEP_SPRITE and direction.x > 0:
		sprite = _shown(new_action.right_sprite)
	elif new_action.left_sprite != GalaxyAction.KEEP_SPRITE:
		sprite = _shown(new_action.left_sprite)
	step = Vector2i.ZERO
	var clip_mode := clip
	clip = Clip.NONE
	world.clip.update_normal(self)
	clip = clip_mode
	if clip == Clip.SIMPLE:
		world.clip.update_simple_box(self)
	elif clip == Clip.NORMAL:
		world.clip.update_normal(self)
	_share_step()


## Switches to [param new_action] from a think or react (Omni
## CK_SetAction2): the timer starts again, the sprite changes, and the
## object is clipped again where it is (unless it stands on a platform).
func set_action(new_action: GalaxyAction) -> void:
	action = new_action
	action_timer = 0
	sprite = new_action.sprite_facing(direction.x, sprite)
	needs_react = true
	step = Vector2i.ZERO
	if top_hit != ON_PLATFORM:
		world.clip.update_normal(self)
	_share_step()


## The original keeps the step of the object whose action runs in one
## shared place, which starting an action resets: an object that starts
## one on another (a slug its slime, Keen his shot) loses its own step of
## this frame and goes on with what is left of this one's (seen in the
## original, D13: the slug does not step back when it leaves its slime).
func _share_step() -> void:
	var in_world := world
	if in_world == null:
		return
	var running := in_world.acting
	if running != null and running != self:
		running.step = step


## Puts the box where the sprite puts it at [member position] (Omni
## CK_ResetClipRects).
func reset_box() -> void:
	var info := world.sprite_info(sprite)
	if info == null:
		return
	box.left = position.x + info.box_left
	box.right = position.x + info.box_right
	box.top = position.y + info.box_top
	box.bottom = position.y + info.box_bottom
	box.middle = (box.right - box.left) / 2 + box.left
	box.tile_left = GalaxyUnits.to_tile(box.left)
	box.tile_right = GalaxyUnits.to_tile(box.right)
	box.tile_top = GalaxyUnits.to_tile(box.top)
	box.tile_bottom = GalaxyUnits.to_tile(box.bottom)
	box.tile_middle = GalaxyUnits.to_tile(box.middle)


## The player ([param player]) touches this object; [param holding] when
## he is on a pole, hanging or looking (Omni CK_KeenSpecialColFunc),
## otherwise as he walks, jumps or stands (CK_KeenColFunc). What pushes,
## carries or takes him somewhere overrides this; what kills him does that
## in its own contact function.
func touched_by_player(_player: GalaxyObject, _holding: bool) -> void:
	pass


## Contact: it kills the player (Omni CK_LethalCol).
func _contact_lethal(other: GalaxyObject) -> void:
	if world.is_player(other) and other.has_method(&"kill"):
		other.call(&"kill")


## Think: gravity and its own horizontal velocity (Omni CK_Fall).
func _think_fall() -> void:
	GalaxyPhysics.gravity_high(self)
	step.x = velocity.x * world.tics


static func _shown(action_sprite: int) -> int:
	return NO_SPRITE if action_sprite == GalaxyAction.NO_SPRITE else action_sprite
