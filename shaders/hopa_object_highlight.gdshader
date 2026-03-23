shader_type canvas_item;
// Pulsing outline highlight for findable HOPA objects.
// Applied to transparent PNG sprites — draws glowing edge around non-transparent pixels.
// Uses 8 fixed directional samples (Mali-safe: no dynamic loops, no non-uniform branching).

uniform vec4 highlight_color : source_color = vec4(0.83, 0.66, 0.26, 0.6);
uniform float pulse_speed : hint_range(0.5, 8.0) = 3.0;
uniform float outline_width : hint_range(1.0, 6.0) = 2.0;
uniform float time_offset : hint_range(0.0, 6.28) = 0.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec2 ps = TEXTURE_PIXEL_SIZE * outline_width;

	// 8 fixed directional samples — cardinal + diagonal
	float neighbors = 0.0;
	neighbors = max(neighbors, texture(TEXTURE, UV + vec2( ps.x,  0.0)).a);
	neighbors = max(neighbors, texture(TEXTURE, UV + vec2(-ps.x,  0.0)).a);
	neighbors = max(neighbors, texture(TEXTURE, UV + vec2( 0.0,  ps.y)).a);
	neighbors = max(neighbors, texture(TEXTURE, UV + vec2( 0.0, -ps.y)).a);
	neighbors = max(neighbors, texture(TEXTURE, UV + vec2( ps.x,  ps.y) * 0.707).a);
	neighbors = max(neighbors, texture(TEXTURE, UV + vec2(-ps.x,  ps.y) * 0.707).a);
	neighbors = max(neighbors, texture(TEXTURE, UV + vec2( ps.x, -ps.y) * 0.707).a);
	neighbors = max(neighbors, texture(TEXTURE, UV + vec2(-ps.x, -ps.y) * 0.707).a);

	// Edge = neighbor is opaque but current pixel is transparent (or near edge)
	float edge = neighbors * (1.0 - tex.a);

	// Pulsing opacity
	float pulse = 0.5 + 0.5 * sin(TIME * pulse_speed + time_offset);
	float glow_alpha = edge * highlight_color.a * pulse;

	// Combine: original texture + glow outline
	vec3 final_rgb = mix(highlight_color.rgb, tex.rgb, tex.a);
	float final_a = max(tex.a, glow_alpha);
	COLOR = vec4(final_rgb, final_a);
}
