shader_type canvas_item;
// Screen flash overlay — tween alpha for celebration effects.
uniform vec4 flash_color : source_color = vec4(1.0, 0.95, 0.75, 0.0);
uniform float alpha : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	COLOR = vec4(flash_color.rgb, alpha);
}
