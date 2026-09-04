extends SceneTree

const CONTENT_SCRIPT := preload("res://scripts/ContentCatalog.gd")
const ROUTE_SCRIPT := preload("res://scripts/RouteRunService.gd")

var _errors: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog: RefCounted = CONTENT_SCRIPT.new()
	_expect(catalog.load_all(), "Could not load card content for route shop tests.")
	var service: RefCounted = ROUTE_SCRIPT.new()
	service.setup(catalog.cards, catalog.cards_by_id)

	var starter_deck: Dictionary = catalog.deck_entries_to_dict(catalog.archetypes_by_id.spicy.starterDeck)
	var run := {
		"starter": "spicy",
		"deck": starter_deck,
		"collection": starter_deck.duplicate(true),
		"money": 30,
	}
	service.initialize_run(run, 90210)
	var starting_deck_size: int = service.deck_total(run.deck)
	var upgrade_id := String(service.upgradeable_card_ids(run)[0])
	var removal_id := _different_card_id(run.deck.keys(), upgrade_id)
	var shop_node := {"id": "shop_smoke", "type": "shop"}

	var upgrade_result: Dictionary = service.buy_card_upgrade(run, shop_node, upgrade_id)
	_expect(bool(upgrade_result.get("ok", false)), "The shop could not upgrade a card.")
	_expect(bool(shop_node.get("upgrade_purchased", false)), "The shop did not remember its upgrade purchase.")
	_expect(service.upgrade_count(run, upgrade_id) == 1, "The upgraded card copy was not persisted on the run.")
	var money_after_upgrade := int(run.money)
	_expect(not bool(service.buy_card_upgrade(run, shop_node, upgrade_id).get("ok", false)), "A shop sold a second card upgrade.")
	_expect(int(run.money) == money_after_upgrade, "A rejected second upgrade still charged money.")

	var prepared: Dictionary = service.prepare_player_combat_deck(run, run.deck)
	var runtime_upgrade_id: String = service.upgraded_card_id(upgrade_id)
	_expect(int(prepared.deck.get(runtime_upgrade_id, 0)) == 1, "The upgraded copy did not enter the runtime battle deck.")
	_expect(prepared.cards.has(runtime_upgrade_id), "The runtime battle deck did not include upgraded card data.")
	var base_card: Dictionary = catalog.cards_by_id[upgrade_id]
	var upgraded_card: Dictionary = prepared.cards.get(runtime_upgrade_id, {})
	_expect(String(upgraded_card.get("name", "")) == String(base_card.get("name", "")), "The upgrade changed the authored card name instead of styling it.")
	_expect(String(upgraded_card.get("text", "")) == String(base_card.get("text", "")), "The upgrade appended status copy to the authored rules text.")
	_expect(bool(upgraded_card.get("upgraded", false)), "The upgraded runtime card lost its visual upgrade state.")
	if base_card.has("attack"):
		_expect(int(upgraded_card.get("attack", 0)) == int(base_card.get("attack", 0)) + 1, "The upgraded card did not gain Attack.")
	if base_card.has("health"):
		_expect(int(upgraded_card.get("health", 0)) == int(base_card.get("health", 0)) + 1, "The upgraded card did not gain Health.")

	var removal_result: Dictionary = service.buy_card_removal(run, shop_node, removal_id, 1)
	_expect(bool(removal_result.get("ok", false)), "The shop could not remove a card.")
	_expect(bool(shop_node.get("remove_purchased", false)), "The shop did not remember its removal purchase.")
	_expect(service.deck_total(run.deck) == starting_deck_size - 1, "Card removal did not remove exactly one card.")
	var money_after_removal := int(run.money)
	_expect(not bool(service.buy_card_removal(run, shop_node, removal_id, 1).get("ok", false)), "A shop sold a second card removal.")
	_expect(int(run.money) == money_after_removal, "A rejected second removal still charged money.")

	_test_event_outcomes(service, catalog, starter_deck)
	_expect(
		service.event_outcome_for_node(1234, "event_a") == service.event_outcome_for_node(1234, "event_a"),
		"An event node did not keep a deterministic single outcome."
	)

	var packed := load("res://scenes/Main.tscn") as PackedScene
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main.autosave_enabled = false
	main.run = run.duplicate(true)
	main.run.pending_route_node = shop_node.duplicate(true)
	main._show_route_shop()
	await process_frame
	await process_frame
	var remove_button := main.find_child("RouteShopRemoveButton", true, false) as Button
	var upgrade_button := main.find_child("RouteShopUpgradeButton", true, false) as Button
	_expect(remove_button != null and remove_button.disabled and "SOLD OUT" in remove_button.text, "Used card removal did not render sold out in the shop.")
	_expect(upgrade_button != null and upgrade_button.disabled and "SOLD OUT" in upgrade_button.text, "Used card upgrade did not render sold out in the shop.")
	var first_held_card := main.find_child("RouteShopkeeperHeldCard", true, false) as Control
	var first_shopkeeper_art := main.find_child("RouteShopkeeperArtwork", true, false) as TextureRect
	var shopkeeper_stage := main.find_child("RouteShopkeeperStage", true, false) as Control
	var display_case := main.find_child("RouteShopDisplayCase", true, false) as PanelContainer
	var displayed_cards := main.find_child("RouteShopCardOffers", true, false) as HBoxContainer
	var services_panel := main.find_child("RouteShopServicesPanel", true, false) as PanelContainer
	var services_stack := main.find_child("RouteShopServices", true, false) as VBoxContainer
	var shop_media := main.find_child("EncounterMediaPanel", true, false) as PanelContainer
	var shop_content := main.find_child("EncounterContent", true, false) as VBoxContainer
	var continue_button := main.find_child("RouteShopContinueButton", true, false) as Button
	var first_held_card_id := String(main.run.pending_route_node.get("shopkeeper_card_id", ""))
	_expect(
		first_shopkeeper_art != null
		and first_shopkeeper_art.texture != null
		and first_shopkeeper_art.texture.resource_path == "res://assets/characters/shopkeeper/route_shopkeeper_card_pose.png"
		and first_held_card != null
		and String(first_held_card.get_meta("card_id", "")) == first_held_card_id
		and first_held_card.get_index() < first_shopkeeper_art.get_index(),
		"The route shop did not render the supplied shopkeeper holding a live card behind her hand."
	)
	_expect(
		shopkeeper_stage != null
		and display_case != null
		and displayed_cards != null
		and displayed_cards.get_child_count() == 4
		and display_case.get_parent() == shopkeeper_stage
		and display_case.position.y > 0.0
		and display_case.position.y < shopkeeper_stage.size.y
		and display_case.offset_left >= 100.0
		and display_case.offset_right < 0.0
		and display_case.z_index > 0
		and shop_media != null
		and not shop_media.clip_contents
		and display_case.is_ancestor_of(displayed_cards),
		"The route shop card inventory was not layered across the lower shopkeeper portrait as one display case."
	)
	_expect(
		services_panel != null
		and services_stack != null
		and services_panel.get_parent() == shopkeeper_stage
		and services_panel.is_ancestor_of(services_stack)
		and services_panel.anchor_left == 1.0
		and services_panel.offset_left <= -450.0
		and remove_button.get_parent() == services_stack
		and upgrade_button.get_parent() == services_stack
		and remove_button.position.y < upgrade_button.position.y
		and shop_media != null
		and shop_content != null
		and not shop_content.visible
		and not shop_media.clip_contents
		and shop_media.size_flags_stretch_ratio > shop_content.size_flags_stretch_ratio
		and shopkeeper_stage.custom_minimum_size.y >= 600.0,
		"The shop services were not vertically stacked over the shared shopkeeper backdrop."
	)
	_expect(
		first_shopkeeper_art.scale.x >= 0.67
		and first_shopkeeper_art.scale.x <= 0.69
		and first_shopkeeper_art.position.y <= -150.0
		and continue_button != null
		and continue_button.custom_minimum_size.x >= 360.0
		and continue_button.custom_minimum_size.y >= 64.0,
		"The shopkeeper was not zoomed out beside the enlarged Continue on Route action."
	)
	var offered_ids: Array = main.run.pending_route_node.get("inventory", [])
	var selected_shop_card_id := String(offered_ids[0]) if not offered_ids.is_empty() else ""
	var selected_shop_choice := main.find_child("RouteShopCardChoice_%s" % selected_shop_card_id, true, false) as Control
	var selected_shop_button := main.find_child("RouteShopBuy_%s" % selected_shop_card_id, true, false) as Button
	var selected_shop_face := selected_shop_choice.find_child("RuntimeCardFace", true, false) as Control if selected_shop_choice != null else null
	var choice_base_position: Vector2 = selected_shop_choice.get_meta("base_position", selected_shop_choice.position) if selected_shop_choice != null else Vector2.ZERO
	_expect(
		selected_shop_choice != null
		and selected_shop_button != null
		and not selected_shop_button.visible
		and selected_shop_face != null
		and selected_shop_choice.size == Vector2(136, 193),
		"The four-card shop case did not begin with larger readable cards and hidden purchase actions."
	)
	main._select_route_shop_card(selected_shop_card_id)
	_expect(
		selected_shop_button != null
		and selected_shop_button.visible
		and selected_shop_choice.position.y < choice_base_position.y
		and selected_shop_choice.scale.x > 1.0,
		"Selecting a shop card did not lift it and reveal its Buy Card action."
	)
	for label_node in main.find_children("*", "Label", true, false):
		var shop_copy := String((label_node as Label).text).strip_edges().to_lower()
		_expect(
			shop_copy not in ["route shop", "cards for sale", "services", "corner card counter"]
			and not shop_copy.begins_with("a one-stop visit"),
			"The wordless shop layout still rendered removed shop-heading copy: %s" % shop_copy
		)
	var deck_before_shop_purchase: int = int(main._deck_total(main.run.deck))
	var money_before_shop_purchase := int(main.run.money)
	var selected_shop_price: int = int(main._card_price(selected_shop_card_id))
	selected_shop_button.emit_signal("pressed")
	await process_frame
	await process_frame
	_expect(
		main._deck_total(main.run.deck) == deck_before_shop_purchase + 1
		and int(main.run.money) == money_before_shop_purchase - selected_shop_price
		and not main.run.pending_route_node.get("inventory", []).has(selected_shop_card_id)
		and main.selected_route_shop_card_id == ""
		and main.last_card_add_effect_context == "route_shop",
		"The revealed Buy Card action did not complete one purchase through the shared card-add effect."
	)
	_expect(
		main.last_route_shop_purchase_effect_stages == [
			"sale_locked", "funds_debited", "card_collected", "deck_confirmed"
		],
		"The route-shop purchase did not record the full styled transaction sequence."
	)
	var repeated_inventory: Array = main.run.pending_route_node.get("inventory", []).duplicate()
	main._show_route_shop()
	await process_frame
	var repeated_held_card := main.find_child("RouteShopkeeperHeldCard", true, false) as Control
	_expect(
		repeated_held_card != null
		and String(repeated_held_card.get_meta("card_id", "")) == first_held_card_id,
		"Refreshing one shop visit changed the shopkeeper's held card."
	)
	main.run.pending_route_node = {
		"id": "shop_smoke_next",
		"type": "shop",
		"label": "Next Shop",
		"inventory": repeated_inventory,
	}
	main._show_route_shop()
	await process_frame
	var next_held_card := main.find_child("RouteShopkeeperHeldCard", true, false) as Control
	var next_held_card_id := String(main.run.pending_route_node.get("shopkeeper_card_id", ""))
	_expect(
		next_held_card != null
		and next_held_card_id != ""
		and next_held_card_id != first_held_card_id
		and String(next_held_card.get_meta("card_id", "")) == next_held_card_id,
		"A new shop visit repeated the shopkeeper's previous display card."
	)
	main._show_route_remove_card()
	await process_frame
	await process_frame
	var remove_overlay := main.find_child("RouteShopServiceOverlay", true, false) as Control
	var remove_grid := main.find_child("RouteRemoveChoices", true, false) as GridContainer
	var remove_confirm := main.find_child("RouteRemoveConfirmButton", true, false) as Button
	var underlying_shop := main.find_child("RouteShopEncounter", true, false) as PanelContainer
	var hidden_shopkeeper := underlying_shop.find_child("RouteShopkeeperArtwork", true, false) as TextureRect if underlying_shop != null else null
	var first_remove_choice := remove_grid.get_child(0) as Control if remove_grid != null and remove_grid.get_child_count() > 0 else null
	var first_remove_face := first_remove_choice.find_child("RuntimeCardFace", true, false) as Control if first_remove_choice != null else null
	_expect(main.current_screen == "route_remove" and remove_overlay != null, "Card removal did not open as a shop overlay.")
	_expect(underlying_shop != null and main.find_child("RouteRemoveEncounter", true, false) == null, "Card removal replaced the shop with a second encounter screen.")
	_expect(remove_grid != null and remove_grid.columns == 6 and remove_grid.get_child_count() > 0, "The removal overlay did not lay out the deck as a six-column card grid.")
	_expect(first_remove_face != null, "The removal overlay did not render its choices through the shared card face.")
	_expect(hidden_shopkeeper != null and not hidden_shopkeeper.visible, "The shopkeeper remained visible behind the removal picker.")
	_expect(remove_confirm != null and remove_confirm.disabled, "The removal confirmation was not initially disabled.")
	var remove_choice_id := String(first_remove_choice.get_meta("card_id", "")) if first_remove_choice != null else ""
	main._select_route_shop_service_card("remove", remove_choice_id)
	var remove_outline := first_remove_choice.find_child("RouteServiceSelectionOutline", true, false) as Control if first_remove_choice != null else null
	_expect(
		remove_outline != null
		and remove_outline.visible
		and remove_confirm != null
		and not remove_confirm.disabled,
		"Selecting a rendered removal card did not reveal its selection state and confirmation action."
	)
	main._close_route_shop_service_overlay()
	await process_frame
	_expect(main.route_shop_service_overlay == null and hidden_shopkeeper.visible, "Closing the removal overlay did not restore the shopkeeper and shop interaction.")

	main._show_route_upgrade_card()
	await process_frame
	await process_frame
	var upgrade_overlay := main.find_child("RouteShopServiceOverlay", true, false) as Control
	var upgrade_grid := main.find_child("RouteUpgradeChoices", true, false) as GridContainer
	var upgrade_confirm := main.find_child("RouteUpgradeConfirmButton", true, false) as Button
	var first_upgrade_choice := upgrade_grid.get_child(0) as Control if upgrade_grid != null and upgrade_grid.get_child_count() > 0 else null
	var first_upgrade_face := first_upgrade_choice.find_child("RuntimeCardFace", true, false) as Control if first_upgrade_choice != null else null
	_expect(
		main.current_screen == "route_upgrade"
		and upgrade_overlay != null
		and upgrade_grid != null
		and first_upgrade_face != null
		and upgrade_confirm != null
		and upgrade_confirm.disabled
		and not hidden_shopkeeper.visible
		and main.find_child("RouteUpgradeEncounter", true, false) == null,
		"Card upgrade did not reuse the rendered-card shop overlay without the shopkeeper."
	)
	var selected_upgrade_id := String(first_upgrade_choice.get_meta("card_id", "")) if first_upgrade_choice != null else ""
	var selected_upgrade_count_before: int = main.route_run_service.upgrade_count(main.run, selected_upgrade_id)
	main._select_route_shop_service_card("upgrade", selected_upgrade_id)
	await main._route_upgrade_card(selected_upgrade_id)
	await process_frame
	var sold_upgrade_button := main.find_child("RouteShopUpgradeButton", true, false) as Button
	_expect(
		main.last_card_upgrade_animation_stages == ["white", "shake", "shine"]
		and main.route_run_service.upgrade_count(main.run, selected_upgrade_id) == selected_upgrade_count_before + 1
		and main.route_shop_service_overlay == null
		and sold_upgrade_button != null
		and sold_upgrade_button.disabled,
		"Confirming a shop upgrade did not run the white, shake, and foil-shine ceremony before returning to the shop."
	)
	main.run.route_battle = {
		"active": true,
		"node_id": "upgrade_battle",
		"node_type": "enemy",
		"label": "Upgrade Test Rival",
		"opponent_affinity": "hearty",
		"location": "Test Table",
	}
	main._begin_kitchen_match(main.run.deck, starter_deck, "Upgrade Test Rival", false, 19, "player", "easy")
	await process_frame
	await process_frame
	var tabletop := main.find_child("Tabletop3DPrototype", true, false)
	var battle_upgrade: Dictionary = tabletop.service.card(runtime_upgrade_id) if tabletop != null else {}
	_expect(tabletop != null and not battle_upgrade.is_empty(), "The Living Table did not load the upgraded runtime card.")
	if base_card.has("attack"):
		_expect(int(battle_upgrade.get("attack", 0)) == int(base_card.get("attack", 0)) + 1, "The Living Table did not use the upgraded Attack value.")

	main.run.pending_route_node = {"id": "event_smoke", "type": "event", "label": "Smoke Event", "event_outcome": "heal"}
	main._show_route_event()
	await process_frame
	var event_buttons := main.find_children("RouteEvent_*", "Button", true, false)
	_expect(event_buttons.size() == 1 and String(event_buttons[0].name).begins_with("RouteEvent_heal"), "A ! node displayed more than its one selected outcome.")

	main.run.pending_route_node = {
		"id": "trade_event_smoke",
		"type": "event",
		"label": "Friendly Trader",
		"event_outcome": "trade_card",
	}
	main._show_route_event()
	await process_frame
	await process_frame
	var trade_node: Dictionary = main.run.pending_route_node
	var trading_card_id := String(trade_node.get("trading_card_id", ""))
	var getting_card_id := String(trade_node.get("getting_card_id", ""))
	var outgoing_face := main.find_child("RouteTradeOutgoingCardFace", true, false) as Control
	var incoming_face := main.find_child("RouteTradeIncomingCardFace", true, false) as Control
	var trading_label := main.find_child("RouteTradeOutgoingLabel", true, false) as Label
	var getting_label := main.find_child("RouteTradeIncomingLabel", true, false) as Label
	var trade_arrows := main.find_child("RouteTradeArrows", true, false) as TextureRect
	var trade_button := main.find_child("RouteEvent_trade_card", true, false) as Button
	var decline_trade_button := main.find_child("RouteEvent_decline_trade", true, false) as Button
	_expect(
		trading_card_id != ""
		and getting_card_id != ""
		and trading_card_id != getting_card_id
		and outgoing_face != null
		and incoming_face != null
		and outgoing_face.find_child("RuntimeCardFace", true, false) != null
		and incoming_face.find_child("RuntimeCardFace", true, false) != null
		and trading_label != null
		and trading_label.text == "TRADING"
		and getting_label != null
		and getting_label.text == "GETTING"
		and trade_arrows != null
		and trade_arrows.texture != null
		and trade_button != null
		and decline_trade_button != null,
		"The trade event did not show both live card faces, exchange labels, arrows, and actions."
	)
	main._show_route_event()
	await process_frame
	_expect(
		String(main.run.pending_route_node.get("trading_card_id", "")) == trading_card_id
		and String(main.run.pending_route_node.get("getting_card_id", "")) == getting_card_id,
		"Reopening the same trade event rerolled its persisted offer."
	)
	var trade_deck_total_before: int = service.deck_total(main.run.deck)
	var trading_count_before := int(main.run.deck.get(trading_card_id, 0))
	var getting_count_before := int(main.run.deck.get(getting_card_id, 0))
	await main._resolve_route_event("trade_card", trading_card_id, getting_card_id)
	await process_frame
	_expect(
		service.deck_total(main.run.deck) == trade_deck_total_before
		and int(main.run.deck.get(trading_card_id, 0)) == trading_count_before - 1
		and int(main.run.deck.get(getting_card_id, 0)) == getting_count_before + 1
		and main.last_route_trade_animation_stages == ["cross", "receive"]
		and main.run.route_resolved.has("trade_event_smoke"),
		"Accepting the trade did not animate, exchange exactly one card, and resolve the event."
	)

	print("ROUTE_SHOP_EVENT_SMOKE_TEST_OK")
	quit(0 if _errors.is_empty() else 1)


func _test_event_outcomes(service: RefCounted, catalog: RefCounted, starter_deck: Dictionary) -> void:
	var base_run := {
		"starter": "spicy",
		"deck": service.compact_starter_deck(starter_deck, 15),
		"collection": service.compact_starter_deck(starter_deck, 15),
		"card_upgrades": {},
		"life": 20,
		"max_life": 40,
		"money": 8,
	}
	var event_run: Dictionary = base_run.duplicate(true)
	service.resolve_event(event_run, "heal")
	_expect(int(event_run.life) == 28, "The heal event did not heal 8 life.")
	event_run = base_run.duplicate(true)
	service.resolve_event(event_run, "max_life")
	_expect(int(event_run.max_life) == 45, "The max-life event did not add 5 max life.")
	event_run = base_run.duplicate(true)
	service.resolve_event(event_run, "money")
	_expect(int(event_run.money) == 13, "The money event did not award $5.")
	event_run = base_run.duplicate(true)
	service.resolve_event(event_run, "steal_money")
	_expect(int(event_run.money) == 5, "The theft event did not steal $3.")
	event_run = base_run.duplicate(true)
	var deck_before_remove: int = service.deck_total(event_run.deck)
	service.resolve_event(event_run, "remove_card", String(event_run.deck.keys()[0]), 1)
	_expect(service.deck_total(event_run.deck) == deck_before_remove - 1, "The forced-removal event did not remove one card.")
	event_run = base_run.duplicate(true)
	var upgrade_id := String(service.upgradeable_card_ids(event_run)[0])
	var event_upgrade: Dictionary = service.resolve_event(event_run, "upgrade_card", upgrade_id)
	_expect(bool(event_upgrade.get("ok", false)), "The risky-upgrade event did not upgrade its selected card.")
	_expect(service.upgrade_count(event_run, upgrade_id) == 1 and int(event_run.life) == 15, "The risky-upgrade event did not persist the upgrade and deal 5 damage.")
	event_run = base_run.duplicate(true)
	var trade_offer: Dictionary = service.trade_offer_for_node(event_run, "spicy", 1234, "event_trade")
	var repeated_trade_offer: Dictionary = service.trade_offer_for_node(event_run, "spicy", 1234, "event_trade")
	var trading_card_id := String(trade_offer.get("trading_card_id", ""))
	var getting_card_id := String(trade_offer.get("getting_card_id", ""))
	_expect(trade_offer == repeated_trade_offer, "The same seeded trade event did not keep a deterministic offer.")
	_expect(
		int(event_run.deck.get(trading_card_id, 0)) > 0
		and getting_card_id != ""
		and getting_card_id != trading_card_id
		and service.card_is_starter_eligible(catalog.cards_by_id[getting_card_id], "spicy"),
		"The trade event offered an invalid source or an out-of-ecosystem replacement."
	)
	var trade_size_before: int = service.deck_total(event_run.deck)
	var trading_count_before := int(event_run.deck.get(trading_card_id, 0))
	var getting_count_before := int(event_run.deck.get(getting_card_id, 0))
	var trade_result: Dictionary = service.resolve_event(
		event_run,
		"trade_card",
		trading_card_id,
		1,
		getting_card_id
	)
	_expect(bool(trade_result.get("ok", false)), "The valid card trade was rejected.")
	_expect(
		service.deck_total(event_run.deck) == trade_size_before
		and int(event_run.deck.get(trading_card_id, 0)) == trading_count_before - 1
		and int(event_run.deck.get(getting_card_id, 0)) == getting_count_before + 1,
		"The card trade did not preserve deck size while exchanging exactly one card."
	)


func _different_card_id(ids: Array, excluded: String) -> String:
	for card_id_value in ids:
		var card_id := String(card_id_value)
		if card_id != excluded:
			return card_id
	return excluded


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_errors.append(message)
	push_error(message)
