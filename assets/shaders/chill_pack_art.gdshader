shader_type canvas_item;

// Packaging is intentionally calmer than the collectible card faces. Keep the
// original illustration and linework, but pull it into the café's paper/glass
// palette so the wrapper reads as a product prop instead of a neon focal point.
uniform float saturation : hint_range(0.0, 1.0) = 0.42;
uniform float contrast : hint_range(0.5, 1.5) = 0.88;
uniform float paper_wash : hint_range(0.0, 0.35) = 0.15;
uniform vec4 wash_color : source_color = vec4(0.91, 0.89, 0.96, 1.0);

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float luminance = dot(source.rgb, vec3(0.299, 0.587, 0.114));
	vec3 muted = mix(vec3(luminance), source.rgb, saturation);
	muted = (muted - vec3(0.5)) * contrast + vec3(0.5);
	muted = mix(muted, wash_color.rgb, paper_wash);
	COLOR = vec4(muted, source.a) * COLOR;
}
