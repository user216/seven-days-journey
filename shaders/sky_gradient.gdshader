shader_type canvas_item;

uniform vec4 color_top : source_color = vec4(0.05, 0.11, 0.24, 1.0);
uniform vec4 color_bottom : source_color = vec4(0.10, 0.17, 0.37, 1.0);
uniform float star_density : hint_range(0.0, 1.0) = 0.0;

// Simple hash for star positions
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	// Smooth vertical gradient
	vec4 col = mix(color_top, color_bottom, UV.y);

	// Stars — only visible when star_density > 0 (night sky)
	if (star_density > 0.01) {
		vec2 grid = floor(UV * vec2(60.0, 120.0));
		float h = hash(grid);
		if (h > 1.0 - star_density * 0.08) {
			// Twinkle using TIME
			float twinkle = 0.6 + 0.4 * sin(TIME * (2.0 + h * 3.0) + h * 6.28);
			float brightness = h * twinkle * star_density;
			// Slightly warm white for stars
			col.rgb += vec3(brightness * 0.9, brightness * 0.85, brightness);
		}
	}

	COLOR = col;
}
