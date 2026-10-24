// The realistic look (RealisticLook; layers A and B of
// docs/realistic/research.md). Light and relief (R3): every game pixel gets
// a slope from the brightness around it, so dark outlines become grooves and
// the things inside them stand out, lit by a light from the upper left;
// lamps, fire and shots light what is around them (lights[]). Atmosphere
// (R2): light that bleeds from bright things (bloom) and turns white where
// it is too bright, as in a photo, a colour grade per game that leaves black
// and white alone, a faint vignette and very fine film grain.
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

// How much the relief changes the light: 0 flat, 1 fully lit by the slope.
uniform float relief_strength = 0.5;
// How steep a step in brightness of one game pixel is.
uniform float relief_bump = 3.0;
// Where the light comes from (x right, y down, z towards the viewer).
uniform vec3 light_direction = vec3(-0.45, -0.6, 0.66);
// The lights near the view (RealisticLights): x, y in game pixels from the
// view's top left, radius, strength; and their colour and height above the
// picture in game pixels.
uniform int light_count = 0;
uniform vec4 lights[16];
uniform vec4 light_colors[16];
// How much a light brightens the air around it, besides what it lights.
uniform float halo = 0.12;

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

// The darkest and the brightest the relief makes a pixel: it never hides
// what the original shows.
const float RELIEF_MIN = 0.75;
const float RELIEF_MAX = 1.3;
// The relief is read at a game pixel and a half, so that a slope is a bevel
// and not a single line.
const float RELIEF_LOD = 0.5;
const int MAX_LIGHTS = 16;

float height(vec2 uv, float lod) {
	return dot(textureLod(screen_texture, uv, lod).rgb, LUMA);
}

// The direction the picture faces at [param uv], from the brightness around
// it: bright is high, dark is low.
vec3 surface_normal(vec2 uv, vec2 game_pixel) {
	float lod = lod_base + RELIEF_LOD;
	float dx = height(uv + vec2(game_pixel.x, 0.0), lod) - height(uv - vec2(game_pixel.x, 0.0), lod);
	float dy = height(uv + vec2(0.0, game_pixel.y), lod) - height(uv - vec2(0.0, game_pixel.y), lod);
	return normalize(vec3(-dx * relief_bump, -dy * relief_bump, 1.0));
}

// How the slope at [param normal] changes the light, 1 on a flat place.
float relief(vec3 normal) {
	vec3 to_light = normalize(light_direction);
	float lit = dot(normal, to_light) / max(to_light.z, 0.1);
	return clamp(mix(1.0, lit, relief_strength), RELIEF_MIN, RELIEF_MAX);
}

// What the lights add at [param point] (game pixels in the view) to a
// surface of [param base] colour facing [param normal].
vec3 lamp_light(vec2 point, vec3 normal, vec3 base) {
	vec3 sum = vec3(0.0);
	for (int index = 0; index < min(light_count, MAX_LIGHTS); index++) {
		vec4 light = lights[index];
		vec2 to_light = light.xy - point;
		float reach = 1.0 - length(to_light) / light.z;
		if (reach <= 0.0) {
			continue;
		}
		float falloff = reach * reach;
		vec3 colour = light_colors[index].rgb;
		vec3 direction = normalize(vec3(to_light, light_colors[index].a));
		float facing = max(dot(normal, direction), 0.0);
		sum += (base * facing + halo * falloff) * colour * light.w * falloff;
	}
	return sum;
}

float hash(vec2 point) {
	return fract(sin(dot(point, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec3 base = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;
	vec2 game_pixel = SCREEN_PIXEL_SIZE * exp2(lod_base);
	vec3 normal = vec3(0.0, 0.0, 1.0);
	if (relief_strength > 0.0) {
		normal = surface_normal(SCREEN_UV, game_pixel);
	}
	vec3 color = base * relief(normal);
	color += lamp_light(SCREEN_UV * view_size, normal, base);
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
