shader_type canvas_item;

// Lift only painted pixels; preserve the supplied alpha and character contour.
uniform vec4 highlight_color : source_color = vec4(1.0);
uniform float highlight_strength : hint_range(0.0, 1.0) = 0.0;
uniform float highlight_start_y = 0.0;

void fragment() {
	float amount = highlight_strength * 0.28 * step(highlight_start_y, UV.y);
	COLOR.rgb = mix(COLOR.rgb, highlight_color.rgb, amount);
}
