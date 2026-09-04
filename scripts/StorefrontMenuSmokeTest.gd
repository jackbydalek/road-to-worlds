extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")
const PALETTE := preload("res://scripts/ui/GamePalette.gd")

var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	var starter: Dictionary = main._deck_entries_to_dict(
		main.archetypes_by_id.spicy.get("starterDeck", [])
	)
	for event_id in main.tournaments_by_id:
		_expect(
			int(main.tournaments_by_id[event_id].get("entryFee", -1)) == 0,
			"%s still charged a tournament entry fee." % event_id
		)
	main.run = main.run_state_service.create_run(
		"spicy",
		starter,
		main._predator_archetype("spicy"),
		"season",
		"white"
	)
	main._generate_shop_inventory()
	main._show_shop_overworld()
	await process_frame
	await process_frame

	var shop_world = main.find_child("CardShopOverworld", true, false)
	_expect(shop_world != null, "The storefront menu test could not open the card store.")
	if shop_world == null:
		quit(1)
		return
	var cafe_sign_text := main.find_child("CafeSignText", true, false) as Label3D
	_expect(
		main.find_child("StorefrontLogo", true, false) == null
		and cafe_sign_text != null
		and cafe_sign_text.text == "Coffee n' Cards",
		"The card store did not preserve its separate Coffee n' Cards sign."
	)
	_expect(
		main.find_child("CafeSignBack", true, false) is MeshInstance3D
		and main.find_child("CafeSignFace", true, false) is MeshInstance3D,
		"The Coffee n' Cards lettering is missing its physical storefront sign."
	)
	_expect(
		int(shop_world.shop_view_render_counts.singles) == 0
		and int(shop_world.shop_view_render_counts.trade) == 0
		and int(shop_world.shop_view_render_counts.meta) == 0
		and int(shop_world.shop_view_render_counts.set_list) == 0,
		"The storefront eagerly rendered hidden shop overlays during initial load."
	)
	var top_bar := main.find_child("TopBar", true, false) as PanelContainer
	var cash_hud := main.find_child("ShopHudCashButton", true, false) as Button
	var deck_hud := main.find_child("ShopHudDeckButton", true, false) as Button
	var save_hud := main.find_child("ShopHudSaveButton", true, false) as Button
	var settings_hud := main.find_child("ShopHudSettingsButton", true, false) as Button
	var card_viewer := main.find_child("ShopCardHoverPreview", true, false) as PanelContainer
	var autosave := main.find_child("AutosaveIndicator", true, false) as Label
	var shop_tooltips_clear := true
	for control_value in shop_world.find_children("*", "Control", true, false):
		var control := control_value as Control
		if control != null and not control.tooltip_text.is_empty():
			shop_tooltips_clear = false
			break
	_expect(shop_tooltips_clear, "The card shop still exposes native hover tooltips.")
	_expect(not main.header_bar.visible and not main.nav.visible, "The 3D store still reserved the persistent outer title or status row.")
	_expect(
		top_bar != null and top_bar.get_theme_stylebox("panel") is StyleBoxFlat,
		"The in-store top bar did not use the formal flat treatment."
	)
	_expect(
		cash_hud != null and cash_hud.get_theme_stylebox("normal") is StyleBoxFlat,
		"The store HUD controls still used the rough sketch treatment."
	)
	_expect(
		card_viewer != null and card_viewer.get_theme_stylebox("panel") is StyleBoxEmpty,
		"The enlarged shop card viewer still has a rough sketch outline."
	)
	_expect(
		deck_hud != null and deck_hud.icon.resource_path == "res://assets/ui/shop_hud/deck_edit.png"
		and save_hud != null and save_hud.icon.resource_path == "res://assets/ui/shop_hud/save.png"
		and settings_hud != null and settings_hud.icon.resource_path == "res://assets/ui/shop_hud/settings.png",
		"The Deck Edit, Save, or Settings HUD control is not using its supplied icon."
	)
	_expect(
		deck_hud != null and deck_hud.expand_icon and deck_hud.get_theme_constant("icon_max_width") == 60 and deck_hud.get_theme_color("icon_normal_color") == Color.WHITE
		and save_hud != null and save_hud.expand_icon and save_hud.get_theme_constant("icon_max_width") == 60 and save_hud.get_theme_color("icon_normal_color") == Color.WHITE
		and settings_hud != null and settings_hud.expand_icon and settings_hud.get_theme_constant("icon_max_width") == 60 and settings_hud.get_theme_color("icon_normal_color") == Color.WHITE,
		"The supplied toolbar icons are still being stretched or tinted."
	)
	_expect(
		autosave != null and autosave.get_parent() == main and not autosave.visible,
		"The save indicator was not converted into an independent hidden glyph."
	)
	main._show_autosave_indicator()
	_expect(
		autosave != null
		and autosave.visible
		and autosave.text == "◆"
		and autosave.size.x <= 40.0,
		"Saving did not display the compact save glyph."
	)
	await create_timer(1.1).timeout
	_expect(autosave != null and not autosave.visible, "The save glyph did not clear after saving.")

	var round_button := main.find_child("StoreOverviewRoundButton", true, false) as Button
	_expect(
		main.root_margin.get_theme_constant("margin_left") == 0
		and main.root_margin.get_theme_constant("margin_right") == 0
		and main.root_margin.get_theme_constant("margin_top") == 0
		and main.root_margin.get_theme_constant("margin_bottom") == 0,
		"The season storefront still exposes the paper shell as an outer border."
	)
	_expect(
		 round_button != null
		and round_button.visible
		and round_button.text == "START ROUND 1"
		and round_button.icon != null
		and round_button.icon_alignment == HORIZONTAL_ALIGNMENT_RIGHT
		and round_button.tooltip_text.is_empty(),
		"The store overview did not offer Start Round 1 before tournament registration."
	)
	if round_button != null:
		var round_face = round_button.get_node_or_null("BattleAngularButtonFace")
		_expect(
			round_button.custom_minimum_size.x >= 500.0
			and round_button.custom_minimum_size.y >= 84.0
			and round_button.get_theme_font_size("font_size") >= 24
			and round_face != null
			and round_face.variant == "primary"
			and round_face.fill_color_for_state("normal").is_equal_approx(PALETTE.SELECTION_BLUE),
			"Start Round does not have the larger tournament-CTA silhouette."
		)
	shop_world.call("_return_to_shopkeeper_menu")
	await process_frame

	var menu_panel := shop_world.menu_panel as PanelContainer
	var menu_content := shop_world.menu_content as VBoxContainer
	var status := main.find_child("ShopkeeperStatus", true, false) as HBoxContainer
	var buy_section := _find_label(main, "BUY CARDS")
	var separator := main.find_child("ShopkeeperExitSeparator", true, false) as HSeparator
	_expect(menu_panel != null and menu_panel.visible, "The cleaned storefront menu did not become visible.")
	_expect(menu_content != null and menu_content.get_theme_constant("separation") == 10, "The storefront menu did not use the intended compact vertical rhythm.")
	_expect(status != null and status.get_child_count() == 2, "The storefront menu did not separate cash and prize-pack status.")
	_expect(buy_section != null and separator != null, "The storefront menu is missing its action grouping.")
	_expect(_find_label(main, "PLAN YOUR WEEK") == null, "The removed planning group is still visible in the clerk menu.")
	_expect(main.find_child("Tournament", true, false) == null, "The tournament action is still inside the shopkeeper menu.")
	_expect(main.find_child("Meta", true, false) == null and main.find_child("Calendar", true, false) == null, "The clerk menu still exposes Meta Analysis or Calendar.")
	_expect(round_button != null and not round_button.visible, "The Start Round CTA remained visible inside the shopkeeper menu.")

	var cash_status := shop_world.menu_cash_status_label as Label
	var prize_status := shop_world.menu_prize_status_label as Label
	_expect(cash_status != null and cash_status.text == "$%d cash" % int(main.run.money), "The storefront cash badge did not match the live balance.")
	_expect(prize_status != null and prize_status.text == "0 prize packs", "The storefront prize badge did not use clear pluralized copy.")

	var actions := [
		main.find_child("BuySingles", true, false) as Button,
		main.find_child("BuyPack", true, false) as Button,
		main.find_child("ViewSetList", true, false) as Button,
		main.find_child("Leave", true, false) as Button,
	]
	var pack_action := actions[1] as Button
	_expect(
		pack_action != null
		and pack_action.text == "Open Pack - $5"
		and not pack_action.disabled,
		"The storefront pack action did not show its $5 price or was unavailable with the starting balance."
	)
	for button_value in actions:
		var button := button_value as Button
		_expect(
			button != null
			and button.custom_minimum_size.y >= 46.0
			and button.alignment == HORIZONTAL_ALIGNMENT_LEFT
			and button.get_theme_stylebox("normal") is StyleBox,
			"A storefront action did not use the cleaned, full-height menu treatment."
		)

	_expect(main.expansions_by_id.has("core"), "The card catalog did not register the Core Set expansion.")
	for card_value in main.cards:
		var card: Dictionary = card_value
		_expect(String(card.get("expansion_id", "")) == "core", "%s was not assigned to the Core Set." % String(card.get("id", "Card")))
	var catalog_set_entries: Array = main._shop_overworld_set_entries()
	_expect(catalog_set_entries.size() == 1, "The current catalog was not grouped into one published expansion.")
	if not catalog_set_entries.is_empty():
		var sorted_cards: Array = (catalog_set_entries[0] as Dictionary).get("cards", [])
		_expect(_set_list_cards_are_ordered(main, sorted_cards), "The Core Set was not sorted by affiliation, card type, then name.")
	var future_expansion := {"id": "second_course", "name": "Second Course", "code": "RTW2", "release_order": 1}
	var future_card: Dictionary = (main.cards[0] as Dictionary).duplicate(true)
	future_card["id"] = "future_set_test_card"
	future_card["name"] = "Future Test Card"
	future_card["expansion_id"] = "second_course"
	main.expansions.append(future_expansion)
	main.expansions_by_id["second_course"] = future_expansion
	main.cards.append(future_card)
	var future_set_entries: Array = main._shop_overworld_set_entries()
	_expect(
		future_set_entries.size() == 2
		and String((future_set_entries[1] as Dictionary).get("id", "")) == "second_course"
		and ((future_set_entries[1] as Dictionary).get("cards", []) as Array).size() == 1,
		"A future expansion did not sort after the Core Set or receive its tagged card."
	)
	main.cards.pop_back()
	main.expansions.pop_back()
	main.expansions_by_id.erase("second_course")
	var set_list_action := actions[2] as Button
	_expect(set_list_action != null and set_list_action.text == "View Set List", "The shopkeeper menu is missing View Set List.")
	if set_list_action != null:
		var set_action_rect := set_list_action.get_global_rect()
		var menu_rect := menu_panel.get_global_rect()
		_expect(
			set_action_rect.position.y >= menu_rect.position.y
			and set_action_rect.end.y <= menu_rect.end.y,
			"View Set List overflowed the shopkeeper panel."
		)
	if set_list_action != null:
		set_list_action.emit_signal("pressed")
	await process_frame
	var set_list_panel := main.find_child("InSceneSetList", true, false) as PanelContainer
	var core_section := main.find_child("InSceneSetSection_core", true, false) as VBoxContainer
	var core_heading := main.find_child("InSceneSetHeading_core", true, false) as Label
	var core_grids := core_section.find_children("InSceneSetGrid_core_*", "GridContainer", true, false) if core_section != null else []
	var spicy_affinity := main.find_child("InSceneSetAffinity_core_spicy", true, false) as VBoxContainer
	var spicy_ingredients := main.find_child("InSceneSetType_core_spicy_ingredient", true, false) as Label
	var neutral_chefs := main.find_child("InSceneSetType_core_neutral_chef", true, false) as Label
	var set_list_back := main.find_child("InSceneSetListBack", true, false) as Button
	var set_list_rows := main.find_children("InSceneSetListCard_*", "PanelContainer", true, false)
	var set_list_faces := main.find_children("InSceneSetListCardFace_*", "Control", true, false)
	_expect(set_list_panel != null and set_list_panel.visible, "View Set List did not open its in-store overlay.")
	_expect(int(shop_world.shop_view_render_counts.set_list) == 1, "Opening the set list did not render it exactly once.")
	_expect(shop_world.current_menu_view() == "set_list", "The storefront did not preserve the set-list view state.")
	_expect(
		core_section != null
		and core_section.get_meta("expansion_id", "") == "core"
		and core_heading != null
		and "Core Set" in core_heading.text
		and "RTW" in core_heading.text,
		"The set list did not group cards under the registered Core Set metadata."
	)
	_expect(set_list_rows.size() == main.cards.size(), "The set list did not include every published card.")
	_expect(
		set_list_back != null
		and set_list_back.visible
		and set_list_panel.get_global_rect().encloses(set_list_back.get_global_rect()),
		"The visual card grid pushed the set-list navigation outside its panel."
	)
	_expect(
		not core_grids.is_empty()
		and core_grids.all(func(grid_value) -> bool: return (grid_value as GridContainer).columns == 6)
		and set_list_faces.size() == main.cards.size(),
		"The set list did not render the complete Core Set as six-column visual card grids."
	)
	_expect(
		spicy_affinity != null
		and spicy_ingredients != null
		and neutral_chefs != null,
		"The set list did not expose affiliation groups with card-type subsections."
	)
	if not set_list_faces.is_empty():
		_expect(
			(set_list_faces[0] as Control).custom_minimum_size == Vector2(126, 179),
			"Set-list thumbnails did not match the compact Deck Workshop card treatment."
		)
	var listed_card_ids := {}
	for row_value in set_list_rows:
		var row := row_value as PanelContainer
		listed_card_ids[String(row.get_meta("card_id", ""))] = true
	for card_value in main.cards:
		var card: Dictionary = card_value
		_expect(listed_card_ids.has(String(card.get("id", ""))), "%s is missing from the set list." % String(card.get("name", "Card")))
	shop_world.call("_layout_set_list_panel", Vector2(960, 540))
	await process_frame
	await process_frame
	var compact_set_list_rect := Rect2(set_list_panel.position, set_list_panel.size) if set_list_panel != null else Rect2()
	_expect(
		set_list_panel != null
		and compact_set_list_rect.position.x >= 0.0
		and compact_set_list_rect.position.y >= 0.0
		and compact_set_list_rect.end.x <= 960.0
		and compact_set_list_rect.end.y <= 540.0,
		"The set list did not fit the compact supported storefront size: %s (minimum %s)." % [compact_set_list_rect, set_list_panel.get_combined_minimum_size()]
	)
	_expect(
		not core_grids.is_empty()
		and core_grids.all(func(grid_value) -> bool: return (grid_value as GridContainer).columns == 5),
		"The visual set list did not reflow its card-type grids to five columns at the compact size."
	)
	shop_world.call("_layout_set_list_panel")
	shop_world.call("_return_to_shopkeeper_menu")
	await process_frame
	if set_list_action != null:
		set_list_action.emit_signal("pressed")
	await process_frame
	_expect(
		int(shop_world.shop_view_render_counts.set_list) == 1,
		"Reopening the unchanged set list rebuilt every card face."
	)
	shop_world.call("_return_to_shopkeeper_menu")
	await process_frame

	main.run.active_tournament = {
		"active": true,
		"event_id": "weekly_locals",
		"event_name": "Weekly Locals",
		"round": 2,
	}
	shop_world.overview_active = true
	shop_world.update_shop_context(main._shop_overworld_context())
	await process_frame
	_expect(
		round_button != null
		and round_button.visible
		and round_button.text == "START ROUND 2"
		and round_button.icon != null
		and round_button.custom_minimum_size.x >= 400.0
		and round_button.get_signal_connection_list("pressed").size() > 0,
		"The store overview did not expose a large, connected Start Round 2 action."
	)
	shop_world.call("_show_menu")
	_expect(round_button != null and not round_button.visible, "The Start Round CTA remained visible after zooming into the shopkeeper.")
	shop_world.call("_return_to_shopkeeper_menu")
	await process_frame

	var browse := actions[0] as Button
	if browse != null:
		browse.emit_signal("pressed")
	await process_frame
	var singles_case := main.find_child("InSceneSinglesCase", true, false) as PanelContainer
	_expect(singles_case != null and singles_case.visible, "The cleaned Browse Singles action no longer opened the in-store case.")
	_expect(int(shop_world.shop_view_render_counts.singles) == 1, "Opening Singles did not lazily render the case exactly once.")

	var shop_music := main.find_child("CardShopMusic", true, false) as AudioStreamPlayer
	_expect(shop_music != null and shop_music.playing, "The card-store soundtrack was not playing in the shop.")
	main._show_deckbuilder()
	await process_frame
	_expect(shop_music != null and shop_music.playing, "Opening Deck Edit stopped the card-store soundtrack.")
	_expect(
		main.cached_shop_overworld == shop_world
		and is_instance_valid(main.cached_shop_overworld)
		and not main.cached_shop_overworld.visible,
		"Opening Deck Edit discarded the live 3D storefront instead of caching it."
	)
	main._show_settings()
	await process_frame
	_expect(shop_music != null and shop_music.playing, "Opening Settings from Deck Edit stopped the card-store soundtrack.")
	main._show_shop()
	await process_frame
	await process_frame
	_expect(
		main.find_child("CardShopOverworld", true, false) == shop_world
		and int(shop_world.shop_view_render_counts.set_list) == 1,
		"Returning from a utility screen rebuilt the 3D store or its cached set list."
	)

	main.run.active_tournament = {}
	main.run.money = 0
	var money_before_entry := int(main.run.money)
	main._on_shop_tournament_requested()
	await process_frame
	await process_frame
	_expect(
		main.current_screen == "kitchen_match"
		and main._season_tournament_active()
		and int(main.run.active_tournament.get("round", 0)) == 1,
		"Start Round 1 did not register and launch the selected tournament for free."
	)
	_expect(int(main.run.money) == money_before_entry, "Registering for the tournament changed the player's money.")
	_expect(
		int(main.run.active_tournament.get("entry_fee", -1)) == 0
		and "Entry was free." in String(main.run.active_tournament.get("logs", [""])[0]),
		"The active tournament did not record free registration."
	)

	if failed:
		quit(1)
		return
	print("Storefront menu smoke test passed.")
	quit()


func _set_list_cards_are_ordered(main, cards: Array) -> bool:
	var previous_key := ""
	for card_value in cards:
		var card: Dictionary = card_value
		var affinity := String(card.get("affinity", "neutral"))
		var card_type := String(card.get("card_type", "card"))
		var affinity_rank: int = main.SET_LIST_AFFINITY_ORDER.find(affinity)
		var type_rank: int = main.SET_LIST_CARD_TYPE_ORDER.find(card_type)
		if affinity_rank < 0:
			affinity_rank = main.SET_LIST_AFFINITY_ORDER.size()
		if type_rank < 0:
			type_rank = main.SET_LIST_CARD_TYPE_ORDER.size()
		var key := "%03d|%s|%03d|%s|%s|%s" % [
			affinity_rank,
			affinity,
			type_rank,
			card_type,
			String(card.get("sort_name", card.get("name", ""))).to_lower(),
			String(card.get("id", "")),
		]
		if not previous_key.is_empty() and previous_key.naturalnocasecmp_to(key) > 0:
			return false
		previous_key = key
	return true


func _find_label(root_node: Node, text: String) -> Label:
	for candidate in root_node.find_children("*", "Label", true, false):
		var label := candidate as Label
		if label.text == text:
			return label
	return null


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
