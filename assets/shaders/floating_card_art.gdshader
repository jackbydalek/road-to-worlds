shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

uniform sampler2D art_texture : source_color, filter_linear_mipmap, repeat_disable;
uniform vec4 outline_color : source_color = vec4(1.0);
uniform float outline_pixels : hint_range(0.0, 5.0) = 2.0;
uniform float opacity : hint_range(0.0, 1.0) = 1.0;

void vertex() {
	// Match the original camera-facing art, including each card's scale.
	mat4 billboard = mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	billboard[0].xyz *= length(MODEL_MATRIX[0].xyz);
	billboard[1].xyz *= length(MODEL_MATRIX[1].xyz);
	billboard[2].xyz *= length(MODEL_MATRIX[2].xyz);
	MODELVIEW_MATRIX = VIEW_MATRIX * billboard;
	// Leave room for the stroke outside artwork touching a texture edge.
	VERTEX.xy *= 1.12;
	UV = (UV - vec2(0.5)) * 1.12 + vec2(0.5);
}

vec4 sample_art(vec2 coordinates) {
	float inside = step(0.0, coordinates.x) * step(coordinates.x, 1.0)
		* step(0.0, coordinates.y) * step(coordinates.y, 1.0);
	return texture(art_texture, coordinates) * inside;
}

void fragment() {
	vec4 original = sample_art(UV);
	vec2 screen_x = dFdx(UV) * outline_pixels;
	vec2 screen_y = dFdy(UV) * outline_pixels;
	float silhouette = original.a;
	for (int index = 0; index < 16; index++) {
		float angle = float(index) * 0.3926990817;
		vec2 offset = cos(angle) * screen_x + sin(angle) * screen_y;
		silhouette = max(silhouette, sample_art(UV + offset).a);
	}
	float combined_alpha = max(original.a, silhouette * outline_color.a);
	float stroke_alpha = max(0.0, combined_alpha - original.a);
	ALBEDO = (original.rgb * original.a + outline_color.rgb * stroke_alpha) / max(combined_alpha, 0.0001);
	ALPHA = combined_alpha * opacity;
}
