// Stretches the game picture to the window with every game pixel the same
// size, also when the window is not a whole number of times as large.
// Inside a game pixel the color is flat; only the one screen pixel where two
// game pixels meet gets a mix of both (needs linear filtering on the
// texture). Without this, nearest filtering makes some game pixels one
// screen pixel wider or taller than others.
shader_type canvas_item;

// The vertex color, which carries the modulate of the node (used to fade).
varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec2 texel = UV / TEXTURE_PIXEL_SIZE;
	vec2 seam = floor(texel + 0.5);
	// How many game pixels one screen pixel covers.
	vec2 footprint = max(fwidth(texel), vec2(1e-5));
	vec2 offset = clamp((texel - seam) / footprint, -0.5, 0.5);
	COLOR = texture(TEXTURE, (seam + offset) * TEXTURE_PIXEL_SIZE) * tint;
}
