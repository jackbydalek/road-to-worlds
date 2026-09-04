shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec3 deep_color : source_color = vec3(0.224, 0.494, 0.659);
uniform vec3 surface_color : source_color = vec3(0.345, 0.663, 0.824);
uniform vec3 glint_color : source_color = vec3(0.839, 0.945, 0.980);

varying vec3 pond_world_position;


float hash21(vec2 point) {
	point = fract(point * vec2(123.34, 345.45));
	point += dot(point, point + 34.345);
	return fract(point.x * point.y);
}


float value_noise(vec2 point) {
	vec2 cell = floor(point);
	vec2 local = fract(point);
	local = local * local * (3.0 - 2.0 * local);
	return mix(
		mix(hash21(cell), hash21(cell + vec2(1.0, 0.0)), local.x),
		mix(hash21(cell + vec2(0.0, 1.0)), hash21(cell + vec2(1.0, 1.0)), local.x),
		local.y
	);
}


void vertex() {
	pond_world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}


void fragment() {
	vec2 world_uv = pond_world_position.xz;
	float broad_water = value_noise(world_uv * 1.7 + vec2(TIME * 0.025, 0.0));
	float ripple_a = sin((world_uv.x * 1.35 + world_uv.y * 0.72) * 8.0 + TIME * 0.55);
	float ripple_b = sin((world_uv.x * -0.55 + world_uv.y * 1.4) * 9.5 - TIME * 0.38);
	float glint = smoothstep(1.42, 1.82, ripple_a + ripple_b);

	vec3 water = mix(deep_color, surface_color, 0.48 + broad_water * 0.38);
	water = mix(water, glint_color, glint * 0.34);
	ALBEDO = water;
	ROUGHNESS = 0.82;
}
