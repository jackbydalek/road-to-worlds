shader_type spatial;
render_mode unshaded, cull_disabled;

// Converts ordinary asset colors into the compact, illustrated Topdeck to Worlds
// palette. Texture details remain readable, but gradients collapse into a few
// painted value bands instead of looking like conventional PBR rendering.
uniform sampler2D source_texture : source_color, filter_nearest_mipmap;
uniform bool use_texture = false;
uniform vec4 source_tint : source_color = vec4(1.0);
uniform int palette_role = 0;

uniform vec4 ink : source_color = vec4(0.161, 0.212, 0.373, 1.0);
uniform vec4 cream : source_color = vec4(1.0, 0.969, 0.945, 1.0);
uniform vec4 coral : source_color = vec4(0.937, 0.494, 0.463, 1.0);
uniform vec4 blush : source_color = vec4(0.949, 0.643, 0.722, 1.0);
uniform vec4 periwinkle : source_color = vec4(0.557, 0.663, 0.902, 1.0);
uniform vec4 sky : source_color = vec4(0.408, 0.773, 0.910, 1.0);
uniform vec4 honey : source_color = vec4(0.847, 0.702, 0.373, 1.0);
uniform vec4 sage : source_color = vec4(0.510, 0.588, 0.435, 1.0);
uniform vec4 lavender : source_color = vec4(0.651, 0.604, 0.718, 1.0);

vec3 rgb_to_hsv_illustrated(vec3 color) {
	vec4 k = vec4(0.0, -0.3333333, 0.6666667, -1.0);
	vec4 p = mix(vec4(color.bg, k.wz), vec4(color.gb, k.xy), step(color.b, color.g));
	vec4 q = mix(vec4(p.xyw, color.r), vec4(color.r, p.yzx), step(p.x, color.r));
	float delta = q.x - min(q.w, q.y);
	float epsilon = 0.000001;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * delta + epsilon)), delta / (q.x + epsilon), q.x);
}

vec3 illustrated_color(vec3 raw_color) {
	vec3 hsv = rgb_to_hsv_illustrated(raw_color);

	if (hsv.z < 0.16) {
		return ink.rgb;
	}
	if (hsv.y < 0.13) {
		if (hsv.z > 0.78) {
			return cream.rgb;
		}
		return mix(lavender.rgb, cream.rgb, smoothstep(0.28, 0.78, hsv.z));
	}

	// Warm reds and oranges become the café's coral and honey accents.
	if (hsv.x < 0.10 || hsv.x >= 0.94) {
		// The source café uses a very dark brown swatch for its broad paving
		// plane. Treat that as a quiet lavender neutral so coral stays an accent.
		if (hsv.z < 0.40) {
			return lavender.rgb;
		}
		return coral.rgb;
	}
	if (hsv.x < 0.19) {
		if (hsv.z < 0.34) {
			return sage.rgb;
		}
		return honey.rgb;
	}
	if (hsv.x < 0.46) {
		return sage.rgb;
	}
	if (hsv.x < 0.56) {
		return sky.rgb;
	}
	if (hsv.x < 0.72) {
		return periwinkle.rgb;
	}
	if (hsv.x < 0.89) {
		return lavender.rgb;
	}
	return blush.rgb;
}

void fragment() {
	vec4 sampled = use_texture ? texture(source_texture, UV) : vec4(1.0);
	vec4 source = sampled * source_tint;
	vec3 hsv = rgb_to_hsv_illustrated(max(source.rgb, vec3(0.0001)));
	vec3 painted = illustrated_color(source.rgb);
	if (palette_role == 1) {
		// The café's single ground mesh contains both paving and roadway UVs.
		// Keep their value separation while moving both into quiet neutrals.
		painted = mix(lavender.rgb, cream.rgb, smoothstep(0.36, 0.82, hsv.z));
	} else if (palette_role == 2) {
		// Broad foliage should read as one soft illustrated shape. Ignoring the
		// source face colors prevents low-poly triangulation from becoming lines.
		painted = sage.rgb;
	} else if (palette_role == 3) {
		painted = mix(honey.rgb, ink.rgb, 0.18);
	}

	// Three stable value bands mimic deliberately painted shadow shapes.
	if (palette_role < 2) {
		if (hsv.z < 0.34) {
			painted = mix(painted, ink.rgb, 0.22);
		} else if (hsv.z > 0.78) {
			painted = mix(painted, cream.rgb, 0.09);
		}
	}

	ALBEDO = painted;
	ROUGHNESS = 0.94;
	METALLIC = 0.0;
}
