class_name Keen3Machine
extends RefCounted
## Mortimer's Mangling Machine in level 16, as Chocolate Keen has it
## (`CVort3_think_mangling_*`; docs/keen3/research.md §6). The level's info
## layer places its parts:
##   12  a spark ([Keen3Spark]); one shot from Keen destroys it
##   13  the heart ([Keen3Heart])
##   16  an arm ([Keen3MachineArm]): tiles that move up and down
##   17, 18  the left and the right leg ([Keen3MachineLeg]), tiles too
## Each spark or the heart that is shot gives [constant POINTS] and a flash
## of the border around the picture ([signal Keen3LevelSession.border_flashed]).
## At the [constant SPARK_COUNT]th spark both arms stop where they are and a
## sweep clears the arms' columns ([constant SIDE_SWEEP_COLUMNS]); that also
## takes away tile 611 beside the heart, which stopped the shots to it. When
## the heart is shot both legs stop, every sprite but Keen is removed, a
## sweep clears the body, and [constant WON_TICKS] ticks later the level is
## done (the game is won). Every tile changes through
## [method LevelSession.set_tile], so the drawing (also xBRZ and HD) follows.
##
## [Keen3LevelSession] makes it ([method found_in]) when the level has any
## of these parts, steps it after every tick and hands it the shots that hit
## a spark or the heart ([method hit]).

const INFO_SPARK := 12
const INFO_HEART := 13
const INFO_ARM := 16
const INFO_LEFT_LEG := 17
const INFO_RIGHT_LEG := 18
## What a sweep, an arm or a leg leaves behind: the level's background.
const EMPTY_TILE := 169
## The shaft of an arm or a leg.
const SHAFT_TILE := 597
## The sixth spark stops the arms (Choco).
const SPARK_COUNT := 6
## Points for a spark and for the heart (Choco).
const POINTS := 1000
## The sweep after the sixth spark: these columns, rows 7-18, a row every
## 30 clock ticks (Choco).
const SIDE_SWEEP_COLUMNS: PackedInt32Array = [5, 6, 7, 17, 18, 19]
const SIDE_SWEEP_ROWS := Vector2i(7, 18)
const SIDE_SWEEP_TICKS := 12.4
## The sweep after the heart: columns 8-16, rows 3-18, a row every 20 clock
## ticks (Choco).
const BODY_SWEEP_COLUMNS := Vector2i(8, 16)
const BODY_SWEEP_ROWS := Vector2i(3, 18)
const BODY_SWEEP_TICKS := 8.2
## Waits are fractions of a tick (the original counts 145.65 clock ticks a
## second): sums of them that should be whole are taken as whole within
## this much.
const TIME_TOLERANCE := 0.001
## The level is done 440 clock ticks (3 s) after the heart was shot (Choco).
const WON_TICKS := 181

var arms: Array[Keen3MachineArm] = []
var legs: Array[Keen3MachineLeg] = []
var sweeps: Array[Keen3MachineSweep] = []
var sparks_destroyed := 0
var heart_destroyed := false
## Ticks until the level is done, counted from the heart's shot; -1 before.
var won_ticks_left := -1


## The machine of [param session]'s level: its sparks and heart are added
## to the session's actors. Null when the level has no part of a machine.
static func found_in(session: Keen3LevelSession) -> Keen3Machine:
	var machine := Keen3Machine.new()
	var found := false
	var level := session.level
	for y in level.height:
		for x in level.width:
			var cell := Vector2i(x, y)
			if machine._add_part(session, cell, level.info_at(cell)):
				found = true
	return machine if found else null


## Advances one tick: the arms, the legs, the sweeps, and the count to the
## end of the level.
func step(session: Keen3LevelSession) -> void:
	for arm in arms:
		arm.step(session)
	for leg in legs:
		leg.step(session)
	for sweep in sweeps:
		sweep.step(session)
	if won_ticks_left > 0:
		won_ticks_left -= 1
		if won_ticks_left == 0:
			session.outcome = LevelSession.Outcome.COMPLETED


## A shot from Keen hit [param target], a spark or the heart.
func hit(session: Keen3LevelSession, target: Actor) -> void:
	if target.removed:
		return
	target.removed = true
	_score(session)
	session.flash_border()
	if target is Keen3Heart:
		_destroy_heart(session)
	else:
		_destroy_spark()


## Whether every arm stands still.
func arms_stopped() -> bool:
	return arms.all(func(arm: Keen3MachineArm) -> bool: return arm.stopped)


func _add_part(session: Keen3LevelSession, cell: Vector2i, info: int) -> bool:
	var start := Vector2(cell * EgaGraphics.TILE_SIZE)
	match info:
		INFO_SPARK:
			session.add_actor(Keen3Spark.placed(start))
		INFO_HEART:
			session.add_actor(Keen3Heart.placed(start))
		INFO_ARM:
			arms.append(Keen3MachineArm.at(cell))
		INFO_LEFT_LEG, INFO_RIGHT_LEG:
			legs.append(Keen3MachineLeg.at(cell, info == INFO_LEFT_LEG))
		_:
			return false
	return true


func _score(session: Keen3LevelSession) -> void:
	var lives := session.inventory.lives
	session.inventory.add_points(POINTS)
	if session.inventory.lives > lives:
		session.play_sound(Sound.Id.EXTRA_LIFE)


func _destroy_spark() -> void:
	sparks_destroyed += 1
	if sparks_destroyed != SPARK_COUNT:
		return
	for arm in arms:
		arm.stopped = true
	sweeps.append(Keen3MachineSweep.across(SIDE_SWEEP_COLUMNS, SIDE_SWEEP_ROWS, SIDE_SWEEP_TICKS))


func _destroy_heart(session: Keen3LevelSession) -> void:
	if heart_destroyed:
		return
	heart_destroyed = true
	for leg in legs:
		leg.stopped = true
	# Every sprite goes, Keen's halo of the ankh excepted (it is part of him).
	for actor in session.actors:
		if not actor is Keen3AnkhShield:
			actor.removed = true
	var columns := PackedInt32Array(range(BODY_SWEEP_COLUMNS.x, BODY_SWEEP_COLUMNS.y + 1))
	sweeps.append(Keen3MachineSweep.across(columns, BODY_SWEEP_ROWS, BODY_SWEEP_TICKS))
	won_ticks_left = WON_TICKS
