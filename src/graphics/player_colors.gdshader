// Draws a sprite in other colors by turning every hue around the color
// wheel, so that player 2's Keen looks different from player 1's. Gray,
// black and white stay as they are. Works on the original pixels as well as
// on xBRZ and HD graphics.
shader_type canvas_item;

// How far to turn the hues: 0.5 is half way around the wheel.
uniform float hue_shift = 0.5;

// The vertex color, which carries the modulate of the node.
varying vec4 tint;

void vertex() {
	tint = COLOR;
}

vec3 rgb_to_hsv(vec3 c) {
	vec4 k = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, k.wz), vec4(c.gb, k.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv_to_rgb(vec3 c) {
	vec3 p = abs(fract(c.xxx + vec3(1.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0);
	return c.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), c.y);
}

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	vec3 hsv = rgb_to_hsv(color.rgb);
	hsv.x = fract(hsv.x + hue_shift);
	COLOR = vec4(hsv_to_rgb(hsv), color.a) * tint;
}
