shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque;

// A restrained ink silhouette pass. Apply it as a material's next pass so the
// original material remains responsible for the object's lighting and texture.
uniform vec4 outline_color : source_color = vec4(0.055, 0.04, 0.09, 1.0);
uniform float outline_width = 0.045;
uniform float radial_width = 0.0;
uniform vec3 radial_origin = vec3(0.0);

void vertex() {
	VERTEX += NORMAL * outline_width;
	// Flat or card-like character meshes often have normals that point mostly
	// toward the camera. Expanding away from a shared character origin gives
	// those meshes a dependable silhouette without affecting normal 3D props.
	vec2 radial_direction = VERTEX.xy - radial_origin.xy;
	if (radial_width > 0.0 && length(radial_direction) > 0.0001) {
		VERTEX.xy += normalize(radial_direction) * radial_width;
	}
}

void fragment() {
	ALBEDO = outline_color.rgb;
	ROUGHNESS = 1.0;
}
