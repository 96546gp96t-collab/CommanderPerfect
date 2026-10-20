class_name Keen4Slug
extends GalaxyCreature
## The poison slug of Keen 4 (Omni `ck4_obj1.c`, facts and numbers only;
## docs/keen4/research.md §7): it crawls 64 units every 8 tics, turning at
## walls, ledges and deadly floors; now and then (16 in 256 at every second
## step) it stops for 60 tics facing Keen and leaves a puddle of slime that
## kills for 300 tics and fades for 60. Touching it kills Keen; a shot
## stuns it for good (it hops −24 and slides 8 sideways, stars over it).

## (Omni CK4_ACT_Slug*.)
const ROWS: PackedStringArray = [
	"crawl_1 SLUG_L_1 SLUG_R_1 step -s 8 64 0 - slug crawl crawl_2",
	"crawl_2 SLUG_L_2 SLUG_R_2 step -s 8 64 0 crawl slug crawl crawl_1",
	"sliming SLUG_SQUIRT_L SLUG_SQUIRT_R step -s 60 64 0 slime slug crawl crawl_1",
	"stunned_1 SLUG_STUN_1 SLUG_STUN_1 think -- 0 0 0 fall - stunned -",
	"stunned_2 SLUG_STUN_2 SLUG_STUN_2 think -- 0 0 0 fall - stunned -",
	"slime_1 SLIME_1 SLIME_1 step -- 300 0 0 - lethal - slime_2",
	"slime_2 SLIME_2 SLIME_2 step -- 60 0 0 - - - -",
]
## It stands this far above the info tile's corner (Omni).
const RISE := 0x71
const PRIORITY := 2
const SLIME_PRIORITY := 0
## The chance to stop and slime, in 256 (Omni).
const SLIME_CHANCE := 16
## The slime lies this far above the bottom of its box (Omni).
const SLIME_RISE := 0x80
## Stunned it hops this high and slides this fast (Omni).
const STUN_SPEED := Vector2i(8, -24)
const STARS := Vector2i(0, -0x80)


## A slug at [param cell] (info 22, 43, 44).
static func spawn(
	world: GalaxyWorld, cell: Vector2i, sprites: Dictionary[StringName, int]
) -> Keen4Slug:
	var slug := Keen4Slug.new()
	slug.priority = PRIORITY
	slug.direction = Vector2i(random_side(world), 1)
	slug.stars_offset = STARS
	var at := GalaxyUnits.from_tile(cell.x)
	slug.enter(world, Vector2i(at, GalaxyUnits.from_tile(cell.y) - RISE), ROWS, sprites, &"crawl_1")
	return slug


## Think: sometimes it stops to slime, facing Keen (Omni CK4_SlugMove).
func _think_crawl() -> void:
	if world.random() < SLIME_CHANCE:
		direction.x = side_of_player()
		_continue_as(&"sliming")


## Think: the slime it leaves (Omni CK4_SlugSlime).
func _think_slime() -> void:
	var slime := GalaxyCreature.new()
	slime.activity = Activity.ON_SCREEN_ONLY
	slime.priority = SLIME_PRIORITY
	slime.direction = Vector2i.ZERO
	slime.enter(world, Vector2i(position.x, box.bottom - SLIME_RISE), ROWS, sprites, &"slime_1")


## Contact: it kills Keen; a shot stuns it (Omni CK4_SlugCol).
func _contact_slug(other: GalaxyObject) -> void:
	if is_player(other):
		kill_player()
		return
	var shot := live_shot(other)
	if shot == null:
		return
	stun(shot, &"stunned_1" if world.random() < HALF_RANDOM else &"stunned_2")
	velocity = Vector2i(direction.x * STUN_SPEED.x, STUN_SPEED.y)
