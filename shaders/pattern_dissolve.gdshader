shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float smoothness : hint_range(0.0, 1.0) = 0.1;
uniform bool inverted = false;
uniform sampler2D pattern_texture : hint_default_white;

void fragment() {
	float p = texture(pattern_texture, UV).r;
	if (inverted) {
		p = 1.0 - p;
	}
	float alpha = smoothstep(progress - smoothness, progress + smoothness, p);
	COLOR = vec4(0.0, 0.0, 0.0, 1.0 - alpha);
}
