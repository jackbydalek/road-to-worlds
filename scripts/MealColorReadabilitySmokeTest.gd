extends SceneTree

const CARD_FACE_SCRIPT := preload("res://scripts/CardFace.gd")
const CONTENT_CATALOG_SCRIPT := preload("res://scripts/ContentCatalog.gd")
const PREVIEW_PATH := "/tmp/road-to-worlds-meal-color-readability.png"
const CARD_PAIRS := [
	["spicy_firecracker_shrimp", "spicy_hot_honey_bee"],
	["hearty_gravy_gazelle", "hearty_bagver"],
	["sweet_strawberry_sharkcake", "sweet_sugar_glider"],
	["fresh_saladmander", "fresh_crisp_capybara"],
	["funky_sauerkrat", "funky_fondue_ferret"],
]

var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(760, 390)
	var background := ColorRect.new()
	background.color = Color("#F4EEF8")
	background.size = Vector2(root.size)
	root.add_child(background)

	var catalog = CONTENT_CATALOG_SCRIPT.new()
	_expect(catalog.load_all(), "Card catalog did not load.")
	if failed:
		quit(1)
		return

	for pair_index in CARD_PAIRS.size():
		var pair: Array = CARD_PAIRS[pair_index]
		var meal: Dictionary = catalog.cards_by_id.get(String(pair[0]), {})
		var ingredient: Dictionary = catalog.cards_by_id.get(String(pair[1]), {})
		_expect(not meal.is_empty() and not ingredient.is_empty(), "A Meal/Ingredient color pair is missing from the catalog.")
		if meal.is_empty() or ingredient.is_empty():
			continue

		var meal_face = CARD_FACE_SCRIPT.new()
		meal_face.configure(meal, "black", false, true)
		meal_face.position = Vector2(25.0 + pair_index * 145.0, 18.0)
		meal_face.size = Vector2(110.0, 156.0)
		meal_face.set_meta("pair_index", pair_index)
		meal_face.set_meta("pair_role", "meal")
		root.add_child(meal_face)

		var ingredient_face = CARD_FACE_SCRIPT.new()
		ingredient_face.configure(ingredient, "black", false, true)
		ingredient_face.position = Vector2(25.0 + pair_index * 145.0, 210.0)
		ingredient_face.size = Vector2(110.0, 156.0)
		ingredient_face.set_meta("pair_index", pair_index)
		ingredient_face.set_meta("pair_role", "ingredient")
		root.add_child(ingredient_face)

	await process_frame
	await process_frame

	for pair_index in CARD_PAIRS.size():
		var meal_backdrop := _find_backdrop(pair_index, "meal")
		var ingredient_backdrop := _find_backdrop(pair_index, "ingredient")
		_expect(meal_backdrop != null and ingredient_backdrop != null, "A Meal/Ingredient pair lost its artwork backdrop.")
		if meal_backdrop == null or ingredient_backdrop == null:
			continue
		var meal_color := (meal_backdrop.get_theme_stylebox("panel") as StyleBoxFlat).bg_color
		var ingredient_color := (ingredient_backdrop.get_theme_stylebox("panel") as StyleBoxFlat).bg_color
		_expect(meal_backdrop.get_meta("card_type_color_role", "") == "meal", "Meal color treatment was not tagged consistently.")
		_expect(ingredient_backdrop.get_meta("card_type_color_role", "") == "ingredient", "Ingredient color treatment was not tagged consistently.")
		_expect(
			meal_color.s > ingredient_color.s + 0.06,
			"Pair %d is not sufficiently separated (Meal %.3f vs Ingredient %.3f saturation)." % [pair_index, meal_color.s, ingredient_color.s]
		)
		_expect(absf(meal_color.h - ingredient_color.h) < 0.03, "A Meal changed hue instead of using a richer version of its affinity color.")

	var preview: Image = null
	if DisplayServer.get_name() != "headless":
		preview = root.get_texture().get_image()
	if preview != null:
		_expect(preview.save_png(PREVIEW_PATH) == OK, "Could not save the Meal color preview.")

	if failed:
		quit(1)
		return
	print("Meal color readability smoke test passed." + (" Preview: " + PREVIEW_PATH if preview != null else ""))
	quit(0)


func _find_backdrop(pair_index: int, role: String) -> Panel:
	for child in root.get_children():
		if child is CardFace and child.get_meta("pair_index", -1) == pair_index and child.get_meta("pair_role", "") == role:
			return child.find_child("CardArtBackdrop", true, false) as Panel
	return null


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
