extends Control
## Painted venue/week identity and progress. This is read-only run state,
## never a route selector or an additional match progression system.
const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const SHAPES := preload("res://scripts/ui/PaintedUiShapes.gd")
const STAMPS := preload("res://scripts/ui/HubRoundProgress.gd")
const FONT := preload("res://assets/fonts/AtkinsonHyperlegibleNext.ttf")

var compact := false:
	set(value):
		compact = value
		if is_node_ready():
			_set_type()
			_layout()
var week := 1
var header_only := false
var round_number := 1
var total_rounds := 4
var venue := "Locals"
var _venue_label: Label
var _round_label: Label
var _stamps: Control
var _laying_out := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_venue_label = _label("VenueLabel")
	_round_label = _label("WeekRoundLabel")
	_set_type()
	_stamps = STAMPS.new()
	_stamps.name = "RoundStamps"
	_stamps.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stamps)
	resized.connect(_layout)
	_venue_label.minimum_size_changed.connect(_layout)
	_round_label.minimum_size_changed.connect(_layout)
	_update()

func configure(week_number: int, current_round: int, rounds: int = 4, venue_name: String = "Locals") -> void:
	week = maxi(1, week_number)
	total_rounds = maxi(1, rounds)
	round_number = clampi(current_round, 1, total_rounds)
	venue = venue_name
	if is_node_ready():
		_update()

func _label(node_name: String) -> Label:
	var label := Label.new()
	label.name = node_name
	label.add_theme_font_override("font", FONT)
	label.add_theme_color_override("font_color", PALETTE.PEACH_INK)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	add_child(label)
	return label

func _update() -> void:
	_venue_label.text = "%s · WEEK %d" % [venue.to_upper(), week] if header_only else venue.to_upper()
	_round_label.text = "Round %d / %d" % [round_number, total_rounds] if header_only else "Week %d · Round %d / %d" % [week, round_number, total_rounds]
	tooltip_text = "%s · %s" % [venue, _round_label.text]
	_stamps.configure(round_number, false, total_rounds)
	_layout()

func _layout() -> void:
	if _venue_label == null or _stamps == null or _laying_out:
		return
	_laying_out = true
	if header_only:
		_stamps.hide()
		var height := maxf(_venue_label.get_minimum_size().y, _round_label.get_minimum_size().y)
		var first_width := _venue_label.get_minimum_size().x
		custom_minimum_size = Vector2(0, height + 12)
		_venue_label.position = Vector2(18, 6)
		_venue_label.size = Vector2(maxf(first_width, 210), height)
		_round_label.position = Vector2(maxf(236, first_width + 38), 6)
		_round_label.size = Vector2(maxf(0, size.x - _round_label.position.x - 18), height)
		_stamps.position.y = height + 16
		_laying_out = false
		queue_redraw()
		return
	var pad := 12.0 if compact else 20.0
	var top := 7.0 if compact else 10.0
	var venue_height := maxf(23 if compact else 34, _venue_label.get_minimum_size().y)
	var round_height := maxf(20 if compact else 25, _round_label.get_minimum_size().y)
	var stamps_height := 26.0 if compact else 29.0
	var venue_width := FONT.get_string_size(_venue_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, _venue_label.get_theme_font_size("font_size")).x
	var round_width := FONT.get_string_size(_round_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, _round_label.get_theme_font_size("font_size")).x
	var required := Vector2(ceilf(maxf(venue_width, round_width) + pad * 2), top + venue_height + round_height + 4 + stamps_height + 7)
	if custom_minimum_size != required:
		custom_minimum_size = required
	# Consumers position nearby controls in the same settings pass. Grow now
	# rather than waiting a frame for Control's minimum-size notification.
	size = size.max(required)
	_venue_label.position = Vector2(pad, top)
	_venue_label.size = Vector2(maxf(0, size.x - pad * 2), venue_height)
	_round_label.position = Vector2(pad, top + venue_height)
	_round_label.size = Vector2(maxf(0, size.x - pad * 2), round_height)
	_stamps.position = Vector2(pad - 4, maxf(_round_label.position.y + round_height + 4, size.y - stamps_height - 7))
	_stamps.size = Vector2(maxf(0, size.x - pad * 2 + 8), stamps_height)
	_laying_out = false
	queue_redraw()

func _set_type() -> void:
	# Set base typography only when choosing the component format. Refreshing
	# run state must retain the player's already-applied large-text overrides.
	_venue_label.add_theme_font_size_override("font_size", 16 if compact or header_only else 26)
	_round_label.add_theme_font_size_override("font_size", 18 if header_only else 12 if compact else 17)

func _draw() -> void:
	if size.x < 1 or size.y < 1 or header_only:
		return
	SHAPES.draw_surface(self, Rect2(Vector2(1, 1), size - Vector2(2, 2)), PALETTE.PEACH_PAPER, 17)
