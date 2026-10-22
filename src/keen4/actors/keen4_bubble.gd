class_name Keen4Bubble
extends GalaxyCreature
## A bubble in Keen 4's Well of Wishes (Omni `ck4_misc.c`,
## CK4_SpawnKeenBubble, and `ck4_obj3.c`, CK4_DopefishBurp, CK4_Bubbles;
## facts and numbers only): the swimming Keen breathes one out every 60
## tics, the Dopefish burps a big one. It rises by its speed, wobbles
## sideways (its sideways speed turns with a chance of 16 × tics in 256 a
## frame), is drawn in front of everything, is not clipped, and is gone at
## the top of the map (y below 3 tiles) or off the screen.

## (Omni CK4_ACT_Bubble0-3, CK4_ACT_DopeBubble0.)
const ROWS: PackedStringArray = [
	"small_0 BUBBLE_T_1 BUBBLE_T_1 think -- 0 0 0 rise - - -",
	"small_1 BUBBLE_T_2 BUBBLE_T_2 think -- 0 0 0 rise - - -",
	"small_2 BUBBLE_T_3 BUBBLE_T_3 think -- 0 0 0 rise - - -",
	"small_3 BUBBLE_T_4 BUBBLE_T_4 think -- 0 0 0 rise - - -",
	"big BUBBLE_1 BUBBLE_1 think -- 0 0 0 rise - - -",
]
const PRIORITY := 3
## The wobble's chance per tic, in 256 (Omni).
const WOBBLE_CHANCE := 16
## It is gone above this (Omni).
const TOP := 0x300
## Keen's bubbles: their speed, where they leave him facing right, and the
## four kinds a random number picks (Omni).
const KEEN_SPEED := Vector2i(4, -24)
const KEEN_RIGHT := 0x180
const KINDS := 4
const RANDOM_RANGE := 256
## The Dopefish's burp: its speed, and where it leaves the fish (Omni).
const BURP_SPEED := Vector2i(4, -20)
const BURP_AT := Vector2i(0x380, 0x200)


## A bubble of Keen ([param keen]): at his head, one of four sizes.
static func breathe(
	world: GalaxyWorld, keen: GalaxyObject, sprites: Dictionary[StringName, int]
) -> Keen4Bubble:
	var at := keen.position
	if keen.direction.x != -1:
		at.x += KEEN_RIGHT
	var kind := world.random() * KINDS / RANDOM_RANGE
	world.play_sound(&"keen_bubble")
	return _blow(world, at, KEEN_SPEED, StringName("small_%d" % kind), sprites)


## The Dopefish ([param fish]) burps a big bubble.
static func burp(
	world: GalaxyWorld, fish: GalaxyObject, sprites: Dictionary[StringName, int]
) -> Keen4Bubble:
	return _blow(world, fish.position + BURP_AT, BURP_SPEED, &"big", sprites)


static func _blow(
	world: GalaxyWorld,
	at: Vector2i,
	speed: Vector2i,
	first: StringName,
	sprites: Dictionary[StringName, int]
) -> Keen4Bubble:
	var bubble := Keen4Bubble.new()
	bubble.priority = PRIORITY
	bubble.activity = Activity.ON_SCREEN_ONLY
	bubble.clip = Clip.NONE
	bubble.velocity = speed
	bubble.enter(world, at, ROWS, sprites, first)
	return bubble


## Think: it rises, wobbles, and is gone at the top (Omni CK4_Bubbles).
func _think_rise() -> void:
	_think_glide()
	if world.random() < world.tics * WOBBLE_CHANCE:
		velocity.x = -velocity.x
	if position.y < TOP:
		world.remove(self)
