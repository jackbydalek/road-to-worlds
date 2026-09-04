shader_type spatial;
render_mode depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 wood_base : source_color = vec4(0.384, 0.314, 0.247, 1.0);
uniform vec4 wood_light : source_color = vec4(0.502, 0.416, 0.322, 1.0);
uniform vec4 wood_dark : source_color = vec4(0.212, 0.176, 0.153, 1.0);
uniform float grain_strength : hint_range(0.0, 0.5, 0.01) = 0.30;

float wood_hash(vec2 point) {
	return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453123);
}

float wood_noise(vec2 point) {
	vec2 cell = floor(point);
	vec2 local = fract(point);
	local = local * local * (3.0 - 2.0 * local);
	float a = wood_hash(cell);
	float b = wood_hash(cell + vec2(1.0, 0.0));
	float c = wood_hash(cell + vec2(0.0, 1.0));
	float d = wood_hash(cell + vec2(1.0, 1.0));
	return mix(mix(a, b, local.x), mix(c, d, local.x), local.y);
}

float wood_fbm(vec2 point) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int octave = 0; octave < 4; octave++) {
		value += wood_noise(point) * amplitude;
		point = point * 2.03 + vec2(13.7, 7.1);
		amplitude *= 0.5;
	}
	return value;
}

void fragment() {
	vec2 uv = UV;

	// Stretch the noise heavily along the board length to create restrained,
	// readable grain instead of isotropic procedural speckle.
	float broad_grain = wood_fbm(vec2(uv.x * 2.6, uv.y * 26.0));
	float warped_y = uv.y + (broad_grain - 0.5) * 0.026;
	float fine_grain = wood_fbm(vec2(uv.x * 5.5, warped_y * 72.0));
	float line_grain = sin(warped_y * 280.0 + broad_grain * 10.0) * 0.5 + 0.5;
	float grain = clamp(broad_grain * 0.52 + fine_grain * 0.34 + line_grain * 0.14, 0.0, 1.0);
	float plank_variation = wood_noise(vec2(uv.y * 0.65, 19.0));
	float dark_fiber = pow(1.0 - line_grain, 5.0) * 0.18;
	float irregular_fiber = smoothstep(0.16, 0.42, abs(fine_grain - broad_grain)) * 0.10;

	vec3 color = mix(wood_base.rgb, wood_light.rgb, grain * grain_strength + plank_variation * 0.07);
	color *= mix(0.92, 1.05, plank_variation);
	color = mix(color, wood_dark.rgb, clamp(dark_fiber + irregular_fiber, 0.0, 0.24));

	ALBEDO = color;
	ROUGHNESS = clamp(0.80 + fine_grain * 0.15 + dark_fiber * 0.10, 0.0, 1.0);
	METALLIC = 0.0;
	SPECULAR = 0.16;
}
