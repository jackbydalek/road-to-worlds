shader_type spatial;
render_mode unshaded;

// Used for auxiliary surfaces embedded in third-party models that should not
// participate in color, depth, or shadow rendering in the game scene.
void fragment() {
	discard;
}
