shader_type canvas_item;
render_mode unshaded;

uniform vec4 cream : source_color = vec4(1.0, 0.969, 0.945, 1.0);
uniform vec4 lavender : source_color = vec4(0.91, 0.89, 0.96, 1.0);
uniform vec4 blush : source_color = vec4(0.984, 0.898, 0.925, 1.0);
uniform vec4 sky : source_color = vec4(0.84, 0.93, 0.98, 1.0);

float soft_field(vec2 uv, vec2 center, float radius) {
	return 1.0 - smoothstep(radius * 0.18, radius, distance(uv, center));
}

void fragment() {
	vec3 result = cream.rgb;
	float lavender_field = soft_field(UV, vec2(0.93, 0.08), 0.78);
	float blush_field = soft_field(UV, vec2(0.08, 0.96), 0.72);
	float sky_field = soft_field(UV, vec2(-0.08, 0.18), 0.58);
	result = mix(result, lavender.rgb, lavender_field * 0.58);
	result = mix(result, blush.rgb, blush_field * 0.44);
	result = mix(result, sky.rgb, sky_field * 0.22);
	COLOR = vec4(result, 1.0);
}
