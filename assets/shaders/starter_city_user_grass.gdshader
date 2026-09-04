shader_type spatial;
render_mode unshaded;

uniform sampler2D grass_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 grass_tint : source_color = vec3(0.51, 0.84, 0.67);
uniform float texture_strength : hint_range(0.0, 1.0) = 0.94;
uniform float saturation : hint_range(0.0, 1.0) = 0.92;
uniform vec2 tile_count = vec2(96.0, 48.0);


void fragment() {
	// Repeat every tile in the same orientation, rotated 180 degrees.
	vec2 grass_uv = vec2(1.0) - fract(UV * tile_count);
	vec3 painted_grass = texture(grass_texture, grass_uv).rgb;
	float luminance = dot(painted_grass, vec3(0.2126, 0.7152, 0.0722));
	painted_grass = mix(vec3(luminance), painted_grass, saturation);
	ALBEDO = mix(grass_tint, painted_grass, texture_strength);
	ROUGHNESS = 1.0;
}
