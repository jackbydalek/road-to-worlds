shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_disabled;

uniform sampler2D source_texture : source_color, filter_nearest, repeat_disable;
uniform int palette_mode = 0;
uniform vec4 road_asphalt : source_color;
uniform vec4 road_shadow : source_color;
uniform vec4 paving : source_color;
uniform vec4 wall : source_color;
uniform vec4 roof : source_color;
uniform vec4 trim : source_color;
uniform vec4 glass_color : source_color;
uniform vec4 sage : source_color;
uniform vec4 warm_accent : source_color;

vec3 shaded_color(vec3 target, float source_luma, float low, float high) {
	float shade = smoothstep(low, high, source_luma);
	return mix(target * 0.78, min(target * 1.06, vec3(1.0)), shade);
}

vec3 road_palette(vec3 source) {
	float luma = dot(source, vec3(0.299, 0.587, 0.114));
	float chroma = max(source.r, max(source.g, source.b)) - min(source.r, min(source.g, source.b));
	bool warm_surface = source.r > source.b * 1.08 && source.r >= source.g * 0.94;
	if (luma > 0.76 || (warm_surface && luma > 0.34)) {
		return shaded_color(paving.rgb, luma, 0.30, 0.92);
	}
	if (luma < 0.30) {
		return shaded_color(road_shadow.rgb, luma, 0.05, 0.42);
	}
	if (chroma < 0.13 || source.b >= source.r * 0.92) {
		return shaded_color(road_asphalt.rgb, luma, 0.20, 0.82);
	}
	return shaded_color(paving.rgb, luma, 0.25, 0.84);
}

vec3 building_palette(vec3 source) {
	float luma = dot(source, vec3(0.299, 0.587, 0.114));
	float maximum = max(source.r, max(source.g, source.b));
	float minimum = min(source.r, min(source.g, source.b));
	float chroma = maximum - minimum;
	if (luma < 0.20) {
		return shaded_color(trim.rgb, luma, 0.04, 0.36);
	}
	if (source.g > source.r * 1.04 && source.g > source.b * 0.96) {
		return shaded_color(sage.rgb, luma, 0.20, 0.84);
	}
	if (source.b > source.r * 1.04 || (source.b > source.g * 1.08 && source.r > source.g)) {
		if (luma > 0.70) {
			return shaded_color(glass_color.rgb, luma, 0.46, 0.96);
		}
		return shaded_color(roof.rgb, luma, 0.16, 0.78);
	}
	if (source.r > source.g * 1.24 && source.g < 0.48 && chroma > 0.20) {
		return shaded_color(warm_accent.rgb, luma, 0.15, 0.78);
	}
	if (chroma < 0.12 && luma < 0.58) {
		return shaded_color(trim.rgb, luma, 0.16, 0.72);
	}
	return shaded_color(wall.rgb, luma, 0.20, 0.94);
}

void fragment() {
	vec4 source = texture(source_texture, UV);
	ALBEDO = palette_mode == 0 ? road_palette(source.rgb) : building_palette(source.rgb);
	ALPHA = source.a;
	ROUGHNESS = 0.94;
}
