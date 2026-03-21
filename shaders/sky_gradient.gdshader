shader_type canvas_item;

uniform vec4 color_top : source_color = vec4(0.05, 0.11, 0.24, 1.0);
uniform vec4 color_bottom : source_color = vec4(0.10, 0.17, 0.37, 1.0);
uniform float star_density : hint_range(0.0, 1.0) = 0.0;

// Simple hash for star positions
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	// 3-band gradient: top → horizon → bottom
	// Horizon band sits at y=0.35 and blends a warm haze
	float y = UV.y;
	vec4 col;
	if (y < 0.35) {
		col = mix(color_top, mix(color_top, color_bottom, 0.5), y / 0.35);
	} else {
		col = mix(mix(color_top, color_bottom, 0.5), color_bottom, (y - 0.35) / 0.65);
	}
	// Horizon haze — warm bright band at the sky-earth transition
	float haze = exp(-pow((y - 0.38) * 4.0, 2.0));
	vec3 haze_color = mix(color_bottom.rgb, vec3(1.0, 0.95, 0.85), 0.3);
	col.rgb = mix(col.rgb, haze_color, haze * 0.25);

	// Stars — only visible when star_density > 0 (night sky)
	if (star_density > 0.01) {
		vec2 grid_size = vec2(60.0, 120.0);
		vec2 grid = floor(UV * grid_size);
		float h = hash(grid);
		if (h > 1.0 - star_density * 0.08) {
			vec2 cell_uv = fract(UV * grid_size) - 0.5;
			float dist = length(cell_uv);
			float star_radius = 0.12 + h * 0.08;
			float star_shape = smoothstep(star_radius, 0.0, dist);

			// Cross-shaped glow on bright stars (h > 0.97)
			float cross_glow = 0.0;
			if (h > 0.97) {
				float glow_x = exp(-abs(cell_uv.y) * 12.0) * exp(-cell_uv.x * cell_uv.x * 30.0);
				float glow_y = exp(-abs(cell_uv.x) * 12.0) * exp(-cell_uv.y * cell_uv.y * 30.0);
				cross_glow = (glow_x + glow_y) * 0.3;
			}

			// Twinkle
			float twinkle = 0.6 + 0.4 * sin(TIME * (2.0 + h * 3.0) + h * 6.28);
			float brightness = (star_shape + cross_glow) * twinkle * star_density;

			// Color temperature varies per star
			vec3 star_color;
			if (h > 0.98) {
				star_color = vec3(0.85, 0.9, 1.0); // blue-white bright stars
			} else if (h > 0.95) {
				star_color = vec3(1.0, 0.95, 0.75); // warm gold
			} else {
				star_color = vec3(0.9, 0.85, 0.8); // neutral warm white
			}

			// Fade stars near horizon (more realistic atmosphere)
			float horizon_fade = smoothstep(0.5, 0.25, y);
			col.rgb += star_color * brightness * horizon_fade;
		}
	}

	COLOR = col;
}
