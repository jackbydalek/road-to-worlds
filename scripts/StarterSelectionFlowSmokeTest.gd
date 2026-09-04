extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main._show_season_run_setup()
	await process_frame
	var setup := main.find_child("SeasonRegistration", true, false) as SeasonSetupMenu
	_expect(setup != null, "Character selection did not open.")
	if setup == null:
		_finish()
		return
	_expect(setup.selected_index == -1, "Character selection did not begin in the three-player lineup.")
	_expect(main.find_child("SpicyCharacterPanel", true, false) != null, "Spicy panel is missing.")
	_expect(main.find_child("HeartyCharacterPanel", true, false) != null, "Hearty panel is missing.")
	_expect(main.find_child("SweetCharacterPanel", true, false) != null, "Sweet panel is missing.")
	var sweet_art := main.find_child("SweetPlayerArtwork", true, false) as TextureRect
	_expect(
		sweet_art != null
		and sweet_art.texture != null
		and sweet_art.texture.resource_path.ends_with("sweet_player_neutral.png"),
		"Sweet did not receive the supplied protagonist art."
	)

	setup.select_starter(1, false)
	await process_frame
	_expect(setup.selected_index == 1 and main.season_setup_archetype_index == 1, "Hearty selection did not expand or update the run choice.")
	var hearty_details := main.find_child("SelectedHeartyDeckDetails", true, false) as Control
	_expect(hearty_details != null and hearty_details.visible, "Expanded Hearty panel did not show its deck description.")
	var hearty_deck_mount := main.find_child("RotatingDeckBoxMount", true, false) as Control
	var hearty_play_button := main.find_child("PlayHeartyButton", true, false) as Button
	_expect(
		hearty_deck_mount != null
		and hearty_play_button != null
		and hearty_deck_mount.get_global_rect().end.y < hearty_play_button.get_global_rect().position.y,
		"The Play button is not positioned below the rotating deck box."
	)
	var hearty_material := setup.panel_art[1].material as ShaderMaterial
	_expect(
		is_equal_approx(float(hearty_material.get_shader_parameter("washout")), 0.18)
		and is_equal_approx(float(hearty_material.get_shader_parameter("brightness")), 0.92),
		"The selected character is still rendered at full saturation."
	)
	_expect(setup.selected_product_viewport.render_target_update_mode == SubViewport.UPDATE_ALWAYS, "The selected deck box is not rotating.")
	var hearty_box := main.find_child("StarterDeckBoxButton_hearty", true, false) as Button
	_expect(hearty_box != null, "The rotating Hearty deck box is not clickable.")
	if hearty_box != null:
		hearty_box.emit_signal("pressed")
	await process_frame
	await process_frame
	_expect(main.find_child("StarterDeckPreview", true, false) != null, "Clicking the rotating deck box did not open its contents.")
	main._close_starter_deck_preview()
	await process_frame

	setup._handle_back()
	await process_frame
	_expect(setup.selected_index == -1 and main.current_screen == "season_setup", "Back did not return from the expanded panel to the lineup.")
	setup.select_starter(0, false)
	await process_frame
	setup._begin_selected_run(0)
	await create_timer(0.12).timeout
	_expect(
		setup.panel_art[0].texture != null and setup.panel_art[0].texture.resource_path.ends_with("player_victory.png"),
		"Play did not swap the selected character to the victory pose."
	)
	await create_timer(0.72).timeout
	for _frame in range(4):
		await process_frame
	_expect(main.current_screen == "route_map", "The victory pose did not hand off to the Starter City run.")
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _finish() -> void:
	if failures.is_empty():
		print("STARTER_SELECTION_FLOW_SMOKE_TEST_OK")
		quit(0)
	else:
		quit(1)
