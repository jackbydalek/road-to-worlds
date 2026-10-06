shader_type canvas_item;

// An exterior paper edge around the original alpha silhouette. No source
// pixels are repainted, and vertex color retains inherited/local UI fades.
uniform vec4 edge_color : source_color = vec4(1.0, 0.957, 0.875, 1.0);
uniform float edge_width_pixels : hint_range(0.0, 32.0) = 7.0;
varying vec4 portrait_modulate;


void vertex() {
	portrait_modulate = COLOR;
}


void fragment() {
	vec4 original = texture(TEXTURE, UV);
	float silhouette_alpha = original.a;
	for (int i = 0; i < 12; i++) {
		float angle = float(i) * 0.52359878;
		vec2 sample_uv = UV + vec2(cos(angle), sin(angle)) * TEXTURE_PIXEL_SIZE * edge_width_pixels;
		if (sample_uv.x >= 0.0 && sample_uv.y >= 0.0 && sample_uv.x <= 1.0 && sample_uv.y <= 1.0) {
			silhouette_alpha = max(silhouette_alpha, texture(TEXTURE, sample_uv).a);
		}
	}
	// Composite paper behind, preserving opaque RGB and antialiased blue ink.
	float paper_alpha = silhouette_alpha * edge_color.a * (1.0 - original.a);
	float alpha = original.a + paper_alpha;
	vec3 rgb = alpha > 0.0 ? (original.rgb * original.a + edge_color.rgb * paper_alpha) / alpha : vec3(0.0);
	COLOR = vec4(rgb, alpha) * portrait_modulate;
}
