class_name Keen5Creature
extends GalaxyCreature
## What Keen 5's creatures share beyond the Galaxy creature
## ([GalaxyCreature]; Omni `ck_misc.c`, `ck5_obj*.c`, facts and numbers
## only; docs/keen5/research.md §7):
##   - placing one on its info tile, some way above it ([method place]);
##   - the "deadly" contact (Omni CK_DeadlyCol): a stunner shot is absorbed,
##     Keen dies; most of Keen 5's cast is like that;
##   - pushing Keen sideways and knocking him off a pole or ledge (the
##     Little Ampton, the Korath, the Shelley; [Keen5Keen]);
##   - the white flash of a creature that a shot hurts without stunning
##     (the Shikadi, the Shockshund): two drawings in white
##     ([member GalaxyObject.flash_white]);
##   - turning back at a wall or ledge as most walkers do, waiting a random
##     0-7 frames ([method _turn_round]).
## A plain Keen5Creature is also what an explosion leaves (the Shelley's
## blast): a picture that kills.

## Misc kinds of the foreground tiles (Omni MISCFLAG_POLE, _COMPUTER).
const POLE := GalaxyTileKinds.POLE
const COMPUTER := 31
## A flash lasts this many drawings (Omni user3 = 2).
const FLASH_DRAWINGS := 2

## Drawings left in white ([method _show_flash]).
var flash := 0


## Puts it at [param cell] (map cells) raised by [param rise] units (Omni:
## each kind's spawn offset), with the actions of [param rows], running
## [param first]. Its facing and priority must be set before.
func place(
	world: GalaxyWorld,
	cell: Vector2i,
	rise: Vector2i,
	rows: PackedStringArray,
	episode_sprites: Dictionary[StringName, int],
	first: StringName
) -> void:
	var at := Vector2i(GalaxyUnits.from_tile(cell.x), GalaxyUnits.from_tile(cell.y))
	enter(world, at + rise, rows, episode_sprites, first)


## Contact: a stunner shot stops, Keen dies (Omni CK_DeadlyCol).
func _contact_deadly(other: GalaxyObject) -> void:
	var shot := live_shot(other)
	if shot != null:
		shot.hit()
	elif is_player(other):
		kill_player(other)


## [param other] as Keen 5's Keen, pushed sideways out of its way (Omni
## CK_PhysPushX); nothing for anything else.
func _push_keen(other: GalaxyObject) -> void:
	var keen := other as Keen5Keen
	if keen != null:
		keen.push_sideways(self)


## Keen on a pole or ledge touches it: he falls off (Omni
## CK_KeenSpecialColFunc, the Little Ampton and the Korath); a stunned one
## does nothing.
func _knock_off(player: GalaxyObject, holding: bool) -> void:
	var keen := player as Keen5Keen
	if keen != null and holding and not stunned:
		keen.knock_off_pole(self)


## A shot hurts it without stunning it: the shot stops and it flashes.
func _flash_hit(shot: GalaxyStunnerShot) -> void:
	flash = FLASH_DRAWINGS
	needs_react = true
	shot.hit()


## When drawn: white while its flash lasts (Omni: the draw functions count
## user3 down).
func _show_flash() -> void:
	flash_white = flash > 0
	if flash > 0:
		flash -= 1


## The stun also ends a flash (Omni: a stunned creature is drawn plainly).
func stun(shot: GalaxyStunnerShot, stunned_action: StringName) -> void:
	flash = 0
	flash_white = false
	super(shot, stunned_action)


## Steps back its last move and faces [param facing], waits a random 0-7
## frames, and starts its action again (Omni, the walkers' draw functions).
func _turn_round(facing: int) -> void:
	position.x -= moved.x
	direction.x = facing
	think_delay = world.random() / TURN_WAIT_DIVISOR
	set_action(action)


## The misc kind of the foreground tile at ([param x], [param y]), without
## the in-front bit.
func _misc_at(x: int, y: int) -> int:
	return world.misc_of(world.fore_tile(x, y))


## The Keen it reacts to: the player's (with two players the nearest).
func _keen() -> GalaxyObject:
	return nearest_player()
