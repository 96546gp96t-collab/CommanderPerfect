// Shows player 2's half of a split screen on top of player 1's picture,
// with a dark line between the halves (see SplitScreen). Everything on
// player 1's side of the line is left transparent.
shader_type canvas_item;

// Size of the view in game pixels.
uniform vec2 view_size = vec2(426.0, 200.0);
// Unit vector from player 1 to player 2: player 2's half is on this side.
uniform vec2 normal = vec2(1.0, 0.0);
uniform float line_width = 2.0;
uniform vec4 line_color : source_color = vec4(0.0, 0.0, 0.0, 0.85);
// 0 hides the line, 1 shows it fully.
uniform float line_strength = 1.0;

void fragment() {
	vec2 point = UV * view_size - view_size * 0.5;
	float side = dot(point, normal);
	vec4 picture = texture(TEXTURE, UV);
	float line_alpha = line_color.a * line_strength;
	if (abs(side) < line_width * 0.5) {
		if (side >= 0.0) {
			COLOR = vec4(mix(picture.rgb, line_color.rgb, line_alpha), 1.0);
		} else {
			COLOR = vec4(line_color.rgb, line_alpha);
		}
	} else if (side > 0.0) {
		COLOR = picture;
	} else {
		COLOR = vec4(0.0);
	}
}
