// Draws the wall behind a level's tiles ([LevelWall]): the wall's texture,
// repeated and fixed to the level (one texel per game pixel, at the same
// place in the level however the view moves), through the wall's mask in
// the tile atlas. The mask is grey where the wall is drawn, as bright as
// it is drawn there (lit, in the dark, in a shadow), and transparent where
// the tile itself or the sky shows.
shader_type canvas_item;

uniform sampler2D wall_texture : repeat_enable, filter_nearest;

// Below this opacity a mask pixel is not part of the wall.
const float THRESHOLD = 0.5;

// Where the pixel is in the level, in game pixels.
varying vec2 level_position;

void vertex() {
	// The model matrix holds the place of the tile map's quadrant; the
	// camera is applied after it, so this does not move with the view.
	level_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec4 mask = texture(TEXTURE, UV);
	if (mask.a < THRESHOLD) {
		discard;
	}
	vec2 size = vec2(textureSize(wall_texture, 0));
	COLOR = vec4(texture(wall_texture, level_position / size).rgb * mask.rgb, 1.0);
}
