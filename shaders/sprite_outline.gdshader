shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 0.84, 0.0, 1.0);
uniform float outline_width : hint_range(0.0, 10.0) = 2.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec2 size = TEXTURE_PIXEL_SIZE * outline_width;

	// Always sample all 4 neighbors (Mali-safe: no texture fetch in non-uniform flow)
	float a = texture(TEXTURE, UV + vec2(size.x, 0.0)).a;
	a += texture(TEXTURE, UV + vec2(-size.x, 0.0)).a;
	a += texture(TEXTURE, UV + vec2(0.0, size.y)).a;
	a += texture(TEXTURE, UV + vec2(0.0, -size.y)).a;

	// Outline: transparent pixel with opaque neighbor
	float is_outline = step(a, 0.0);  // 1.0 if no neighbor, 0.0 if outline candidate
	is_outline = (1.0 - is_outline) * step(tex.a, 0.1);  // has neighbor AND pixel is transparent

	COLOR = mix(tex, outline_color, is_outline);
}
