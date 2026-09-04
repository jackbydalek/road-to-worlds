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
		var frame := face.find_child("CardFrame", true, false) as Panel
		var icon := face.find_child("CardAffinityIcon", true, false) as Label
		var symbol_box := face.find_child("CardSymbolBox", true, false) as Panel
		var symbol_tint := face.find_child("DualAffinitySymbolTint", true, false) as Panel
		var symbol_divider := face.find_child("DualAffinitySymbolDivider", true, false) as Panel
		var first_stripe := face.find_child("AffinityStripe0", true, false) as Panel
		var second_stripe := face.find_child("AffinityStripe1", true, false) as Panel
		var dual_tint := face.find_child("DualArtTint", true, false) as Panel
		var dual_type_tint := face.find_child("DualTypeTint", true, false) as Panel
		var left_rail := face.find_child("DualAffinityRailLeft", true, false) as Panel
		var right_rail := face.find_child("DualAffinityRailRight", true, false) as Panel
		var dual_badge := face.find_child("DualAffinityBadgeLabel", true, false)
		var type_label := face.find_child("CardType", true, false) as Label
		var expected_icons := ""
		for affinity_id in DUAL_FRAME_AFFINITY_ORDER[expected_frame_key]:
			var symbol := AFFINITY_VISUALS.symbol(String(affinity_id))
			expected_icons += symbol
		_expect(frame != null and frame.get_meta("frame_style", "") == "illustrated_card", "%s did not use the reusable illustrated frame." % String(card.get("id", "")))
		_expect(first_stripe != null and second_stripe != null, "%s did not display both affinity stripe segments." % String(card.get("id", "")))
		_expect(dual_tint != null and left_rail != null and right_rail != null, "%s did not receive the split artwork tint and opposing side rails." % String(card.get("id", "")))
		_expect(dual_type_tint != null, "%s did not split its Ingredient or Meal classification pill between both affinities." % String(card.get("id", "")))
		_expect(symbol_tint != null and symbol_divider != null, "%s did not split the larger affinity-symbol box between both affinity colors." % String(card.get("id", "")))
		if symbol_box != null:
			_expect(symbol_box.size.x >= symbol_box.size.y * 1.65, "%s did not give its dual affinity symbols a wide enough box." % String(card.get("id", "")))
		_expect(dual_badge == null, "%s still displayed the redundant DUAL badge." % String(card.get("id", "")))
		_expect(
			type_label != null
			and type_label.text == String(card.get("card_type", "")).capitalize()
			and type_label.clip_text,
			"%s did not keep its card type on a clean, clipped line separate from recipe symbols." % String(card.get("id", ""))
		)
		_expect(icon != null and icon.text == expected_icons, "%s did not display both affinity symbols." % String(card.get("id", "")))
		face.free()

	_expect(dual_card_count > 0, "The catalog did not contain a dual-affinity card to exercise the split accent stripe.")
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
