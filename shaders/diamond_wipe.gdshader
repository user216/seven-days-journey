shader_type canvas_item;
// Diamond wipe transition — Manhattan distance creates diamond shape.
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float softness : hint_range(0.0, 0.2) = 0.04;

void fragment() {
	vec2 uv = UV;
	// Aspect correction for portrait
	uv.y *= 1920.0 / 1080.0;
	vec2 c = vec2(0.5, 0.5 * 1920.0 / 1080.0);
	float dist = abs(uv.x - c.x) + abs(uv.y - c.y);
	float max_radius = 2.0;
	float radius = max_radius * (1.0 - progress);
	float a = smoothstep(radius, radius - softness, dist);
	COLOR = vec4(0.0, 0.0, 0.0, a);
}
