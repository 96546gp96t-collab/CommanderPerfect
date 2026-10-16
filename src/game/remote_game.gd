class_name RemoteGame
extends Node
## What the player who joined an online game sees of the host's game, for
## [LevelView] in its REMOTE mode: the host's map or level with the tiles
## that changed, the Keens and the other actors as the host sends them
## every tick ([Snapshot]), and the arrow at the edge of the screen toward
## the other player (for the host too).
##
## In a level the host's Keen is player 1; this player's own Keen is player
## 2 (in his colors), and the camera follows it. On the world map only the
## host's Keen walks.
##
## The nodes it uses are in the scene of [LevelView].

## What the host shows: the map or a level.
var kind := OnlineMessages.Scene.WAITING
## Plays the sounds of the host's game.
var sounds: SoundPlayer
## Where the host's Keen stood on the world map last, for the ending.
var map_position := Vector2.INF
## Whether the next snapshot is the first of this scene.
var _fresh := true
var _own_dead := false
var _mirrors := MirrorActors.new()

@onready var _level_map: LevelMap = %LevelMap
@onready var _keen: Keen = %Keen
@onready var _second_player: TwoPlayerView = %TwoPlayers
@onready var _actor_layer: ActorLayer = %ActorLayer
@onready var _arrow: PartnerArrow = %Arrow


## Starts showing the host's map or level ([param scene_kind]):
## [param level], fresh from its file, with [param tiles] (x, y, tile, ...)
## changed as the host has them.
func begin(
	scene_kind: OnlineMessages.Scene,
	level: LevelData,
	properties: TileProperties,
	tiles: PackedInt32Array
) -> void:
	kind = scene_kind
	_fresh = true
	_own_dead = false
	_mirrors.clear()
	for start in range(0, tiles.size(), OnlineMessages.TILE_FIELDS):
		var cell := Vector2i(tiles[start], tiles[start + 1])
		if level.playable_rect().has_point(cell):
			level.set_tile(cell, tiles[start + 2])
	_level_map.show_level(level, properties)
	_keen.show_sprite(_keen.position, -1)


## A tile of [param level] changed at the host.
func change_tile(level: LevelData, cell: Vector2i, tile: int) -> void:
	if level.playable_rect().has_point(cell):
		level.set_tile(cell, tile)
		_level_map.set_tile(cell, tile)


## Shows one tick. Returns true for the first one of a scene: then the
## camera should jump to it instead of gliding.
func show(snapshot: Snapshot) -> bool:
	for sound in snapshot.sounds:
		sounds.play(sound as Sound.Id)
	var keens := snapshot.keens
	if keens.is_empty():
		return false
	if kind == OnlineMessages.Scene.MAP:
		_keen.show_sprite(keens[0].position, keens[0].sprite)
		map_position = keens[0].position
	else:
		_keen.show_frame(keens[0].position, keens[0].sprite, keens[0].width)
		_own_dead = keens.size() > 1 and keens[1].dead
		if keens.size() > 1:
			_second_player.show_remote(keens[1])
		else:
			_second_player.hide_remote()
		_actor_layer.show_actors(_mirrors.update(snapshot))
	var first := _fresh
	_fresh = false
	return first


## Where the camera looks, [param current] being where it looks now: at
## his own Keen in a level (staying put while he dies), at the host's on
## the world map.
func camera_target(current: Vector2) -> Vector2:
	if kind == OnlineMessages.Scene.MAP:
		return _keen.smooth_position() + MapKeen.SPRITE_SIZE / 2.0
	if not _second_player.is_remote():
		return _keen.smooth_position() + KeenPhysics.SPRITE_SIZE / 2.0
	return current if _own_dead else _second_player.keen_center()


## Points the arrow from [param view] to the other player when he is out
## of sight: for the host to the Keen of the player who joined
## ([param to_partner]), for the player who joined to the host's Keen
## ([param to_host]).
func point_arrow(view: Rect2, to_partner: bool, to_host: bool) -> void:
	if to_partner:
		_arrow.color = PartnerArrow.PARTNER_COLOR
		_arrow.point_at(view, _second_player.keen_center())
	elif to_host and _keen.visible:
		_arrow.color = PartnerArrow.HOST_COLOR
		_arrow.point_at(view, _keen.smooth_position() + KeenPhysics.SPRITE_SIZE / 2.0)
	else:
		_arrow.visible = false
