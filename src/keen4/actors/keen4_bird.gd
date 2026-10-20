class_name Keen4Bird
extends GalaxyCreature
## The blue bird of Keen 4 (Omni `ck4_obj1.c`, facts and numbers only;
## docs/keen4/research.md §7):
##   - hatched from an egg ([Keen4Egg]) it stands 120 tics, then walks to
##     Keen, 128 units every 7 tics, turning at walls;
##   - when Keen stands on the ground 3 tiles (or more) higher, and the bird
##     fits in the air, it flies: speeding up 1 on odd tics towards Keen, at
##     most 16 sideways and 16 up or down, with a plain box
##     (1024 × 512 units); it also flies off a ledge;
##   - flying, it lands on a flat floor when Keen's feet are less than half
##     a tile below its own;
##   - touching it kills Keen (not while it stands after hatching or is
##     stunned); a shot stuns it for 240 tics, then it blinks for 80 and
##     walks again.

## (Omni CK4_ACT_Bird*.)
const ROWS: PackedStringArray = [
	"hatched BIRD_WALK_L_1 BIRD_WALK_R_1 step -s 120 128 0 - hatched walk walk_2",
	"walk_1 BIRD_WALK_L_1 BIRD_WALK_R_1 step -s 7 128 0 - bird walk walk_2",
	"walk_2 BIRD_WALK_L_2 BIRD_WALK_R_2 step -s 7 128 0 - bird walk walk_3",
	"walk_3 BIRD_WALK_L_3 BIRD_WALK_R_3 step -s 7 128 0 - bird walk walk_4",
	"walk_4 BIRD_WALK_L_4 BIRD_WALK_R_4 step -s 7 128 0 walk bird walk walk_1",
	"fly_1 BIRD_FLY_1 BIRD_FLY_1 slide+ -- 8 0 0 fly bird fly fly_2",
	"fly_2 BIRD_FLY_2 BIRD_FLY_2 slide+ -- 8 0 0 fly bird fly fly_3",
	"fly_3 BIRD_FLY_3 BIRD_FLY_3 slide+ -- 8 0 0 fly bird fly fly_4",
	"fly_4 BIRD_FLY_4 BIRD_FLY_4 slide+ -- 8 0 0 fly bird fly fly_1",
	"stunned BIRD_STUN BIRD_STUN step+ -- 240 0 0 fall hatched - recover_1",
	"recover_1 BIRD_WALK_L_1 BIRD_WALK_R_1 step -s 20 0 0 - hatched - recover_2",
	"recover_2 BIRD_STUN BIRD_STUN step -s 20 0 0 - hatched - recover_3",
	"recover_3 BIRD_WALK_L_1 BIRD_WALK_R_1 step -s 20 0 0 - hatched - recover_4",
	"recover_4 BIRD_STUN BIRD_STUN step -s 20 0 0 recover hatched - walk_1",
]
const RISE := 0xF1
const PRIORITY := 2
## Flying: its plain box, how fast it speeds up and how fast at most (Omni).
const FLYING_BOX := Vector2i(0x400, 0x200)
const FLY_ACCEL := 1
const FLY_SPEED := 16
const TAKE_OFF_SPEED := -8
## It flies when Keen's feet are this much higher (Omni).
const FLY_HEIGHT := 0x300
## It lands when Keen's feet are less than this below its own (Omni).
const LAND_DEPTH := 0x80
const FLAT := 1

## Flying: it hit a floor or ceiling, and keeps its facing until free
## (Omni user1).
var bumped := false


## A bird at [param cell] (info 77, 78), facing Keen.
static func spawn(
	world: GalaxyWorld, cell: Vector2i, sprites: Dictionary[StringName, int]
) -> Keen4Bird:
	var at := Vector2i(GalaxyUnits.from_tile(cell.x), GalaxyUnits.from_tile(cell.y) - RISE)
	return _new_bird(world, at, sprites, PRIORITY)


## The bird hatching at [param at] (units) from an egg.
static func hatch(
	world: GalaxyWorld, at: Vector2i, sprites: Dictionary[StringName, int]
) -> Keen4Bird:
	return _new_bird(world, at, sprites, 0)


static func _new_bird(
	world: GalaxyWorld, at: Vector2i, sprites: Dictionary[StringName, int], shown_at: int
) -> Keen4Bird:
	var bird := Keen4Bird.new()
	bird.priority = shown_at
	bird.simple_box_size = FLYING_BOX
	bird.direction = Vector2i(1 if at.x < world.nearest_player(at).position.x else -1, 1)
	bird.enter(world, at, ROWS, sprites, &"hatched")
	return bird


## Think while walking: towards Keen; it flies when he stands well above
## it and it fits in the air (Omni CK4_BirdWalk).
func _think_walk() -> void:
	direction.x = side_of_player()
	var keen := nearest_player()
	if box.bottom < keen.box.bottom + FLY_HEIGHT or keen.top_hit == 0:
		return
	if _fits(actions[&"fly_1"]):
		_continue_as(&"fly_1")
		clip = Clip.SIMPLE
		velocity.y = TAKE_OFF_SPEED
		bumped = false


## Think while flying: towards Keen (Omni CK4_BirdFly).
func _think_fly() -> void:
	if not bumped:
		direction.x = side_of_player()
	GalaxyPhysics.accelerate_x_only(self, direction.x * FLY_ACCEL, FLY_SPEED)
	var down := position.y < nearest_player().position.y
	GalaxyPhysics.accelerate_y(self, FLY_ACCEL if down else -FLY_ACCEL, FLY_SPEED)


func _think_recover() -> void:
	stunned = false


## Contact while walking or flying: Keen dies; a shot stuns it (Omni
## CK4_BirdCol).
func _contact_bird(other: GalaxyObject) -> void:
	if is_player(other):
		kill_player(other)
	elif live_shot(other) != null:
		clip = Clip.NORMAL
		_contact_hatched(other)


## Contact while it cannot hurt: only a shot (Omni CK4_BirdHatchedCol).
func _contact_hatched(other: GalaxyObject) -> void:
	var shot := live_shot(other)
	if shot != null:
		velocity.x = 0
		stun(shot, &"stunned")


## React while walking: it turns at walls; without a floor it flies (Omni
## CK4_BirdDraw).
func _react_walk() -> void:
	if _wall_ahead():
		position.x -= moved.x
		direction.x = -direction.x
		think_delay = world.random() / TURN_WAIT_DIVISOR
		set_action(action)
	if top_hit == 0:
		velocity.y = -FLY_SPEED
		clip = Clip.SIMPLE
		_become(&"fly_1")


## React while flying: walls turn it; over a flat floor near Keen's height
## it tries to land (Omni CK4_BirdFlyingDraw).
func _react_fly() -> void:
	if bottom_hit != 0 or top_hit != 0:
		bumped = true
	if (right_hit != 0 and velocity.x < 0) or (left_hit != 0 and velocity.x > 0):
		velocity.x = 0
		direction.x = -direction.x
	if top_hit == FLAT and nearest_player().box.bottom - box.bottom < LAND_DEPTH:
		_try_landing()
		return
	if bottom_hit == 0 and top_hit == 0:
		bumped = false


func _try_landing() -> void:
	var flying := action
	clip = Clip.NORMAL
	_become(&"walk_1")
	step = Vector2i(0, LAND_DEPTH)
	world.clip.update_simple(self)
	if top_hit == 0:
		clip = Clip.SIMPLE
		set_action(flying)


## Whether its box would be in no solid tile with the sprite of
## [param next] (Omni CK_PreviewClipRects); its sprite stays that one when
## it fits.
func _fits(next: GalaxyAction) -> bool:
	var old_sprite := sprite
	var old_box := box.copy()
	sprite = next.sprite_facing(direction.x, sprite)
	reset_box()
	if world.clip.is_stuck(self):
		sprite = old_sprite
		box = old_box
		return false
	return true
