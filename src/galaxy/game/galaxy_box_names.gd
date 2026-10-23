class_name GalaxyBoxNames
extends RefCounted
## What the boxes of a Galaxy episode are, for playing online (made from
## Keen 4's [Keen4BoxNames], milestone E11): the host's boxes are made by
## [GalaxyNamedBoxes] (and an episode's own messages, such as Keen 5's
## [Keen5NamedMessages]), which name each picture here
## ([method name_all]); the name goes with the snapshot
## ([member GalaxySnapshot.box]), and the joiner makes the same picture
## from his own files ([method image_for]). The pictures never travel.
##
## A name is the kind, its numbers, and the page of a box of several. The
## kinds every episode has are [enum Kind]; an episode's own kinds start at
## [constant EPISODE_KINDS] and come through its subclass
## ([method _argument_count], [method _episode_pages]; Keen 5's fuse
## message: [Keen5BoxNames]).

enum Kind {
	NONE,
	ONE_MOMENT,
	ENTERING,
	DEMO_ENTERING,
	PAUSED,
	TRY_AGAIN,
	GAME_OVER,
	## The loading box with a text of the game run (Keen 5's arrival on
	## Korath III).
	LOADING,
}

## An episode's own kinds are numbered from here on.
const EPISODE_KINDS := 32
## The names of this many pictures are kept (a blinking choice makes a new
## picture often).
const MAX_KEPT := 64
## The numbers a kind takes before the page.
const ARGUMENTS: Dictionary[int, int] = {
	Kind.ONE_MOMENT: 0,
	Kind.ENTERING: 1,
	Kind.DEMO_ENTERING: 0,
	Kind.PAUSED: 0,
	Kind.TRY_AGAIN: 3,
	Kind.GAME_OVER: 0,
	Kind.LOADING: 1,
}
const MAX_MAP := GalaxyOnlineMessages.MAX_MAP

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


## The picture [param description] names, made with [param boxes] (and
## the episode's own messages); null when the name makes no sense.
func image_for(description: PackedInt32Array, boxes: GalaxyGameBoxes) -> Image:
	if description.is_empty() or boxes == null:
		return null
	var kind := description[0]
	var count := _argument_count(kind)
	if count < 0 or description.size() != count + 2:
		return null
	var page := description[-1]
	var pages := _pages(kind, description, boxes)
	return pages[page] if page >= 0 and page < pages.size() else null


## How many numbers [param kind] takes before the page; -1 for no kind.
func _argument_count(kind: int) -> int:
	return ARGUMENTS.get(kind, -1)


func _pages(kind: int, description: PackedInt32Array, boxes: GalaxyGameBoxes) -> Array[Image]:
	var single: Array[Image] = []
	var number := description[1] if description.size() > 2 else 0
	var real_map := number >= 0 and number <= MAX_MAP
	match kind:
		Kind.ONE_MOMENT:
			single.append(boxes.one_moment())
		Kind.ENTERING:
			return boxes.entering(number) if real_map else single
		Kind.DEMO_ENTERING:
			return boxes.demo_entering()
		Kind.PAUSED:
			single.append(boxes.paused())
		Kind.TRY_AGAIN:
			if real_map:
				single.append(boxes.try_again(number, clampi(description[2], 0, 1), description[3]))
		Kind.GAME_OVER:
			single.append(boxes.game_over())
		Kind.LOADING:
			return boxes.loading_game_text(number)
		_:
			return _episode_pages(kind, description)
	return single


## The pages of an episode's own kind [param _kind] (none by default).
func _episode_pages(_kind: int, _description: PackedInt32Array) -> Array[Image]:
	var none: Array[Image] = []
	return none
