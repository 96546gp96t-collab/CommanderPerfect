class_name GalaxyPhysics
extends RefCounted
## Gravity, acceleration and damping as the original does them: tic by tic
## over the tics of the logic frame, changing the velocity only on **odd
## absolute tics**, and adding the velocity of every tic to the object's
## step (Omni `ck_phys.c`; docs/keen4/research.md §4). The frame's tics come
## from the object's [GalaxyWorld] ([member GalaxyWorld.tics] ending at
## [member GalaxyWorld.tic]).

## Gravity high: +4 every odd tic (Keen, most things), mid: +3 (Keen on
## Easy, mushrooms, the dying Keen) (Omni).
const HIGH := 4
const MID := 3
## Nothing falls faster than this, in units per tic (Omni).
const MAX_FALL := 70


static func gravity_high(object: GalaxyObject) -> void:
	_gravity(object, HIGH)


static func gravity_mid(object: GalaxyObject) -> void:
	_gravity(object, MID)


## The pogo's "low gravity" while jump is held: the speed does not change
## at all. Omnispeak's own comment doubts this (its condition never holds;
## research.md §12), but the original does it too: a held bounce rises
## 6 pixels in every one of its 12 frames at −48 (seen in the original,
## D4).
static func gravity_low(object: GalaxyObject) -> void:
	for _tic in _tics(object):
		object.step.y += object.velocity.y


## Speeds up sideways by [param accel] on odd tics up to ±[param limit];
## the object turns when its speed changes sign (Omni CK_PhysAccelHorz).
static func accelerate_x(object: GalaxyObject, accel: int, limit: int) -> void:
	var negative := object.velocity.x < 0
	for tic in _tics(object):
		if tic & 1:
			object.velocity.x += accel
			if (object.velocity.x < 0) != negative:
				negative = object.velocity.x < 0
				object.direction.x = -1 if negative else 1
			object.velocity.x = clampi(object.velocity.x, -limit, limit)
		object.step.x += object.velocity.x


## As [method accelerate_x] without turning (Omni CK_PhysAccelHorz2).
static func accelerate_x_only(object: GalaxyObject, accel: int, limit: int) -> void:
	for tic in _tics(object):
		if tic & 1:
			object.velocity.x = clampi(object.velocity.x + accel, -limit, limit)
		object.step.x += object.velocity.x


## Speeds up vertically (Omni CK_PhysAccelVert1).
static func accelerate_y(object: GalaxyObject, accel: int, limit: int) -> void:
	for tic in _tics(object):
		if tic & 1:
			object.velocity.y = clampi(object.velocity.y + accel, -limit, limit)
		object.step.y += object.velocity.y


## Slows down sideways by 1 on odd tics, to 0 (Omni CK_PhysDampHorz).
static func damp_x(object: GalaxyObject) -> void:
	var negative := object.velocity.x < 0
	var change := -signi(object.velocity.x)
	for tic in _tics(object):
		if tic & 1:
			object.velocity.x += change
			if (object.velocity.x < 0) != negative:
				object.velocity.x = 0
		object.step.x += object.velocity.x


## Gravity of [param add] per odd tic. An upward speed that would end
## between −add and 0 becomes 0 and the rest of the frame adds nothing
## (Omni).
static func _gravity(object: GalaxyObject, add: int) -> void:
	for tic in _tics(object):
		if tic & 1:
			if object.velocity.y < 0 and object.velocity.y >= -add:
				object.step.y += object.velocity.y
				object.velocity.y = 0
				return
			object.velocity.y = mini(object.velocity.y + add, MAX_FALL)
		object.step.y += object.velocity.y


## The absolute tics of the frame being run.
static func _tics(object: GalaxyObject) -> Array:
	var world := object.world
	return range(world.tic - world.tics, world.tic)
