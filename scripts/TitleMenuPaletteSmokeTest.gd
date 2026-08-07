extends SceneTree

const TITLE_MENU := preload("res://scenes/ui/TitleMenu.tscn")
const PREVIEW_PATH := "/tmp/topdeck-to-worlds-title-menu-palette.png"
const NAVY := Color("#29365F")
const CORAL := Color("#EF7E76")
const BLUSH := Color("#F2A4B8")
const PERIWINKLE := Color("#8EA9E6")
const LAVENDER_GLASS := Color("#E8E3F5")

var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	var menu := TITLE_MENU.instantiate()
	root.add_child(menu)
	await process_frame
	await process_frame

	var sign := menu.get_node("ShopSign") as PanelContainer
	var title_logo := menu.get_node("ShopSign/TitleLogo") as TextureRect
	var title_logo_crop := title_logo.texture as AtlasTexture if title_logo != null else null
	var start := menu.get_node("PosterLayer/GameStartButton") as Button
	var how_to := menu.get_node("PosterLayer/TitleHowToPlayButton") as Button
	var credits := menu.get_node("PosterLayer/CreditsPosterButton") as Button
	var grade := menu.get_node("NightColorGrade") as ColorRect
	var sign_style := sign.get_theme_stylebox("panel") as StyleBoxFlat
	var start_style := start.get_theme_stylebox("normal") as StyleBoxFlat
	var how_to_style := how_to.get_theme_stylebox("normal") as StyleBoxFlat
	var credits_style := credits.get_theme_stylebox("normal") as StyleBoxFlat

	_expect(sign_style.bg_color.is_equal_approx(Color(NAVY, 0.97)), "The title sign retained its brown café backing.")
	_expect(
		title_logo_crop != null
		and title_logo_crop.atlas != null
		and title_logo_crop.atlas.resource_path == "res://assets/logos/topdeck-to-worlds-storefront.png",
		"The supplied Topdeck to Worlds logo was not confined to the main-menu sign."
	)
	_expect(start_style.bg_color.is_equal_approx(Color(CORAL, 0.98)) and start_style.border_color.is_equal_approx(NAVY), "Start Game did not use the coral-and-navy direction.")
	_expect(how_to_style.bg_color.is_equal_approx(Color(LAVENDER_GLASS, 0.98)) and how_to_style.border_color.is_equal_approx(PERIWINKLE), "How to Play did not use the lavender-and-periwinkle direction.")
	_expect(credits_style.bg_color.is_equal_approx(Color(BLUSH, 0.96)) and credits_style.border_color.is_equal_approx(NAVY), "Credits did not use the blush-and-navy direction.")
	_expect(start.get_theme_color("font_color").is_equal_approx(NAVY), "Title-card text did not use navy ink.")
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
