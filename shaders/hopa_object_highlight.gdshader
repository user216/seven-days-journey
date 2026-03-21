shader_type canvas_item;
// Pulsing outline highlight for findable HOPA objects.
// Applied to transparent PNG sprites — draws glowing edge around non-transparent pixels.

uniform vec4 highlight_color : source_color = vec4(0.83, 0.66, 0.26, 0.6);
uniform float pulse_speed : hint_range(0.5, 8.0) = 3.0;
uniform float outline_width : hint_range(1.0, 6.0) = 2.0;
uniform float time_offset : hint_range(0.0, 6.28) = 0.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec2 pixel_size = TEXTURE_PIXEL_SIZE;

	// Sample neighboring pixels to detect edges of non-transparent regions
	float neighbors = 0.0;
	for (float dx = -outline_width; dx <= outline_width; dx += 1.0) {
		for (float dy = -outline_width; dy <= outline_width; dy += 1.0) {
			if (dx == 0.0 && dy == 0.0) continue;
			float dist = length(vec2(dx, dy));
			if (dist > outline_width) continue;
			vec2 offset_uv = UV + vec2(dx, dy) * pixel_size;
			float sample_a = texture(TEXTURE, offset_uv).a;
			neighbors = max(neighbors, sample_a);
		}
	}

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
