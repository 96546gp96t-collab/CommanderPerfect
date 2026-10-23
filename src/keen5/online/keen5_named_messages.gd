class_name Keen5NamedMessages
extends Keen5Messages
## Keen 5's fuse messages ([Keen5Messages]), each picture named in
## [member names] for the player who joins online (milestone E11;
## [Keen5BoxNames]).

var names := GalaxyBoxNames.new()


static func create_named(data: GalaxyData, box_names: GalaxyBoxNames) -> Keen5NamedMessages:
	var messages := Keen5NamedMessages.new()
	Keen5Messages.create(data, messages)
	messages.names = box_names
	return messages


func fuse(map: int) -> Array[Image]:
	return names.name_all(super(map), [Keen5BoxNames.FUSE, map])
