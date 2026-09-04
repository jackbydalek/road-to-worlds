extends RefCounted
class_name CardUpgradeReveal

## Shared upgrade ceremony for shop and event cards. The opaque angular flash
## conceals the face rebuild, then the permanent foil treatment gets a stronger
## one-shot sweep as the upgraded card is revealed.

const PALETTE := preload("res://scripts/ui/GamePalette.gd")


func play(
	host: Node,
	card_visual: Control,
	card_face: Control,
	upgraded_card: Dictionary,
	difficulty_id: String,
	animate_art: bool,
	reduced_motion: bool = false,
	skip_timing: bool = false
) -> Array[String]:
	var stages: Array[String] = []
	if host == null or card_visual == null or card_face == null:
		return stages
	var origin_position := card_visual.position
	var origin_rotation := card_visual.rotation
	var origin_scale := card_visual.scale
	var flash := _make_white_flash(card_visual)
	card_visual.add_child(flash)
	card_visual.set_meta("upgrade_animation_active", true)

	stages.append("white")
	card_visual.set_meta("upgrade_animation_stage", "white")
	if skip_timing:
		flash.color.a = 1.0
	else:
		var white_in := host.create_tween().set_parallel(true)
		white_in.tween_property(flash, "color:a", 1.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		white_in.tween_property(card_visual, "scale", origin_scale * 1.045, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await white_in.finished

	stages.append("shake")
	card_visual.set_meta("upgrade_animation_stage", "shake")
	if not reduced_motion and not skip_timing:
		var shake_offsets := [-7.0, 7.0, -6.0, 5.0, -3.0, 0.0]
		var shake_rotations := [-1.8, 1.9, -1.4, 1.0, -0.5, 0.0]
		var shake := host.create_tween()
		for shake_index in range(shake_offsets.size()):
			shake.set_parallel(true)
			shake.tween_property(
				card_visual,
				"position",
				origin_position + Vector2(float(shake_offsets[shake_index]), 0.0),
				0.045
			).set_trans(Tween.TRANS_SINE)
			shake.tween_property(
				card_visual,
				"rotation",
				origin_rotation + deg_to_rad(float(shake_rotations[shake_index])),
				0.045
			).set_trans(Tween.TRANS_SINE)
			shake.chain()
		await shake.finished
	elif not skip_timing:
		await host.get_tree().create_timer(0.10).timeout

	_configure_upgraded_face(card_face, upgraded_card, difficulty_id, animate_art)
	var foil := card_face.find_child("UpgradedCardFoil", true, false) as Control
	if foil != null and foil.has_method("start_reveal_sweep"):
		foil.call("start_reveal_sweep")
	stages.append("shine")
	card_visual.set_meta("upgrade_animation_stage", "shine")

	if skip_timing:
		flash.queue_free()
	else:
		var reveal := host.create_tween().set_parallel(true)
		reveal.tween_property(flash, "color:a", 0.0, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		reveal.tween_property(card_visual, "scale", origin_scale * 1.075, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		reveal.chain().tween_property(card_visual, "scale", origin_scale, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await reveal.finished
		flash.queue_free()
		await host.get_tree().create_timer(0.34 if reduced_motion else 0.46).timeout

	card_visual.position = origin_position
	card_visual.rotation = origin_rotation
	card_visual.scale = origin_scale
	card_visual.set_meta("upgrade_animation_active", false)
	card_visual.set_meta("upgrade_animation_stage", "complete")
	return stages


func _make_white_flash(card_visual: Control) -> Polygon2D:
	var flash := Polygon2D.new()
	flash.name = "CardUpgradeWhiteFlash"
	flash.polygon = _angular_card_polygon(_resolved_card_size(card_visual))
	flash.color = Color(PALETTE.COOL_WHITE, 0.0)
	flash.z_index = 40
	return flash


func _resolved_card_size(card_visual: Control) -> Vector2:
	var resolved := card_visual.size
	if resolved.x <= 1.0 or resolved.y <= 1.0:
		resolved = card_visual.custom_minimum_size
	return Vector2(maxf(1.0, resolved.x), maxf(1.0, resolved.y))


func _angular_card_polygon(card_size: Vector2) -> PackedVector2Array:
	var design_points := PackedVector2Array([
		Vector2(24, 4), Vector2(386, 4), Vector2(416, 34),
		Vector2(416, 586), Vector2(386, 616), Vector2(24, 616),
		Vector2(4, 596), Vector2(4, 24),
	])
	var scale_value := Vector2(card_size.x / 420.0, card_size.y / 620.0)
	var points := PackedVector2Array()
	for design_point in design_points:
		points.append(design_point * scale_value)
	return points


func _configure_upgraded_face(
	card_face: Control,
	upgraded_card: Dictionary,
	difficulty_id: String,
	animate_art: bool
) -> void:
	var previous_minimum := card_face.custom_minimum_size
	var previous_size := card_face.size
	card_face.call("configure", upgraded_card, difficulty_id, animate_art)
	card_face.custom_minimum_size = previous_minimum
	card_face.size = previous_size
