extends SceneTree

const CARD_FACE_SCRIPT := preload("res://scripts/CardFace.gd")

var failed := false


func _init() -> void:
	for card_type in ["spice", "environment"]:
		var card := {
			"id": "frame_test_%s" % card_type,
			"name": card_type.capitalize(),
			"card_type": card_type,
			"archetype": "neutral",
			"text": "Support card frame check.",
		}
		_expect(CARD_FACE_SCRIPT.supports_card(card), "%s cards were not accepted by the authored card renderer." % card_type.capitalize())

		var face := CARD_FACE_SCRIPT.new()
		face.configure(card, "gold", false, false, false)
		var icon := face.find_child("CardAffinityIcon", true, false) as Label
		var runtime := face.find_child("RuntimeCardFace", true, false) as RuntimeAngularCard
		var affinity_label := face.find_child("AffinityLabel", true, false) as Label
		var footer_label := face.find_child("FooterLabel", true, false) as Label
		_expect(runtime != null and runtime.get_meta("frame_style", "") == "runtime_angular_card", "%s did not use the shared angular card renderer." % card_type.capitalize())
		_expect(icon != null and icon.visible and icon.text != "", "%s did not display its support-card classification icon." % card_type.capitalize())
		_expect(runtime != null and not runtime.show_stats, "%s displayed unit combat stats." % card_type.capitalize())
		_expect(runtime != null and runtime._uses_full_width_category_rail(), "%s did not use the Chef/Tool full-width category rail." % card_type.capitalize())
		_expect(runtime != null and runtime._uses_expanded_rules_panel(), "%s did not use the Chef/Tool expanded rules panel." % card_type.capitalize())
		_expect(affinity_label != null and not affinity_label.visible, "%s still displayed a redundant affinity beside its category." % card_type.capitalize())
		_expect(footer_label != null and not footer_label.visible, "%s still displayed the removed utility footer." % card_type.capitalize())
		face.free()

	if failed:
		quit(1)
		return
	print("Spice and Environment card frame smoke test passed.")
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
