class_name RealisticLights
extends RefCounted
## The lights of the realistic look near one view (layer B of
## docs/realistic/research.md): lamps, fire and signs among the tiles, and
## shots, collected every frame and handed to realistic_look.gdshader. Each
## game says which of its tiles give light ([method from_tiles]); the
## kinds of light ([Kind]) are ours, tuned by eye.

## At most this many lights are drawn, the ones nearest the middle of the
## view: the shader's arrays hold this many.
const MAX_LIGHTS := 16
## Lights this far outside the view still light its edge.
const MARGIN := 48.0
const TILE_SIZE := 16


## One kind of light: its colour, how far it reaches and how strong it is,
## where it sits in its tile or sprite, and how high above the picture.
class Kind:
	extends RefCounted
	var color: Color
	var radius: float
	var strength: float
	var offset: Vector2
	var height: float

	static func create(
		light_color: Color, reach: float, power: float, place: Vector2, above := 12.0
	) -> Kind:
		var kind := Kind.new()
		kind.color = light_color
		kind.radius = reach
		kind.strength = power
		kind.offset = place
		kind.height = above
		return kind


## A ceiling lamp, shining down.
static var ceiling_lamp := Kind.create(Color(0.75, 0.85, 1.0), 72.0, 0.9, Vector2(8, 14))
## A sign that glows, such as an exit.
static var glowing_sign := Kind.create(Color(1.0, 0.35, 0.3), 40.0, 0.6, Vector2(8, 8))
## Fire and lava.
static var flames := Kind.create(Color(1.0, 0.6, 0.25), 64.0, 0.75, Vector2(8, 6))
## Electricity, force fields and energy beams.
static var energy := Kind.create(Color(0.55, 0.75, 1.0), 56.0, 0.8, Vector2(8, 8))
## A small lamp on a pole.
static var pole_lamp := Kind.create(Color(1.0, 0.95, 0.8), 40.0, 0.6, Vector2(8, 4))
## A flying shot.
static var shot_light := Kind.create(Color(1.0, 0.9, 0.7), 44.0, 1.0, Vector2(8, 4), 6.0)
## A shot hitting something.
static var splash_light := Kind.create(Color(1.0, 0.85, 0.5), 52.0, 1.1, Vector2(8, 6), 6.0)

var _view: Rect2
## The lights found so far: position in the level, and their kind.
var _places: PackedVector2Array = []
var _kinds: Array[Kind] = []


static func create(view: Rect2) -> RealisticLights:
	var lights := RealisticLights.new()
	lights._view = view
	return lights


## Adds a light of [param kind] for the tile or sprite whose top left is at
## [param position] (level pixels), when it reaches the view.
func add(position: Vector2, kind: Kind) -> void:
	var place := position + kind.offset
	if not _view.grow(kind.radius + MARGIN).has_point(place):
		return
	_places.append(place)
	_kinds.append(kind)


## Adds the lights of the tiles of [param level] near the view: [param kinds]
## gives the kind of light of each tile number that has one.
func add_tiles(level: LevelData, kinds: Dictionary[int, Kind]) -> void:
	if level == null or kinds.is_empty():
		return
	var area := _view.grow(MARGIN)
	var first := Vector2i((area.position / TILE_SIZE).floor()).max(Vector2i.ZERO)
	var last := Vector2i((area.end / TILE_SIZE).ceil()).min(Vector2i(level.width, level.height))
	for y in range(first.y, last.y):
		for x in range(first.x, last.x):
			var tile := level.tile_at(Vector2i(x, y))
			if kinds.has(tile):
				add(Vector2(x, y) * TILE_SIZE, kinds[tile])


## Adds a light for every shot among [param actors] (Keen 1-3).
func add_shots(actors: Array[Actor]) -> void:
	for actor in actors:
		var flying := actor as RaygunShot
		if flying != null:
			add_shot(flying.position, flying.is_splashing)


## Adds the light of a shot whose sprite is at [param position]; brighter
## where it [param hit] something.
func add_shot(position: Vector2, hit: bool) -> void:
	add(position, splash_light if hit else shot_light)


## The lights for the shader, nearest the middle of the view first: per
## light (x, y from the view's top left, radius, strength) and (red, green,
## blue, height).
func uniforms() -> Array[PackedVector4Array]:
	var center := _view.get_center()
	var order: Array[int] = []
	order.assign(range(_places.size()))
	order.sort_custom(
		func(a: int, b: int) -> bool:
			return _places[a].distance_squared_to(center) < _places[b].distance_squared_to(center)
	)
	var where := PackedVector4Array()
	var colors := PackedVector4Array()
	for index in order.slice(0, MAX_LIGHTS):
		var kind := _kinds[index]
		var place := _places[index] - _view.position
		where.append(Vector4(place.x, place.y, kind.radius, kind.strength))
		colors.append(Vector4(kind.color.r, kind.color.g, kind.color.b, kind.height))
	return [where, colors]
