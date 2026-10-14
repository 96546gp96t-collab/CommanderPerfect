class_name Enemy
extends Actor
## Base class for the enemies of Keen 1: walking, falling, getting shot and
## what happens when Keen touches them. Each kind fills in [method _think].
##
## When the level starts, every enemy drops onto the floor below it (the
## level places it at the top of its cell, which can be a few pixels up). It
## then waits until it comes into view and from then on stays active.
## Speeds are in pixels per tick, like in [KeenPhysics]. Values marked
## "estimate" have not been compared with the original yet; see
## docs/enemies.md.

## The same falling as Keen when he walks off a ledge.
const GRAVITY := 4 * KeenPhysics.SUBPIXEL
const MAX_FALL_SPEED := KeenPhysics.MAX_FALL_SPEED
## At the start of a level, an enemy drops at most this far onto a floor.
const MAX_SETTLE_DISTANCE := 4.0 * EgaGraphics.TILE_SIZE

## 1 when looking right, -1 when looking left.
var facing := -1
var velocity := Vector2.ZERO
var health := 1
var is_active := false
var on_ground := false
## Shot dead; only the corpse is left, which no longer does anything.
var is_dead := false
## The collision box inside the sprite, set by each kind.
var body_box := Rect2(0, 0, 16, 16)
## Whether gravity pulls this enemy; not for cannons and the chain.
var falls := true


func hitbox() -> Rect2:
	return Rect2(position + body_box.position, body_box.size)


func step(session: LevelSession) -> void:
	if not is_active:
		var area := session.active_area()
		# Cannons have no size, so their position counts too.
		if not area.intersects(hitbox()) and not area.has_point(position):
			return
		is_active = true
	_think(session)


## Drops the enemy onto the floor below it, if there is one close by.
func settle(session: LevelSession) -> void:
	if not falls:
		return
	var drop := session.collision.sweep_y(hitbox(), MAX_SETTLE_DISTANCE)
	if drop < MAX_SETTLE_DISTANCE:
		position.y += drop
		on_ground = true


## Whether Keen's shots stop at this enemy. Corpses let them through.
func stops_shots() -> bool:
	return not is_dead


## Whether touching Keen does something.
func touches_keen() -> bool:
	return not is_dead


## A shot from Keen hit this enemy. Most enemies lose health and die.
func hit_by_shot(_session: LevelSession) -> void:
	health -= 1
	if health <= 0:
		die()


## Kills the enemy, whatever its health (the falling stone of level 16).
func die() -> void:
	is_dead = true


## Keen touches this enemy. Most enemies kill him.
func touch_keen(session: LevelSession) -> void:
	session.keen.kill()


## What the enemy does in one tick once it is active.
func _think(_session: LevelSession) -> void:
	pass


## Falls with gravity; lands on floors and bumps against ceilings.
func _fall(session: LevelSession) -> void:
	velocity.y = minf(velocity.y + GRAVITY, MAX_FALL_SPEED)
	var moved := session.collision.sweep_y(hitbox(), velocity.y)
	position.y += moved
	on_ground = velocity.y > 0.0 and moved < velocity.y
	if moved != velocity.y:
		velocity.y = 0.0
	if session.collision.is_below_level(hitbox()):
		removed = true


## Moves [param speed] pixels in the direction the enemy faces. Returns
## false when a wall stopped it.
func _walk(session: LevelSession, speed: float) -> bool:
	var distance := facing * speed
	var moved := session.collision.sweep_x(hitbox(), distance)
	position.x += moved
	return is_equal_approx(moved, distance)


## Whether the floor ends just ahead, in the direction the enemy faces.
func _at_ledge(session: LevelSession) -> bool:
	var box := hitbox()
	var ahead := box
	ahead.position.x += facing * box.size.x
	return on_ground and session.collision.floor_under(ahead) == TileProperties.Floor.NONE


## -1 when Keen is to the left, 1 when he is to the right.
func _direction_to_keen(session: LevelSession) -> int:
	var keen_center := session.keen.hitbox().get_center().x
	return -1 if keen_center < hitbox().get_center().x else 1


## Whether Keen stands at about the same height, so that the enemy can see
## him along the floor.
func _keen_at_same_height(session: LevelSession) -> bool:
	var keen_feet := session.keen.hitbox().end.y
	return absf(keen_feet - hitbox().end.y) < EgaGraphics.TILE_SIZE


## Pushes Keen away from this enemy with [param speed].
func _push_keen(session: LevelSession, direction: int, speed: float) -> void:
	session.keen.push(direction * speed)
