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
uniform vec4 text_color = vec4(1.0);
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
		COLOR = text.r > 0.5 ? text_color : texelFetch(inside, ivec2(pixel), 0);
	}
}
"""
## The intro's words drawn in a palette of their own (Keen 5): one word
## alone, both over each other (the words are masks, see-through elsewhere).
const WORDS_SHADER := """
shader_type canvas_item;
uniform sampler2D left_word : filter_nearest;
uniform sampler2D right_word : filter_nearest;
uniform float left_x;
uniform float right_x;
uniform vec4 alone;
uniform vec4 both;

float word_at(sampler2D word, float x, vec2 pixel) {
	ivec2 size = textureSize(word, 0);
	ivec2 at = ivec2(int(pixel.x - x), int(pixel.y));
	if (at.x < 0 || at.x >= size.x || at.y < 0 || at.y >= size.y) {
		return 0.0;
	}
	return texelFetch(word, at, 0).a > 0.5 ? 1.0 : 0.0;
}

void fragment() {
	vec2 pixel = floor(UV * vec2(320.0, 200.0));
	float count = word_at(left_word, left_x, pixel) + word_at(right_word, right_x, pixel);
	COLOR = count > 1.5 ? both : (count > 0.5 ? alone : vec4(0.0));
}
"""

## The words' colours, alone and over each other; empty: Keen 4's way (two
## dark grey sprites added together).
var word_colors: Array[Color] = []
var _black := ColorRect.new()
var _screen := Control.new()
var _picture := Sprite2D.new()
var _right_word := Sprite2D.new()
var _left_word := Sprite2D.new()
var _credit := Sprite2D.new()
var _story := ColorRect.new()
var _story_material := ShaderMaterial.new()
var _words := ColorRect.new()
var _words_material := ShaderMaterial.new()
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
	var words_shader := Shader.new()
	words_shader.code = WORDS_SHADER
	_words_material.shader = words_shader
	_words.material = _words_material
	_words.size = Vector2(SCREEN_SIZE)
	_words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen.add_child(_words)
	_screen.move_child(_words, _credit.get_index())
	clear()


## Puts the original's screen in the middle of a picture
## [param game_size] wide, black around it.
func fit(game_size: Vector2i) -> void:
	_black.size = Vector2(game_size)
	_screen.position = Vector2((game_size.x - SCREEN_SIZE.x) / 2.0, 0)


## Nothing shown (the game is seen).
func clear() -> void:
	visible = false
	for item: CanvasItem in [_picture, _right_word, _left_word, _credit, _story, _words]:
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
	if not word_colors.is_empty():
		_show_coloured_words(intro)
	else:
		_show_added_words(intro)
	if intro.credit >= 0:
		if intro.credit != _credit_shown:
			_credit_shown = intro.credit
			_credit.texture = ImageTexture.create_from_image(intro.credits[intro.credit])
		_credit.position = Vector2(intro.credit_corner())
		_credit.visible = true


func _show_added_words(intro: GalaxyIntroCredits) -> void:
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


func _show_coloured_words(intro: GalaxyIntroCredits) -> void:
	if _left_word.texture == null:
		_left_word.texture = ImageTexture.create_from_image(
			intro.left_word.image(Color.WHITE, true)
		)
		_right_word.texture = ImageTexture.create_from_image(intro.right_word.image(Color.WHITE))
		_words_material.set_shader_parameter("left_word", _left_word.texture)
		_words_material.set_shader_parameter("right_word", _right_word.texture)
		_words_material.set_shader_parameter("alone", word_colors[0])
		_words_material.set_shader_parameter("both", word_colors[-1])
	_words_material.set_shader_parameter("left_x", float(intro.left_word_x()))
	_words_material.set_shader_parameter("right_x", float(intro.right_word_x()))
	_words.visible = true


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
		_story_material.set_shader_parameter("text_color", scroller.text_color)
		_story.visible = true
	_story_material.set_shader_parameter("distance", float(distance))
