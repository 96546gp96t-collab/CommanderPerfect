class_name GalaxyTitleLayer
extends Control
## What a Galaxy episode shows over the whole screen between its games:
## the intro credits ([GalaxyIntroCredits]), the title picture, the story
## scroller ([GalaxyStoryScroller]), the help and end pages, all on the
## original's 320 × 200 screen, black around it in widescreen. It lies over
## the game in the World viewport's Ui layer (the message boxes stay in
## front of it).
##
## The scrolling words of the intro are two sprites drawn with additive
## blending: either one alone is dark grey (85), both together light grey
## (170), as the original's palette for that part gives. The story is one
## rectangle with a shader that does the original's row squeezing on the
## graphics card.

const SCREEN_SIZE := Vector2i(320, 200)
const STORY_SHADER := """
shader_type canvas_item;
uniform sampler2D strip : filter_nearest;
uniform sampler2D rows : filter_nearest;
uniform sampler2D outside : filter_nearest;
uniform sampler2D inside : filter_nearest;
uniform float distance;
uniform float strip_height;
const float MIDDLE = 160.0;
const float UNIT = 2048.0;

void fragment() {
	vec2 pixel = floor(UV * vec2(320.0, 200.0));
	vec3 row = texelFetch(rows, ivec2(0, int(pixel.y)), 0).rgb;
	float start = MIDDLE - row.r / 2.0;
	COLOR = texelFetch(outside, ivec2(pixel), 0);
	if (pixel.x >= start && pixel.x < MIDDLE + row.r / 2.0) {
		float strip_row = distance - row.g;
		if (strip_row < 0.0 || strip_row >= strip_height) {
			strip_row = 0.0;
		}
		float strip_x = floor((pixel.x - start) * row.b / UNIT);
		vec4 text = texelFetch(strip, ivec2(int(strip_x), int(strip_row)), 0);
		COLOR = text.r > 0.5 ? vec4(1.0) : texelFetch(inside, ivec2(pixel), 0);
	}
}
"""

var _black := ColorRect.new()
var _screen := Control.new()
var _picture := Sprite2D.new()
var _right_word := Sprite2D.new()
var _left_word := Sprite2D.new()
var _credit := Sprite2D.new()
var _story := ColorRect.new()
var _story_material := ShaderMaterial.new()
## The credit whose picture [member _credit] holds.
var _credit_shown := -1


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Always the original pixels, also when xBRZ makes the World viewport
	# filter its textures smoothly (D11).
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_black.color = Color.BLACK
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_black)
	_screen.clip_contents = true
	_screen.size = Vector2(SCREEN_SIZE)
	_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_screen)
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	for sprite: Sprite2D in [_picture, _right_word, _left_word, _credit]:
		sprite.centered = false
		_screen.add_child(sprite)
	_right_word.material = additive
	_left_word.material = additive
	var shader := Shader.new()
	shader.code = STORY_SHADER
	_story_material.shader = shader
	_story.material = _story_material
	_story.size = Vector2(SCREEN_SIZE)
	_story.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen.add_child(_story)
	clear()


## Puts the original's screen in the middle of a picture
## [param game_size] wide, black around it.
func fit(game_size: Vector2i) -> void:
	_black.size = Vector2(game_size)
	_screen.position = Vector2((game_size.x - SCREEN_SIZE.x) / 2.0, 0)


## Nothing shown (the game is seen).
func clear() -> void:
	visible = false
	for item: CanvasItem in [_picture, _right_word, _left_word, _credit, _story]:
		item.visible = false


## Black only.
func show_black() -> void:
	clear()
	visible = true


## [param image] (320 × 200) over black.
func show_picture(image: Image) -> void:
	show_black()
	_picture.texture = ImageTexture.create_from_image(image)
	_picture.visible = true


## The two words of the intro and its credit for this frame.
func show_scroll(intro: GalaxyIntroCredits) -> void:
	show_black()
	if _left_word.texture == null:
		_left_word.texture = ImageTexture.create_from_image(
			intro.left_word.image(GalaxyIntroCredits.ONE_WORD, true)
		)
		_right_word.texture = ImageTexture.create_from_image(
			intro.right_word.image(GalaxyIntroCredits.ONE_WORD)
		)
	_left_word.position = Vector2(intro.left_word_x(), 0)
	_right_word.position = Vector2(intro.right_word_x(), 0)
	_left_word.visible = true
	_right_word.visible = true
	if intro.credit >= 0:
		if intro.credit != _credit_shown:
			_credit_shown = intro.credit
			_credit.texture = ImageTexture.create_from_image(intro.credits[intro.credit])
		_credit.position = Vector2(intro.credit_corner())
		_credit.visible = true


## The story at [param distance] rows of its strip.
func show_story(scroller: GalaxyStoryScroller, distance: int) -> void:
	if not _story.visible:
		show_black()
		_story_material.set_shader_parameter(
			"strip", ImageTexture.create_from_image(scroller.strip)
		)
		_story_material.set_shader_parameter(
			"rows", ImageTexture.create_from_image(GalaxyStoryScroller.row_table())
		)
		_story_material.set_shader_parameter(
			"outside", ImageTexture.create_from_image(scroller.outside)
		)
		_story_material.set_shader_parameter(
			"inside", ImageTexture.create_from_image(scroller.inside)
		)
		_story_material.set_shader_parameter("strip_height", float(scroller.strip_height))
		_story.visible = true
	_story_material.set_shader_parameter("distance", float(distance))
