extends SceneTree
## Bounded native render check of the supplied shop and its live service surfaces.
var failures: Array[String] = []
var capture_directory := "res://outputs/supplied_locals_2026_09_14/shop"
const AREAS := [
	["seller", "HubSellerButton", "HubShopkeeper"],
	["counter", "HubShopButton", "HubShopDesk"],
	["machine", "HubMachineButton", "VendingMachineBody"],
]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			capture_directory = argument.trim_prefix("--capture-dir=")
	var main = load("res://scenes/Main.tscn").instantiate()
	main.autosave_suspended = true
	root.add_child(main)
	await process_frame
	await process_frame
	main.autosave_enabled = false
	main.player_settings.reduced_motion = true
	main.run_state_service.save_path = "/private/tmp/supplied-shop-capture-%d.json" % OS.get_process_id()
	var deck: Dictionary = main._deck_entries_to_dict(main.archetypes_by_id.spicy.starterDeck)
	main.run = main.run_state_service.create_run("spicy", deck, "hearty", "season", "blue")
	main.route_run_service.initialize_run(main.run, 424242)
	main.run.money = 16
	main.run.life = 25
	main.run.hub_shop = {"id": "locals_card_shop", "type": "shop", "hub_shop": true, "inventory": ["spicy_jalapeno_panther", "item_switchblade", "spicy_hot_honey_bee", "spicy_sriracharrow"]}
	main._show_tournament_hub()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_directory))
	for dimensions in [Vector2i(1280, 720), Vector2i(1440, 900)]:
		root.size = dimensions
		main._leave_hub_shop()
		await _settle()
		await _neutral_pointer()
		var hub = main.find_child("TournamentHub", true, false)
		for artwork_name in ["HubRoomArtwork", "HubShopDesk", "VendingMachineBody"]:
			_expect(hub.find_child(artwork_name, true, false).get_meta("asset_origin", "") == "owner_supplied_screen_layers", artwork_name + " is not using supplied art")
		for control in [hub._tournament_slip, hub._life_label, hub._funds_label, hub._deck_button, hub._next_round_button]:
			_expect(root.get_visible_rect().encloses(control.get_global_rect()), "Shop status or action clipped: " + String(control.name))
		var status_rect: Rect2 = hub.find_child("HubTopBar", true, false).get_global_rect()
		for control in [hub._tournament_slip, hub._life_label, hub._funds_label, hub._deck_button]:
			_expect(status_rect.encloses(control.get_global_rect()), "Readout escaped its shared painted surface: " + String(control.name))
		_check_overview_layout(hub, "%dx%d" % [dimensions.x, dimensions.y])
		_capture("overview", dimensions)
		await _exercise_overview_areas(main, hub, dimensions)
		main._open_hub_view("counter")
		await _settle()
		_check_top_controls(hub, "counter %s" % dimensions)
		for control in hub._shop_view.focus_controls() + [hub._reroll_button]:
			_expect(root.get_visible_rect().encloses(control.get_global_rect()), "Counter action clipped: " + String(control.name))
		_capture("counter", dimensions)
		main._open_hub_view("machine")
		await _settle()
		_check_top_controls(hub, "vending %s" % dimensions)
		for control in hub._snack_view.focus_controls():
			_expect(root.get_visible_rect().encloses(control.get_global_rect()), "Snack choice clipped: " + String(control.name))
			_expect(control.is_visible_in_tree() and not control.disabled, "Snack choice is not usable")
		_expect(not hub._heal_button.is_visible_in_tree() and not hub._upgrade_button.is_visible_in_tree(), "A snack action appeared before selection")
		_capture("vending", dimensions)
		main._open_hub_view("seller")
		await _settle()
		_check_top_controls(hub, "seller %s" % dimensions)
		_capture("seller", dimensions)
	root.size = Vector2i(1280, 720)
	main.player_settings.text_scale = 1.25
	main._apply_accessibility_to_tree()
	main._show_tournament_hub()
	main._open_hub_view("machine")
	await _settle()
	_capture("vending_large_text", Vector2i(1280, 720))
	main.run.life = main.run.max_life
	main._show_tournament_hub()
	await _settle()
	_capture("vending_full_life", Vector2i(1280, 720))
	main.run.hub_break_used = true
	main.run.hub_break_choice = "upgrade"
	main._show_tournament_hub()
	await _settle()
	_capture("vending_used", Vector2i(1280, 720))
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/content/demo_progression.json"))
	for box in config.deckboxes:
		if box.id == "big_lunch":
			main.run.deckbox = box.duplicate(true)
	main.run.week = 2
	main.run.hub_round = 2
	main.run.max_life = 45
	main.run.life = 28
	main.run.hub_notice = "Sriracharrow added to your deck."
	main._show_tournament_hub()
	main._leave_hub_shop()
	await _settle()
	var hub = main.find_child("TournamentHub", true, false)
	hub.show_notice("Sriracharrow added to your deck.", true)
	await _settle()
	var status_rect: Rect2 = hub.find_child("HubTopBar", true, false).get_global_rect()
	_expect(status_rect.encloses(hub._deckbox_button.get_global_rect()), "Champion deckbox escaped the shared status surface at large text")
	_expect(root.get_visible_rect().encloses(hub._deckbox_button.get_global_rect()), "Champion deckbox clipped at large text")
	_check_overview_layout(hub, "1280x720 champion deckbox at125%")
	_capture("overview_deckbox_large_text", Vector2i(1280, 720))
	main._open_hub_view("counter")
	await _settle()
	_capture("counter_large_text", Vector2i(1280, 720))
	for dimensions in [Vector2i(1280, 720), Vector2i(1440, 900)]:
		root.size = dimensions
		main._leave_hub_shop()
		await _settle()
		await _neutral_pointer()
		_check_overview_layout(hub, "%s at125%%" % dimensions)
		_capture("overview_large_text", dimensions)
		await _exercise_overview_areas(main, hub, dimensions, "large_text_")
	main._release_audio_streams()
	main.queue_free()
	await process_frame
	for failure in failures: push_error(failure)
	print("Supplied shop visual checks: %d failures" % failures.size())
	quit(0 if failures.is_empty() else 1)

func _settle() -> void:
	for unused in range(12): await process_frame
	RenderingServer.force_draw(false)
	await process_frame

func _capture(view: String, dimensions: Vector2i) -> void:
	if DisplayServer.get_name() == "headless": return
	var path := capture_directory.path_join("%s_%dx%d.png" % [view, dimensions.x, dimensions.y])
	_expect(root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path)) == OK, "Capture failed: " + path)
	print("SUPPLIED_SHOP_CAPTURE ", path)

func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)

func _check_top_controls(hub: Control, context: String) -> void:
	var viewport_rect := root.get_visible_rect()
	var status := hub.find_child("HubTopBar", true, false) as Control
	var status_rect := status.get_global_rect()
	_expect(viewport_rect.encloses(status_rect), "Shared shop status is clipped: " + context)
	_expect(status_rect.position.x < viewport_rect.size.x * 0.08 and status_rect.position.y < viewport_rect.size.y * 0.10, "Shared shop status is not in the upper-left corner: " + context)
	var utility_rects: Array[Rect2] = []
	for name in ["HubSaveButton", "HubSettingsButton"]:
		var button := hub.find_child(name, true, false) as Button
		var rect := button.get_global_rect()
		_expect(button.is_visible_in_tree() and not button.disabled and viewport_rect.encloses(rect), "%s is unavailable or clipped: %s" % [name, context])
		_expect(rect.get_center().x > viewport_rect.size.x * 0.65 and rect.position.y < viewport_rect.size.y * 0.12, "%s is not in the upper-right corner: %s" % [name, context])
		_expect(not status_rect.intersects(rect), "%s overlaps the shared status: %s" % [name, context])
		for other in utility_rects:
			_expect(not other.intersects(rect), "Save and Settings overlap: " + context)
		utility_rects.append(rect)

func _check_overview_layout(hub: Control, context: String) -> void:
	_check_top_controls(hub, context)
	var viewport_rect := root.get_visible_rect()
	var next := hub.find_child("HubNextRoundButton", true, false) as Button
	var next_rect := next.get_global_rect()
	_expect(next.is_visible_in_tree() and not next.disabled and viewport_rect.encloses(next_rect), "Next Round is unavailable or clipped: " + context)
	_expect(absf(next_rect.get_center().x - viewport_rect.get_center().x) < 3.0, "Next Round is not horizontally centered: " + context)
	_expect(next_rect.position.y > viewport_rect.size.y * 0.80, "Next Round is not near the bottom edge: " + context)
	_expect(next.size.x >= 320 and next.size.y >= 60, "Next Round lost its large primary-action footprint: " + context)
	for name in ["HubSellerHint", "HubMachineHint"]:
		var label := hub.find_child(name, true, false) as Control
		_expect(label == null or not label.is_visible_in_tree(), "An overview furniture label still covers the artwork: " + name + " " + context)
	var case_button := hub.find_child("HubShopButton", true, false) as Button
	_expect(case_button.text.is_empty(), "The case still shows a permanent word label: " + context)
	var display := hub.find_child("HubShopDisplayWindow", true, false) as Control
	_expect(case_button.get_global_rect().encloses(display.get_global_rect()), "The case button is not attached to the physical display: " + context)
	_expect(not next_rect.intersects(case_button.get_global_rect()), "Next Round overlaps the physical case target: " + context)
	var clerk := hub.find_child("HubShopkeeper", true, false) as TextureRect
	var painted_clerk := _painted_texture_rect(clerk)
	_expect(painted_clerk.has_area(), "The clerk has no visible supplied pixels: " + context)
	var status := hub.find_child("HubTopBar", true, false) as Control
	_expect(not status.get_global_rect().intersects(painted_clerk), "Shared status covers Mina's painted silhouette: " + context)
	for name in ["HubSellerButton", "HubShopButton", "HubMachineButton"]:
		var button := hub.find_child(name, true, false) as Button
		_expect(button.is_visible_in_tree() and not button.disabled and button.focus_mode == Control.FOCUS_ALL and viewport_rect.encloses(button.get_global_rect()), "Physical shop area is inaccessible: " + name + " " + context)
		_expect(not button.tooltip_text.is_empty(), "Label-free shop area lost its accessible description: " + name + " " + context)
	var notice := hub.find_child("HubNoticeLabel", true, false) as Label
	if notice.is_visible_in_tree():
		_expect(viewport_rect.encloses(notice.get_global_rect()) and not notice.get_global_rect().intersects(next_rect), "Shop notice overlaps Next Round or is clipped: " + context)

func _exercise_overview_areas(main: Node, hub: Control, dimensions: Vector2i, prefix: String = "") -> void:
	for area in AREAS:
		var area_id := String(area[0])
		var context := "%s %s %s" % [dimensions, prefix, area_id]
		var button := hub.find_child(String(area[1]), true, false) as Button
		await _neutral_pointer()
		_check_highlights(hub, "", "idle before " + context)
		# Programmatic focus alone must not switch a pointer-driven highlight.
		# Start keyboard navigation before positioning the requested focus target.
		_press_key(KEY_TAB)
		button.grab_focus()
		await _settle()
		_expect(root.gui_get_focus_owner() == button, "Physical area cannot receive keyboard focus: " + context + " " + _input_state(hub, button))
		_check_highlights(hub, area_id, "keyboard focus " + context)
		_capture(prefix + "focus_" + area_id, dimensions)
		_press_key(KEY_ENTER)
		await _settle()
		_check_open_area(hub, area_id, "keyboard activation " + context)
		main.call("_leave_hub_shop")
		await _settle()
		_check_room_return(main, hub, "after keyboard activation " + context)
		await _neutral_pointer()
		_move_pointer(button.get_global_rect().get_center())
		await _settle()
		# Native resize/warp notifications can arrive during rendered settling.
		# Deliver the intended motion after those events, then inspect and render
		# the actual GUI hit-test result without another OS event-pump interval.
		Input.flush_buffered_events()
		_push_pointer(button.get_global_rect().get_center())
		RenderingServer.force_draw(false)
		_expect(button.is_hovered(), "Pointer did not reach the physical area: " + context + " " + _input_state(hub, button))
		_check_highlights(hub, area_id, "pointer hover " + context)
		_capture(prefix + "hover_" + area_id, dimensions)
		_click(button)
		await _settle()
		_check_open_area(hub, area_id, "pointer activation " + context)
		main.call("_leave_hub_shop")
		await _settle()
		_check_room_return(main, hub, "after pointer activation " + context)
	await _neutral_pointer()
	_check_highlights(hub, "", "idle after visiting every area")

func _check_room_return(main: Node, hub: Control, context: String) -> void:
	_expect(main.get("current_screen") == "route_hub" and not hub.get("_shop_open") and not hub.get("_seller_open") and not hub.get("_machine_open") and not hub.get("_transitioning"), "Back did not restore the room: " + context + " pending=" + str(main.get("run").get("pending_route_node", {})))

func _input_state(hub: Control, button: Button) -> String:
	return "mouse=%s rect=%s disabled=%s focus_mode=%d views=%s" % [root.get_mouse_position(), button.get_global_rect(), button.disabled, button.focus_mode, [hub.get("_shop_open"), hub.get("_seller_open"), hub.get("_machine_open")]]

func _check_open_area(hub: Control, area_id: String, context: String) -> void:
	var property := "_shop_open" if area_id == "counter" else "_seller_open" if area_id == "seller" else "_machine_open"
	_expect(bool(hub.get(property)) and not bool(hub.get("_transitioning")), "%s did not open the correct area: %s" % [context, area_id])
	_check_highlights(hub, "", context + " during close-up")
	for area in AREAS:
		var button := hub.find_child(String(area[1]), true, false) as Button
		_expect(button.disabled, "A physical room target remained active during close-up: " + String(area[0]))

func _check_highlights(hub: Control, active_area: String, context: String) -> void:
	for area in AREAS:
		var button := hub.find_child(String(area[1]), true, false) as Button
		var artwork := hub.find_child(String(area[2]), true, false) as CanvasItem
		var expected := String(area[0]) == active_area
		_expect(bool(button.get_meta("highlight_active", false)) == expected, "Wrong area highlight state: %s (%s)" % [area[0], context])
		var material := artwork.material as ShaderMaterial
		_expect(material != null, "Physical area lacks an artwork highlight material: " + String(area[0]))
		if material != null:
			var strength := float(material.get_shader_parameter("highlight_strength"))
			_expect(is_equal_approx(strength, 1.0 if expected else 0.0), "Artwork highlight disagrees with interaction state: %s (%s)" % [area[0], context])

func _neutral_pointer() -> void:
	var focused := root.gui_get_focus_owner()
	if focused != null:
		focused.release_focus()
	var viewport_rect := root.get_visible_rect()
	var point := viewport_rect.position + viewport_rect.size * Vector2(0.985, 0.20)
	_move_pointer(point)
	await _settle()
	Input.flush_buffered_events()
	_push_pointer(point)

func _move_pointer(point: Vector2) -> void:
	# Native window resize events can replace a synthetic motion with the OS
	# pointer's old position. Keep the real pointer and the injected event aligned.
	if DisplayServer.get_name() != "headless":
		root.warp_mouse(point)
	_push_pointer(point)

func _push_pointer(point: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	event.global_position = point
	root.push_input(event, true)

func _press_key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)

func _painted_texture_rect(artwork: TextureRect) -> Rect2:
	if artwork == null or artwork.texture == null:
		return Rect2()
	var image := artwork.texture.get_image()
	if image == null:
		return Rect2()
	var used := Rect2(image.get_used_rect())
	var source_size := artwork.texture.get_size()
	var fit := minf(artwork.size.x / source_size.x, artwork.size.y / source_size.y)
	var origin := (artwork.size - source_size * fit) * 0.5
	var local_rect := Rect2(origin + used.position * fit, used.size * fit)
	var transform := artwork.get_global_transform()
	var bounds := Rect2(transform * local_rect.position, Vector2.ZERO)
	for point in [Vector2(local_rect.end.x, local_rect.position.y), local_rect.end, Vector2(local_rect.position.x, local_rect.end.y)]:
		bounds = bounds.expand(transform * point)
	return bounds

func _click(control: Control) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = control.get_global_rect().get_center()
	event.global_position = event.position
	root.push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)
