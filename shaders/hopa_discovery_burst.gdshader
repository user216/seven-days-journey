shader_type canvas_item;
// Radial burst effect when a hidden object is found.
// Applied to a fullscreen ColorRect. Drive "progress" via Tween (0.0 → 1.0).

uniform vec2 center = vec2(0.5, 0.5);
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 burst_color : source_color = vec4(0.83, 0.66, 0.26, 0.4);
uniform float ring_width : hint_range(0.01, 0.15) = 0.05;

void fragment() {
	float ring_radius = progress * 0.8;
	float dist = length(UV - center);

	// Ring band
	float inner = ring_radius - ring_width * 0.5;
	float outer = ring_radius + ring_width * 0.5;
	float ring = smoothstep(inner - 0.02, inner, dist) * (1.0 - smoothstep(outer, outer + 0.02, dist));

	// Fade as ring expands
	float fade = (1.0 - progress) * burst_color.a;

	// Subtle golden tint inside the ring
	float inner_tint = smoothstep(ring_radius, 0.0, dist) * 0.1 * (1.0 - progress);

	float alpha = ring * fade + inner_tint;
	COLOR = vec4(burst_color.rgb, alpha);
}
