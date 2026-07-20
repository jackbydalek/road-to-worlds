extends RefCounted


const STEPS := [
	{
		"title": "Welcome to the Cook-Off",
		"subtitle": "Your goal",
		"body": "Both Chefs begin with 25 life. Build your board, serve Meals, and reduce the opposing Chef to 0 life before they do the same to you.",
		"tips": [
			"Your deck, hand, discard pile, and two board zones are always visible.",
			"The first player cannot attack on their opening turn. Use it to set up."
		],
		"focus": "goal"
	},
	{
		"title": "Know Your Cards",
		"subtitle": "Four essentials",
		"body": "Ingredients and Meals stay on the board. Tools resolve once and go to the discard. Chef cards create powerful effects, but you can use only one Chef each turn.",
		"tips": [
			"Ingredients provide the recipe types printed on them.",
			"Meals show the Ingredients their recipe requires.",
			"Card text overrides the basic rules whenever the two disagree."
		],
		"focus": "hand"
	},
	{
		"title": "Prepare Ingredients",
		"subtitle": "Set up this turn, cook next turn",
		"body": "Play Ingredients from your hand into Prep or Plated. A new Ingredient is PREPARING; it must survive until your next turn before it becomes RECIPE READY.",
		"tips": [
			"Prep is usually the safest place for an Ingredient you plan to cook with.",
			"Look for the RECIPE READY badge before selecting an Ingredient."
		],
		"focus": "ingredients"
	},
	{
		"title": "Serve a Meal",
		"subtitle": "Turn ready Ingredients into your main threats",
		"body": "Press Recipe on the matching ready Ingredients, then play a Meal from your hand. Choose Prep or Plated for the Meal. Its Ingredients are sacrificed to the discard pile.",
		"tips": [
			"You may serve one Meal per turn.",
			"A recipe must match every symbol listed on the Meal.",
			"Some advanced Meals also require sacrificing another Meal."
		],
		"focus": "serve"
	},
	{
		"title": "Use Prep and Plated",
		"subtitle": "Safety versus pressure",
		"body": "Plated units can normally attack and be attacked. Prep units are protected from normal attacks, but normally cannot attack. You may move one unit between these zones each turn.",
		"tips": [
			"Keep future recipes and support effects in Prep.",
			"Move attackers and defenders to Plated when you are ready to fight.",
			"Each zone has limited space, so plan before playing a card."
		],
		"focus": "zones"
	},
	{
		"title": "Attack and Defend",
		"subtitle": "Clear the plate, then hit the Chef",
		"body": "Select a ready Plated attacker, then choose an opposing Plated unit. Both units deal their Attack as damage at the same time. When the opposing Plated zone is empty, you can attack their Chef directly.",
		"tips": [
			"Damage remains on a unit until it is healed or KO'd.",
			"A unit is KO'd when damage reduces its Health to 0.",
			"Keywords such as Taunt and Stalwart can change legal targets."
		],
		"focus": "combat"
	},
	{
		"title": "Your Turn Checklist",
		"subtitle": "You are ready to play",
		"body": "Play Ingredients, use Tools or a Chef, serve one Meal, move one unit if needed, activate abilities, and attack with ready units. When you are finished, press End Turn and watch for reactions.",
		"tips": [
			"Read the message strip when an action needs another target or choice.",
			"Hover or inspect cards to review their full text.",
			"Reduce the opposing Chef to 0 life to win the match."
		],
		"focus": "checklist"
	}
]


var host
var step_index := 0


func open(host_ref) -> void:
	host = host_ref
	step_index = 0
	_render()


func _render() -> void:
	host.current_screen = "tutorial"
	host._apply_screen_chrome()
	host._clear(host.nav)
	host._clear(host.content)
	host._update_status()
	host._set_footer("Tutorial %d of %d — use Previous and Next to move through the walkthrough." % [step_index + 1, STEPS.size()])

	var step: Dictionary = STEPS[step_index]
	var header: VBoxContainer = host._add_panel(host.content, "Learn to Play", "#172a38")
	var progress_label: Label = host._add_body_text(header, "STEP %d OF %d  •  %s" % [step_index + 1, STEPS.size(), String(step.get("subtitle", ""))])
	progress_label.add_theme_color_override("font_color", Color("#8ed9ff"))
	var progress := ProgressBar.new()
	progress.name = "TutorialProgress"
	progress.max_value = STEPS.size()
	progress.value = step_index + 1
	progress.show_percentage = false
	progress.custom_minimum_size = Vector2(0, 10)
	header.add_child(progress)

	var stage := HBoxContainer.new()
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.add_theme_constant_override("separation", 12)
	host.content.add_child(stage)

	var lesson: VBoxContainer = host._add_bordered_panel(stage, String(step.get("title", "Tutorial")), "#202936", "#58bce8", 2)
	lesson.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lesson.custom_minimum_size = Vector2(390, 390)
	var body: Label = host._add_body_text(lesson, String(step.get("body", "")))
	body.add_theme_font_size_override("font_size", 17)

	var remember := Label.new()
	remember.text = "REMEMBER"
	remember.add_theme_font_size_override("font_size", 13)
	remember.add_theme_color_override("font_color", Color("#ffe08a"))
	lesson.add_child(remember)
	for tip in step.get("tips", []):
		host._add_body_text(lesson, "• " + String(tip))

	var preview: VBoxContainer = host._add_bordered_panel(stage, "Table Preview", "#f3ead8", "#ec7130", 2)
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview.custom_minimum_size = Vector2(610, 390)
	_build_table_preview(preview, String(step.get("focus", "goal")))

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	host.content.add_child(actions)

	var title_button: Button = host._make_button("Back to Title")
	title_button.name = "TutorialExitButton"
	host._connect_pressed(title_button, host._show_start)
	actions.add_child(title_button)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(spacer)

	if step_index > 0:
		var previous: Button = host._make_button("Previous")
		previous.name = "TutorialPreviousButton"
		host._connect_pressed(previous, func() -> void: _change_step(-1))
		actions.add_child(previous)

	var next: Button = host._make_button("Finish Tutorial" if step_index == STEPS.size() - 1 else "Next")
	next.name = "TutorialFinishButton" if step_index == STEPS.size() - 1 else "TutorialNextButton"
	host._style_button(next, "target" if step_index == STEPS.size() - 1 else "action")
	host._connect_pressed(next, host._show_start if step_index == STEPS.size() - 1 else func() -> void: _change_step(1))
	actions.add_child(next)


func _change_step(delta: int) -> void:
	step_index = clampi(step_index + delta, 0, STEPS.size() - 1)
	_render()


func _build_table_preview(parent: Node, focus: String) -> void:
	var opponent_chef := _banner("OPPOSING CHEF  •  25 LIFE", focus == "goal", Color("#a9413b"))
	parent.add_child(opponent_chef)

	var opponent_zones := HBoxContainer.new()
	opponent_zones.add_theme_constant_override("separation", 6)
	parent.add_child(opponent_zones)
	_add_zone(opponent_zones, "OPPONENT PLATED", ["Guard Meal\n4 ATK / 5 HP"], focus == "combat")
	_add_zone(opponent_zones, "OPPONENT PREP", ["Ingredient\nPREPARING"], false)

	var divider := HSeparator.new()
	parent.add_child(divider)

	var player_zones := HBoxContainer.new()
	player_zones.add_theme_constant_override("separation", 6)
	parent.add_child(player_zones)
	_add_zone(player_zones, "YOUR PLATED", ["Ready Meal\n5 ATK / 4 HP"], focus in ["zones", "combat"])
	_add_zone(player_zones, "YOUR PREP", ["Sweet Ingredient\nRECIPE READY", "Spicy Ingredient\nPREPARING"], focus in ["ingredients", "serve", "zones"])

	var hand_title := _banner("YOUR HAND", focus in ["hand", "serve", "checklist"], Color("#315b75"))
	parent.add_child(hand_title)
	var hand := HBoxContainer.new()
	hand.add_theme_constant_override("separation", 5)
	parent.add_child(hand)
	_add_card(hand, "Ingredient", "Build recipes", Color("#67a975"), focus in ["hand", "ingredients"])
	_add_card(hand, "Meal", "Needs recipe", Color("#d98945"), focus in ["hand", "serve"])
	_add_card(hand, "Tool", "One-shot effect", Color("#6889b5"), focus == "hand")
	_add_card(hand, "Chef", "Once per turn", Color("#9b6ca8"), focus == "hand")

	var callout_text := "Reduce this life to 0 to win."
	match focus:
		"hand": callout_text = "Read type, recipe, stats, and effect before playing."
		"ingredients": callout_text = "A new Ingredient becomes RECIPE READY on your next turn."
		"serve": callout_text = "Select ready Ingredients → play the matching Meal → choose a zone."
		"zones": callout_text = "Move one unit between Prep and Plated each turn."
		"combat": callout_text = "Clear opposing Plated units before attacking the Chef."
		"checklist": callout_text = "Set up, serve, move, activate, attack, then End Turn."
	var callout := _banner(callout_text, true, Color("#173e52"))
	callout.name = "TutorialStepCallout"
	parent.add_child(callout)


func _add_zone(parent: Node, title: String, cards: Array, highlighted: bool) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(0, 92)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#ead7b5"), Color("#ffe477") if highlighted else Color("#9d7449"), 4 if highlighted else 1))
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)
	var heading := Label.new()
	heading.text = title
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 12)
	heading.add_theme_color_override("font_color", Color("#173e52"))
	box.add_child(heading)
	var cards_row := HBoxContainer.new()
	cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_row.add_theme_constant_override("separation", 4)
	box.add_child(cards_row)
	for card_text in cards:
		_add_card(cards_row, String(card_text).get_slice("\n", 0), String(card_text).get_slice("\n", 1), Color("#ec7130"), highlighted)


func _add_card(parent: Node, title: String, subtitle: String, color: Color, highlighted: bool) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(105, 52)
	panel.add_theme_stylebox_override("panel", _panel_style(color, Color("#fff19a") if highlighted else Color("#173e52"), 3 if highlighted else 1))
	parent.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var name_label := Label.new()
	name_label.text = title
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	box.add_child(name_label)
	var detail := Label.new()
	detail.text = subtitle
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.add_theme_font_size_override("font_size", 10)
	detail.add_theme_color_override("font_color", Color("#fff4df"))
	box.add_child(detail)


func _banner(text: String, highlighted: bool, color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 38)
	panel.add_theme_stylebox_override("panel", _panel_style(color, Color("#ffe477") if highlighted else color.lightened(0.22), 3 if highlighted else 1))
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color.WHITE)
	panel.add_child(label)
	return panel


func _panel_style(background: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(6)
	style.content_margin_left = 7
	style.content_margin_right = 7
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style
