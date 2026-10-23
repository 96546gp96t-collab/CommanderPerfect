class_name GalaxyEgaFade
extends RefCounted
## The original's fade to and from black, as its EGA palettes do it (Omni
## `id_vl.c`: VL_FadeToBlack, VL_FadeFromBlack; seen in Keen 5's exploding
## galaxy, E7): four levels, each a palette shown for 6 tics:
##   - level 0: everything black;
##   - level 1: the dark colours (0-8) black, the bright ones (9-15) as
##     their dark twins (9 blue, ..., 15 light grey);
##   - level 2: the dark colours black, the bright ones (8-15) as they are;
##   - level 3: the whole palette.
## [method material] is a shader for a rectangle laid over the picture: it
## does this to every pixel under it of an EGA colour; a colour outside the
## palette (xBRZ's blends) is only darkened by the level's share.

const LEVELS := 4
const WHOLE := 3
const STEP_TICS := 6
const COLORS := 16
const SHADER := """
shader_type canvas_item;
uniform int level = 3;
uniform vec3 palette[16];
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

void fragment() {
	vec4 pixel = textureLod(screen_texture, SCREEN_UV, 0.0);
	int found = -1;
	for (int index = 0; index < 16; index++) {
		if (distance(pixel.rgb, palette[index]) < 0.01) {
			found = index;
		}
	}
	if (level >= 3) {
		COLOR = pixel;
	} else if (found < 0) {
		COLOR = vec4(pixel.rgb * float(level) / 3.0, pixel.a);
	} else if (level == 0 || (level == 1 && found <= 8) || (level == 2 && found < 8)) {
		COLOR = vec4(0.0, 0.0, 0.0, pixel.a);
	} else if (level == 1) {
		COLOR = vec4(palette[found - 8], pixel.a);
	} else {
		COLOR = pixel;
	}
}
"""

static var _material: ShaderMaterial


## The fade's material at [param level] (0 black … 3 whole).
static func material(level: int) -> ShaderMaterial:
	if _material == null:
		var shader := Shader.new()
		shader.code = SHADER
		_material = ShaderMaterial.new()
		_material.shader = shader
		var colors := PackedVector3Array()
		for index in COLORS:
			var color := EgaPalette.color(index)
			colors.append(Vector3(color.r, color.g, color.b))
		_material.set_shader_parameter("palette", colors)
	_material.set_shader_parameter("level", clampi(level, 0, WHOLE))
	return _material


## The colour EGA colour [param index] shows at [param level].
static func faded(index: int, level: int) -> Color:
	if level >= WHOLE:
		return EgaPalette.color(index)
	if level == 0 or (level == 1 and index <= 8) or (level == 2 and index < 8):
		return Color.BLACK
	return EgaPalette.color(index - 8 if level == 1 else index)
