extends SceneTree

const CARD_FACE_SCRIPT := preload("res://scripts/CardFace.gd")
const CONTENT_CATALOG_SCRIPT := preload("res://scripts/ContentCatalog.gd")
const PREVIEW_PATH := "/tmp/road_to_worlds_card_face_preview.png"

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
	hearty_face.configure(catalog.cards_by_id.hearty_stewoose, "blue", true)
	hearty_face.position = Vector2(1020, 20)
	hearty_face.size = Vector2(480, 682)
	root.add_child(hearty_face)

	await process_frame
	await process_frame

	var bee_frame := bee_face.find_child("CardFrame", true, false) as TextureRect
	var bee_art := bee_face.find_child("CardArtwork", true, false) as TextureRect
	var sweet_frame := sweet_face.find_child("CardFrame", true, false) as TextureRect
	var sweet_art := sweet_face.find_child("CardArtwork", true, false) as TextureRect
	var sweet_icon := sweet_face.find_child("CardAffinityIcon", true, false) as Label
	var hearty_frame := hearty_face.find_child("CardFrame", true, false) as TextureRect
	var hearty_art := hearty_face.find_child("CardArtwork", true, false) as TextureRect
	var hearty_icon := hearty_face.find_child("CardAffinityIcon", true, false) as Label
	var hearty_type := hearty_face.find_child("CardType", true, false) as Label
	var hearty_requirements := hearty_face.find_child("CardRequirements", true, false) as Label
	var card_icon_font := sweet_icon.get_theme_font("font") as FontFile if sweet_icon != null else null
	_expect(bee_frame != null and bee_frame.texture.resource_path.ends_with("spicy_ingredient/black.png"), "The default difficulty did not use the black Spicy Ingredient frame.")
	_expect(sweet_frame != null and sweet_frame.texture.resource_path.ends_with("sweet_ingredient/gold.png"), "The Gold difficulty did not use the corrected Sweet Ingredient frame.")
	_expect(hearty_frame != null and hearty_frame.texture.resource_path.ends_with("hearty_meal/blue.png"), "The Blue difficulty did not use the Hearty Meal frame.")
	_expect(bee_art != null and not bool(bee_art.get_meta("art_pending", true)), "Hot Honey Bee did not load its converted artwork frames.")
	_expect(sweet_art != null and bool(sweet_art.get_meta("art_pending", false)), "A Sweet Ingredient without artwork did not use ART PENDING.")
	_expect(hearty_art != null and bool(hearty_art.get_meta("art_pending", false)), "A Hearty Meal without artwork did not use ART PENDING.")
	_expect(sweet_icon != null and sweet_icon.text == "🍬" and hearty_icon != null and hearty_icon.text == "🍲", "Sweet or Hearty cards did not use their Noto affinity emoji.")
	_expect(card_icon_font != null and not card_icon_font.allow_system_fallback, "Card affinity symbols could still fall back to the system's colored emoji font.")
	_expect(hearty_type != null and hearty_type.text == "Meal", "The Hearty Meal frame did not render its card type.")
	_expect(hearty_requirements != null and hearty_requirements.text == "2× Hearty Ingredients", "The Hearty Meal frame did not summarize its recipe requirements.")
	_expect(hearty_requirements.get_theme_font_size("font_size") < hearty_type.get_theme_font_size("font_size"), "Meal requirements were not rendered smaller than the Meal label.")

	var chef_face := CARD_FACE_SCRIPT.new()
	chef_face.configure(catalog.cards_by_id.chef_mary, "gold", false)
	var chef_frame := chef_face.find_child("CardFrame", true, false) as TextureRect
	var chef_icon := chef_face.find_child("CardAffinityIcon", true, false) as Label
	var chef_stats := chef_face.find_child("CardStats", true, false) as Label
	_expect(CARD_FACE_SCRIPT.supports_card(catalog.cards_by_id.chef_mary), "Chef cards were not accepted by the authored card renderer.")
	_expect(chef_frame != null and chef_frame.texture.resource_path.ends_with("frames/chef/black.png"), "Chef cards did not use the supplied Black Chef frame.")
	_expect(chef_icon != null and not chef_icon.visible and chef_stats != null and not chef_stats.visible, "Chef cards displayed affinity or combat-stat fields that are not present on their frame.")

	var tool_face := CARD_FACE_SCRIPT.new()
	tool_face.configure(catalog.cards_by_id.item_wooden_spoon, "blue", false)
	var tool_frame := tool_face.find_child("CardFrame", true, false) as TextureRect
	var tool_type := tool_face.find_child("CardType", true, false) as Label
	_expect(CARD_FACE_SCRIPT.supports_card(catalog.cards_by_id.item_wooden_spoon), "Tool cards were not accepted by the authored card renderer.")
	_expect(tool_frame != null and tool_frame.texture.resource_path.ends_with("frames/tool/black.png"), "Tool cards did not use the supplied Black Tool frame.")
	_expect(tool_type != null and not tool_type.visible, "Tool cards displayed a type field that is not present on their frame.")
	chef_face.free()
	tool_face.free()

	var mixed_recipe_face := CARD_FACE_SCRIPT.new()
	mixed_recipe_face.configure(catalog.cards_by_id.hearty_mastiff_potato, "black", false)
	var mixed_requirements := mixed_recipe_face.find_child("CardRequirements", true, false) as Label
	_expect(mixed_requirements != null and mixed_requirements.text == "Hearty Ingredient + Any Ingredient", "Mixed Meal recipe requirements were not formatted correctly.")
	var required_meal_face := CARD_FACE_SCRIPT.new()
	required_meal_face.configure(catalog.cards_by_id.sweet_bottomless_trifle_tern, "black", false)
	var required_meal_requirements := required_meal_face.find_child("CardRequirements", true, false) as Label
	_expect(required_meal_requirements != null and required_meal_requirements.text == "Sweet Meal + Sweet Ingredient", "A Meal-sacrifice requirement was not included in the recipe line.")
	mixed_recipe_face.free()
	required_meal_face.free()

	var first_art_path := bee_art.texture.resource_path if bee_art != null and bee_art.texture != null else ""
	await create_timer(0.08).timeout
	var advanced_art_path := bee_art.texture.resource_path if bee_art != null and bee_art.texture != null else ""
	_expect(first_art_path != "" and advanced_art_path != first_art_path, "Hot Honey Bee artwork did not advance at its authored frame timing.")

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
