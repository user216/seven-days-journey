shader_type canvas_item;
// Noise dissolve transition — hash-based pixel dissolve.
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float softness : hint_range(0.0, 0.3) = 0.1;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 grid = floor(UV * 80.0);
	float noise = hash(grid);
	float a = smoothstep(progress - softness, progress + softness, noise);
	a = 1.0 - a;
	COLOR = vec4(0.0, 0.0, 0.0, a);
}
