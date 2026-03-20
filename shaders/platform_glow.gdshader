shader_type canvas_item;
// Platform glow effect — rounded rectangle with soft emission

uniform vec4 glow_color : source_color = vec4(0.83, 0.66, 0.26, 0.5);
uniform float glow_radius : hint_range(0.0, 1.0) = 0.3;
uniform float pulse : hint_range(0.0, 2.0) = 1.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	// Distance from center for glow falloff
	vec2 centered = (UV - 0.5) * 2.0;
	float edge_dist = max(abs(centered.x), abs(centered.y));
	float glow = smoothstep(1.0, 1.0 - glow_radius, edge_dist);
	vec4 glow_layer = vec4(glow_color.rgb, glow_color.a * glow * pulse);
	COLOR = mix(tex, tex + glow_layer, glow);
}
