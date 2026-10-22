class_name Keen5Piece
extends GalaxyShrapnel
## A piece of an exploded Shelley or Shikadi mine (Omni `ck5_obj2.c`
## CK5_SpawnShellyBits, `ck5_obj3.c` CK5_MineExplode, CK5_MineShrapCol;
## facts and numbers only): it flies off, falls and bounces until spent
## ([GalaxyShrapnel]); it kills Keen and absorbs a stunner shot. A mine's
## pieces also tell what else they touch: an object with a method
## [code]hit_by_piece(piece)[/code] hears it (milestone E5's QED, which a
## mine's piece destroys).

## Pieces are drawn behind everything (Omni: a new object's zLayer is 0).
const PRIORITY := 0

## It tells the objects it touches: a mine's piece.
var reports_touches := false


## A piece at [param at] (units) flying off with [param speed], with the
## actions of [param rows] starting with [param first].
static func throw(
	world: GalaxyWorld,
	at: Vector2i,
	speed: Vector2i,
	rows: PackedStringArray,
	episode_sprites: Dictionary[StringName, int],
	first: StringName
) -> Keen5Piece:
	var piece := Keen5Piece.new()
	piece.priority = PRIORITY
	piece.direction = Vector2i.ZERO
	piece.velocity = speed
	piece.enter(world, at, rows, episode_sprites, first)
	return piece


## Contact: a stunner shot stops, Keen dies; a mine's piece tells anything
## else it touches (Omni CK_DeadlyCol, CK5_MineShrapCol).
func _contact_piece(other: GalaxyObject) -> void:
	var shot := live_shot(other)
	if shot != null:
		shot.hit()
	elif is_player(other):
		kill_player(other)
	elif reports_touches and other.has_method(&"hit_by_piece"):
		other.call(&"hit_by_piece", self)
