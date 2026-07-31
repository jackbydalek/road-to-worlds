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
		var frame := face.find_child("CardFrame", true, false) as TextureRect
		var icon := face.find_child("CardAffinityIcon", true, false) as Label
		var stats := face.find_child("CardStats", true, false) as Label
		var expected_path := "res://assets/cards/frames/%s/black.png" % card_type
		_expect(frame != null and frame.texture != null and frame.texture.resource_path == expected_path, "%s did not use its supplied black frame." % card_type.capitalize())
		_expect(frame != null and frame.texture.get_size() == Vector2(501, 711), "%s frame was not imported at 501 × 711." % card_type.capitalize())
		_expect(icon != null and not icon.visible, "%s displayed a unit affinity icon." % card_type.capitalize())
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
