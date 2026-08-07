shader_type spatial;
render_mode unshaded, cull_disabled;

// Recolors the real storefront atlas swatches. The building is one combined
// mesh, so matching its authored palette is the precise way to change glass,
// door, and trim faces without adding overlay geometry.
uniform sampler2D source_texture : source_color, filter_nearest_mipmap;

uniform vec4 source_window_sky : source_color = vec4(0.459, 0.906, 1.0, 1.0);
uniform vec4 source_window_mint : source_color = vec4(0.808, 0.980, 1.0, 1.0);
uniform vec4 source_frame : source_color = vec4(0.157, 0.039, 0.118, 1.0);
uniform vec4 source_frame_shadow : source_color = vec4(0.196, 0.086, 0.137, 1.0);
uniform vec4 source_door : source_color = vec4(0.329, 0.369, 0.459, 1.0);

uniform vec4 window_sky : source_color = vec4(0.557, 0.663, 0.902, 1.0);
uniform vec4 window_blush : source_color = vec4(0.949, 0.643, 0.722, 1.0);
uniform vec4 frame_ink : source_color = vec4(0.161, 0.212, 0.373, 1.0);
uniform vec4 frame_secondary : source_color = vec4(0.325, 0.384, 0.541, 1.0);
uniform vec4 door_color : source_color = vec4(0.651, 0.604, 0.718, 1.0);

varying vec3 model_position;

void vertex() {
	model_position = VERTEX;
}

float swatch_match(vec3 color, vec3 source) {
	return 1.0 - smoothstep(0.018, 0.075, distance(color, source));
}

vec3 replace_swatch(vec3 color, vec3 source, vec3 target) {
	float match_amount = swatch_match(color, source);
	return mix(color, target, match_amount);
}

void fragment() {
	vec3 source = texture(source_texture, UV).rgb;
	vec3 color = source;
	color = replace_swatch(color, source_window_sky.rgb, window_sky.rgb);
	color = replace_swatch(color, source_window_mint.rgb, window_blush.rgb);
	color = replace_swatch(color, source_frame.rgb, frame_ink.rgb);
	color = replace_swatch(color, source_frame_shadow.rgb, frame_secondary.rgb);
	color = replace_swatch(color, source_door.rgb, door_color.rgb);

	// The authored door lives on the positive-X end of this combined mesh.
	// Keep its slate body solid lavender, while allowing the two glass swatches
	// inside that body to retain the same blush/periwinkle window treatment.
	float door_face = swatch_match(source, source_door.rgb);
	float door_region = step(180.0, model_position.x);
	color = mix(color, door_color.rgb, door_face * door_region);

	ALBEDO = color;
	ROUGHNESS = 0.94;
	METALLIC = 0.0;
}
