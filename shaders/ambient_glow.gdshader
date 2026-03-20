shader_type canvas_item;
// Ambient glow for nature elements — soft radial glow behind objects

uniform vec4 glow_color : source_color = vec4(0.95, 0.9, 0.7, 0.3);
uniform float radius : hint_range(0.0, 2.0) = 1.0;

void fragment() {
	vec2 centered = (UV - 0.5) * 2.0;
	float dist = length(centered);
	float glow = smoothstep(radius, 0.0, dist);
	COLOR = vec4(glow_color.rgb, glow_color.a * glow * glow);
}
