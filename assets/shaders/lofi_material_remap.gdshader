shader_type spatial;
render_mode unshaded;

uniform sampler2D source_texture : source_color;
uniform vec4 shadow_color : source_color = vec4(0.12, 0.09, 0.18, 1.0);
uniform vec4 mid_color : source_color = vec4(0.46, 0.35, 0.50, 1.0);
uniform vec4 highlight_color : source_color = vec4(0.78, 0.64, 0.70, 1.0);
uniform float midpoint : hint_range(0.2, 0.8) = 0.52;
uniform float material_roughness : hint_range(0.0, 1.0) = 0.88;

void fragment() {
	vec4 source = texture(source_texture, UV);
	float value = dot(source.rgb, vec3(0.299, 0.587, 0.114));
	float lower = smoothstep(0.0, midpoint, value);
	float upper = smoothstep(midpoint, 1.0, value);
	vec3 remapped = mix(shadow_color.rgb, mid_color.rgb, lower);
	remapped = mix(remapped, highlight_color.rgb, upper);
	ALBEDO = remapped;
	ROUGHNESS = material_roughness;
	ALPHA = source.a;
}
