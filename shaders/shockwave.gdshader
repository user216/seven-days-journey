shader_type canvas_item;

uniform vec2 center = vec2(0.5, 0.5);
uniform float force : hint_range(0.0, 0.1) = 0.03;
uniform float size : hint_range(0.0, 1.5) = 0.0;
uniform float thickness : hint_range(0.0, 0.3) = 0.1;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec2 uv = SCREEN_UV;
	float dist = distance(uv, center);
	if (dist > size - thickness && dist < size + thickness) {
		float diff = (dist - size) / thickness;
		float displacement = force * smoothstep(1.0, 0.0, abs(diff));
		uv += normalize(uv - center) * displacement;
	}
	COLOR = texture(screen_tex, uv);
}
