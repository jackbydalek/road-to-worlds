shader_type spatial;
render_mode unshaded;

uniform sampler2D paving_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 paving_surface_color : source_color = vec3(0.839, 0.855, 0.875);
uniform vec3 paving_joint_color : source_color = vec3(0.655, 0.675, 0.702);
uniform float texture_scale : hint_range(0.1, 4.0) = 0.72;

varying vec3 paving_world_position;


void vertex() {
	paving_world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}


void fragment() {
	// World-space sampling keeps every masonry tile the same size and direction,
	// regardless of the wide ground mesh used to frame the route.
	vec2 paving_uv = fract(paving_world_position.xz * texture_scale);
	vec3 paving_source = texture(paving_texture, paving_uv).rgb;
	float paving_luminance = dot(paving_source, vec3(0.2126, 0.7152, 0.0722));
	ALBEDO = mix(
		paving_joint_color,
		paving_surface_color,
		smoothstep(0.56, 0.84, paving_luminance)
	);
	ROUGHNESS = 1.0;
}
