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
		var frame := face.find_child("CardFrame", true, false) as Panel
		var icon := face.find_child("CardAffinityIcon", true, false) as Label
		var stats := face.find_child("CardStats", true, false) as Label
		_expect(frame != null and frame.get_meta("frame_style", "") == "cozy_cafe", "%s did not use the reusable cozy frame." % card_type.capitalize())
		_expect(icon != null and icon.visible and icon.text != "", "%s did not display its support-card classification icon." % card_type.capitalize())
		_expect(stats != null and not stats.visible, "%s displayed unit combat stats." % card_type.capitalize())
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
