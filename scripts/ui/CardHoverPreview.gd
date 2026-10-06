extends Node
## Shared non-blocking hover/focus preview. The source owns its lifetime.
const CONTENT := preload("res://scripts/ui/CardInspectionContent.gd")
const INSPECTION := preload("res://scripts/ui/CardInspectionOverlay.gd")
const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const DELAY := 0.38
var _source: Control
var _card: Dictionary
var _difficulty := "white"
var _ticket := 0
var _popup: PanelContainer


static func bind(source: Control, card: Dictionary, difficulty: String = "white") -> void:
	INSPECTION.bind(source, card, difficulty)
	var helper := source.get_node_or_null("SharedHoverController")
	if helper == null:
		helper = load("res://scripts/ui/CardHoverPreview.gd").new()
		helper.name = "SharedHoverController"
		helper._source = source
		source.add_child(helper)
	helper._card = card.duplicate(true)
	helper._difficulty = difficulty


func _ready() -> void:
	_source.mouse_entered.connect(_queue_preview.bind(true))
	_source.mouse_exited.connect(_hide_preview)
	_source.focus_entered.connect(_queue_preview.bind(false))
	_source.focus_exited.connect(_hide_preview)
	_source.gui_input.connect(func(event: InputEvent) -> void:
		if (event is InputEventMouseButton or event is InputEventKey) and event.is_pressed():
			_hide_preview()
	)


func _queue_preview(pointer: bool) -> void:
	_ticket += 1
	var ticket := _ticket
	await get_tree().create_timer(DELAY).timeout
	if ticket != _ticket or not bool(_source.get_meta("inspection_available", true)) or not _source.is_visible_in_tree() or not get_tree().get_nodes_in_group("shared_card_inspection").is_empty():
		return
	if pointer and not _source.get_global_rect().has_point(_source.get_global_mouse_position()):
		return
	_hide_preview()
	_popup = PanelContainer.new()
	_popup.name = "SharedCardHoverPreview"
	_popup.z_index = 3800
	_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	CONTENT.apply_sketch_paper(_popup, PALETTE.PEACH_PAPER)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 0)
	_popup.add_child(body)
	body.add_child(CONTENT.make_content(_card, _difficulty))
	CONTENT._ignore_mouse(_popup)
	_popup.minimum_size_changed.connect(_position_preview)
	get_tree().root.add_child(_popup)
	_position_preview()
	_position_preview.call_deferred()


func _position_preview() -> void:
	if not is_instance_valid(_popup):
		return
	_popup.size = Vector2.ZERO
	var viewport_size := _source.get_viewport_rect().size
	var source_rect := _source.get_global_rect()
	var x := source_rect.end.x + 14
	if x + _popup.size.x > viewport_size.x - 12:
		x = source_rect.position.x - _popup.size.x - 14
	_popup.position = Vector2(clampf(x, 12, maxf(12, viewport_size.x - _popup.size.x - 12)), clampf(source_rect.position.y - 32, 12, maxf(12, viewport_size.y - _popup.size.y - 12)))


func _hide_preview() -> void:
	_ticket += 1
	if is_instance_valid(_popup):
		_popup.hide()
		_popup.queue_free()
	_popup = null


func _process(_delta: float) -> void:
	if is_instance_valid(_popup) and not _source.is_visible_in_tree():
		_hide_preview()


func _exit_tree() -> void:
	_hide_preview()
