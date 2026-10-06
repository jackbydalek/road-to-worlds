extends SceneTree

const PORTRAIT := preload("res://scripts/ui/SeatedRivalPortrait.gd")
const HAND := preload("res://scripts/ui/RivalHeldCards.gd")
const CAST := preload("res://scripts/ui/PeachSodaCast.gd")
const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const OUTPUT_DIR := "res://outputs/cast_live_hands_2026-09-11"
var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920, 1600)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var background := ColorRect.new()
	background.size = Vector2(viewport.size)
	background.color = PALETTE.PEACH_PAPER
	viewport.add_child(background)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for cast_id in ["pip", "milo", "bea", "mina"]:
		var portraits: Array[TextureRect] = []
		for index in range(4):
			var count: int = [0, 1, 3, 7][index]
			var portrait := PORTRAIT.new()
			portrait.configure(cast_id, true, true)
			portrait.position = Vector2(index % 2 * 960, index / 2 * 800)
			portrait.size = Vector2(960, 796)
			viewport.add_child(portrait)
			portraits.append(portrait)
			var hand := HAND.new()
			portrait.add_child(hand)
			hand.configure(portrait, cast_id, true)
			hand.sync_count(count)
			_check(hand.held_count == count and hand._cards.size() == count, "%s does not display %d cards" % [cast_id, count])
			for card in hand._cards:
				_check(card.texture == HAND.SLEEVE and not card.has_meta("card_id"), "Concealed hand leaks a card identity")
			_check(portrait.texture == CAST.texture_for(cast_id), "Live fan changed the source portrait")
			var label := Label.new()
			label.text = "%s · %d cards" % [cast_id.capitalize(), count]
			label.position = Vector2(20, 24)
			label.add_theme_color_override("font_color", PALETTE.PEACH_INK)
			label.add_theme_font_size_override("font_size", 30)
			portrait.add_child(label)
		for ignored in range(3):
			await process_frame
		if DisplayServer.get_name() != "headless":
			RenderingServer.force_draw(false)
			viewport.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUTPUT_DIR.path_join(cast_id + "_counts.png")))
		for portrait in portraits:
			var hand = portrait.get_child(0)
			var initial_count: int = hand.held_count
			hand.set_reduced_motion(false)
			hand.animate_draw(Vector2(0, 400))
			_check(hand.held_count == initial_count + 1 and hand.is_animating(), "Draw did not update the live hand")
			hand.animate_play(Vector2(1000, 1400))
			_check(hand.held_count == initial_count, "Play did not remove exactly one card")
			hand.set_reduced_motion(true)
			_check(not hand.is_animating() and hand._cards.size() == initial_count, "Reduced Motion left a duplicate flight")
			hand.sync_count(0)
			_check(hand._cards.is_empty(), "Empty hand retained sleeves")
			portrait.queue_free()
		await process_frame
	viewport.queue_free()
	await process_frame
	print("CAST_LIVE_HAND_SMOKE_TEST_%s: four cast poses, four counts each, draw/play/Reduced Motion; %d failures" % ["OK" if failures.is_empty() else "FAILED", failures.size()])
	quit(0 if failures.is_empty() else 1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)
