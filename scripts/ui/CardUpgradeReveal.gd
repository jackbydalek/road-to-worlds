extends RefCounted
class_name CardUpgradeReveal

## One self-contained ceremony for an existing card copy: focus, foil, then
## return the same copy to its deck. This presentation never mutates the deck.
const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const CARD_FACE := preload("res://scripts/CardFace.gd")
const DECK_STACK := preload("res://scripts/ui/RewardDeckStack.gd")
const SLEEVE := preload("res://assets/cards/card_backs/living_table.png")
const BODY_FONT := preload("res://assets/fonts/AtkinsonHyperlegibleNext.ttf")
const FACE_SIZE := Vector2(250, 355)


class CeremonyOverlay extends Control:
	func _input(_event: InputEvent) -> void:
		if is_visible_in_tree():
			get_viewport().set_input_as_handled()

	func _gui_input(_event: InputEvent) -> void:
		accept_event()


class FoilGlints extends Control:
	var card_rect := Rect2()
	var progress := 0.0:
		set(value):
			progress = value
			queue_redraw()

	func _draw() -> void:
		if progress <= 0.0 or progress >= 1.0:
			return
		var offsets := [
			Vector2(-0.68, -0.35), Vector2(0.63, -0.43),
			Vector2(-0.73, 0.12), Vector2(0.75, 0.03),
			Vector2(-0.57, 0.46), Vector2(0.62, 0.39),
			Vector2(-0.30, -0.60), Vector2(0.31, 0.58),
		]
		var colors := [GamePalette.PEACH_PAPER, GamePalette.CARD_BORDER_GOLD, GamePalette.PEACH_MINT]
		for index in range(offsets.size()):
			var local_phase := clampf((progress - float(index % 3) * 0.065) / 0.80, 0.0, 1.0)
			var energy := sin(local_phase * PI)
			var origin := card_rect.get_center() + Vector2(offsets[index]) * card_rect.size
			var radius := card_rect.size.x * (0.032 + 0.012 * float(index % 2)) * energy
			var inner := radius * 0.22
			# Skip subpixel stars: their nearly coincident points can fail
			# triangulation at the beginning/end of an eased glint.
			if radius >= 1.0:
				draw_colored_polygon(PackedVector2Array([
					origin + Vector2(0, -radius), origin + Vector2(inner, -inner),
					origin + Vector2(radius, 0), origin + Vector2(inner, inner),
					origin + Vector2(0, radius), origin + Vector2(-inner, inner),
					origin + Vector2(-radius, 0), origin + Vector2(-inner, -inner),
				]), Color(colors[index % colors.size()], energy * 0.92))


func play(
	host: Control,
	before_card: Dictionary,
	upgraded_card: Dictionary,
	difficulty_id: String,
	reduced_motion: bool = false,
	skip_timing: bool = false,
	deck_count: int = 0,
	source_rect: Rect2 = Rect2()
) -> Array[String]:
	var stages: Array[String] = []
	if host == null or not host.is_inside_tree():
		return stages
	var previous_focus := host.get_viewport().gui_get_focus_owner()
	var overlay := CeremonyOverlay.new()
	overlay.name = "RouteCardUpgradeRevealOverlay"
	overlay.z_index = 1200
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.focus_mode = Control.FOCUS_ALL
	overlay.accessibility_name = "Foiling your card"
	overlay.set_meta("reduced_motion", reduced_motion)
	overlay.set_meta("upgrade_animation_active", true)
	overlay.set_meta("deck_count", deck_count)
	overlay.set_meta("source_rect", source_rect)
	host.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.grab_focus()
	var dimmer := ColorRect.new()
	dimmer.name = "RouteCardUpgradeRevealDimmer"
	dimmer.color = Color(PALETTE.PEACH_INK, 0.0)
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(dimmer)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var glints := FoilGlints.new()
	glints.name = "RouteUpgradeFoilGlints"
	glints.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glints.visible = not reduced_motion
	overlay.add_child(glints)
	glints.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var deck = DECK_STACK.new()
	deck.name = "RouteUpgradeDeckStack"
	deck.set_card_count(deck_count)
	overlay.add_child(deck)
	var deck_label := _label("RouteUpgradeDeckCount", "Your deck · %d cards" % deck_count, 17, host)
	overlay.add_child(deck_label)
	var visual := Control.new()
	visual.name = "RouteUpgradeSpotlightCard"
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.size = FACE_SIZE
	visual.pivot_offset = FACE_SIZE * 0.5
	visual.set_meta("difficulty_id", difficulty_id)
	visual.set_meta("inspection_card", before_card.duplicate(true))
	visual.set_meta("upgrade_animation_active", true)
	overlay.add_child(visual)
	var before_face := _make_face(before_card, difficulty_id, not reduced_motion)
	before_face.name = "BeforeCardFace"
	visual.add_child(before_face)
	var upgraded_face := _make_face(upgraded_card, difficulty_id, not reduced_motion)
	upgraded_face.name = "CardFace"
	upgraded_face.hide()
	visual.add_child(upgraded_face)
	var back := TextureRect.new()
	back.name = "RouteUpgradeSleevedCardBack"
	back.texture = SLEEVE
	back.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	back.stretch_mode = TextureRect.STRETCH_SCALE
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.size = FACE_SIZE
	back.hide()
	visual.add_child(back)
	var flash := _make_white_flash()
	visual.add_child(flash)
	# Both destination rectangles are recomputed when the window changes. Motion
	# uses normalized progress rather than retaining stale screen coordinates.
	var state := {"focus": 0.0, "flight": 0.0, "stage": "focus"}
	var layout := func() -> void:
		_layout(overlay, visual, deck, deck_label, glints, source_rect, state, reduced_motion)
	overlay.resized.connect(layout)
	layout.call()
	_set_stage(overlay, visual, stages, "focus")
	if skip_timing:
		state.focus = 1.0
		dimmer.color.a = 0.79
		layout.call()
	else:
		var focus := overlay.create_tween().set_parallel(true)
		focus.tween_property(dimmer, "color:a", 0.79, 0.22 if reduced_motion else 0.38)
		focus.tween_method(func(value: float) -> void:
			state.focus = value
			layout.call(), 0.0, 1.0, 0.22 if reduced_motion else 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		await focus.finished
	_set_stage(overlay, visual, stages, "white")
	state.stage = "white"
	if skip_timing:
		flash.color.a = 1.0
	else:
		var anticipation := overlay.create_tween()
		anticipation.tween_property(flash, "color:a", 1.0, 0.14 if reduced_motion else 0.22).set_trans(Tween.TRANS_SINE)
		await anticipation.finished
	before_face.hide()
	upgraded_face.show()
	visual.set_meta("inspection_card", upgraded_card.duplicate(true))
	var foil := upgraded_face.find_child("UpgradedCardFoil", true, false) as Control
	if foil != null:
		if reduced_motion:
			foil.set_process(false)
		elif not skip_timing:
			foil.call("start_reveal_sweep", true)
	overlay.accessibility_name = "%s foiled. Returning to your deck." % String(upgraded_card.get("name", "Card"))
	_set_stage(overlay, visual, stages, "shine")
	state.stage = "shine"
	if skip_timing:
		flash.color.a = 0.0
	else:
		var shine := overlay.create_tween().set_parallel(true)
		shine.tween_property(flash, "color:a", 0.0, 0.22).set_trans(Tween.TRANS_SINE)
		if not reduced_motion:
			shine.tween_property(glints, "progress", 1.0, 1.10)
			shine.tween_method(func(value: float) -> void:
				state["shine"] = value
				layout.call(), 0.0, 1.0, 1.10)
		else:
			shine.tween_interval(0.34)
		await shine.finished
	_set_stage(overlay, visual, stages, "deck")
	state.stage = "deck"
	if skip_timing:
		state.flight = 1.0
		layout.call()
	elif reduced_motion:
		# Keep the card stationary. The visible stack remains the destination.
		var dissolve := overlay.create_tween()
		dissolve.tween_property(visual, "modulate:a", 0.0, 0.24)
		await dissolve.finished
	else:
		var flight := overlay.create_tween()
		flight.tween_method(func(value: float) -> void:
			state.flight = value
			layout.call()
			var turn := clampf((value - 0.36) / 0.40, 0.0, 1.0)
			upgraded_face.visible = turn < 0.5
			back.visible = turn >= 0.5, 0.0, 1.0, 0.68)
		await flight.finished
	visual.hide()
	deck.play_arrival(reduced_motion or skip_timing)
	if not skip_timing:
		var settle := overlay.create_tween()
		settle.tween_interval(0.10 if reduced_motion else 0.18)
		settle.tween_property(overlay, "modulate:a", 0.0, 0.12)
		await settle.finished
	_set_stage(overlay, visual, stages, "complete")
	overlay.set_meta("upgrade_animation_active", false)
	visual.set_meta("upgrade_animation_active", false)
	overlay.set_process_input(false)
	overlay.hide()
	if is_instance_valid(previous_focus) and previous_focus.is_visible_in_tree() and previous_focus.focus_mode != Control.FOCUS_NONE:
		previous_focus.grab_focus()
	overlay.get_parent().remove_child(overlay)
	overlay.queue_free()
	return stages


func _layout(
	overlay: Control, visual: Control, deck: Control, deck_label: Label,
	glints: FoilGlints, source_rect: Rect2,
	state: Dictionary, reduced_motion: bool
) -> void:
	var viewport_size := overlay.size
	var unit := clampf(minf(viewport_size.x / 1280.0, viewport_size.y / 720.0), 0.65, 1.4)
	var card_height := minf(viewport_size.y * 0.60, 600.0)
	var card_size := FACE_SIZE * (card_height / FACE_SIZE.y)
	var center := viewport_size * Vector2(0.50, 0.48)
	var target := Rect2(center - card_size * 0.5, card_size)
	glints.card_rect = target
	deck.size = Vector2(128, 145) * unit
	deck.position = Vector2(viewport_size.x - 76.0 * unit - deck.size.x, viewport_size.y - deck.size.y - 67.0 * unit)
	deck_label.position = deck.position + Vector2(-64, deck.size.y + 2)
	deck_label.size = Vector2(deck.size.x + 128.0, 40.0 * unit)
	var landing: Rect2 = overlay.get_global_transform().affine_inverse() * deck.get_landing_rect_global()
	overlay.set_meta("centered_rect", target)
	overlay.set_meta("landing_rect", landing)
	visual.set_meta("centered_rect", target)
	var origin := center
	var display_size := card_size
	var angle := 0.0
	if String(state.stage) == "focus" and not reduced_motion:
		var intro := float(state.focus)
		var start_center := center + Vector2(0, 28.0 * unit)
		var start_size := card_size * 0.90
		if source_rect.has_area():
			start_center = source_rect.get_center()
			start_size = source_rect.size
		origin = start_center.lerp(center, intro)
		display_size = start_size.lerp(card_size, intro)
		angle = deg_to_rad(-3.0) * (1.0 - intro)
	elif String(state.stage) == "shine" and not reduced_motion:
		var anticipation := sin(float(state.get("shine", 0.0)) * PI)
		origin.y -= anticipation * 8.0 * unit
		angle = deg_to_rad(2.2) * anticipation
	elif String(state.stage) == "deck" and not reduced_motion:
		var progress := float(state.flight)
		var ease := progress * progress * (3.0 - 2.0 * progress)
		var arc := center.lerp(landing.get_center(), 0.5) + Vector2(0, -66.0 * unit)
		origin = center * pow(1.0 - ease, 2.0) + arc * 2.0 * (1.0 - ease) * ease + landing.get_center() * ease * ease
		display_size = card_size.lerp(landing.size, ease)
		var turn := clampf((progress - 0.36) / 0.40, 0.0, 1.0)
		display_size.x *= maxf(0.04, absf(1.0 - turn * 2.0))
		angle = -sin(progress * PI) * 0.12
	visual.position = origin - FACE_SIZE * 0.5
	visual.scale = display_size / FACE_SIZE
	visual.rotation = angle


func _make_face(card: Dictionary, difficulty_id: String, animate_art: bool) -> Control:
	var face := CARD_FACE.new()
	face.configure(card, difficulty_id, animate_art)
	face.custom_minimum_size = FACE_SIZE
	face.size = FACE_SIZE
	return face


func _label(node_name: String, text_value: String, font_size: int, host: Control) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text_value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", BODY_FONT)
	label.add_theme_color_override("font_color", PALETTE.PEACH_PAPER)
	var text_scale := clampf(float(host.get_theme_default_font_size()) / 16.0, 1.0, 1.5)
	label.add_theme_font_size_override("font_size", roundi(float(font_size) * text_scale))
	return label


func _set_stage(overlay: Control, visual: Control, stages: Array[String], stage: String) -> void:
	stages.append(stage)
	overlay.set_meta("upgrade_animation_stage", stage)
	visual.set_meta("upgrade_animation_stage", stage)


func _make_white_flash() -> Polygon2D:
	var flash := Polygon2D.new()
	flash.name = "CardUpgradeWhiteFlash"
	var points := PackedVector2Array([
		Vector2(24, 4), Vector2(386, 4), Vector2(416, 34),
		Vector2(416, 586), Vector2(386, 616), Vector2(24, 616),
		Vector2(4, 596), Vector2(4, 24),
	])
	for index in range(points.size()):
		points[index] *= FACE_SIZE / Vector2(420, 620)
	flash.polygon = points
	flash.color = Color(PALETTE.PEACH_PAPER, 0.0)
	flash.z_index = 40
	return flash
