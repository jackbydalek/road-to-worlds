shader_type canvas_item;

// Recipe symbols must read as one ink color even when their source glyph uses
// an embedded multicolor emoji palette.
void fragment() {
	float glyph_alpha = texture(TEXTURE, UV).a * COLOR.a;
	COLOR = vec4(0.0, 0.0, 0.0, glyph_alpha);
}
