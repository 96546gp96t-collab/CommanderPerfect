class_name Keen5Sphereful
extends Keen5Creature
## The Sphereful of Keen 5 (Omni `ck5_obj3.c`, facts and numbers only;
## docs/keen5/research.md §7): its 2 × 2 tile box is kept out of the walls
## ([GalaxyClip.update_simple_box]). Every 16th tic its speed changes by
## one: down (to at most 8) and towards Keen sideways (at most 8 either
## way). Walls send it back sideways and ceilings down (sound
## "sphereful_ceiling"); a floor bounces it up a little faster when Keen is
## above it, slower when not, at 4 to 12 units a tic (sound
## "spindred_fly_up"). Four pictures of 6 tics. Four diamonds circle it,
## drawn only (no box): two in front of it and two behind, changing every 8
## tics along a table of 16 steps (Omni CK5_SpherefulTileCol). Touching it
## kills Keen; a shot is absorbed.

## (Omni CK5_ACT_Sphereful*.)
const ROWS: PackedStringArray = [
	"float_1 SPHEREFUL1 SPHEREFUL1 step+ -- 6 0 0 drift deadly bounce float_2",
	"float_2 SPHEREFUL2 SPHEREFUL2 step+ -- 6 0 0 drift deadly bounce float_3",
	"float_3 SPHEREFUL3 SPHEREFUL3 step+ -- 6 0 0 drift deadly bounce float_4",
	"float_4 SPHEREFUL4 SPHEREFUL4 step+ -- 6 0 0 drift deadly bounce float_1",
]
const RISE := Vector2i(0, -0x100)
const PRIORITY := 1
const BOX := Vector2i(512, 512)
## Its speed changes on tics that are a multiple of 16, up to 8 (Omni).
const DRIFT_MASK := 0xF
const MAX_DRIFT := 8
## Bouncing off a floor: its upward speed lies between these (Omni).
const SLOWEST_BOUNCE := -4
const FASTEST_BOUNCE := -12
## The diamonds: a 16-step table of offsets (x and y), the step changes
## every 8 tics; the picture changes every 4 steps; the half of the circle
## in front, its priority and the one behind (Omni).
const DIAMOND_PATH: PackedInt32Array = [
	0x180,
	0x171,
	0x148,
	0x109,
	0x0C0,
	0x077,
	0x03A,
	0x00F,
	0x000,
	0x00F,
	0x03A,
	0x077,
	0x0C0,
	0x109,
	0x148,
	0x171,
]
const DIAMOND_SHIFT := 3
const DIAMOND_STEPS := 16
const STEPS_PER_PICTURE := 4
const DIAMOND_WIDTH := 0x180
const HALF_CIRCLE := 8
const FRONT_PRIORITY := 2
const BACK_PRIORITY := 0
const DIAMONDS := 4


## A Sphereful at [param cell] (info 105, 106, 107).
static func spawn(
	world: GalaxyWorld, cell: Vector2i, sprites: Dictionary[StringName, int]
) -> Keen5Sphereful:
	var sphereful := Keen5Sphereful.new()
	sphereful.priority = PRIORITY
	sphereful.clip = Clip.SIMPLE
	sphereful.simple_box_size = BOX
	sphereful.place(world, cell, RISE, ROWS, sprites, &"float_1")
	return sphereful


## Think: it drifts down and towards Keen (Omni CK5_SpherefulBounce).
func _think_drift() -> void:
	needs_react = true
	if step != Vector2i.ZERO:
		return
	var keen_x := _keen().position.x
	for tic in range(world.tic - world.tics, world.tic):
		if tic & DRIFT_MASK == 0:
			if velocity.y < MAX_DRIFT:
				velocity.y += 1
			if keen_x > position.x and velocity.x < MAX_DRIFT:
				velocity.x += 1
			if keen_x < position.x and velocity.x > -MAX_DRIFT:
				velocity.x -= 1
		step += velocity


## React: walls, ceilings and floors bounce it; the diamonds are drawn
## (Omni CK5_SpherefulTileCol).
func _react_bounce() -> void:
	if left_hit != 0 or right_hit != 0:
		velocity.x = -velocity.x
		world.play_sound(&"sphereful_ceiling")
	if bottom_hit != 0:
		velocity.y = -velocity.y
		world.play_sound(&"sphereful_ceiling")
	if top_hit != 0:
		velocity.y = -velocity.y
		velocity.y += -1 if _keen().position.y < position.y else 1
		velocity.y = clampi(velocity.y, FASTEST_BOUNCE, SLOWEST_BOUNCE)
		world.play_sound(&"spindred_fly_up")
	_place_diamonds()


## The four diamonds: two at one point of the circle, mirrored left and
## right, two half a circle further.
func _place_diamonds() -> void:
	while overlays.size() < DIAMONDS:
		overlays.append(Overlay.new())
	var turn := (world.tic >> DIAMOND_SHIFT) & (DIAMOND_STEPS - 1)
	var picture: int = sprites.get(&"SPHEREGUARD1", NO_SPRITE) + turn / STEPS_PER_PICTURE
	for half in 2:
		var at := (turn + half * HALF_CIRCLE) & (DIAMOND_STEPS - 1)
		var along := DIAMOND_PATH[at]
		var layer := FRONT_PRIORITY if at >= HALF_CIRCLE else BACK_PRIORITY
		_diamond(half * 2, picture, Vector2i(along, along), layer)
		_diamond(half * 2 + 1, picture, Vector2i(DIAMOND_WIDTH - along, along), layer)


func _diamond(index: int, picture: int, offset: Vector2i, layer: int) -> void:
	var diamond := overlays[index]
	diamond.sprite = picture
	diamond.offset = offset
	diamond.priority = layer
