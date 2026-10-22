class_name Keen4BoxNames
extends RefCounted
## What the boxes of Keen 4 are, for playing online (milestone D12): the
## host's boxes are made by [Keen4NamedBoxes] and [Keen4NamedMessages],
## which name each picture here ([method name_all]); the name goes with the
## snapshot ([member GalaxySnapshot.box]), and the joiner makes the same
## picture from his own files ([method image_for]). The pictures never
## travel.
##
## A name is the kind, its numbers, and the page of a box of several.

enum Kind {
	NONE,
	ONE_MOMENT,
	ENTERING,
	DEMO_ENTERING,
	PAUSED,
	CANT_SWIM,
	TRY_AGAIN,
	GAME_OVER,
	COUNCIL,
	JANITOR,
	LINDSEY,
	WETSUIT,
}

## The names of this many pictures are kept (a blinking choice makes a new
## picture often).
const MAX_KEPT := 64
## The numbers a kind takes before the page.
const ARGUMENTS: Dictionary[Kind, int] = {
	Kind.ONE_MOMENT: 0,
	Kind.ENTERING: 1,
	Kind.DEMO_ENTERING: 0,
	Kind.PAUSED: 0,
	Kind.CANT_SWIM: 0,
	Kind.TRY_AGAIN: 3,
	Kind.GAME_OVER: 0,
	Kind.COUNCIL: 2,
	Kind.JANITOR: 0,
	Kind.LINDSEY: 1,
	Kind.WETSUIT: 0,
}
const MAX_RESCUED := Keen4Progress.COUNCIL_COUNT

var _names: Dictionary[int, PackedInt32Array] = {}
var _order: Array[int] = []


## Names [param image] with [param description] (kind and numbers, page 0).
func name(image: Image, description: Array) -> Image:
	var named: Array[Image] = [image]
	return name_all(named, description)[0]


## Names each of [param images] with [param description] and its page.
func name_all(images: Array[Image], description: Array) -> Array[Image]:
	for page in images.size():
		var image := images[page]
		if image == null:
			continue
		var full := PackedInt32Array(description)
		full.append(page)
		var id := image.get_instance_id()
		if not _names.has(id):
			_order.append(id)
		_names[id] = full
		while _order.size() > MAX_KEPT:
			_names.erase(_order.pop_front())
	return images


## The name of [param image]; empty when it has none.
func description_of(image: Image) -> PackedInt32Array:
	if image == null:
		return PackedInt32Array()
	return _names.get(image.get_instance_id(), PackedInt32Array())


## The picture [param description] names, made with [param boxes] and
## [param messages]; null when the name makes no sense.
static func image_for(
	description: PackedInt32Array, boxes: Keen4GameBoxes, messages: Keen4Messages
) -> Image:
	if description.is_empty() or boxes == null or messages == null:
		return null
	var kind := description[0]
	if not ARGUMENTS.has(kind) or description.size() != ARGUMENTS[kind] + 2:
		return null
	var page := description[-1]
	var pages := _pages(kind as Kind, description, boxes, messages)
	return pages[page] if page >= 0 and page < pages.size() else null


static func _pages(
	kind: Kind, description: PackedInt32Array, boxes: Keen4GameBoxes, messages: Keen4Messages
) -> Array[Image]:
	var single: Array[Image] = []
	var map := description[1] if description.size() > 2 else 0
	var real_map := map >= 0 and map <= Keen4Episode.LAST_MAP
	match kind:
		Kind.ONE_MOMENT:
			single.append(boxes.one_moment())
		Kind.ENTERING:
			return boxes.entering(map) if real_map else single
		Kind.DEMO_ENTERING:
			return boxes.demo_entering()
		Kind.PAUSED:
			single.append(boxes.paused())
		Kind.CANT_SWIM:
			single.append(boxes.cant_swim())
		Kind.TRY_AGAIN:
			if real_map:
				single.append(boxes.try_again(map, clampi(description[2], 0, 1), description[3]))
		Kind.GAME_OVER:
			single.append(boxes.game_over())
		Kind.COUNCIL:
			if real_map:
				return messages.council(map, clampi(description[2], 0, MAX_RESCUED))
		Kind.JANITOR:
			return messages.janitor()
		Kind.LINDSEY:
			return messages.lindsey(map) if real_map else single
		Kind.WETSUIT:
			return messages.wetsuit()
	return single
