extends SceneTree

const WORKSPACE_UI := preload("res://scripts/ui/WorkspaceUIComponents.gd")

var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var normal_tag := WORKSPACE_UI.make_price_sticker(5)
	var sale_tag := WORKSPACE_UI.make_price_sticker(6)
	root.add_child(normal_tag)
	root.add_child(sale_tag)
	await process_frame

	var normal_amount := normal_tag.find_child("PriceAmount", true, false) as Label
	var sale_amount := sale_tag.find_child("PriceAmount", true, false) as Label
	var normal_style := normal_tag.get_theme_stylebox("panel") as StyleBoxFlat
	var sale_style := sale_tag.get_theme_stylebox("panel") as StyleBoxFlat
	_expect(
		not bool(normal_tag.get_meta("shows_sale", true))
		and normal_tag.find_child("SaleStrip", true, false) == null
		and normal_amount != null
		and normal_amount.text == "$5"
		and normal_style != null
		and is_equal_approx(normal_style.bg_color.a, 1.0)
		and normal_style.corner_radius_top_left <= 2,
		"A normal $5 price did not render as an opaque square yellow sticker."
	)
	_expect(
		bool(sale_tag.get_meta("shows_sale", false))
		and sale_tag.find_child("SaleStrip", true, false) != null
		and sale_amount != null
		and sale_amount.text == "$6"
		and sale_style != null
		and is_equal_approx(sale_style.bg_color.a, 1.0)
		and sale_style.corner_radius_top_left <= 2,
		"A price above $5 did not render as an opaque square sticker with the SALE strip."
	)

	if failed:
		quit(1)
		return
	print("Price sticker smoke test passed.")
	quit()


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
