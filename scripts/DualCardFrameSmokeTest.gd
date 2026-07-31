extends SceneTree

const CARD_FACE_SCRIPT := preload("res://scripts/CardFace.gd")
const CONTENT_CATALOG_SCRIPT := preload("res://scripts/ContentCatalog.gd")
const AFFINITY_VISUALS := preload("res://scripts/AffinityVisuals.gd")
const DUAL_FRAME_KEYS := {
	"funky|spicy": "spicy_funky",
	"fresh|spicy": "spicy_fresh",
	"hearty|sweet": "hearty_sweet",
	"fresh|hearty": "hearty_fresh",
	"funky|sweet": "sweet_funky",
}
const DUAL_FRAME_AFFINITY_ORDER := {
	"spicy_funky": ["spicy", "funky"],
	"spicy_fresh": ["spicy", "fresh"],
	"hearty_sweet": ["hearty", "sweet"],
	"hearty_fresh": ["hearty", "fresh"],
	"sweet_funky": ["sweet", "funky"],
}

var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog = CONTENT_CATALOG_SCRIPT.new()
	_expect(catalog.load_all(), "The card catalog did not load.")
	if failed:
		quit(1)
		return

	for frame_key in DUAL_FRAME_KEYS.values():
		for card_type in ["ingredient", "meal"]:
			var frame_path := "res://assets/cards/frames/dual/%s_%s.png" % [String(frame_key), card_type]
			_expect(ResourceLoader.exists(frame_path), "Missing supplied dual frame: %s." % frame_path)
			var frame_texture := load(frame_path) as Texture2D
			_expect(frame_texture != null and frame_texture.get_width() == 501 and frame_texture.get_height() == 711, "Dual frame was not imported at 501 × 711: %s." % frame_path)

	var dual_card_count := 0
	for card in catalog.cards:
		var affinities: Array = card.get("archetypes", [])
		if affinities.size() != 2:
			continue
		dual_card_count += 1
		var sorted_affinities: Array[String] = [String(affinities[0]), String(affinities[1])]
		sorted_affinities.sort()
		var pair_key := "|".join(sorted_affinities)
		var expected_frame_key := String(DUAL_FRAME_KEYS.get(pair_key, ""))
		_expect(expected_frame_key != "", "%s uses a dual pair without a supplied frame." % String(card.get("id", "")))

		var face = CARD_FACE_SCRIPT.new()
		face.configure(card, "gold", false)
		var frame := face.find_child("CardFrame", true, false) as TextureRect
		var icon := face.find_child("CardAffinityIcon", true, false) as Label
		var expected_path := "frames/dual/%s_%s.png" % [expected_frame_key, String(card.get("card_type", ""))]
		var expected_icons := ""
		for affinity_id in DUAL_FRAME_AFFINITY_ORDER[expected_frame_key]:
			expected_icons += AFFINITY_VISUALS.symbol(String(affinity_id))
		_expect(frame != null and frame.texture.resource_path.ends_with(expected_path), "%s did not select its supplied dual frame." % String(card.get("id", "")))
		_expect(icon != null and icon.text == expected_icons, "%s did not display both affinity symbols." % String(card.get("id", "")))
		face.free()

	_expect(dual_card_count == 15, "Expected the supplied frames to cover all 15 dual-type cards.")
	if failed:
		quit(1)
		return
	print("Dual card frame smoke test passed.")
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
