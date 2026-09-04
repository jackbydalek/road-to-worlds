extends Node

const BUTTON_FACE_SCRIPT := preload("res://scripts/ui/BattleAngularButtonFace.gd")
const STYLE_STATES := ["normal", "hover", "pressed", "disabled", "focus"]


func _ready() -> void:
	add_to_group("ui_button_style_controller")
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_bind_existing_buttons")


func _bind_existing_buttons() -> void:
	var root := get_tree().root
	for node in root.find_children("*", "", true, false):
		if node is Button:
			_style_button(node as Button)


func _on_node_added(node: Node) -> void:
	if node is Button:
		call_deferred("refresh_button_by_id", node.get_instance_id())


func refresh_button_by_id(instance_id: int) -> void:
	var node := instance_from_id(instance_id)
	if node is Button:
		_style_button(node as Button)


func _style_button(button: Button) -> void:
	if not is_instance_valid(button) or bool(button.get_meta("ui_button_style_exempt", false)):
		return
	if button.text.strip_edges().is_empty() and button.icon == null and not bool(button.get_meta("ui_button_style_force", false)):
		return
	var authored_variant := (
		button.has_meta("ui_button_variant")
		and not bool(button.get_meta("ui_button_variant_inferred", false))
	)
	var variant := _resolve_variant(button)
	button.set_meta("ui_button_variant", variant)
	button.set_meta("ui_button_variant_inferred", not authored_variant)
	_hide_legacy_face_layers(button)
	if not bool(button.get_theme_stylebox("normal").get_meta("global_angular_button_spacing", false)):
		_install_spacing_styles(button)
	var face = button.get_node_or_null("BattleAngularButtonFace")
	if face == null:
		face = BUTTON_FACE_SCRIPT.new()
		face.name = "BattleAngularButtonFace"
		face.configure(button, variant)
		button.add_child(face)
	else:
		face.configure(button, variant)
	if face.has_method("mark_restyled"):
		face.mark_restyled()
	button.set_meta("ui_button_style_managed", true)


func _install_spacing_styles(button: Button) -> void:
	for state_name in STYLE_STATES:
		var current := button.get_theme_stylebox(state_name)
		var spacing := StyleBoxFlat.new()
		spacing.bg_color = Color.TRANSPARENT
		spacing.border_color = Color.TRANSPARENT
		spacing.content_margin_left = current.get_content_margin(SIDE_LEFT)
		spacing.content_margin_top = current.get_content_margin(SIDE_TOP)
		spacing.content_margin_right = current.get_content_margin(SIDE_RIGHT)
		spacing.content_margin_bottom = current.get_content_margin(SIDE_BOTTOM)
		spacing.set_meta("global_angular_button_spacing", true)
		button.add_theme_stylebox_override(state_name, spacing)


func _resolve_variant(button: Button) -> String:
	var explicit := (
		""
		if bool(button.get_meta("ui_button_variant_inferred", false))
		else String(button.get_meta("ui_button_variant", "")).to_lower()
	)
	if explicit.is_empty():
		var theme_variant := String(button.theme_type_variation).to_lower()
		if "primary" in theme_variant:
			explicit = "primary"
		elif "danger" in theme_variant:
			explicit = "danger"
		elif "target" in theme_variant:
			explicit = "target"
		elif "selected" in theme_variant:
			explicit = "selected"
	var identity := (String(button.name) + " " + button.text).to_lower()
	if explicit in ["", "default", "secondary"]:
		if _contains_any(identity, ["abandon", "delete", "forfeit", "destroy"]):
			return "danger"
		var label := button.text.strip_edges().to_lower()
		if _contains_any(identity, ["confirm", "accept"]) or label in ["save", "done", "finish"]:
			return "confirm"
		if _contains_any(identity, ["how to play", "tutorial"]):
			return "secondary"
		if _is_primary_label(label):
			return "primary"
		if button.text.strip_edges().is_empty() and button.icon != null:
			return "light"
	return _normalize_variant(explicit)


func _hide_legacy_face_layers(button: Button) -> void:
	for child_name in ["Fill", "Artwork"]:
		var layer := button.get_node_or_null(child_name) as CanvasItem
		if layer != null:
			layer.visible = false
			layer.set_meta("hidden_by_global_button_style", true)


func _normalize_variant(value: String) -> String:
	match value:
		"action", "primary":
			return "primary"
		"danger", "destructive":
			return "danger"
		"target", "special":
			return "target"
		"selected", "active":
			return "selected"
		"confirm", "success":
			return "confirm"
		"warning", "reward":
			return "warning"
		"light":
			return "light"
		_:
			return "secondary"


func _contains_any(text: String, terms: Array[String]) -> bool:
	for term in terms:
		if term in text:
			return true
	return false


func _is_primary_label(label: String) -> bool:
	return (
		label in ["play", "next", "register"]
		or label.begins_with("start ")
		or label.begins_with("continue")
		or label.begins_with("play ")
		or label.begins_with("register ")
		or label.begins_with("buy ")
		or label.begins_with("open pack")
	)
