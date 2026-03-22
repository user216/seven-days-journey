shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 0.84, 0.0, 1.0);
uniform float outline_width : hint_range(0.0, 10.0) = 2.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a > 0.1) {
		COLOR = tex;
	} else {
		vec2 size = TEXTURE_PIXEL_SIZE * outline_width;
		float a = texture(TEXTURE, UV + vec2(size.x, 0.0)).a;
		a += texture(TEXTURE, UV + vec2(-size.x, 0.0)).a;
		a += texture(TEXTURE, UV + vec2(0.0, size.y)).a;
		a += texture(TEXTURE, UV + vec2(0.0, -size.y)).a;
		if (a > 0.0) {
			COLOR = outline_color;
		} else {
			COLOR = tex;
		}
	}
}
