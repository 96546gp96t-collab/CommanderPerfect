class_name Keen3AnkhShield
extends Actor
## The halo around Keen while the ankh protects him: it follows his
## [Keen3Body] and shows the picture that [method Keen3Body.halo_sprite]
## asks for. It touches nothing. It is gone once the ankh's time is over or
## Keen is dead. The [ActorLayer] draws it, behind Keen; the middle of the
## halo is transparent, so Keen shows through.

var keen: Keen3Body


## A halo around [param body].
static func around(body: Keen3Body) -> Keen3AnkhShield:
	var shield := Keen3AnkhShield.new()
	shield.keen = body
	shield._follow()
	return shield


## Moves with Keen, who has already moved in this tick.
func step(_session: LevelSession) -> void:
	_follow()
	removed = not keen.is_protected()


func sprite_index() -> int:
	return keen.halo_sprite()


func _follow() -> void:
	position = keen.position + Keen3Body.HALO_OFFSET
