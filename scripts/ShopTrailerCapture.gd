extends SceneTree
## Current Locals shop, recorded directly from the game at 1920×1080 / 60 fps.
## Uses a temporary run and never writes the player's save or settings.

const MAIN_SCENE := preload("res://scenes/Main.tscn")
const CAPTURE_SIZE := Vector2i(1920, 1080)
const PALETTE := preload("res://scripts/ui/GamePalette.gd")
var shop_hub
var main
var curtain: ColorRect


func _init() -> void:
	# Movie Maker reads these settings at startup, independently of root.size.
	# Runtime-only overrides preserve the project's normal gameplay resolution.
	ProjectSettings.set_setting("display/window/size/window_width_override", CAPTURE_SIZE.x)
	ProjectSettings.set_setting("display/window/size/window_height_override", CAPTURE_SIZE.y)


func _initialize() -> void:
	root.size = CAPTURE_SIZE
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	curtain = ColorRect.new()
	curtain.size = Vector2(CAPTURE_SIZE)
	curtain.color = PALETTE.CARBON
	curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	curtain.z_index = 4095
	root.add_child(curtain)
	call_deferred("_run")


func _run() -> void:
	print("SHOP_TRAILER_INITIALIZING")
	main = MAIN_SCENE.instantiate()
	main.autosave_suspended = true
	root.add_child(main)
	# Movie Maker locks dimensions on the first rendered frame. Override saved
	# window preferences immediately, before yielding that first frame.
	root.mode = Window.MODE_WINDOWED
	root.size = CAPTURE_SIZE
	await _settle(14)
	main.autosave_enabled = false
	main.run_state_service.save_path = "/private/tmp/top-cut-shop-trailer-save.json"
	main.player_settings.reduced_motion = false
	main.player_settings.text_scale = 1.0
	main.player_settings.high_contrast = false
	main.player_settings.music_volume = 60.0
	main.player_settings.sfx_volume = 85.0
	main.player_settings.master_volume = 80.0
	main._apply_player_settings(false)
	root.mode = Window.MODE_WINDOWED
	root.size = CAPTURE_SIZE
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	# Keep hover previews and tooltips out of the take, regardless of desktop pointer.
	Input.warp_mouse(Vector2(4, 4))
	var deck: Dictionary = main._deck_entries_to_dict(main.archetypes_by_id.spicy.starterDeck)
	main.run = main.run_state_service.create_run("spicy", deck, "hearty", "season", "white")
	main.route_run_service.initialize_run(main.run, 20260905)
	main.run.hub_round = 2
	main.run.life = 28
	main.run.money = 12
	main.run.hub_notice = ""
	main.run.hub_shop = {
		"id": "locals_card_shop", "type": "shop", "hub_shop": true,
		"inventory": ["spicy_jalapeno_panther", "item_switchblade", "spicy_hot_honey_bee", "spicy_sriracharrow"],
	}
	main._show_tournament_hub()
	shop_hub = main.find_child("TournamentHub", true, false)
	assert(shop_hub != null, "Trailer could not create the current shop.")
	# Feed the production spring a repeatable camera path instead of a live mouse.
	shop_hub.set_process(false)
	shop_hub._parallax_position = Vector2(-0.65, 0.12)
	shop_hub._parallax_velocity = Vector2.ZERO
	_pose(-0.65)
	root.gui_release_focus()
	await _settle(24)
	print("SHOP_TRAILER_START_FRAME ", Engine.get_process_frames())
	await _fade_from_dark(0.4)
	await _still("shop-room")
	var drift: Tween = shop_hub.create_tween()
	drift.tween_method(_pose, -0.65, 0.65, 2.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await drift.finished
	var center: Tween = shop_hub.create_tween()
	center.tween_method(_pose, 0.65, 0.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await center.finished
	main._open_hub_shop()
	await _hold(0.85)
	shop_hub.set_process(true)
	root.gui_release_focus()
	assert(shop_hub._shop_zoom == 1.0 and shop_hub._shop_view._interactive, "Trailer counter failed to open.")
	await _still("shop-counter")
	await _hold(0.8)
	var card := main.find_child("RouteShopCardButton_spicy_sriracharrow", true, false) as Button
	_move_pointer(card)
	await _hold(0.45)
	if shop_hub._shop_view._hovered_id != "spicy_sriracharrow":
		push_error("Native pointer left the card during capture. Retake with the mouse untouched.")
		quit(1)
		return
	await _still("shop-hover")
	await _hold(0.6)
	_click_control(card)
	await _hold(0.3)
	root.gui_release_focus()
	await _still("shop-card")
	await _hold(1.5)
	var copies_before: int = main.run.deck.get("spicy_sriracharrow", 0)
	var buy := main.find_child("RouteShopBuy_spicy_sriracharrow", true, false) as Button
	assert(buy != null and buy.visible and not buy.disabled, "Trailer purchase is unavailable.")
	_click_control(buy)
	await _hold(0.12)
	assert(main.route_shop_purchase_busy and main.find_child("RouteShopPurchasedCard", true, false) != null, "Purchase skipped the flying-card animation.")
	var money_during_purchase: int = main.run.money
	main._route_shop_buy_card("spicy_hot_honey_bee")
	assert(main.run.money == money_during_purchase and main.run.hub_shop.inventory.has("spicy_hot_honey_bee"), "A second purchase entered during the animation.")
	assert((main.find_child("HubDeckLabel", true, false) as Label).text == "15 CARDS", "Deck count changed before the card arrived.")
	await _still("shop-purchase")
	await _hold(0.38)
	root.gui_release_focus()
	assert(int(main.run.deck.get("spicy_sriracharrow", 0)) == copies_before + 1, "Trailer purchase did not add the card.")
	await _hold(1.7)
	assert(not main.route_shop_purchase_busy and shop_hub._shop_view._selected_id.is_empty(), "Purchase did not finish cleanly.")
	await _fade_to_dark(0.4)
	await _hold(0.12)
	print("TRAILER_CLIP_CAPTURED shop_counter")
	main._release_audio_streams()
	quit(0)


func _pose(horizontal: float) -> void:
	shop_hub._advance_parallax(Vector2(horizontal, 0.12), 1.0 / 60.0)
	shop_hub._apply_camera_pose()


func _move_pointer(control: Control) -> void:
	var point := control.get_global_rect().get_center()
	Input.warp_mouse(point * Vector2(root.size) / root.get_visible_rect().size)
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion, true)


func _click_control(control: Control) -> void:
	_move_pointer(control)
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = control.get_global_rect().get_center()
	event.global_position = event.position
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)


func _still(label: String) -> void:
	await RenderingServer.frame_post_draw
	var path := "res://outputs/shop_trailer/%s.png" % label
	assert(root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path)) == OK)


func _fade_from_dark(duration: float) -> void:
	var tween := curtain.create_tween()
	tween.tween_property(curtain, "color:a", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	curtain.hide()


func _fade_to_dark(duration: float) -> void:
	curtain.show()
	var tween := curtain.create_tween()
	tween.tween_property(curtain, "color:a", 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished


func _hold(seconds: float) -> void:
	await create_timer(seconds).timeout


func _settle(frame_count: int) -> void:
	for unused in range(frame_count):
		await process_frame
