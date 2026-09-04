shader_type spatial;
render_mode unshaded, cull_disabled, depth_prepass_alpha;

uniform float connect_west : hint_range(0.0, 1.0) = 0.0;
uniform float connect_east : hint_range(0.0, 1.0) = 0.0;
uniform float connect_north : hint_range(0.0, 1.0) = 0.0;
uniform float connect_south : hint_range(0.0, 1.0) = 0.0;
uniform float path_half_width : hint_range(0.18, 0.48) = 0.36;
uniform float edge_width : hint_range(0.01, 0.12) = 0.055;
uniform vec3 surface_color : source_color = vec3(0.792, 0.847, 0.898);
uniform vec3 highlight_color : source_color = vec3(0.902, 0.933, 0.957);
uniform vec3 edge_color : source_color = vec3(0.529, 0.592, 0.651);
uniform vec3 fleck_color : source_color = vec3(0.682, 0.737, 0.784);
uniform vec3 motif_color : source_color = vec3(0.702, 0.761, 0.812);

varying vec3 path_world_position;


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


float path_distance(vec2 point, float half_width) {
	// A circular center joins any active arms into soft corners and also gives
	// one-way streets the rounded endpoints used by the illustrated reference.
	float distance_to_path = length(point) - half_width;
	if (connect_west > 0.5) {
		distance_to_path = min(distance_to_path, max(abs(point.y) - half_width, point.x));
	}
	if (connect_east > 0.5) {
		distance_to_path = min(distance_to_path, max(abs(point.y) - half_width, -point.x));
	}
	if (connect_north > 0.5) {
		distance_to_path = min(distance_to_path, max(abs(point.x) - half_width, point.y));
	}
	if (connect_south > 0.5) {
		distance_to_path = min(distance_to_path, max(abs(point.x) - half_width, -point.y));
	}
	return distance_to_path;
}


void vertex() {
	path_world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}


void fragment() {
	vec2 point = UV - vec2(0.5);
	float inner_distance = path_distance(point, path_half_width);
	float outer_distance = path_distance(point, path_half_width + edge_width);
	float antialias_width = max(fwidth(outer_distance) * 1.35, 0.0015);
	float outer_coverage = 1.0 - smoothstep(-antialias_width, antialias_width, outer_distance);
	float inner_coverage = 1.0 - smoothstep(-antialias_width, antialias_width, inner_distance);

	vec2 world_uv = path_world_position.xz;
	float broad_wear = value_noise(world_uv * 1.8);
	float fine_wear = value_noise(world_uv * 8.5);
	vec3 path_surface = mix(surface_color, highlight_color, 0.12 + broad_wear * 0.22);
	path_surface = mix(path_surface, edge_color, (fine_wear - 0.5) * 0.09 + 0.045);

	float fleck = step(0.955, hash21(floor(world_uv * 13.0)));
	float tiny_fleck = step(0.982, hash21(floor((world_uv + vec2(8.7, 3.1)) * 23.0)));
	path_surface = mix(path_surface, fleck_color, fleck * 0.12 + tiny_fleck * 0.08);

	// A quiet diamond-and-dot cadence suggests the reference's patterned city
	// paving without copying its exact protected tile art.
	vec2 motif_uv = fract(world_uv * 1.18) - vec2(0.5);
	float diamond_distance = abs(motif_uv.x) + abs(motif_uv.y);
	float diamond = 1.0 - smoothstep(0.018, 0.038, abs(diamond_distance - 0.16));
	float center_dot = 1.0 - smoothstep(0.025, 0.055, length(motif_uv));
	float motif = max(diamond * 0.62, center_dot * 0.48);
	path_surface = mix(path_surface, motif_color, motif * 0.28);

	ALBEDO = mix(edge_color, path_surface, inner_coverage);
	ROUGHNESS = 1.0;
	ALPHA = outer_coverage;
	ALPHA_SCISSOR_THRESHOLD = 0.02;
}
