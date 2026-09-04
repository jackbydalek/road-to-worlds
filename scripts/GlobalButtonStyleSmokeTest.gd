extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")
const TABLE_SCENE := preload("res://scenes/Tabletop3DPrototype.tscn")

var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await _settle()
	_audit_visible_buttons(main, "title")
	_expect_variant(main, "ContinueRunButton", "primary")
	_expect_variant(main, "GameStartButton", "secondary")
	_expect_variant(main, "TitleHowToPlayButton", "secondary")

	main._show_settings()
	await _settle()
	_audit_visible_buttons(main, "settings")
	_expect_variant(main, "SettingsAbandonRunButton", "danger")

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
	await _settle()
	_audit_visible_buttons(main, "season hub")
	_expect_variant(main, "ExitToCardStoreButton", "secondary")

	main._show_shop()
	await _settle()
	_audit_visible_buttons(main, "shop")
	_expect_variant(main, "StoreOverviewRoundButton", "primary")

	main.queue_free()
	await _settle()
	var table = TABLE_SCENE.instantiate()
	root.add_child(table)
	await _settle()
	_audit_visible_buttons(table, "battle")
	_expect_variant(table, "EndTurnButton", "primary")
	_expect_variant(table, "SettingsButton", "secondary")

	if failed:
		quit(1)
		return
	print("Global button style smoke test passed.")
	quit(0)


func _audit_visible_buttons(scope: Node, screen_name: String) -> void:
	var audited := 0
	for node in scope.find_children("*", "", true, false):
		if not (node is Button):
			continue
		var button := node as Button
		if not button.is_visible_in_tree() or bool(button.get_meta("ui_button_style_exempt", false)):
			continue
		if button.text.strip_edges().is_empty() and button.icon == null:
			continue
		audited += 1
		_expect(
			button.get_node_or_null("BattleAngularButtonFace") != null,
			"%s has an unstyled visible button: %s." % [screen_name, button.name]
		)
	_expect(audited > 0, "%s did not expose any visible buttons to audit." % screen_name)


func _expect_variant(scope: Node, button_name: String, expected_variant: String) -> void:
	var button := scope.find_child(button_name, true, false) as Button
	var face = button.get_node_or_null("BattleAngularButtonFace") if button != null else null
	_expect(
		face != null and face.variant == expected_variant,
		"%s did not use the %s global button variant." % [button_name, expected_variant]
	)


func _settle() -> void:
	await process_frame
	await process_frame
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
