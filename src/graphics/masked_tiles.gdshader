// Draws masked tiles (behavior -2) in front of the sprites through their
// mask: the next tile in the tile atlas, drawn in black and white. Black
// means that the tile's pixel is drawn in front, white that it is
// see-through. Thresholding the mask works on the original pixels as well as
// on xBRZ and HD atlases, whose masks are scaled with the tiles.
//
// The atlas is [LevelTileSet]'s: `columns` cells wide and `rows` cells high,
// every cell the same size, tile n at column n % columns, row n / columns.
shader_type canvas_item;

// The size of the tile atlas in cells.
uniform float columns = 16.0;
uniform float rows = 1.0;
// Whether a see-through pixel of the mask counts as drawn. The atlas behind a
// picture ([LevelBackdrop]) leaves the level's background color out of every
// tile, so a mask loses its black or its white there, where it touches the
// edge of the tile: black when that color is black.
uniform bool holes_drawn = false;

// Below this brightness (or opacity) a mask pixel counts as black (or as a hole).
const float THRESHOLD = 0.5;
const vec3 LUMINANCE = vec3(0.299, 0.587, 0.114);

void fragment() {
	// The next cell; after the last column it is the first one of the next row.
	float column = floor(UV.x * columns);
	vec2 to_mask = column < columns - 1.0
		? vec2(1.0 / columns, 0.0)
		: vec2((1.0 - columns) / columns, 1.0 / rows);
	vec4 mask = texture(TEXTURE, UV + to_mask);
	bool drawn = mask.a < THRESHOLD ? holes_drawn : dot(mask.rgb, LUMINANCE) < THRESHOLD;
	if (!drawn) {
		discard;
	}
}
