extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")
const PALETTE := preload("res://scripts/ui/GamePalette.gd")
var failures: Array[String] = []
var assertions := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1440, 900)
	var main = MAIN_SCENE.instantiate()
	main.autosave_enabled = false
	root.add_child(main)
	await _settle()
	main._show_season_run_setup()
	await _settle()
	var setup = main.find_child("SeasonRegistration", true, false)
	_expect(setup != null, "Starter table did not open.")
	if setup == null:
		_finish()
		return
	_expect(setup.selected_index == -1 and setup.view_state == "table", "Setup did not begin at the three boxes.")
	_expect(setup.boxes.size() == 3, "The table needs exactly three starter boxes.")
	_expect(main.find_child("SpicyCharacterPanel", true, false) == null, "The retired character lineup is still present.")
	_expect(not setup.difficulty_scrim.visible and not setup.receipt.visible, "Difficulty controls leaked into the overview.")
	_expect(setup.start_button.disabled, "Start is enabled before deck/border selection.")
	var original_cards: Array = []
	for index in range(3):
		var box = setup.boxes[index]
		var expected_id: String = setup.COVER_IDS[index]
		original_cards.append(main.cards_by_id[expected_id].duplicate(true))
		_expect(String(box.card_data.id) == expected_id, "Wrong original card in %s window." % box.name)
		_expect(box.affiliation_color == setup.STARTER_ACCENTS[index], "A package changed exact affiliation color.")
		var artwork := box.face.find_child("CardArtwork", true, false) as TextureRect
		_expect(artwork != null and artwork.texture == load(main.cards_by_id[expected_id].art_frames[0]), "Window artwork is not the original first frame.")
		_expect(Rect2(Vector2.ZERO, box.window.size).encloses(box.face.get_rect()), "A window clips part of its card face.")
		_expect(box.face.size.x >= 240 and box.face.size.y >= 350, "Card window collapsed into an unreadable strip.")
		_expect(not box.face._runtime_face.compact_visual, "Retail window lost the full card layout.")

	# Use actual keyboard focus/activation, then cancel while the box is moving.
	root.set_meta("reduced_motion", false)
	setup.boxes[0].grab_focus()
	await _key(KEY_RIGHT)
	_expect(setup.boxes[1].has_focus(), "Right arrow did not focus the next starter.")
	await _key(KEY_SPACE)
	_expect(setup.selected_index == 1, "Space did not select the focused starter box.")
	_expect(setup.view_state == "moving" and not setup.receipt.visible, "Controls appeared before the box arrived.")
	setup._begin_selected_run()
	_expect(not setup.starting, "Start bypassed the explicit border choice.")
	await _key(KEY_ESCAPE)
	await create_timer(0.38).timeout
	_expect(setup.selected_index == -1 and not setup.receipt.visible, "Escape did not cancel the in-flight selection.")
	_expect(setup.boxes[1].has_focus(), "Back did not restore focus to the same box.")

	for starter_index in range(3):
		setup.select_starter(starter_index, false)
		await _settle()
		_expect(setup.receipt.visible and setup.selected_difficulty_index == -1 and setup.start_button.disabled, "A new starter skipped its border decision.")
		var box = setup.boxes[starter_index]
		var package_color: Color = box.package_color
		var affiliation_color: Color = box.affiliation_color
		for border_index in range(5):
			setup.difficulty_buttons[border_index].pressed.emit()
			await _settle()
			_expect(setup.selected_difficulty_index == border_index and main.season_setup_difficulty_index == border_index, "Border choice was not preserved in Main.")
			_expect(main.find_child("SeasonRegistration", true, false) == setup, "A border click rebuilt the whole scene.")
			_expect(box.border_color == setup.BORDER_COLORS[border_index], "The visible card rim did not change to its difficulty color.")
			_expect(box.package_color == package_color and box.affiliation_color == affiliation_color, "Difficulty recolored the package or affiliation.")
			_expect(not setup.start_button.disabled and setup.difficulty_buttons[border_index].button_pressed, "Selected border lacks explicit state or Start gating.")
			var cash: int = main.run_state_service.starting_money_for_difficulty(setup.BORDER_IDS[border_index])
			_expect(setup.border_rules.text.contains("40 starting life") and setup.border_rules.text.contains("$%d" % cash), "Border copy does not match current route life/cash.")
			var recovery_copy := "Full heal each new week" if border_index < 2 else "Heal 20 each new week, up to max"
			_expect(setup.border_rules.text.contains(recovery_copy), "Border selection does not explain its weekly recovery.")
			_expect(not setup.border_rules.text.contains("season life") and not setup.border_rules.text.contains("AI"), "Legacy difficulty claims leaked into the run setup.")
			_expect(main.cards_by_id[setup.COVER_IDS[starter_index]] == original_cards[starter_index], "Preview modified authoritative card data.")
		setup._handle_back()
		await _settle()
		_expect(setup.selected_index == -1 and setup.selected_difficulty_index == -1, "Back did not clear the two-step choice.")

	# Real deck inspection is a nested overlay; Escape closes it first.
	setup.select_starter(1, false)
	setup.select_difficulty(1)
	await _settle()
	setup.deck_list_button.pressed.emit()
	await _settle()
	_expect(main.find_child("StarterDeckPreview", true, false) != null, "View deck did not open the actual starter list.")
	await _key(KEY_ESCAPE)
	_expect(main.find_child("StarterDeckPreview", true, false) == null and setup.selected_index == 1, "Escape closed the starter table before its nested deck list.")

	for window_size in [Vector2i(1440, 900), Vector2i(1280, 720), Vector2i(1024, 600)]:
		root.size = window_size
		await _settle()
		setup._collapse_selection()
		await _settle()
		_check_layout(setup, "table %s" % window_size)
		setup.select_starter(2, false)
		setup.select_difficulty(4)
		await _settle()
		_check_layout(setup, "difficulty %s" % window_size)
	main.player_settings.text_scale = 1.25
	main._apply_player_settings(false)
	await _settle()
	_check_layout(setup, "large text")
	_expect(setup.border_rules.get_minimum_size().y <= 120, "Large-text rules exceed their reserved panel.")
	_expect(setup.receipt_title.get_minimum_size().y <= 65, "Large-text title exceeds its reserved header.")
	main.player_settings.text_scale = 1.0
	main._apply_player_settings(false)
	setup._collapse_selection()
	await _settle()
	root.set_meta("reduced_motion", true)
	setup.select_starter(0, true)
	_expect(setup.view_state == "difficulty" and setup.receipt.visible, "Reduced Motion did not immediately settle in the same state.")
	setup._collapse_selection()
	await _settle()

	# Each starter follows the real confirmation signal into the locked Locals run.
	for starter_index in range(3):
		if starter_index > 0:
			main._show_season_run_setup()
			await _settle()
			setup = main.find_child("SeasonRegistration", true, false)
		setup.select_starter(starter_index, false)
		setup.select_difficulty([2, 4, 0][starter_index])
		await _settle()
		setup.start_button.pressed.emit()
		await _settle()
		_expect(main.current_screen == "route_hub", "Start did not enter the tournament hub.")
		_expect(String(main.run.starter) == ["spicy", "hearty", "sweet"][starter_index], "Started the wrong starter deck.")
		_expect(main._deck_total(main.run.deck) == 15 and int(main.run.life) == 40, "New run lost its15 cards or persistent life.")
		_expect(String(main.run.difficulty) == ["yellow", "gold", "white"][starter_index], "Start lost the chosen card border.")
	main._release_audio_streams()
	main.queue_free()
	await _settle()
	_finish()

func _check_layout(setup, context: String) -> void:
	var available: Rect2 = setup.get_global_rect().grow(2)
	var controls: Array[Control] = [setup.back_button, setup.welcome_note]
	if setup.selected_index < 0:
		for box in setup.boxes:
			controls.append(box)
		for tag in setup.deck_labels:
			controls.append(tag)
	else:
		controls.append(setup.boxes[setup.selected_index])
		controls.append(setup.receipt)
		controls.append(setup.start_button)
		controls.append(setup.deck_list_button)
		for button in setup.difficulty_buttons:
			controls.append(button)
	for control in controls:
		_expect(available.encloses(_bounds(control)), "%s: %s leaves the visible table." % [context, control.name])
	if setup.selected_index >= 0:
		_expect(not _bounds(setup.boxes[setup.selected_index]).intersects(_bounds(setup.receipt)), context + ": selected box overlaps its receipt.")
	else:
		_expect(not _bounds(setup.welcome_note).intersects(_bounds(setup.boxes[0])), context + ": welcome note covers the Spicy hanger.")

func _bounds(control: Control) -> Rect2:
	var transform := control.get_global_transform()
	var points := [Vector2.ZERO, Vector2(control.size.x, 0), control.size, Vector2(0, control.size.y)]
	var bounds := Rect2(transform * points[0], Vector2.ZERO)
	for point in points:
		bounds = bounds.expand(transform * point)
	return bounds

func _key(keycode: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	root.push_input(event)
	await process_frame
	event = InputEventKey.new()
	event.keycode = keycode
	event.pressed = false
	root.push_input(event)
	await process_frame

func _settle() -> void:
	for frame in range(4):
		await process_frame

func _expect(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failures.append(message)
		push_error(message)

func _finish() -> void:
	if failures.is_empty():
		print("STARTER_SELECTION_FLOW_SMOKE_TEST_OK: %d checks" % assertions)
	quit(0 if failures.is_empty() else 1)
