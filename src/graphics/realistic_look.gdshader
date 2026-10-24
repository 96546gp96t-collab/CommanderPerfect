// The atmosphere of the realistic mode (RealisticLook; layer A of
// docs/realistic/research.md): light that bleeds from bright things
// (bloom) and turns white where it is too bright, as in a photo, a colour
// grade per game that leaves black and white alone, a faint vignette and
// very fine film grain.
// Drawn over the level, below the HUD and the windows, so that text stays as
// it is.
shader_type canvas_item;
render_mode unshaded;

// Mipmaps give the bloom its blur cheaply; they are made from the World
// viewport, which is render_scale times larger than the game picture.
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
// log2 of the viewport's screen pixels per game pixel: mip level
// lod_base + n is blurred over 2^n game pixels at every window size.
uniform float lod_base = 1.0;
// Size of the view in game pixels, for a round vignette.
uniform vec2 view_size = vec2(426.0, 200.0);

uniform float bloom_strength = 0.45;
// 0 leaves the bloom out, on a computer too slow for it.
uniform int bloom_levels = 4;
// Brightness (0-1) from which a colour starts to glow.
uniform float bloom_threshold = 0.7;
uniform vec3 shadow_tint = vec3(1.0);
uniform vec3 highlight_tint = vec3(1.0);
// Raises black a little, in the colour of the shadows.
uniform float lift = 0.02;
uniform float saturation = 1.0;
// 0 keeps the tones; 1 is a full S-curve.
uniform float contrast = 0.12;
uniform float vignette = 0.18;
uniform float grain = 0.012;

const vec3 LUMA = vec3(0.2126, 0.7152, 0.0722);
// How much of the light beyond white goes into the other channels.
const float BURN = 0.5;
// Blur levels of the bloom, in doublings of a game pixel, and their weights.
const int BLOOM_LEVELS = 4;
const float BLOOM_WEIGHTS[4] = { 0.35, 0.3, 0.2, 0.15 };
// How much of [param color] glows: none below the threshold, then softly
// more. By brightness as the eye sees it, so that a large field of a
// saturated colour (the world map's light red) does not glow.
vec3 bright_part(vec3 color) {
	float glow = smoothstep(bloom_threshold, 1.0, dot(color, LUMA));
	return color * glow;
}

// One tap per level: the levels blend into each other, and the glow is
// smooth enough without more (each tap costs a lot on a slow GPU).
vec3 bloom(vec2 uv) {
	vec3 sum = vec3(0.0);
	for (int level = 0; level < min(bloom_levels, BLOOM_LEVELS); level++) {
		float lod = lod_base + float(level + 1);
		sum += bright_part(textureLod(screen_texture, uv, lod).rgb) * BLOOM_WEIGHTS[level];
	}
	return sum;
}

// Light beyond white spills into the other channels, the way an
// overexposed part of a photo turns white.
vec3 burn_out(vec3 color) {
	float excess = max(max(color.r, max(color.g, color.b)) - 1.0, 0.0);
	return min(color, vec3(1.0)) + vec3(excess * BURN);
}

float hash(vec2 point) {
	return fract(sin(dot(point, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec3 color = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;
	color += bloom(SCREEN_UV) * bloom_strength;
	color = burn_out(color);
	// The tints weigh most in the dark and the middle tones; black and
	// white stay neutral, so the EGA colours keep their look.
	float luma = dot(color, LUMA);
	float shadows = 1.0 - smoothstep(0.0, 0.5, luma);
	float middle = 4.0 * luma * (1.0 - luma);
	color *= mix(vec3(1.0), shadow_tint, shadows) * mix(vec3(1.0), highlight_tint, middle);
	color = mix(vec3(dot(color, LUMA)), color, saturation);
	color = mix(color, smoothstep(0.0, 1.0, color), contrast);
	color = lift * shadow_tint + color * (1.0 - lift);
	vec2 from_center = (SCREEN_UV - 0.5) * vec2(view_size.x / view_size.y, 1.0);
	color *= 1.0 - vignette * smoothstep(0.35, 1.0, length(from_center) * 1.1);
	color += (hash(FRAGCOORD.xy + fract(TIME) * 61.0) - 0.5) * grain;
	COLOR = vec4(clamp(color, 0.0, 1.0), 1.0);
}
