extends SceneTree

const TITLE_MENU := preload("res://scenes/ui/TitleMenu.tscn")
const PREVIEW_PATH := "/tmp/topdeck-to-worlds-title-menu-palette.png"

var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	var menu := TITLE_MENU.instantiate()
	root.add_child(menu)
	await process_frame
	await process_frame
	menu.configure(false, true, false)
	await process_frame

	var sign := menu.get_node("ShopSign") as PanelContainer
	var title_logo := menu.get_node("ShopSign/TitleLogo") as TextureRect
	var title_logo_crop := title_logo.texture as AtlasTexture if title_logo != null else null
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

	_expect(is_zero_approx(sign_style.bg_color.a), "The floating title logo still has a heavy sign backing.")
	_expect(
		title_logo_crop != null
		and title_logo_crop.atlas != null
		and title_logo_crop.atlas.resource_path == "res://assets/logos/topdeck-to-worlds-storefront.png",
		"The supplied TOP CUT: Locals to Worlds logo was not confined to the main-menu sign."
	)
	if title_logo_crop != null and title_logo_crop.atlas != null:
		var logo_image := title_logo_crop.atlas.get_image()
		var logo_used_rect := logo_image.get_used_rect() if logo_image != null else Rect2i()
		_expect(
			logo_image != null
			and logo_used_rect.size.x > 0
			and logo_used_rect.size.y > 0
			and title_logo_crop.region.encloses(Rect2(logo_used_rect)),
			"The title-logo atlas crop cut off visible pixels from the supplied logo."
		)
	_expect(continue_face != null and continue_face.variant == "primary", "Continue did not use the shared primary angular button.")
	_expect(start_face != null and start_face.variant == "secondary", "New Game did not use the shared secondary angular button.")
	_expect(how_to_face != null and how_to_face.variant == "secondary", "How to Play did not use the shared secondary angular button.")
	_expect(credits_face != null and credits_face.variant == "secondary", "Credits did not use the shared secondary angular button.")
	_expect(title_pattern != null and title_pattern.get_script() != null, "The restrained title pattern was not active.")
	_expect(menu.get_node_or_null("StorefrontBackdrop") == null, "The retired 3D storefront was still loading behind the basic title pattern.")
	_expect(card_swirl.get_child_count() >= 6, "The title screen did not build its in-game card swirl.")
	var title_center_x: float = menu.get_global_rect().get_center().x
	for centered_button in [continue_button, start, how_to, credits]:
		_expect(absf(centered_button.get_global_rect().get_center().x - title_center_x) < 1.0, "%s was not centered on the title axis." % centered_button.name)
	_expect(continue_button.visible and continue_button.position.y < start.position.y, "Continue was not placed above New Game on the title.")
	for child in card_swirl.get_children():
		_expect(child.has_meta("card_id") and child.get_node_or_null("CardFace/RuntimeCardFace") != null, "A title swirl card was not rendered through the shared card face.")
	var first_swirl_card := card_swirl.get_child(0) as Node2D
	var position_before := first_swirl_card.position
	menu.set_process(false)
	menu.swirl_elapsed += 0.6
	menu.call("_layout_card_swirl")
	_expect(first_swirl_card.position.distance_to(position_before) > 8.0, "The title cards did not move along their inward spiral.")
	_expect(not start.has_focus(), "New Game was highlighted before the player interacted with the title menu.")
	_expect(is_zero_approx(grade.color.a), "The old warm coffee color grade remained over the title screen.")

	if DisplayServer.get_name() != "headless":
		var preview := root.get_texture().get_image()
		_expect(preview.save_png(PREVIEW_PATH) == OK, "Could not save the title-menu palette preview.")

	if failed:
		quit(1)
		return
	print("Title menu palette smoke test passed." + (" Preview: " + PREVIEW_PATH if DisplayServer.get_name() != "headless" else ""))
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
