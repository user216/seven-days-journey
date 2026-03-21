shader_type canvas_item;
// Circle iris wipe — expands or contracts a circular cutout.
// progress: 0.0 = fully visible, 1.0 = fully black

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec2 center = vec2(0.5, 0.5);
uniform float softness : hint_range(0.0, 0.2) = 0.04;

void fragment() {
	// Correct for portrait aspect ratio
	vec2 uv = UV;
	uv.y *= 1920.0 / 1080.0;  // stretch to make circle not oval
	vec2 c = center;
	c.y *= 1920.0 / 1080.0;

	float dist = length(uv - c);
	// Max radius to cover corners from center
	float max_radius = 1.5;
	float radius = max_radius * (1.0 - progress);
	float alpha = smoothstep(radius, radius - softness, dist);
	COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
