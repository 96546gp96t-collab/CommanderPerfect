class_name Keen5Shot
extends GalaxyEnemyShot
## A shot of a Keen 5 creature or laser turret (Omni `ck5_misc.c`
## CK5_SpawnEnemyShot, `ck_obj.c` CK_TurretShoot, `ck5_obj3.c`; facts and
## numbers only): Robo Red's, the Shockshund's bark, the turrets' laser
## and the Shikadi's pole spark. It lives only near the screen (gone
## beyond the sleep margin, Keen 5's 6 tiles), flies by its velocity (think
## [code]glide[/code]), kills Keen and then shows its hit pictures; at any
## side of a tile it plays its sound and shows them too. Only the
## Shockshund's bark is stopped by the stunner. A shot fired into a wall is
## never made (Omni CK_NotStuckInWall). The rows come from the creature
## that fires it: [code]hit_1[/code] is its first hit picture.

const HIT := &"hit_1"
## Shots are drawn behind everything (Omni: a new object's zLayer is 0).
const PRIORITY := 0

## The sound when it hits a wall.
var hit_sound := &"enemy_shot_hit"
## A stunner shot and this one stop each other (the bark).
var meets_stunner := false
## It is an enemy shot for the Shelley, which explodes when one touches it
## (Omni CT5_EnemyShot).
var is_enemy_shot := true


## A shot at [param at] (units) with [param speed] (units a tic), the
## actions of [param rows] starting with [param first]; null when it would
## start in a wall and [param check_walls] (Omni CK5_SpawnEnemyShot).
static func launch(
	world: GalaxyWorld,
	at: Vector2i,
	speed: Vector2i,
	rows: PackedStringArray,
	episode_sprites: Dictionary[StringName, int],
	first: StringName,
	check_walls := true
) -> Keen5Shot:
	var shot := Keen5Shot.new()
	shot.activity = Activity.ON_SCREEN_ONLY
	shot.priority = PRIORITY
	shot.direction = Vector2i.ZERO
	shot.velocity = speed
	shot.enter(world, at, rows, episode_sprites, first)
	if check_walls and world.clip.is_stuck(shot):
		world.remove(shot)
		return null
	return shot


## Contact: Keen dies and it shows where it hit; a stunner shot stops it
## when it [member meets_stunner] (Omni CK5_RoboShotCol, CK5_BarkShotCol,
## CK_TurretShotCol).
func _contact_shot(other: GalaxyObject) -> void:
	if is_player(other):
		kill_player(other)
		_become(HIT)
		return
	var stunner := live_shot(other) if meets_stunner else null
	if stunner != null:
		stunner.hit()
		_become(HIT)


## React: any side of a tile stops it (Omni CK5_RoboShotTileCol,
## CK5_BarkShotTileCol, CK_TurretShotDraw).
func _react_shot() -> void:
	if top_hit != 0 or right_hit != 0 or bottom_hit != 0 or left_hit != 0:
		world.play_sound(hit_sound)
		_become(HIT)
