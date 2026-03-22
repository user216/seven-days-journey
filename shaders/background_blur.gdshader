shader_type canvas_item;
// 5-tap box blur for popup background dimming.
// Apply to a ColorRect with BackBufferCopy as copy source.
uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear;
uniform float blur_amount : hint_range(0.0, 5.0) = 0.0;

void fragment() {
	vec2 ps = SCREEN_PIXEL_SIZE * blur_amount;
	vec4 col = texture(screen_tex, SCREEN_UV);
	col += texture(screen_tex, SCREEN_UV + vec2(ps.x, 0.0));
	col += texture(screen_tex, SCREEN_UV - vec2(ps.x, 0.0));
	col += texture(screen_tex, SCREEN_UV + vec2(0.0, ps.y));
	col += texture(screen_tex, SCREEN_UV - vec2(0.0, ps.y));
	col /= 5.0;
	// Combine with the dimmer's own alpha
	COLOR = vec4(col.rgb * (1.0 - COLOR.a) + COLOR.rgb * COLOR.a, COLOR.a);
}
