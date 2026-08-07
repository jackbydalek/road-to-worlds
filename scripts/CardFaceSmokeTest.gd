extends SceneTree

const CARD_FACE_SCRIPT := preload("res://scripts/CardFace.gd")
const CONTENT_CATALOG_SCRIPT := preload("res://scripts/ContentCatalog.gd")
const PREVIEW_PATH := "/tmp/topdeck_to_worlds_card_face_preview.png"

var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1530, 730)
	var background := ColorRect.new()
	background.color = Color("#dad4ca")
	background.position = Vector2.ZERO
	background.size = Vector2(root.size)
	root.add_child(background)

	var catalog = CONTENT_CATALOG_SCRIPT.new()
	_expect(catalog.load_all(), "Card catalog did not load.")
	if failed:
		quit(1)
		return
	var animated_art_frame_counts := {
		"spicy_sriracharrow": 6,
		"spicy_firecracker_shrimp": 6,
		"hearty_bagver": 6,
		"hearty_french_bread_dog": 6,
		"hearty_dumpling_tortoise": 6,
		"hearty_kale_whale": 6,
		"hearty_ramen_ram": 6,
		"sweet_cinnamon_snail": 6,
		"sweet_jellyfish": 6,
		"sweet_caramel_camel": 6,
		"sweet_strawberry_sharkcake": 6,
		"sweet_pup_tart": 6,
		"sweet_pandacake": 6,
		"sweet_soft_serve_crab": 6,
		"fresh_harvest_hydra": 6,
		"fresh_garden_gorilla": 6,
		"fresh_saladmander": 6,
		"fresh_salad_shield_skunk": 6,
		"fresh_comeback_corgi": 6,
		"fresh_crisp_capybara": 6,
		"fresh_sprout_squirrel": 6
	}
	for card_id in animated_art_frame_counts:
		var frames: Array = catalog.cards_by_id[card_id].get("art_frames", [])
		_expect(frames.size() == int(animated_art_frame_counts[card_id]) and frames.all(func(frame_path) -> bool: return ResourceLoader.exists(String(frame_path))), "%s did not load every converted artwork frame." % card_id)
	_expect(String(catalog.cards_by_id.sweet_caramel_camel.name) == "Choco Bat" and String(catalog.cards_by_id.sweet_caramel_camel.art_frames[0]).contains("sweet_caramel_camel"), "Choco Bat did not replace Caramel Camel with the converted artwork.")
	var chef_names := {
		"chef_john": "Chef Carmy",
		"chef_bill": "Chef Rachel",
		"chef_carl": "Chef Ramsey",
		"chef_mary": "Chef Giada"
	}
	for card_id in chef_names:
		_expect(String(catalog.cards_by_id[card_id].name) == String(chef_names[card_id]), "%s did not use its updated chef name." % card_id)
		var chef_art_path := String(catalog.cards_by_id[card_id].get("art_path", ""))
		_expect(not chef_art_path.is_empty() and ResourceLoader.exists(chef_art_path), "%s did not load its supplied portrait." % card_id)
	var bee_face := CARD_FACE_SCRIPT.new()
	bee_face.configure(catalog.cards_by_id.spicy_hot_honey_bee, "white", true)
	bee_face.position = Vector2(20, 20)
	bee_face.size = Vector2(480, 682)
	root.add_child(bee_face)

	var sweet_face := CARD_FACE_SCRIPT.new()
	sweet_face.configure(catalog.cards_by_id.sweet_caramel_camel, "gold", true)
	sweet_face.position = Vector2(520, 20)
	sweet_face.size = Vector2(480, 682)
	root.add_child(sweet_face)

	var hearty_face := CARD_FACE_SCRIPT.new()
	hearty_face.configure(catalog.cards_by_id.hearty_polar_pot_pie_bear, "blue", true)
	hearty_face.position = Vector2(1020, 20)
	hearty_face.size = Vector2(480, 682)
	root.add_child(hearty_face)

	await process_frame
	await process_frame

	var bee_frame := bee_face.find_child("CardFrame", true, false) as Panel
	var bee_art := bee_face.find_child("CardArtwork", true, false) as TextureRect
	var sweet_frame := sweet_face.find_child("CardFrame", true, false) as Panel
	var sweet_art := sweet_face.find_child("CardArtwork", true, false) as TextureRect
	var sweet_icon := sweet_face.find_child("CardAffinityIcon", true, false) as Label
	var hearty_frame := hearty_face.find_child("CardFrame", true, false) as Panel
	var hearty_art := hearty_face.find_child("CardArtwork", true, false) as TextureRect
	var hearty_icon := hearty_face.find_child("CardAffinityIcon", true, false) as Label
	var hearty_type := hearty_face.find_child("CardType", true, false) as Label
	var hearty_requirements := hearty_face.find_child("CardRequirements", true, false) as Label
	var hearty_rules := hearty_face.find_child("CardRules", true, false) as Label
	var hearty_rules_backdrop := hearty_face.find_child("CardRulesBackdrop", true, false) as Panel
	var card_icon_font := sweet_icon.get_theme_font("font") as FontFile if sweet_icon != null else null
	_expect(bee_frame != null and bee_frame.get_meta("frame_style", "") == "cozy_cafe", "The Spicy Ingredient did not use the reusable cozy card frame.")
	_expect(sweet_frame != null and sweet_frame.get_meta("difficulty_id", "") == "gold", "The Gold card did not retain its difficulty trim.")
	_expect(hearty_frame != null and hearty_frame.get_meta("difficulty_id", "") == "blue", "The Blue card did not retain its difficulty trim.")
	_expect(bee_art != null and not bool(bee_art.get_meta("art_pending", true)), "Hot Honey Bee did not load its converted artwork frames.")
	_expect(sweet_art != null and not bool(sweet_art.get_meta("art_pending", true)), "Choco Bat did not load its converted artwork frames.")
	_expect(hearty_art != null and not bool(hearty_art.get_meta("art_pending", true)), "Polar Pot Pie Bear did not load its converted artwork frames.")
	_expect(sweet_icon != null and sweet_icon.text == "🍬" and hearty_icon != null and hearty_icon.text == "🍲", "Sweet or Hearty cards did not use their Noto affinity emoji.")
	_expect(card_icon_font != null and not card_icon_font.allow_system_fallback, "Card affinity symbols could still fall back to the system's colored emoji font.")
	_expect(hearty_type != null and hearty_type.text == "Meal", "The Hearty Meal frame did not render its card type.")
	_expect(hearty_requirements != null and hearty_requirements.text == "🍲 + *", "The Hearty Meal frame did not summarize its mixed recipe with affinity symbols.")
	_expect(hearty_requirements.get_theme_font_size("font_size") < hearty_type.get_theme_font_size("font_size"), "Meal requirements were not rendered smaller than the Meal label.")
	_expect(hearty_rules != null and hearty_rules.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER, "Card rules were not centered in the ability area.")
	_expect(hearty_rules != null and hearty_rules.get_theme_font("font").resource_path.ends_with("AtkinsonHyperlegibleNext.ttf"), "Card rules did not use the bundled hyperlegible font.")
	_expect(hearty_rules_backdrop != null and hearty_rules_backdrop.visible, "Card rules lost their layout backdrop control.")
	var rules_style := hearty_rules_backdrop.get_theme_stylebox("panel") as StyleBoxFlat if hearty_rules_backdrop != null else null
	_expect(rules_style != null and rules_style.bg_color.a > 0.0 and rules_style.border_color.a > 0.0, "Card rules did not receive the soft stationery panel.")

	var fresh_ingredient_face := CARD_FACE_SCRIPT.new()
	fresh_ingredient_face.configure(catalog.cards_by_id.fresh_crisp_capybara, "silver", false)
	var fresh_ingredient_frame := fresh_ingredient_face.find_child("CardFrame", true, false) as Panel
	var fresh_meal_face := CARD_FACE_SCRIPT.new()
	fresh_meal_face.configure(catalog.cards_by_id.fresh_saladmander, "yellow", false)
	var fresh_meal_frame := fresh_meal_face.find_child("CardFrame", true, false) as Panel
	for fresh_card_type in ["ingredient", "meal"]:
		for fresh_border in ["black", "blue", "yellow", "silver", "gold"]:
			var fresh_frame_path := "res://assets/cards/frames/fresh_%s/%s.png" % [fresh_card_type, fresh_border]
			_expect(ResourceLoader.exists(fresh_frame_path), "The supplied Fresh %s %s frame was not imported." % [fresh_border.capitalize(), fresh_card_type.capitalize()])
	_expect(CARD_FACE_SCRIPT.supports_card(catalog.cards_by_id.fresh_crisp_capybara), "Fresh cards were not accepted by the authored card renderer.")
	_expect(fresh_ingredient_frame != null and fresh_ingredient_frame.get_meta("difficulty_id", "") == "silver", "A Fresh Ingredient lost its Silver difficulty trim.")
	_expect(fresh_meal_frame != null and fresh_meal_frame.get_meta("difficulty_id", "") == "yellow", "A Fresh Meal lost its Yellow difficulty trim.")
	fresh_ingredient_face.free()
	fresh_meal_face.free()

	var funky_ingredient_face := CARD_FACE_SCRIPT.new()
	funky_ingredient_face.configure(catalog.cards_by_id.funky_fondue_ferret, "blue", false)
	var funky_ingredient_frame := funky_ingredient_face.find_child("CardFrame", true, false) as Panel
	var funky_meal_face := CARD_FACE_SCRIPT.new()
	funky_meal_face.configure(catalog.cards_by_id.funky_sauerkrat, "gold", false)
	var funky_meal_frame := funky_meal_face.find_child("CardFrame", true, false) as Panel
	for funky_card_type in ["ingredient", "meal"]:
		for funky_border in ["black", "blue", "yellow", "silver", "gold"]:
			var funky_frame_path := "res://assets/cards/frames/funky_%s/%s.png" % [funky_card_type, funky_border]
			_expect(ResourceLoader.exists(funky_frame_path), "The supplied Funky %s %s frame was not imported." % [funky_border.capitalize(), funky_card_type.capitalize()])
	_expect(CARD_FACE_SCRIPT.supports_card(catalog.cards_by_id.funky_fondue_ferret), "Funky cards were not accepted by the authored card renderer.")
	_expect(funky_ingredient_frame != null and funky_ingredient_frame.get_meta("difficulty_id", "") == "blue", "A Funky Ingredient lost its Blue difficulty trim.")
	_expect(funky_meal_frame != null and funky_meal_frame.get_meta("difficulty_id", "") == "gold", "A Funky Meal lost its Gold difficulty trim.")
	funky_ingredient_face.free()
	funky_meal_face.free()

	var chef_face := CARD_FACE_SCRIPT.new()
	chef_face.configure(catalog.cards_by_id.chef_mary, "gold", false)
	var chef_frame := chef_face.find_child("CardFrame", true, false) as Panel
	var chef_art := chef_face.find_child("CardArtwork", true, false) as TextureRect
	var chef_icon := chef_face.find_child("CardAffinityIcon", true, false) as Label
	var chef_stats := chef_face.find_child("CardStats", true, false) as Label
	_expect(CARD_FACE_SCRIPT.supports_card(catalog.cards_by_id.chef_mary), "Chef cards were not accepted by the authored card renderer.")
	_expect(chef_frame != null and chef_frame.get_meta("frame_style", "") == "cozy_cafe", "Chef cards did not use the reusable cozy frame.")
	_expect(chef_art != null and not bool(chef_art.get_meta("art_pending", true)), "Chef Giada did not load her supplied portrait.")
	_expect(chef_icon != null and chef_icon.visible and chef_icon.text == "🧑‍🍳" and chef_stats != null and not chef_stats.visible, "Chef cards did not display their utility classification correctly.")

	var tool_face := CARD_FACE_SCRIPT.new()
	tool_face.configure(catalog.cards_by_id.item_wooden_spoon, "blue", false)
	var tool_frame := tool_face.find_child("CardFrame", true, false) as Panel
	var tool_type := tool_face.find_child("CardType", true, false) as Label
	_expect(CARD_FACE_SCRIPT.supports_card(catalog.cards_by_id.item_wooden_spoon), "Tool cards were not accepted by the authored card renderer.")
	_expect(tool_frame != null and tool_frame.get_meta("frame_style", "") == "cozy_cafe", "Tool cards did not use the reusable cozy frame.")
	_expect(tool_type != null and tool_type.visible and tool_type.text.contains("Item"), "Tool cards did not display their utility classification ribbon.")
	chef_face.free()
	tool_face.free()

	var mixed_recipe_face := CARD_FACE_SCRIPT.new()
	mixed_recipe_face.configure(catalog.cards_by_id.hearty_polar_pot_pie_bear, "black", false)
	var mixed_requirements := mixed_recipe_face.find_child("CardRequirements", true, false) as Label
	_expect(mixed_requirements != null and mixed_requirements.text == "🍲 + *", "Mixed Meal recipe requirements were not formatted correctly.")
	var required_meal_face := CARD_FACE_SCRIPT.new()
	required_meal_face.configure(catalog.cards_by_id.fresh_harvest_hydra, "black", false)
	var required_meal_requirements := required_meal_face.find_child("CardRequirements", true, false) as Label
	_expect(required_meal_requirements != null and required_meal_requirements.text == "2× 🍋‍🟩 + *", "Harvest Hydra's two-Fresh-plus-any recipe was not displayed correctly.")
	mixed_recipe_face.free()
	required_meal_face.free()

	var first_art_path := bee_art.texture.resource_path if bee_art != null and bee_art.texture != null else ""
	var first_sweet_art_path := sweet_art.texture.resource_path if sweet_art != null and sweet_art.texture != null else ""
	await create_timer(0.08).timeout
	var advanced_art_path := bee_art.texture.resource_path if bee_art != null and bee_art.texture != null else ""
	var advanced_sweet_art_path := sweet_art.texture.resource_path if sweet_art != null and sweet_art.texture != null else ""
	_expect(first_art_path != "" and advanced_art_path != first_art_path, "Hot Honey Bee artwork did not advance at its authored frame timing.")
	_expect(first_sweet_art_path != "" and advanced_sweet_art_path != first_sweet_art_path, "Choco Bat artwork did not advance at its authored frame timing.")

	await process_frame
	var preview: Image = null
	if DisplayServer.get_name() != "headless":
		preview = root.get_texture().get_image()
	if preview != null:
		var preview_error := preview.save_png(PREVIEW_PATH)
		_expect(preview_error == OK, "Could not save the card-face visual preview.")

	if failed:
		quit(1)
		return
	print("Card face smoke test passed." + (" Preview: " + PREVIEW_PATH if preview != null else ""))
	quit()


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
