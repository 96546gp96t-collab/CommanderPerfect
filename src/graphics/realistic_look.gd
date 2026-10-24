class_name RealisticLook
extends CanvasLayer
## The realistic look (option Realistic, F8; layers A and B of
## docs/realistic/research.md): a layer in a World viewport that draws the
## picture of the level again through realistic_look.gdshader, with relief,
## the light of lamps, fire and shots ([RealisticLights], from
## [member lights_source] every frame), bloom, a colour grade
## ([RealisticGrade]), a vignette and film grain.
##
## It sits in front of the level and behind the [b]Ui[/b] layer (the HUD,
## the windows, the menus), so text and the HUD stay exactly as they are.
## Hidden it draws nothing and costs nothing: the screen copy it reads is
## only made while it is visible.
##
## It must never make the game stutter (docs/realistic/research.md §10):
## when the game runs slower than the screen (at most 60 frames per second)
## for [constant SLOW_SECONDS] seconds in a row while the look is shown, the
## bloom and the relief, which cost the most, are left out for the rest of
## the session ([member lighter]).

## Sent once when the look became lighter.
signal made_lighter

const SHADER := preload("res://src/graphics/realistic_look.gdshader")
## The layer of the HUD and the windows; this one is put in front of it in
## the tree, so it is drawn just before it.
const UI_LAYER := 1
const BLOOM_LEVELS := 4
## Below this share of the wanted frame rate a second counts as slow.
const SLOW_SHARE := 0.9
const SLOW_SECONDS := 3
const WANTED_FPS := 60.0

## Whether the bloom is left out, for every look, since the game was slow
## with it.
static var lighter := false
## Whether a slow game makes the look lighter; off while measuring it
## (tools/measure_frames.gd).
static var may_get_lighter := true

## Gives the lights near this look's view every frame; returns null when
## there are none (no level shown).
var lights_source := Callable()

var _rect := ColorRect.new()
var _relief_strength := 0.0
var _second := 0.0
var _slow_seconds := 0


func _init() -> void:
	layer = UI_LAYER
	visible = false
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = SHADER
	_rect.material = material
	add_child(_rect)


## A look for [param viewport], drawn just before its node [param before]
## (its Ui layer), or after everything when that is null.
static func add_to(viewport: Viewport, before: Node = null) -> RealisticLook:
	var look := RealisticLook.new()
	look.name = "RealisticLook"
	viewport.add_child(look)
	if before != null:
		viewport.move_child(look, before.get_index())
	return look


## Shows the look over a view of [param view_size] game pixels, drawn at
## [param render_scale] screen pixels per game pixel, in the colours of
## [param grade].
func show_look(grade: RealisticGrade, view_size: Vector2i, render_scale: int) -> void:
	visible = true
	_rect.position = Vector2.ZERO
	_rect.size = Vector2(view_size)
	var material := _rect.material as ShaderMaterial
	material.set_shader_parameter("lod_base", log(float(maxi(render_scale, 1))) / log(2.0))
	material.set_shader_parameter("view_size", Vector2(view_size))
	material.set_shader_parameter("bloom_levels", 0 if lighter else BLOOM_LEVELS)
	material.set_shader_parameter("shadow_tint", _rgb(grade.shadow_tint))
	material.set_shader_parameter("highlight_tint", _rgb(grade.highlight_tint))
	material.set_shader_parameter("light_direction", grade.light_direction)
	_relief_strength = grade.relief_strength
	material.set_shader_parameter("relief_strength", 0.0 if lighter else _relief_strength)
	for parameter: String in [
		"bloom_strength",
		"bloom_threshold",
		"lift",
		"saturation",
		"contrast",
		"vignette",
		"grain",
		"relief_bump",
		"halo",
	]:
		material.set_shader_parameter(parameter, grade.get(parameter))


func hide_look() -> void:
	visible = false


func _process(delta: float) -> void:
	if not visible:
		return
	_update_lights()
	if lighter:
		if _rect.material.get_shader_parameter("bloom_levels") != 0:
			_rect.material.set_shader_parameter("bloom_levels", 0)
			_rect.material.set_shader_parameter("relief_strength", 0.0)
		return
	_second += delta
	if _second < 1.0 or not may_get_lighter:
		return
	_second = 0.0
	var refresh := DisplayServer.screen_get_refresh_rate()
	var wanted := minf(refresh, WANTED_FPS) if refresh > 0.0 else WANTED_FPS
	if note_second(Engine.get_frames_per_second(), wanted):
		lighter = true
		made_lighter.emit()


func _update_lights() -> void:
	var lights: RealisticLights = lights_source.call() if lights_source.is_valid() else null
	var material := _rect.material as ShaderMaterial
	if lights == null:
		material.set_shader_parameter("light_count", 0)
		return
	var arrays := lights.uniforms()
	material.set_shader_parameter("light_count", arrays[0].size())
	if arrays[0].is_empty():
		return
	# The arrays always hold the shader's full length.
	arrays[0].resize(RealisticLights.MAX_LIGHTS)
	arrays[1].resize(RealisticLights.MAX_LIGHTS)
	material.set_shader_parameter("lights", arrays[0])
	material.set_shader_parameter("light_colors", arrays[1])


## Counts one second at [param fps] frames per second, where [param wanted]
## are wanted; returns whether that made [constant SLOW_SECONDS] slow seconds
## in a row.
func note_second(fps: float, wanted: float) -> bool:
	_slow_seconds = _slow_seconds + 1 if fps < wanted * SLOW_SHARE else 0
	return _slow_seconds >= SLOW_SECONDS


## A tint can be above 1, which a [Color] keeps but a colour uniform clamps.
static func _rgb(color: Color) -> Vector3:
	return Vector3(color.r, color.g, color.b)
