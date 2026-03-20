shader_type canvas_item;
// Vignette overlay — darkens edges of screen for cinematic feel

uniform float intensity : hint_range(0.0, 1.0) = 0.4;
uniform float softness : hint_range(0.0, 2.0) = 0.7;
uniform vec4 vignette_color : source_color = vec4(0.0, 0.05, 0.02, 1.0);

void fragment() {
	vec2 centered = (UV - 0.5) * 2.0;
	float dist = length(centered);
	float vignette = smoothstep(1.0 - softness, 1.0 + softness * 0.2, dist);
	COLOR = vec4(vignette_color.rgb, vignette * intensity);
}
