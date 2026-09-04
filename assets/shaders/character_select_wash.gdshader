shader_type canvas_item;

uniform float washout : hint_range(0.0, 1.0) = 0.68;
uniform float brightness : hint_range(0.0, 1.2) = 0.58;

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float luma = dot(source.rgb, vec3(0.299, 0.587, 0.114));
	vec3 washed = mix(source.rgb, vec3(luma), washout) * brightness;
	COLOR = vec4(washed, source.a) * COLOR;
}
