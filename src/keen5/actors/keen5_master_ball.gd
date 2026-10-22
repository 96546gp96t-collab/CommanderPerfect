class_name Keen5MasterBall
extends Keen5Shot
## The ball a Shikadi Master throws, and the sparks it turns into (Omni
## `ck5_obj3.c`, facts and numbers only; docs/keen5/research.md §7): the
## ball flies off with gravity mid, bounces off walls and stops at
## ceilings; on a floor it turns into two sparks running along it (48
## units a tic each way, gravity high, sound "master_shot"), which are gone
## at the first wall. The Master's teleport also leaves two sparks. Ball and
## sparks kill Keen and are gone; a stunner shot ends them too. Only the
## ball, and the spark it became, count as enemy shots (Omni
## CT5_EnemyShot); the other sparks do not.

## (Omni CK5_ACT_MasterBall*, CK5_ACT_MasterSparks*.)
const ROWS: PackedStringArray = [
	"ball_1 MASTERSHOT4 MASTERSHOT1 step+ -- 8 0 0 fall_mid ball ball ball_2",
	"ball_2 MASTERSHOT3 MASTERSHOT2 step+ -- 8 0 0 fall_mid ball ball ball_3",
	"ball_3 MASTERSHOT2 MASTERSHOT3 step+ -- 8 0 0 fall_mid ball ball ball_4",
	"ball_4 MASTERSHOT1 MASTERSHOT4 step+ -- 8 0 0 fall_mid ball ball ball_1",
	"sparks_1 MASTERFLOORSPARK1 MASTERFLOORSPARK1 step+ -- 6 0 0 fall ball sparks sparks_2",
	"sparks_2 MASTERFLOORSPARK2 MASTERFLOORSPARK2 step+ -- 6 0 0 fall ball sparks sparks_3",
	"sparks_3 MASTERFLOORSPARK3 MASTERFLOORSPARK3 step+ -- 6 0 0 fall ball sparks sparks_4",
	"sparks_4 MASTERFLOORSPARK4 MASTERFLOORSPARK4 step+ -- 6 0 0 fall ball sparks sparks_1",
]
## The sparks' speed along the floor (Omni).
const SPARK_SPEED := 48


## A ball at [param at] (units) thrown with [param speed]; null when it
## would start in a wall (Omni CK5_MasterShoot, CK5_SpawnEnemyShot).
static func throw_ball(
	world: GalaxyWorld, at: Vector2i, speed: Vector2i, sprites: Dictionary[StringName, int]
) -> Keen5MasterBall:
	var ball := Keen5MasterBall.new()
	ball.activity = Activity.ON_SCREEN_ONLY
	ball.priority = PRIORITY
	ball.direction = Vector2i.ZERO
	ball.velocity = speed
	ball.enter(world, at, ROWS, sprites, &"ball_1")
	if world.clip.is_stuck(ball):
		world.remove(ball)
		return null
	return ball


## A spark at [param at] (units) running [param way] (−1 left, 1 right):
## no enemy shot, awake as any creature.
static func spark(
	world: GalaxyWorld, at: Vector2i, way: int, sprites: Dictionary[StringName, int]
) -> Keen5MasterBall:
	var spark_object := Keen5MasterBall.new()
	spark_object.is_enemy_shot = false
	spark_object.activity = Activity.ACTIVE
	spark_object.priority = PRIORITY
	spark_object.direction = Vector2i.ZERO
	spark_object.velocity = Vector2i(SPARK_SPEED * way, 0)
	spark_object.enter(world, at, ROWS, sprites, &"sparks_1")
	return spark_object


## Contact: a stunner shot ends it; Keen dies and it is gone (Omni
## CK5_MasterBallCol).
func _contact_ball(other: GalaxyObject) -> void:
	var shot := live_shot(other)
	if shot != null:
		shot.hit()
		world.remove(self)
	elif is_player(other):
		kill_player(other)
		world.remove(self)


## React of the ball: walls send it back, ceilings stop its rise, a floor
## turns it into sparks (Omni CK5_MasterBallTileCol).
func _react_ball() -> void:
	if right_hit != 0 or left_hit != 0:
		velocity.x = -velocity.x
	if bottom_hit != 0:
		velocity.y = 0
	if top_hit != 0:
		world.play_sound(&"master_shot")
		velocity.x = SPARK_SPEED
		_become(&"sparks_1")
		spark(world, position, -1, sprites)


## React of a spark: a wall ends it (Omni CK5_MasterSparksTileCol).
func _react_sparks() -> void:
	if right_hit != 0 or left_hit != 0:
		world.remove(self)
