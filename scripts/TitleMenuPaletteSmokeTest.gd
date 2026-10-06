extends SceneTree

const TITLE_MENU := preload("res://scenes/ui/TitleMenu.tscn")
const WORDMARK := preload("res://scripts/ui/LocalsWordmark.gd")
var preview_directory := "res://outputs/supplied_screen_art_2026-09-14/title"

var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var viewport_size := Vector2i(1440, 900)
	var use_fallback := "--fallback" in OS.get_cmdline_user_args()
	var large_text := "--large-text" in OS.get_cmdline_user_args()
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			preview_directory = argument.trim_prefix("--capture-dir=")
		if argument.begins_with("--size="):
			var parts := argument.trim_prefix("--size=").split("x")
			viewport_size = Vector2i(int(parts[0]), int(parts[1]))
	root.size = viewport_size
	var menu := TITLE_MENU.instantiate()
	menu.use_supplied_title_art = not use_fallback
	root.add_child(menu)
	await process_frame
	await process_frame
	menu.configure(false, true, false, {"run_loop": "route", "hub_round": 3, "starter": "spicy", "life": 28, "max_life": 40})
	if large_text:
		for node in menu.find_children("*", "Control", true, false):
			if node.has_theme_font_size_override("font_size"):
				node.add_theme_font_size_override("font_size", roundi(node.get_theme_font_size("font_size") * 1.25))
	await process_frame

	var sign := menu.get_node("ShopSign") as PanelContainer
	var title_logo := menu.get_node("ShopSign/TitleLogo") as Control
	var start := menu.get_node("PosterLayer/GameStartButton") as Button
	var continue_button := menu.get_node("PosterLayer/ContinueRunButton") as Button
	var how_to := menu.get_node("PosterLayer/TitleHowToPlayButton") as Button
	var credits := menu.get_node("PosterLayer/CreditsPosterButton") as Button
	var title_pattern := menu.get_node("TitlePattern") as Control
	var card_swirl := menu.get_node("CardSwirlLayer") as Control
	var grade := menu.get_node("NightColorGrade") as ColorRect
	var sign_style := sign.get_theme_stylebox("panel") as StyleBoxFlat
	var start_face = start.get_node_or_null("BattleAngularButtonFace")
	var continue_face = continue_button.get_node_or_null("BattleAngularButtonFace")
	var how_to_face = how_to.get_node_or_null("BattleAngularButtonFace")
	var credits_face = credits.get_node_or_null("BattleAngularButtonFace")
	var room_active: bool = menu.supplied_title_art_active
	if not use_fallback:
		_expect(room_active, "The approved title room was not loaded by the actual title scene.")

	_expect(is_zero_approx(sign_style.bg_color.a), "The floating title logo still has a heavy sign backing.")
	_expect(
		title_logo != null
		and title_logo.get_script().resource_path == "res://scripts/ui/LocalsWordmark.gd",
		"The title did not use the shared See You at Locals logo control."
	)
	_expect(WORDMARK.LOGO_TEXTURE.resource_path == "res://assets/logos/see_you_at_locals_supplied.png" and title_logo.get_meta("owner_supplied", false), "The title did not use the supplied hanging logo.")
	var logo_rect: Rect2 = title_logo.get_logo_rect()
	_expect(Rect2(Vector2.ZERO, title_logo.size).encloses(logo_rect), "The supplied logo overflowed its sign area.")
	_expect(is_equal_approx(logo_rect.size.x / logo_rect.size.y, WORDMARK.LOGO_SOURCE_REGION.size.x / WORDMARK.LOGO_SOURCE_REGION.size.y), "The supplied logo was stretched out of proportion.")
	_expect(ProjectSettings.get_setting("application/config/name") == "See You at Locals", "The application display name did not match the title brand.")
	_expect(ProjectSettings.get_setting("application/config/use_custom_user_dir", false), "The display-name change stopped pinning the existing save directory.")
	_expect(ProjectSettings.get_setting("application/config/custom_user_dir_name") == "Godot/app_userdata/Topdeck to Worlds", "The display-name change moved the existing save directory.")
	_expect(OS.get_user_data_dir().ends_with("/Godot/app_userdata/Topdeck to Worlds"), "The resolved user directory did not preserve existing saves.")
	_expect(continue_face != null and continue_face.variant == "primary", "Continue did not use the shared primary action button.")
	_expect(start_face != null and start_face.variant == "secondary", "New Game did not use the shared secondary paper button.")
	_expect(how_to_face != null and how_to_face.variant == "secondary", "How to Play did not use the shared secondary paper button.")
	_expect(credits_face != null and credits_face.variant == "secondary", "Credits did not use the shared secondary paper button.")
	_expect(title_pattern != null and title_pattern.get_script() != null, "The cloth-and-paper title tabletop was not active.")
	_expect(menu.get_node_or_null("StorefrontBackdrop") == null, "The retired 3D storefront was still loading behind the title.")
	if room_active:
		var room := menu.get_node_or_null("SuppliedTitleRoom") as TextureRect
		_expect(room != null and room.texture != null and room.get_meta("owner_supplied", false) and not room.get_meta("ai_generated", false), "The title illustration did not retain its supplied source marker.")
		_expect(room.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED, "The room illustration was stretched out of proportion.")
		_expect(room.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR, "The painted title inherited nearest-neighbor downscaling.")
		_expect(title_pattern.menu_only and not card_swirl.visible, "The old tabletop obscured the illustrated room.")
		_expect(card_swirl.get_child_count() == 0, "The illustrated room loaded an unnecessary foreground card fan.")
	else:
		_expect(menu.get_node_or_null("SuppliedTitleRoom") == null, "The fallback title still loaded supplied room art.")
		_expect(not title_pattern.menu_only and card_swirl.visible, "The fallback native title was not restored.")
		_expect(card_swirl.get_child_count() >= 6, "The fallback title screen did not build its tabletop card fans.")
	var action_left := continue_button.position.x
	var sheet_rect: Rect2 = menu.get_menu_sheet_rect()
	for action in [continue_button, start, how_to, credits]:
		if not room_active or action != credits:
			_expect(absf(action.position.x - action_left) < 1.0, "%s did not align with the menu sheet." % action.name)
		_expect(sheet_rect.encloses(action.get_rect()), "%s overflowed the printed menu sheet." % action.name)
		_expect(menu.get_global_rect().encloses(action.get_global_rect()), "%s overflowed the title viewport." % action.name)
	if room_active:
		_expect(is_equal_approx(how_to.position.y, credits.position.y), "The two secondary title actions did not share their compact row.")
		_expect(how_to.get_rect().end.x < credits.position.x and not how_to.get_rect().intersects(credits.get_rect()), "The secondary title actions overlap.")
		_expect(continue_button.size.x > how_to.size.x and continue_button.size.y > how_to.size.y, "The title lost its primary action hierarchy.")
	_expect(sign.get_rect().end.y <= continue_button.position.y, "Title lettering overlaps the menu's live actions.")
	if room_active:
		var room_rect: Rect2 = menu.get_title_room_rect()
		# Normalized face bounds: clerk, customer, foreground player, window player.
		for face in [Rect2(0.145, 0.245, 0.085, 0.13), Rect2(0.27, 0.265, 0.09, 0.15), Rect2(0.65, 0.44, 0.11, 0.18), Rect2(0.78, 0.27, 0.075, 0.13)]:
			var face_rect := Rect2(room_rect.position + face.position * room_rect.size, face.size * room_rect.size)
			_expect(not sheet_rect.intersects(face_rect) and not sign.get_rect().intersects(face_rect), "The room menu or wordmark obscured a person's face.")
	elif viewport_size.x >= 1000:
		_expect(continue_button.get_global_rect().get_center().x < menu.get_global_rect().get_center().x, "Wide title did not leave room for the card fan beside the menu.")
	else:
		_expect(absf(continue_button.get_global_rect().get_center().x - menu.get_global_rect().get_center().x) < 1.0, "Narrow title did not center its compact menu.")
	_expect(continue_button.visible and continue_button.position.y < start.position.y, "Continue was not placed above New Game on the title.")
	for child in card_swirl.get_children():
		_expect(child.has_meta("card_id") and child.get_node_or_null("CardFace/RuntimeCardFace") != null, "A title tabletop card was not rendered through the shared card face.")
	if not room_active:
		var first_swirl_card := card_swirl.get_child(0) as Node2D
		var position_before := first_swirl_card.position
		menu.set_process(false)
		menu.swirl_elapsed += 0.6
		menu.call("_layout_card_swirl")
		_expect(first_swirl_card.position.is_equal_approx(position_before), "The tabletop cards moved despite the static locals presentation.")
	_expect(not start.has_focus(), "New Game was highlighted before the player interacted with the title menu.")
	_expect(is_zero_approx(grade.color.a), "The old warm coffee color grade remained over the title screen.")

	if room_active:
		await _verify_title_frames(menu)

	var preview_path := preview_directory.path_join(("title_fallback_%dx%d.png" if use_fallback else "title_%dx%d.png") % [viewport_size.x, viewport_size.y])
	if DisplayServer.get_name() != "headless":
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(preview_directory))
		RenderingServer.force_draw(false)
		await process_frame
		var preview := root.get_texture().get_image()
		if large_text:
			preview_path = preview_path.trim_suffix(".png") + "_large_text.png"
		_expect(preview.save_png(preview_path) == OK, "Could not save the title-menu palette preview.")

	await _verify_menu_inputs(menu)
	menu.configure(false, false, false)
	await process_frame
	_expect(not continue_button.visible and start_face.variant == "primary", "A fresh start did not promote New game as the primary action.")
	if DisplayServer.get_name() != "headless":
		RenderingServer.force_draw(false)
		await process_frame
		var fresh_preview := root.get_texture().get_image()
		_expect(fresh_preview.save_png(preview_directory.path_join("title_fresh_%dx%d.png" % [viewport_size.x, viewport_size.y])) == OK, "Could not capture the fresh-run title.")
	var start_events := [0]
	menu.start_requested.connect(func() -> void: start_events[0] += 1)
	start.pressed.emit()
	await create_timer(0.4).timeout
	_expect(start_events[0] == 1, "New game did not emit its existing start signal once.")
	menu.queue_free()
	await process_frame
	var continue_menu := TITLE_MENU.instantiate()
	continue_menu.use_supplied_title_art = not use_fallback
	root.add_child(continue_menu)
	await process_frame
	continue_menu.configure(false, true, false, {"run_loop": "route", "hub_round": 3, "starter": "spicy", "life": 28, "max_life": 40})
	var continue_events := [0]
	continue_menu.continue_requested.connect(func() -> void: continue_events[0] += 1)
	_expect(continue_menu.continue_button.text == "Continue · Round 3", "Continue lost its saved-round label.")
	continue_menu.continue_button.pressed.emit()
	await create_timer(0.4).timeout
	_expect(continue_events[0] == 1, "Continue did not emit its existing continue signal once.")

	if failed:
		quit(1)
		return
	print("Title menu palette smoke test passed." + (" Preview: " + preview_path if DisplayServer.get_name() != "headless" else ""))
	quit(0)


func _verify_title_frames(menu: Control) -> void:
	_expect(not menu.title_frame_timer.is_stopped(), "The supplied title animation timer did not start.")
	menu.title_frame_timer.stop()
	_expect(menu.title_frames.size() == 3, "The title did not load all three supplied frames.")
	_expect(is_equal_approx(menu.title_frame_timer.wait_time, 0.125), "The title loop did not use its intended eight frames per second.")
	root.set_meta("reduced_motion", true)
	menu._advance_title_frame()
	_expect(menu.title_frame_index == 0 and menu.title_room.texture == menu.title_frames[0], "Reduced Motion did not settle on the first supplied frame.")
	root.set_meta("reduced_motion", false)
	for frame_index in [1, 2, 0]:
		menu._advance_title_frame()
		_expect(menu.title_frame_index == frame_index and menu.title_room.texture == menu.title_frames[frame_index], "The title frame sequence did not loop in supplied order.")
		if DisplayServer.get_name() != "headless":
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(preview_directory))
			RenderingServer.force_draw(false)
			await process_frame
			var image := root.get_texture().get_image()
			_expect(image.save_png(preview_directory.path_join("frame_%d_%dx%d.png" % [frame_index + 1, root.size.x, root.size.y])) == OK, "Could not capture the title animation frame.")
	root.set_meta("reduced_motion", true)
	for tick in range(4):
		menu._advance_title_frame()
	_expect(menu.title_frame_index == 0 and menu.title_room.texture == menu.title_frames[0], "Reduced Motion allowed the title to animate.")
	root.set_meta("reduced_motion", false)


func _verify_menu_inputs(menu: Control) -> void:
	var events := {"tutorial": 0, "settings": 0}
	menu.tutorial_requested.connect(func() -> void: events.tutorial += 1)
	menu.settings_requested.connect(func() -> void: events.settings += 1)
	var how_to := menu.get_node("PosterLayer/TitleHowToPlayButton") as Button
	var credits := menu.get_node("PosterLayer/CreditsPosterButton") as Button
	var options := menu.get_node("TitleOptionsButton") as Button
	var escape := InputEventKey.new()
	escape.pressed = true
	escape.keycode = KEY_ESCAPE
	how_to.pressed.emit()
	_expect(events.tutorial == 1, "How to play lost its tutorial signal.")
	credits.pressed.emit()
	_expect(menu.get_node("CreditsPanel").visible, "Credits did not open.")
	menu._unhandled_key_input(escape)
	_expect(not menu.get_node("CreditsPanel").visible and credits.has_focus(), "Escape did not dismiss credits and restore focus.")
	options.pressed.emit()
	_expect(menu.get_node("TitleOptionsPanel").visible, "Settings options did not open.")
	menu.get_node("TitleOptionsPanel/OptionsFrame/OptionsMargin/Options/TitleSettingsButton").pressed.emit()
	_expect(events.settings == 1, "Settings lost its navigation signal.")
	menu._unhandled_key_input(escape)
	_expect(not menu.get_node("TitleOptionsPanel").visible and options.has_focus(), "Escape did not dismiss options and restore focus.")
	if menu.supplied_title_art_active:
		var continue_button := menu.get_node("PosterLayer/ContinueRunButton") as Button
		continue_button.grab_focus()
		var tab := InputEventKey.new()
		tab.pressed = true
		tab.keycode = KEY_TAB
		Input.parse_input_event(tab)
		await process_frame
		_expect(menu.get_node("PosterLayer/GameStartButton").has_focus(), "Keyboard Tab did not move from Continue to New game.")
		var release := InputEventKey.new()
		release.keycode = KEY_TAB
		Input.parse_input_event(release)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
