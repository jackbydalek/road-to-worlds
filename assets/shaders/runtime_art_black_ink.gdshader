shader_type canvas_item;

// Existing illustrations use a cool navy drawing ink. Preserve every fill
// color while remapping only dark, blue-biased pixels toward true black.
uniform vec4 ink_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);


void fragment() {
	vec4 sample_color = texture(TEXTURE, UV);
	float value = max(sample_color.r, max(sample_color.g, sample_color.b));
	float blue_bias = sample_color.b - max(sample_color.r, sample_color.g);
	float dark_mask = 1.0 - smoothstep(0.34, 0.52, value);
	float navy_mask = smoothstep(0.025, 0.11, blue_bias) * dark_mask * sample_color.a;
	sample_color.rgb = mix(sample_color.rgb, ink_color.rgb, navy_mask);
	COLOR = sample_color;
}
