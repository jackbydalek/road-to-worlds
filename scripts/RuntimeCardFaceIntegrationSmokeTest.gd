extends SceneTree

const CARD_FACE_SCRIPT := preload("res://scripts/CardFace.gd")
const CONTENT_CATALOG_SCRIPT := preload("res://scripts/ContentCatalog.gd")
const PALETTE := preload("res://scripts/ui/GamePalette.gd")

var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog = CONTENT_CATALOG_SCRIPT.new()
	_expect(catalog.load_all(), "Card catalog did not load.")
	if failed:
		quit(1)
		return

	var cases := [
		{"id": "fresh_comeback_corgi", "compact": false, "size": Vector2(420, 620)},
		{"id": "fresh_spicy_mexican_sweet_corino", "compact": false, "size": Vector2(420, 620)},
		{"id": "sweet_pup_tart", "compact": false, "size": Vector2(420, 620)},
		{"id": "spicy_ghost_pepper_python", "compact": true, "size": Vector2(112, 159)},
		{"id": "item_wooden_spoon", "compact": false, "size": Vector2(274, 390)},
		{"id": "chef_mary", "compact": false, "size": Vector2(274, 390)},
		{"id": "spice_fresh_balsamic", "compact": false, "size": Vector2(274, 390)},
		{"id": "environment_spicy_taqueria", "compact": false, "size": Vector2(274, 390)},
		{"id": "spicy_funky_jambaye_aye", "compact": false, "size": Vector2(176, 250)},
	]
	for index in cases.size():
		var spec: Dictionary = cases[index]
		var card: Dictionary = catalog.cards_by_id.get(String(spec.id), {})
		_expect(not card.is_empty(), "Missing runtime integration card %s." % String(spec.id))
		if card.is_empty():
			continue
		var face := CARD_FACE_SCRIPT.new()
		face.configure(card, "black", false, bool(spec.compact))
		face.position = Vector2(index * 440, 0)
		face.custom_minimum_size = spec.size
		root.add_child(face)
		await process_frame
		face.size = spec.size
		await process_frame

		var runtime := face.find_child("RuntimeCardFace", true, false) as RuntimeAngularCard
		_expect(runtime != null, "%s did not use RuntimeAngularCard." % String(spec.id))
		if runtime == null:
			continue
		_expect(runtime.card_name == String(card.name).to_upper(), "%s lost its title." % String(spec.id))
		var card_title := runtime.find_child("CardTitle", true, false) as Label
		_expect(card_title != null, "%s lost its visible title label." % String(spec.id))
		if card_title != null:
			var title_font_size := card_title.get_theme_font_size("font_size")
			var title_outline := card_title.get_theme_constant("outline_size")
			var measured_title_width := card_title.get_theme_font("font").get_string_size(
				card_title.text,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				title_font_size
			).x + float(title_outline * 2)
			_expect(measured_title_width <= card_title.size.x + 0.5, "%s title still exceeds its header (%.1f > %.1f)." % [String(spec.id), measured_title_width, card_title.size.x])
			if String(spec.id) == "fresh_spicy_mexican_sweet_corino":
				var preferred_title_size := roundi(32.0 * minf(runtime.size.x / 420.0, runtime.size.y / 620.0))
				_expect(title_font_size < preferred_title_size, "Mexican Sweet Corino did not reduce its title size dynamically.")
		_expect(runtime.rules_text == String(card.text), "%s lost authored rules text." % String(spec.id))
		_expect(runtime.compact_visual == bool(spec.compact), "%s used the wrong compact mode." % String(spec.id))
		var art := runtime.find_child("CardArtwork", true, false) as TextureRect
		_expect(art != null and art.texture != null, "%s did not load its artwork." % String(spec.id))
		var standard_foil := runtime.find_child("UpgradedCardFoil", true, false) as Control
		_expect(standard_foil != null and not standard_foil.visible, "%s displayed the upgraded foil treatment on a standard card." % String(spec.id))
		var rules := runtime.find_child("CardRules", true, false) as Label
		_expect(rules != null and rules.visible != bool(spec.compact), "%s used the wrong rules visibility." % String(spec.id))
		if String(card.card_type) == "meal":
			var recipe := runtime.find_child("CardRequirements", true, false) as Label
			_expect(recipe != null and not recipe.text.is_empty(), "%s lost its Meal recipe." % String(spec.id))
		if String(card.card_type) in ["tool", "chef", "spice", "environment"]:
			var type_label := runtime.find_child("CardType", true, false) as Label
			var affinity_label := runtime.find_child("AffinityLabel", true, false) as Label
			var footer_label := runtime.find_child("FooterLabel", true, false) as Label
			var expected_type := (
				"TOOL"
				if String(card.card_type) == "tool"
				else String(card.card_type).to_upper()
			)
			_expect(type_label != null and type_label.text == expected_type, "%s did not use its full-width category label." % String(spec.id))
			_expect(affinity_label != null and not affinity_label.visible, "%s still displayed Neutral beside its category." % String(spec.id))
			_expect(footer_label != null and not footer_label.visible, "%s still displayed the support footer." % String(spec.id))
		if card.get("archetypes", []).size() == 2:
			_expect(runtime.affinities.size() == 2, "%s lost its dual affinities." % String(spec.id))
		if bool(runtime.show_stats) and float(spec.size.x) <= 176.0:
			var attack_value := runtime.find_child("AttackValue", true, false) as Label
			_expect(attack_value != null, "%s lost its attack value." % String(spec.id))
			if attack_value != null:
				var outline := attack_value.get_theme_constant("outline_size")
				var number_height := attack_value.get_theme_font("font").get_height(attack_value.get_theme_font_size("font_size")) + outline * 2
				_expect(outline <= 2, "%s retained an oversized stat outline (%d px at %.0f px requested / %.0f px face / %.0f px rendered)." % [String(spec.id), outline, float(spec.size.x), face.size.x, runtime.size.x])
				_expect(number_height <= attack_value.size.y + 2.0, "%s stat number exceeds its pod height (%.1f > %.1f)." % [String(spec.id), number_height, attack_value.size.y])

	var upgraded_card: Dictionary = catalog.cards_by_id.fresh_comeback_corgi.duplicate(true)
	upgraded_card.upgraded = true
	var upgraded_face := CARD_FACE_SCRIPT.new()
	upgraded_face.configure(upgraded_card)
	upgraded_face.custom_minimum_size = Vector2(420, 620)
	upgraded_face.size = Vector2(420, 620)
	root.add_child(upgraded_face)
	await process_frame
	var upgraded_runtime := upgraded_face.find_child("RuntimeCardFace", true, false) as RuntimeAngularCard
	var upgraded_title := upgraded_runtime.find_child("CardTitle", true, false) as Label if upgraded_runtime != null else null
	var upgraded_foil := upgraded_runtime.find_child("UpgradedCardFoil", true, false) as Control if upgraded_runtime != null else null
	_expect(upgraded_runtime != null and upgraded_runtime.upgraded, "The shared card face did not retain the upgraded state.")
	_expect(
		upgraded_title != null and upgraded_title.get_theme_color("font_color").is_equal_approx(PALETTE.STATE_REWARD),
		"An upgraded card title did not use the shared reward-yellow state color (%s instead of %s)." % [
			str(upgraded_title.get_theme_color("font_color")) if upgraded_title != null else "missing",
			str(PALETTE.STATE_REWARD),
		]
	)
	_expect(
		upgraded_foil != null
		and upgraded_foil.visible
		and bool(upgraded_foil.get("active")),
		"An upgraded card did not enable the shared animated foil overlay."
	)
	if upgraded_foil != null:
		var initial_foil_phase := float(upgraded_foil.get("phase"))
		await create_timer(0.16).timeout
		_expect(
			absf(float(upgraded_foil.get("phase")) - initial_foil_phase) > 0.001,
			"The upgraded foil reflection did not animate."
		)
		upgraded_foil.call("start_reveal_sweep")
		await create_timer(0.10).timeout
		_expect(
			bool(upgraded_foil.get("reveal_active"))
			and float(upgraded_foil.get("reveal_phase")) > 0.0,
			"The upgraded foil did not expose its stronger one-shot reveal shine."
		)

	if failed:
		quit(1)
		return
	print("Runtime CardFace integration smoke test passed.")
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
