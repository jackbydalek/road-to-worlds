extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")
const OUTPUT_PATH := "res://outputs/illustrated_vfx/battle_shell_no_border.png"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main._start_new_run_with_mode("sweet", "debug", "white")
	var player_deck: Dictionary = main._deck_entries_to_dict(main.archetypes_by_id.sweet.starterDeck)
	var opponent_deck: Dictionary = main._opponent_deck_for_round("hearty", 1)
	main._begin_kitchen_match(player_deck, opponent_deck, "League Player", false, 20260825, "player", "easy")
	for _frame in range(12):
		await process_frame
	var table := main.find_child("Tabletop3DPrototype", true, false) as Control
	if table != null:
		table.turn_banner_panel.visible = false
		table.rival_action_panel.visible = false
	var margins := ["margin_left", "margin_right", "margin_top", "margin_bottom"]
	for margin_name in margins:
		if main.root_margin.get_theme_constant(margin_name) != 0:
			push_error("Battle shell retained outer margin: %s" % margin_name)
	if table != null:
		var header := table.find_child("MatchHeader", true, false) as Control
		var info := table.find_child("BoardInfoButton", true, false) as Control
		if header == null or info == null or header.get_global_rect().end.x >= info.get_global_rect().position.x:
			push_error("Battle header still overlaps the right utility controls.")
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.save_png(ProjectSettings.globalize_path(OUTPUT_PATH)) != OK:
		push_error("Could not save corrected battle-shell preview.")
	quit()
