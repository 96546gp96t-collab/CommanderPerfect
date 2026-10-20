class_name Keen3Ball
extends Keen3Carrier
## The ball of Keen 3 (info value 7), as Chocolate Keen has it: it sets off
## diagonally toward Keen's start, [constant SPEED] on each axis, without
## gravity, and bounces off walls, floors and ceilings ([method bounce]).
## One picture (109). It is harmless and solid: Keen rides on it and is
## pushed by it ([Keen3Carrier]); when it carries him up into a ceiling it
## bounces down as if it had hit the ceiling itself. Every shot splashes on
## it; it never breaks. It wakes and sleeps as the enemies do
## ([Keen3ActiveArea]).

const SPRITE := 109
## BALL's box (0, 0, 15, 15) in EGAHEAD.CK3: the whole sprite.
const BODY_BOX := Rect2(0, 0, 16, 16)
## 400 on each axis (Choco).
const SPEED := 121 * Keen2Enemy.SUBPIXEL


## A ball at [param start] (the top left of its cell); Keen's sprite is at
## [param keen_at].
static func spawned(start: Vector2, keen_at: Vector2) -> Keen3Ball:
	var ball := Keen3Ball.new()
	ball.position = start
	ball.body_box = BODY_BOX
	ball.falls = false
	ball.velocity = start_velocity(start, keen_at)
	return ball


## The first speed of a ball or jack at [param start]: toward [param keen_at]
## on both axes, as the original compares the sprites' top left corners
## (right and down when level).
static func start_velocity(start: Vector2, keen_at: Vector2) -> Vector2:
	return Vector2(
		-SPEED if start.x > keen_at.x else SPEED, -SPEED if start.y > keen_at.y else SPEED
	)


## One tick of [param enemy]'s flight (a ball or a jack): sideways, then up
## or down, each through the tiles; an axis that hits a tile turns round.
static func bounce(enemy: Enemy, session: LevelSession) -> void:
	var moved_x := session.collision.sweep_x(enemy.hitbox(), enemy.velocity.x)
	enemy.position.x += moved_x
	if moved_x != enemy.velocity.x:
		enemy.velocity.x = -enemy.velocity.x
	var moved_y := session.collision.sweep_y(enemy.hitbox(), enemy.velocity.y)
	enemy.position.y += moved_y
	if moved_y != enemy.velocity.y:
		enemy.velocity.y = -enemy.velocity.y


## It wakes and sleeps as Keen 3's enemies do; awake, it bounces on.
func step(session: LevelSession) -> void:
	last_move = Vector2.ZERO
	var keen_3 := session as Keen3LevelSession
	if keen_3 == null:
		return
	if not is_active:
		if not keen_3.wakes_at(position):
			return
		is_active = true
	elif not keen_3.keeps_awake_at(position):
		is_active = false
		return
	var before := position
	bounce(self, session)
	last_move = position - before


func sprite_index() -> int:
	return SPRITE


func hit_by_shot(_session: LevelSession) -> void:
	pass


func _stopped(direction: Vector2) -> void:
	if direction.x != 0.0:
		velocity.x = -direction.x * SPEED
	if direction.y != 0.0:
		velocity.y = -direction.y * SPEED
