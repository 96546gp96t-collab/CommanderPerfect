class_name Keen5BoxNames
extends GalaxyBoxNames
## The names of Keen 5's boxes for playing online (milestone E11): the
## Galaxy ones ([GalaxyBoxNames]) and Keen 5's own, the fuse message
## ([Keen5Messages], named by [Keen5NamedMessages]): [FUSE, map, page].
## The Korath III arrival's box is the shared loading box with a text of
## the game run ([constant GalaxyBoxNames.Kind.LOADING]).

## The two screens after a fuse broke in a map.
const FUSE := GalaxyBoxNames.EPISODE_KINDS

## The joiner's own fuse messages, which draw [constant FUSE].
var messages: Keen5Messages


func _argument_count(kind: int) -> int:
	if kind == FUSE:
		return 1
	return super(kind)


func _episode_pages(kind: int, description: PackedInt32Array) -> Array[Image]:
	if kind == FUSE and messages != null:
		return messages.fuse(description[1])
	return super(kind, description)
