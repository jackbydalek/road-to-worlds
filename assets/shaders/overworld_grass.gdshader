shader_type spatial;
render_mode diffuse_burley, specular_disabled;

uniform sampler2D grass_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 grass_tint : source_color = vec3(0.51, 0.59, 0.44);
uniform float texture_strength : hint_range(0.0, 1.0) = 0.72;
uniform float saturation : hint_range(0.0, 1.0) = 0.78;
uniform vec2 tile_count = vec2(12.0, 6.0);


vec2 mirrored_tile_uv(vec2 tiled_uv) {
	// Alternating mirrored tiles keep the supplied painting continuous at each
	// boundary instead of exposing the photograph's non-seamless edges.
	vec2 paired_uv = mod(tiled_uv, vec2(2.0));
	return vec2(1.0) - abs(paired_uv - vec2(1.0));
}


void fragment() {
	vec3 painted_grass = texture(grass_texture, mirrored_tile_uv(UV * tile_count)).rgb;
	float luminance = dot(painted_grass, vec3(0.2126, 0.7152, 0.0722));
	painted_grass = mix(vec3(luminance), painted_grass, saturation);
	ALBEDO = mix(grass_tint, painted_grass, texture_strength);
	ROUGHNESS = 0.95;
}
