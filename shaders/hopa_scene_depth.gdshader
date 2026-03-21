shader_type canvas_item;
// Atmospheric depth effect for HOPA scene backgrounds.
// Adds vignette, warm light source, bottom fog, and dust shimmer.

uniform vec4 fog_color : source_color = vec4(0.99, 0.98, 0.95, 1.0);
uniform float fog_density : hint_range(0.0, 0.5) = 0.15;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.3;
uniform vec2 light_position = vec2(0.5, 0.2);
uniform float light_radius : hint_range(0.1, 1.0) = 0.4;
uniform float light_intensity : hint_range(0.0, 0.5) = 0.2;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	// 1. Vignette — darken edges
	vec2 centered = (UV - 0.5) * 2.0;
	centered.y *= 0.5625; // portrait aspect correction
	float dist = length(centered);
	float vignette = smoothstep(0.6, 1.4, dist) * vignette_strength;

	// 2. Warm light glow from light source position
	float light_dist = length(UV - light_position);
	float light_glow = smoothstep(light_radius, 0.0, light_dist) * light_intensity;
	vec3 light_color = vec3(1.0, 0.95, 0.85); // warm white

	// 3. Bottom fog — increases toward bottom of screen (depth illusion)
	float fog_amount = UV.y * UV.y * fog_density;
	vec3 fog = fog_color.rgb * fog_amount;

	// 4. Dust shimmer in light beam area
	float shimmer = sin(UV.x * 80.0 + TIME * 1.5) * sin(UV.y * 60.0 + TIME * 0.8);
	shimmer = max(0.0, shimmer) * 0.03;
	float in_light = smoothstep(light_radius * 1.5, 0.0, light_dist);
	shimmer *= in_light;

	// Combine
	vec3 result = tex.rgb;
	result += light_color * light_glow;       // warm glow
	result += vec3(shimmer);                    // dust particles
	result = mix(result, fog_color.rgb, fog_amount); // bottom fog
	result *= (1.0 - vignette);                // edge darkening

	COLOR = vec4(result, tex.a);
}
