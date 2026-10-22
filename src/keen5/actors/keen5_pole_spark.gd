class_name Keen5PoleSpark
extends Keen5Shot
## The spark a Shikadi sends along a pole (Omni `ck5_obj3.c` CK5_ShikadiPole,
## CK5_PoleZap; facts and numbers only): unclipped, it runs along the pole
## towards Keen, 48 units every frame (not every tic), and is gone where the
## pole ends (the tile at its middle column and top row is no pole). It
## kills Keen and absorbs a stunner shot; it counts as an enemy shot.

## (Omni CK5_ACT_PoleZap*: both pictures are the first spark, as in the
## original's table.)
const ROWS: PackedStringArray = [
	"run_1 SHIKADIPOLESPARK1 SHIKADIPOLESPARK1 step+ -- 0 0 0 run pole_spark - run_2",
	"run_2 SHIKADIPOLESPARK1 SHIKADIPOLESPARK1 step+ -- 0 0 0 run pole_spark - run_1",
]
## Units a frame (Omni CK5_ShikadiPoleZapSpeed).
const SPEED := 48
const POLE := GalaxyTileKinds.POLE


## A spark at [param at] (units) running up ([param way] −1) or down (1).
static func send(
	world: GalaxyWorld, at: Vector2i, way: int, sprites: Dictionary[StringName, int]
) -> Keen5PoleSpark:
	var spark := Keen5PoleSpark.new()
	spark.activity = Activity.ON_SCREEN_ONLY
	spark.priority = PRIORITY
	spark.clip = Clip.NONE
	spark.direction = Vector2i(0, way)
	spark.enter(world, at, ROWS, sprites, &"run_1")
	return spark


## Think: along the pole, gone where it ends (Omni CK5_PoleZap).
func _think_run() -> void:
	if step.y != 0:
		return
	step.y = direction.y * SPEED
	var tile := world.fore_tile(box.tile_middle, box.tile_top)
	if world.tile_info.fore(GalaxyTileInfo.Fore.MISC, tile) != POLE:
		action = null


## Contact: a stunner shot stops, Keen dies (Omni CK_DeadlyCol).
func _contact_pole_spark(other: GalaxyObject) -> void:
	var shot := live_shot(other)
	if shot != null:
		shot.hit()
	elif is_player(other):
		kill_player(other)
