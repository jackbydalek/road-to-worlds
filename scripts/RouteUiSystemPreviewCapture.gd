extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")
const OUTPUT_ROOT := "res://outputs/illustrated_vfx"

var main: Control


func _initialize() -> void:
	root.size = Vector2i(1440, 900)
	call_deferred("_run")


func _run() -> void:
	main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await _settle(4)
	main.autosave_enabled = false
	main.player_settings.reduced_motion = true
	main._start_new_run_with_mode("spicy", "season", "white")
	await _settle(10)

	main.run.pending_route_node = {
		"id": "preview_shop",
		"type": "shop",
		"label": "Corner Card Counter",
	}
	main._show_route_shop()
	await _settle(6)
	await _capture("route_ui_system_shop.png")
	main._show_route_remove_card()
	await _settle(8)
	await _capture("route_ui_system_shop_remove_overlay.png")
	var remove_choices := main.find_child("RouteRemoveChoices", true, false) as GridContainer
	if remove_choices != null and remove_choices.get_child_count() > 0:
		var remove_choice := remove_choices.get_child(0) as Control
		main._select_route_shop_service_card("remove", String(remove_choice.get_meta("card_id", "")))
		await _settle(5)
		await _capture("route_ui_system_shop_remove_selected.png")
	main._close_route_shop_service_overlay()
	await _settle(4)
	main._show_route_upgrade_card()
	await _settle(8)
	await _capture("route_ui_system_shop_upgrade_overlay.png")
	main._close_route_shop_service_overlay()
	await _settle(4)
	var shop_inventory: Array = main.run.get("pending_route_node", {}).get("inventory", [])
	if not shop_inventory.is_empty():
		var selected_shop_card_id := String(shop_inventory[0])
		main._select_route_shop_card(selected_shop_card_id)
		await _settle(6)
		await _capture("route_ui_system_shop_selected.png")
		main.player_settings.reduced_motion = false
		main._route_shop_buy_card(selected_shop_card_id)
		await create_timer(0.10).timeout
		await _capture("route_ui_system_shop_card_added.png")
		await create_timer(0.22).timeout
		main.player_settings.reduced_motion = true

	main.run.pending_route_node = {
		"id": "preview_event",
		"type": "event",
		"label": "A Street-Table Expert",
		"event_outcome": "upgrade_card",
	}
	main._show_route_event()
	await _settle(6)
	await _capture("route_ui_system_event.png")

	main.run.pending_route_node = {
		"id": "preview_trade_event",
		"type": "event",
		"label": "Friendly Trader",
		"event_outcome": "trade_card",
	}
	main._show_route_event()
	await _settle(8)
	await _capture("route_ui_system_trade_event.png")
	var trade_node: Dictionary = main.run.pending_route_node
	main.player_settings.reduced_motion = false
	main._resolve_route_event(
		"trade_card",
		String(trade_node.get("trading_card_id", "")),
		String(trade_node.get("getting_card_id", ""))
	)
	await create_timer(0.22).timeout
	await _capture("route_ui_system_trade_animation.png")
	await create_timer(0.55).timeout
	main.player_settings.reduced_motion = true

	main.run.pending_route_node = {
		"id": "preview_enemy",
		"type": "enemy",
		"label": "Park Regular Jules",
	}
	main.run.route_battle = {
		"active": true,
		"node_id": "preview_enemy",
		"node_type": "enemy",
		"label": "Park Regular Jules",
		"opponent_affinity": "hearty",
		"opponent_life": 12,
		"location": "Park Table",
	}
	main._show_route_encounter_intro()
	await _settle(6)
	await _capture("route_ui_system_encounter.png")

	main.run.reward_offer = main.route_run_service.generate_reward_offer("spicy", "enemy", 8821)
	main.run.reward_picks_remaining = main.run.reward_offer.size()
	main.run.route_pack_opened = true
	main.run.route_reward_intro_seen = true
	main._show_route_card_reward()
	await _settle(10)
	await _capture("route_ui_system_reward.png")

	print("ROUTE_UI_SYSTEM_PREVIEWS_OK")
	quit()


func _capture(file_name: String) -> void:
	await process_frame
	var image := root.get_viewport().get_texture().get_image()
	var output_path := ProjectSettings.globalize_path("%s/%s" % [OUTPUT_ROOT, file_name])
	if image == null or image.is_empty() or image.save_png(output_path) != OK:
		push_error("Could not save route UI preview: %s" % output_path)


func _settle(frame_count: int) -> void:
	for _frame in range(frame_count):
		await process_frame
