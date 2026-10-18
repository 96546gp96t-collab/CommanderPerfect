class_name Keen3Hits
extends RefCounted
## Keen 3's hits in one tick, as Chocolate Keen's contact rules have them;
## [Keen3LevelSession] makes one after the carriers moved their riders and
## hands it the awake enemies (only they touch anything):
##   Keen's shot   splashes on every awake sprite but Keen and the corpses:
##                 an enemy loses a hit; a fireball splashes too; a wave or
##                 a gun's shot flies on
##   fireball      kills Keen (also a stunned one), grunts and Foobs, and
##                 splashes on anything but a mother or a corpse
##   gun's shot    flies through everything and kills Keen, grunts and Foobs
##                 on its way
##   wave          kills Keen
##   touch         each enemy does to Keen what it says (kill, stun, push,
##                 carry; the Foob dies)
## The ankh protects Keen from every kill ([method Keen3Body.kill]).

var _session: Keen3LevelSession


func _init(session: Keen3LevelSession) -> void:
	_session = session


## Every flying shot and every wave against [param targets] and the Keens,
## then the enemies touching the Keens.
func resolve(targets: Array[Enemy]) -> void:
	for actor in _session.actors:
		var shot := actor as Keen3Shot
		if shot == null or not shot.is_flying():
			continue
		if shot.from_keen:
			_hit_with_keen_shot(shot, targets)
		elif shot is Keen3GunShot:
			_hit_with_gun_shot(shot, targets)
		else:
			_hit_with_fireball(shot, targets)
	for actor in _session.actors:
		if actor is Keen3SoundWave:
			_hit_keens(actor.hitbox())
	_touch_enemies(targets)


## Keen's [param shot] splashes on the first living enemy, fireball or wave
## it touches; an enemy loses a hit, a fireball splashes too.
func _hit_with_keen_shot(shot: Keen3Shot, targets: Array[Enemy]) -> void:
	var box := shot.hitbox()
	for enemy in targets:
		if enemy.stops_shots() and box.intersects(enemy.hitbox()):
			_hurt(enemy, enemy.hit_by_shot.bind(_session))
			_splash(shot)
			return
	for actor in _session.actors:
		if actor == shot or actor.removed or not box.intersects(actor.hitbox()):
			continue
		if actor is Keen3Fireball and actor.is_flying():
			actor.splash()
			_splash(shot)
			return
		if actor is Keen3SoundWave or _is_flying_gun_shot(actor):
			_splash(shot)
			return


## A gun's [param shot] flies through everything; it kills every Keen and
## every grunt and Foob it touches on its way.
func _hit_with_gun_shot(shot: Keen3Shot, targets: Array[Enemy]) -> void:
	var box := shot.hitbox()
	_hit_keens(box)
	for enemy in targets:
		if _hurt_by_enemy_shot(enemy, box):
			_hurt(enemy, enemy.die)


## A [param fireball] kills the Keen it touches (the ankh still protects
## him), and grunts and Foobs; it splashes on anything but a mother, a
## corpse or another fireball's splash.
func _hit_with_fireball(fireball: Keen3Shot, targets: Array[Enemy]) -> void:
	var box := fireball.hitbox()
	if _hit_keens(box):
		_splash(fireball)
		return
	for enemy in targets:
		if Keen3Fireball.passes(enemy) or not box.intersects(enemy.hitbox()):
			continue
		if _hurt_by_enemy_shot(enemy, box):
			_hurt(enemy, enemy.die)
		_splash(fireball)
		return
	for actor in _session.actors:
		var other_shot := actor is Keen3SoundWave or _is_flying_gun_shot(actor)
		if other_shot and box.intersects(actor.hitbox()):
			_splash(fireball)
			return


## Whether an enemy shot in [param box] kills [param enemy]: a living grunt
## or Foob there (Choco).
func _hurt_by_enemy_shot(enemy: Enemy, box: Rect2) -> bool:
	var kind := enemy as Keen3Enemy
	return (
		kind != null
		and not kind.is_dead
		and kind.hurt_by_enemy_shots()
		and box.intersects(kind.hitbox())
	)


static func _is_flying_gun_shot(actor: Actor) -> bool:
	return actor is Keen3GunShot and actor.is_flying()


## Kills every living Keen in [param box], also a stunned one. Returns
## whether one was there (dead or protected by the ankh or not).
func _hit_keens(box: Rect2) -> bool:
	var hit := false
	for body in _session.keens:
		if not body.is_dead and box.intersects(body.hitbox()):
			body.kill()
			hit = true
	return hit


## Each awake enemy that touches a living Keen does what it does to him.
func _touch_enemies(targets: Array[Enemy]) -> void:
	for body in _session.keens:
		for enemy in targets:
			if body.is_dead or not enemy.touches_keen():
				continue
			if enemy.hitbox().intersects(body.hitbox()):
				_hurt(enemy, enemy.touch_keen.bind(_session, body))


## Does [param attack] to [param enemy], and lets it scream if that kills
## it (as [LevelSession] does).
func _hurt(enemy: Enemy, attack: Callable) -> void:
	var was_dead := enemy.is_dead
	attack.call()
	if enemy.is_dead and not was_dead:
		_session.play_sound(enemy.death_sound())


func _splash(shot: Keen3Shot) -> void:
	_session.play_sound(Sound.Id.SHOT_HIT)
	shot.splash()
