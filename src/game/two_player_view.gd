class_name TwoPlayerView
extends Node
## Shows the second player in a level for [LevelView]: his Keen, in his own
## colors, and the split screen ([SplitScreen]).
##
## While the two players are close together, both cameras look at the same
## place and the World viewport shows them both. When they move apart, the
## World2 viewport, which looks at the same level with the second camera,
## is laid over the half of the screen on player 2's side (the SplitView),
## with a dark line between the halves, and a small arrow next to each Keen
## points to the other one ([PartnerArrows]). World2 only draws while the
## screen is split.
##
## The nodes it uses are in the scene of [LevelView].

const PLAYER_COLORS_SHADER := preload("res://src/graphics/player_colors.gdshader")
const SPLIT_SCREEN_SHADER := preload("res://src/graphics/split_screen.gdshader")
## Player 2's Keen has every color turned this far around the color wheel:
## his yellow helmet turns blue.
const PLAYER_2_HUE_SHIFT := 0.5
## The color of Keen's helmet, which stands for player 1.
const HELMET_COLOR := Color("ffff55")

var split := SplitScreen.new()
## The color of each player, for the arrows that point to him.
var player_colors: Array[Color] = [HELMET_COLOR, turn_hue(HELMET_COLOR, PLAYER_2_HUE_SHIFT)]
## The level the second player plays in; null when he does not.
var _session: LevelSession

@onready var _world: SubViewport = %World
@onready var _world_2: SubViewport = %World2
@onready var _keen: Keen = %Keen
@onready var _keen_2: Keen = %Keen2
@onready var _camera: LevelCamera = %Camera
@onready var _camera_anchor: Node2D = %CameraAnchor
@onready var _camera_2: LevelCamera = %Camera2
@onready var _camera_anchor_2: Node2D = %CameraAnchor2
@onready var _split_view: TextureRect = %SplitView
@onready var _arrows: PartnerArrows = %PartnerArrows


func _ready() -> void:
	_world_2.world_2d = _world.world_2d
	_split_view.texture = _world_2.get_texture()
	_split_view.material = ShaderMaterial.new()
	_split_view.material.shader = SPLIT_SCREEN_SHADER
	_camera_2.follow_exactly(true)
	var colors := ShaderMaterial.new()
	colors.shader = PLAYER_COLORS_SHADER
	colors.set_shader_parameter("hue_shift", PLAYER_2_HUE_SHIFT)
	_keen_2.material = colors


## [param color] with its hue turned [param shift] around the color wheel,
## as the player colors shader does.
static func turn_hue(color: Color, shift: float) -> Color:
	return Color.from_hsv(fposmod(color.h + shift, 1.0), color.s, color.v, color.a)


func set_textures(textures: GraphicsTextures) -> void:
	_keen_2.set_textures(textures)


## Takes the textures again, after the graphics changed.
func refresh() -> void:
	_keen_2.refresh()


## Whether a second Keen is in the level on the screen.
func is_active() -> bool:
	return _session != null


## The second player joins [param session]: his Keen appears with its
## sprite at [param at], and both cameras start at [param view_center].
func start(session: LevelSession, at: Vector2, view_center: Vector2) -> void:
	_session = session
	var body := session.add_player(at)
	_keen_2.show_body(body)
	_keen_2.snap()
	_keen_2.visible = true
	split.reset(view_center)
	_camera.follow_exactly(true)
	update(0.0)


## The second player leaves the level (if he was in one), or the level is
## over: back to one Keen and one camera that follows him.
func stop() -> void:
	if _session != null and _session.keens.size() > 1:
		_session.remove_player(_session.keens[1])
	_session = null
	_keen_2.visible = false
	_split_view.visible = false
	_world_2.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_arrows.hide_arrows()
	_camera.follow_exactly(false)


## Shows player 2's Keen as he is after the last tick.
func show_body() -> void:
	if _session != null:
		_keen_2.show_body(_session.keens[1])


## See [method SpriteView.place].
func place(blend: float, smooth: bool) -> void:
	_keen_2.place(blend, smooth)


## Hides or shows player 2's Keen together with player 1's.
func set_keen_visible(shown: bool) -> void:
	_keen_2.visible = shown and _session != null


## What each player sees, in level pixels.
func view_rects() -> Array[Rect2]:
	return [split.view_rect(0), split.view_rect(1)]


## Sets the scroll limits for a level area of [param area] pixels seen
## through a view of [param view_size] pixels.
func frame(area: Rect2i, view_size: Vector2i) -> void:
	_camera_2.frame(area, view_size)
	split.view_size = Vector2(view_size)
	split.center_range = LevelCamera.center_range(
		LevelCamera.limits_for(area, view_size), view_size
	)
	_split_view.size = Vector2(view_size)


## Moves the two cameras after [param delta] seconds, and shows the second
## half of the screen while the players are far apart.
func update(delta: float) -> void:
	if _session == null:
		return
	var keens := _session.keens
	var centers: Array[Vector2] = [_middle_of(_keen), _middle_of(_keen_2)]
	split.update(centers, [not keens[0].is_dead, not keens[1].is_dead], delta)
	_camera_anchor.position = split.centers[0]
	_camera_anchor_2.position = split.centers[1]
	var is_split := split.is_split()
	_split_view.visible = is_split
	_world_2.render_target_update_mode = (
		SubViewport.UPDATE_ALWAYS if is_split else SubViewport.UPDATE_DISABLED
	)
	if not is_split:
		_arrows.hide_arrows()
		return
	var strength := split.line_strength()
	var material := _split_view.material as ShaderMaterial
	material.set_shader_parameter("view_size", split.view_size)
	material.set_shader_parameter("normal", split.normal)
	material.set_shader_parameter("line_strength", strength)
	_arrows.show_arrows(centers, player_colors, strength)


## The middle of [param keen]'s sprite where it is drawn now.
static func _middle_of(keen: Keen) -> Vector2:
	return keen.smooth_position() + KeenPhysics.SPRITE_SIZE / 2.0
