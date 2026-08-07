shader_type spatial;
render_mode unshaded, cull_disabled;

// The source character is authored against a tiny indexed palette. Its PNG
// also stores Blender-specific transparency, which Godot interpreted as a
// nearly white ghost. Sample only the RGB swatch and paint it opaquely into
// the same illustrated colors used by the rest of the shop.
uniform sampler2D source_texture : source_color, filter_nearest;
uniform vec4 ink : source_color = vec4(0.161, 0.212, 0.373, 1.0);
uniform vec4 cream : source_color = vec4(1.0, 0.969, 0.945, 1.0);
uniform vec4 blush : source_color = vec4(0.949, 0.643, 0.722, 1.0);
uniform vec4 sage : source_color = vec4(0.510, 0.588, 0.435, 1.0);

void fragment() {
	vec3 swatch = texture(source_texture, UV).rgb;
	float value = max(swatch.r, max(swatch.g, swatch.b));
	vec3 painted = cream.rgb;

	if (value < 0.18) {
		painted = ink.rgb;
	} else if (swatch.r > swatch.g * 1.08) {
		painted = blush.rgb;
	} else if (swatch.g > swatch.r * 1.05) {
		painted = mix(sage.rgb, ink.rgb, 0.28);
	} else if (value < 0.48) {
		painted = ink.rgb;
	}

	ALBEDO = painted;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
}
