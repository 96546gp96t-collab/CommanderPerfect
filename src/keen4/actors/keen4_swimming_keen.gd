class_name Keen4SwimmingKeen
extends GalaxyKeenBody
## Keen in his wetsuit in Keen 4's Well of Wishes (info 42, level 17; Omni
## `ck4_misc.c`, CK4_SpawnScubaKeen, CK4_KeenSwim, CK4_KeenSwimCol,
## CK4_KeenSwimDraw, facts and numbers only; docs/keen4/research.md §5):
##   - he starts at the info tile's corner facing right, clipped with a
##     simple box (640 × 384 units), drawn with priority 1;
##   - every tic his position changes by his speed; on every 8th tic the
##     speed relaxes towards rest: sideways by 3 above 12 (either way),
##     else by 1, towards 0; downwards by 3 above 12 and by 1 above 4,
##     upwards by 1 from below 4 and by 3 below −12; so with nothing held
##     he sinks slowly (4 and 5 by turns: seen in the original, D6, 20
##     pixels a second); the stick adds 2 on those tics, the way it is
##     held; with nothing held sideways a speed that turns round becomes
##     0, and with nothing held up or down a rise that turns into sinking
##     faster than 4 becomes 0;
##   - jump kicks: 18 in each direction held, and the next of his two
##     pictures (50 tics each otherwise);
##   - a bubble every 60 tics ([Keen4Bubble]);
##   - walls stop him sideways, floors and ceilings up and down;
##   - no stunner, no poles; touching an item takes it, touching the
##     council member rescues him ([Keen4Council]);
##   - dying, he flies off in his suit; the Dopefish eats him whole
##     ([method be_eaten]): he is held in its mouth and the level is lost
##     180 tics after he is swallowed.

## (Omni CK4_ACT_KeenSwim0-1, KeenSwimDie0-1, KeenEaten0-1.)
const ROWS: PackedStringArray = [
	"swim_1 SWIM_L_1 SWIM_R_1 step+ -- 50 0 0 swim swim swim swim_2",
	"swim_2 SWIM_L_2 SWIM_R_2 step+ -- 50 0 0 swim swim swim swim_1",
	"die_1 SUIT_DIE_1 SUIT_DIE_1 think -- 0 0 0 dying - - die_1",
	"die_2 SUIT_DIE_2 SUIT_DIE_2 think -- 0 0 0 dying - - die_2",
	"eaten_1 SUIT_DIE_1 SUIT_DIE_1 think -- 0 0 0 - - - eaten_2",
	"eaten_2 x x step -- 180 0 0 eaten - - eaten_2",
]
const BOX := Vector2i(0x280, 0x180)
const PRIORITY := 1
## A kick (Omni).
const KICK := 18
## Every this many tics the speed relaxes (Omni: tic & 7 == 0).
const RELAX_MASK := 7
## The relaxing steps (Omni).
const FAST := 12
const SINK_REST := 4
const SMALL_STEP := 1
const BIG_STEP := 3
const STICK_PUSH := 2
## A bubble when more tics than this went by since the last (Omni).
const BUBBLE_TICS := 60

## Tics since his last bubble (Omni user4).
var bubble_tics := 0
## Caught by the Dopefish: nothing else touches him (Omni CT_Friendly).
var eaten := false


## The swimming Keen of [param world] at [param cell] (info 42).
static func spawn(
	world: GalaxyWorld, cell: Vector2i, episode_sprites: Dictionary[StringName, int]
) -> Keen4SwimmingKeen:
	var keen := Keen4SwimmingKeen.new()
	keen.position = Vector2i(GalaxyUnits.from_tile(cell.x), GalaxyUnits.from_tile(cell.y))
	keen.direction = Vector2i(1, 1)
	world.add(keen)
	keen.use_sprites(episode_sprites)
	keen.clip = Clip.SIMPLE
	keen.simple_box_size = BOX
	keen.priority = PRIORITY
	keen.start(keen.actions[&"swim_1"])
	return keen


## His actions are his own under water.
func use_sprites(episode_sprites: Dictionary[StringName, int]) -> void:
	super(episode_sprites)
	actions = GalaxyAction.table_from(ROWS, episode_sprites)


## Kills him, unless something keeps him safe or the Dopefish has him.
func kill() -> void:
	if eaten:
		return
	super()


## The Dopefish catches him; false in god mode (Omni CK4_DopefishCol).
func be_eaten() -> bool:
	if god_mode or eaten or is_dying():
		return false
	eaten = true
	clip = Clip.NONE
	_become(&"eaten_1")
	return true


## The Dopefish swallows him: he is gone, the level is lost later.
func be_swallowed() -> void:
	_become(&"eaten_2")


## Think: kicks, the stick, and the slow relaxing of his speed (Omni
## CK4_KeenSwim).
func _think_swim() -> void:
	var was_left := velocity.x < 0
	var was_up := velocity.y < SINK_REST
	bubble_tics += world.tics
	if bubble_tics > BUBBLE_TICS:
		bubble_tics = 0
		Keen4Bubble.breathe(world, self, sprites)
	if _jump_pressed():
		_use_jump()
		if input.direction != 0:
			velocity.x = input.direction * KICK
		if input.vertical != 0:
			velocity.y = input.vertical * KICK
		if action.next != null:
			action = action.next
	if input.direction != 0:
		direction.x = input.direction
	for tic in range(world.tic - world.tics, world.tic):
		if tic & RELAX_MASK == 0:
			_relax(was_left, was_up)
		step += velocity


## One relaxing step of his speed, with the stick.
func _relax(was_left: bool, was_up: bool) -> void:
	velocity.x += _towards_rest(velocity.x, 0) + STICK_PUSH * input.direction
	if input.direction == 0 and (velocity.x < 0) != was_left:
		velocity.x = 0
	velocity.y += _towards_rest(velocity.y, SINK_REST) + STICK_PUSH * input.vertical
	if input.vertical == 0 and velocity.y > SINK_REST and was_up:
		velocity.y = 0


## How a speed of [param speed] relaxes towards [param rest] (Omni).
static func _towards_rest(speed: int, rest: int) -> int:
	if speed > FAST:
		return -BIG_STEP
	if speed > rest:
		return -SMALL_STEP
	if speed > -FAST:
		return SMALL_STEP
	return BIG_STEP


## Contact: items are taken, the council member is rescued (Omni
## CK4_KeenSwimCol).
func _contact_swim(other: GalaxyObject) -> void:
	var item := other as GalaxyItem
	if item != null:
		if not item.taken:
			_collect(item.collect(sprites))
	elif other is Keen4Council:
		(other as Keen4Council).rescue()


## React: walls and floors stop him (Omni CK4_KeenSwimDraw).
func _react_swim() -> void:
	if right_hit != 0 or left_hit != 0:
		velocity.x = 0
	if (top_hit != 0 and velocity.y > 0) or (bottom_hit != 0 and velocity.y < 0):
		velocity.y = 0


## Think at the end of being swallowed: the level is lost (Omni
## CK4_KillKeenUnderwater).
func _think_eaten() -> void:
	world.state = GalaxyWorld.LevelState.DIED


## No gem holders under water.
func _reach_gem_holder(_x: int, _y: int, _colour: int) -> void:
	pass
