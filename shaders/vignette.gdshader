shader_type canvas_item;
// Vignette overlay — darkens edges with time-of-day color adaptation.
// Portrait-aware aspect ratio correction.

uniform float intensity : hint_range(0.0, 1.0) = 0.4;
uniform float softness : hint_range(0.0, 2.0) = 0.7;
uniform vec4 vignette_color : source_color = vec4(0.0, 0.05, 0.02, 1.0);
uniform float time_factor : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	// Correct for portrait aspect ratio (1080x1920)
	vec2 centered = (UV - 0.5) * 2.0;
	centered.y *= 0.5625; // 1080/1920 correction — makes vignette oval, not circular
	float dist = length(centered);
	float vignette = smoothstep(1.0 - softness, 1.0 + softness * 0.2, dist);

	// Shift vignette color by time of day
	vec3 tint;
	if (time_factor < 0.1) {
		// Night — deep blue-black
		tint = vec3(0.02, 0.02, 0.08);
	} else if (time_factor < 0.2) {
		// Dawn — warm amber edge
		float t = (time_factor - 0.1) / 0.1;
		tint = mix(vec3(0.02, 0.02, 0.08), vec3(0.15, 0.08, 0.02), t);
	} else if (time_factor < 0.75) {
		// Day — subtle green-brown (nature)
		tint = vignette_color.rgb;
	} else if (time_factor < 0.9) {
		// Sunset — warm orange edge
		float t = (time_factor - 0.75) / 0.15;
		tint = mix(vignette_color.rgb, vec3(0.12, 0.05, 0.01), t);
	} else {
		// Night
		tint = vec3(0.02, 0.02, 0.08);
	}

	COLOR = vec4(tint, vignette * intensity);
}
