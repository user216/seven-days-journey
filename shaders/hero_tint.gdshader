shader_type canvas_item;

// Tint colors passed from GDScript — default white = no change
uniform vec4 skin_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 hair_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 dress_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
// Glow intensity (0 = off, 1 = full)
uniform float glow_intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 glow_color : source_color = vec4(1.0, 0.95, 0.8, 1.0);

void fragment() {
	vec4 col = texture(TEXTURE, UV);

	// Skip transparent pixels
	if (col.a < 0.01) {
		COLOR = col;
	} else {
		float r = col.r;
		float g = col.g;
		float b = col.b;
		float mx = max(r, max(g, b));
		float mn = min(r, min(g, b));
		float chroma = mx - mn;

		// Skin detection: warm peach — R > 0.7, R > G > B, moderate chroma
		float skin_score = 0.0;
		if (r > 0.7 && r > g && g > b && chroma > 0.1 && chroma < 0.5) {
			skin_score = smoothstep(0.0, 0.3, r - b) * smoothstep(0.7, 0.85, r);
		}

		// Hair detection: darker brown — R 0.25-0.75, R > G > B, higher chroma
		float hair_score = 0.0;
		if (r > 0.25 && r < 0.75 && r > g && g > b && (r - b) > 0.12) {
			hair_score = smoothstep(0.0, 0.2, r - b) * (1.0 - smoothstep(0.65, 0.8, r));
		}

		// Dress/clothing detection: near-white, high lightness, low saturation
		float dress_score = 0.0;
		float lightness = (mx + mn) * 0.5;
		float sat = (mx > 0.001) ? chroma / mx : 0.0;
		if (lightness > 0.85 && sat < 0.15) {
			dress_score = smoothstep(0.85, 0.95, lightness) * (1.0 - smoothstep(0.0, 0.15, sat));
		}

		// Apply tints — blend based on detection score
		vec3 tinted = col.rgb;
		tinted = mix(tinted, tinted * skin_tint.rgb, skin_score);
		tinted = mix(tinted, tinted * hair_tint.rgb, hair_score);
		tinted = mix(tinted, tinted * dress_tint.rgb, dress_score);

		// Add glow rim
		if (glow_intensity > 0.01) {
			vec2 center_uv = UV - vec2(0.5);
			float dist = length(center_uv);
			float edge = smoothstep(0.25, 0.5, dist);
			tinted += glow_color.rgb * edge * glow_intensity * col.a * 0.4;
		}

		COLOR = vec4(tinted, col.a);
	}
}
