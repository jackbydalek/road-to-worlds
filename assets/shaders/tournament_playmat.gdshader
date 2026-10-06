shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 fabric_base : source_color;
uniform vec4 fabric_light : source_color;
uniform float weave_scale = 640.0;
uniform float weave_strength = 0.048;

float fiber_hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float cloth_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 local = fract(p);
	vec2 blend = local * local * (3.0 - 2.0 * local);
	return mix(mix(fiber_hash(cell), fiber_hash(cell + vec2(1.0, 0.0)), blend.x),
		mix(fiber_hash(cell + vec2(0.0, 1.0)), fiber_hash(cell + vec2(1.0, 1.0)), blend.x), blend.y);
}

void fragment() {
	vec2 rounded_edge = max(abs(UV - vec2(0.5)) - vec2(0.482), vec2(0.0));
	if (length(rounded_edge) > 0.018) { discard; }
	// A tightly woven, matte charcoal cloth. The weave fades below pixel scale
	// rather than becoming a bright grid or flickering over the distant slots.
	vec2 threads = UV * weave_scale;
	float footprint = max(length(dFdx(threads)), length(dFdy(threads)));
	float thread_visibility = 1.0 - smoothstep(0.26, 0.85, footprint);
	float warp = sin(threads.x * 6.283185);
	float weft = sin(threads.y * 6.283185);
	float weave = (warp * weft) * thread_visibility;
	float fiber = cloth_noise(UV * 190.0) - 0.5;
	float soft_wear = cloth_noise(UV * 19.0) - 0.5;
	vec3 cloth = mix(fabric_base.rgb, fabric_light.rgb, 0.19 + fiber * 0.08);
	ALBEDO = cloth * (1.0 + weave * weave_strength + fiber * 0.026 + soft_wear * 0.022);
	ROUGHNESS = 1.0;
	SPECULAR = 0.035;
	METALLIC = 0.0;
}
