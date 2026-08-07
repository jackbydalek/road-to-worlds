extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")

var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	var starter: Dictionary = main._deck_entries_to_dict(
		main.archetypes_by_id.spicy.get("starterDeck", [])
	)
	main.run = main.run_state_service.create_run(
		"spicy",
		starter,
		main._predator_archetype("spicy"),
		"season",
		"white"
	)
	main._generate_shop_inventory()
	main._show_season_run()
	await process_frame
	await process_frame

	var background := main.find_child("PaperBackground", true, false) as ColorRect
	var pastel_background := main.find_child("PastelWorkspaceBackground", true, false) as ColorRect
	_expect(
		background != null and not background.visible
		and pastel_background != null and pastel_background.visible,
		"The season menu did not use the responsive pastel card-café background."
	)
	_expect(not main.header_bar.visible and not main.footer_label.visible, "The legacy shell chrome still surrounds the Nexus season menu.")
	_expect(main.find_child("SeasonHubMenuRail", true, false) != null, "The Nexus menu rail is missing.")
	_expect(main.find_child("SeasonHubEventWorkspace", true, false) != null, "The Nexus event workspace is missing.")
	var season_header := main.find_child("SeasonHubHeader", true, false) as PanelContainer
	var season_rail := main.find_child("SeasonHubMenuRail", true, false) as PanelContainer
	var header_style := season_header.get_theme_stylebox("panel") as StyleBoxFlat if season_header != null else null
	var rail_style := season_rail.get_theme_stylebox("panel") as StyleBoxFlat if season_rail != null else null
	_expect(header_style != null and header_style.bg_color.get_luminance() > 0.65, "The season header fell back to the old dark dashboard surface.")
	_expect(rail_style != null and rail_style.bg_color.get_luminance() > 0.65, "The season menu rail fell back to the old dark dashboard surface.")

	var events_button := main.find_child("SeasonHubEventsButton", true, false) as Button
	var register_button := main.find_child("SeasonHubNextStepButton", true, false) as Button
	var current_event := main.find_child("SeasonHubCalendarButton_weekly_locals", true, false) as Button
	var locked_event := main.find_child("SeasonHubCalendarButton_monthly_regionals", true, false) as Button
	_expect(events_button != null and not events_button.disabled, "The selected Season Events tile does not retain its active styling.")
	_expect(register_button != null and register_button.text == "REGISTER" and not register_button.disabled, "The selected legal event does not expose Register.")
	_expect(current_event != null and current_event.text == "CURRENT EVENT" and not current_event.disabled, "The current event does not render as the active selection.")
	_expect(locked_event != null and locked_event.text == "LOCKED" and locked_event.disabled, "The future event does not render as locked.")

	main._show_start()
	await process_frame
	_expect(background != null and background.visible and not pastel_background.visible, "Leaving the season menu did not restore the lightweight cream background.")

	main._release_audio_streams()
	await create_timer(0.12).timeout
	main.queue_free()
	for unused_frame in range(4):
		await process_frame
	if failed:
		quit(1)
		return
	print("Nexus season UI smoke test passed.")
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
