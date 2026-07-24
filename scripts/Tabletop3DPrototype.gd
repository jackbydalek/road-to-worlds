extends Control

signal exit_requested
signal match_finished(result: Dictionary)

const CARD_FACE_SCRIPT := preload("res://scripts/CardFace.gd")
const COMBAT_SERVICE_SCRIPT := preload("res://scripts/cooking/CookingCombatService.gd")
const CARD_BACK := preload("res://assets/cards/card_backs/living_table.png")
const ART_PENDING := preload("res://assets/cards/art_pending.png")

const TABLE_Y := 0.235
const DRAG_Y := 0.82
const FIELD_CARD_SIZE := Vector2(1.08, 1.54)
const PLAYER_HAND_Z := 4.25
const OPPONENT_HAND_Z := -5.18
const PLAYER_HAND_MAX_WIDTH := 8.8
const OPPONENT_HAND_MAX_WIDTH := 6.6
const HAND_CARD_GAP := 0.14
const CARD_FACE_TEXTURE_SIZE := Vector2i(320, 455)
const FLOATING_ART_HEIGHT := 0.62
const REACTION_WINDOW_SECONDS := 5.0
const TUTORIAL_STEPS := [
	{"lesson": 1, "title": "Welcome to the Table", "body": "Both Chefs normally begin at 25 life. Ingredients and Meals occupy Prep or Plated. Prep is protected; Plated is where combat happens.", "prompt": "Press Begin to learn by playing a fixed practice hand.", "action": "continue", "scenario": "opening"},
	{"lesson": 2, "title": "Play an Ingredient", "body": "Ingredients build recipes. New Ingredients are PREPARING until the start of your next turn.", "prompt": "Click the glowing Hot Honey Bee in your hand.", "action": "select_hand", "card_id": "spicy_hot_honey_bee"},
	{"lesson": 2, "title": "Choose a Safe Zone", "body": "Prep protects a card from normal attacks while it matures. Plated cards can fight, but can also be attacked.", "prompt": "In Card Info, choose Play → Prep 2.", "action": "play_hand", "card_id": "spicy_hot_honey_bee", "zone": "prep", "slot": 1},
	{"lesson": 2, "title": "Let It Mature", "body": "At the start of your next turn, the Ingredient becomes RECIPE READY. Normal matches give the rival a full turn in between.", "prompt": "Press END TURN. The lesson will fast-forward the scripted rival turn.", "action": "end_turn"},
	{"lesson": 3, "title": "Set an Environment", "body": "Environments stay in their own slot and change the rules of your kitchen. Playing another replaces the old one.", "prompt": "Click the glowing Blazing Wok.", "action": "select_hand", "card_id": "environment_blazing_wok", "scenario": "recipe"},
	{"lesson": 3, "title": "Use the Environment", "body": "Blazing Wok gives each Meal you serve +1 Attack.", "prompt": "Choose Use Environment in Card Info.", "action": "play_hand", "card_id": "environment_blazing_wok"},
	{"lesson": 4, "title": "Serve a Meal", "body": "Meals are stronger units, but they require RECIPE READY Ingredients that match every symbol in their recipe.", "prompt": "Click the glowing Sriracharrow in your hand.", "action": "select_hand", "card_id": "spicy_sriracharrow"},
	{"lesson": 4, "title": "Choose Its Zone", "body": "You may serve one Meal each turn. This one will enter Prep, using the slot its Ingredient is about to vacate.", "prompt": "Choose Serve → Prep 2 (Sacrifice).", "action": "begin_meal", "card_id": "spicy_sriracharrow", "zone": "prep", "slot": 1},
	{"lesson": 4, "title": "Pay the Recipe", "body": "The cyan glow marks legal recipe Ingredients. The selected Ingredient will be sacrificed to your discard pile.", "prompt": "Click the glowing Hot Honey Bee on your table.", "action": "select_recipe", "card_id": "spicy_hot_honey_bee"},
	{"lesson": 4, "title": "Confirm the Meal", "body": "Sriracharrow needs one Spicy Ingredient. The selected Bee satisfies the full recipe.", "prompt": "Press Serve Meal in the message strip.", "action": "confirm_meal"},
	{"lesson": 5, "title": "Prep Versus Plated", "body": "A unit in Prep is safe but normally cannot attack. You may move one unit between Prep and Plated each turn.", "prompt": "Click your glowing Sriracharrow.", "action": "select_field", "card_id": "spicy_sriracharrow"},
	{"lesson": 5, "title": "Move Into Combat", "body": "Moving into Plated makes a unit available for combat immediately, unless another rule says otherwise.", "prompt": "Choose Move → Plated 1.", "action": "move_unit", "card_id": "spicy_sriracharrow", "zone": "plated", "slot": 0},
	{"lesson": 6, "title": "Support Cards", "body": "Spices attach to a unit. Tools resolve once and go to discard. Chef cards are powerful actions limited to one per turn.", "prompt": "Click your glowing Sriracharrow first.", "action": "select_field", "card_id": "spicy_sriracharrow", "scenario": "support"},
	{"lesson": 6, "title": "Choose a Spice Target", "body": "A Spice needs a friendly unit selected before it can be played.", "prompt": "Choose Season This Card.", "action": "select_spice_target", "card_id": "spicy_sriracharrow"},
	{"lesson": 6, "title": "Play a Spice", "body": "Cayenne Crunch stays attached and gives the selected Meal +1 Attack.", "prompt": "Click the glowing Cayenne Crunch in your hand.", "action": "select_hand", "card_id": "spice_cayenne_crunch"},
	{"lesson": 6, "title": "Attach the Spice", "body": "The action is locked to the Meal you selected.", "prompt": "Choose Season Selected.", "action": "play_hand", "card_id": "spice_cayenne_crunch"},
	{"lesson": 6, "title": "Use a Tool", "body": "Tools are one-shot effects. Wooden Spoon draws one card, then goes to your discard pile.", "prompt": "Click the glowing Wooden Spoon.", "action": "select_hand", "card_id": "item_wooden_spoon"},
	{"lesson": 6, "title": "Resolve the Tool", "body": "Tools do not occupy a board slot.", "prompt": "Choose Use Tool.", "action": "play_hand", "card_id": "item_wooden_spoon"},
	{"lesson": 6, "title": "Use a Chef", "body": "Chef Giada draws three cards. You may use only one Chef card each turn.", "prompt": "Click the glowing Chef Giada.", "action": "select_hand", "card_id": "chef_mary"},
	{"lesson": 6, "title": "Resolve the Chef", "body": "Chef cards also resolve immediately and go to your discard pile.", "prompt": "Choose Use Chef.", "action": "play_hand", "card_id": "chef_mary"},
	{"lesson": 7, "title": "Choose an Attacker", "body": "Only ready Plated units can normally attack. Each attacker can attack once per turn.", "prompt": "Click the glowing left Sriracharrow.", "action": "select_field", "instance_id": 1, "scenario": "combat"},
	{"lesson": 7, "title": "Declare the Attack", "body": "Selecting an attacker makes legal defenders glow.", "prompt": "Choose Choose Attacker.", "action": "select_attacker", "instance_id": 1},
	{"lesson": 7, "title": "Clear Their Plated Zone", "body": "If the rival has a Plated unit, you must attack a legal defender before attacking their Chef. Combat damage is simultaneous.", "prompt": "Click the glowing opposing Bagver.", "action": "attack_unit", "target_instance_id": 3},
	{"lesson": 7, "title": "Choose Your Second Attacker", "body": "Your first Meal is spent, but the second is still ready.", "prompt": "Click the glowing right Sriracharrow.", "action": "select_field", "instance_id": 2},
	{"lesson": 7, "title": "Declare the Final Attack", "body": "The rival Plated zone is empty, so a direct Chef attack is now legal.", "prompt": "Choose Choose Attacker.", "action": "select_attacker", "instance_id": 2},
	{"lesson": 7, "title": "Attack the Rival Chef", "body": "Reducing the opposing Chef to 0 life wins the match.", "prompt": "Click the glowing rival Chef.", "action": "attack_chef"},
	{"lesson": 7, "title": "Tutorial Complete", "body": "You played an Ingredient, matured and sacrificed it, served and moved a Meal, used support cards, cleared a defender, and won with a direct attack.", "prompt": "Return to the title screen when you are ready.", "action": "finish"}
]
const ZONE_CENTERS := {
	"player_prep": Vector3(0.0, TABLE_Y, 1.25),
	"player_plated": Vector3(0.0, TABLE_Y, -0.65),
	"opponent_plated": Vector3(0.0, TABLE_Y, -2.55),
	"opponent_prep": Vector3(0.0, TABLE_Y, -4.25)
}
const ZONE_EXTENTS := {
	"player_prep": Vector2(2.8, 0.82),
	"player_plated": Vector2(2.0, 0.82),
	"opponent_plated": Vector2(2.0, 0.82),
	"opponent_prep": Vector2(2.8, 0.82)
}
const AUX_ZONE_POSITIONS := {
	"player_deck": Vector3(5.05, TABLE_Y, 2.72),
	"player_discard": Vector3(5.05, TABLE_Y, 1.05),
	"player_environment": Vector3(-5.05, TABLE_Y, 0.05),
	"opponent_deck": Vector3(-5.05, TABLE_Y, -4.55),
	"opponent_discard": Vector3(-5.05, TABLE_Y, -2.88),
	"opponent_environment": Vector3(5.05, TABLE_Y, -3.0)
}

@onready var viewport_container: SubViewportContainer = $ViewportContainer
@onready var world_viewport: SubViewport = $ViewportContainer/WorldViewport
@onready var camera: Camera3D = $ViewportContainer/WorldViewport/World/Camera3D
@onready var card_layer: Node3D = $ViewportContainer/WorldViewport/World/CardLayer
@onready var animation_ghost_layer: Node3D = $ViewportContainer/WorldViewport/World/AnimationGhostLayer
@onready var texture_viewports: Node = $CardTextureViewports
@onready var player_chef: Node3D = $ViewportContainer/WorldViewport/World/PlayerChef
@onready var opponent_chef: Node3D = $ViewportContainer/WorldViewport/World/OpponentChef
@onready var status_label: Label = $Interface/StatusPanel/Margin/StatusRow/StatusLabel
@onready var title_label: Label = $Interface/TopBar/Margin/TopRow/Title
@onready var confirm_choice_button: Button = $Interface/StatusPanel/Margin/StatusRow/ConfirmChoiceButton
@onready var cancel_choice_button: Button = $Interface/StatusPanel/Margin/StatusRow/CancelChoiceButton
@onready var effect_layer: Control = $Interface/EffectLayer
@onready var action_panel: PanelContainer = $Interface/ActionPanel
@onready var action_list: VBoxContainer = $Interface/ActionPanel/Margin/Actions
@onready var prompt_panel: PanelContainer = $Interface/PromptPanel
@onready var prompt_content: VBoxContainer = $Interface/PromptPanel/Margin/PromptContent
@onready var card_tray_overlay: Control = $Interface/CardTrayOverlay
@onready var card_tray_panel: PanelContainer = $Interface/CardTrayOverlay/TrayPanel
@onready var card_tray_title: Label = $Interface/CardTrayOverlay/TrayPanel/Margin/Content/Header/Title
@onready var card_tray_close_button: Button = $Interface/CardTrayOverlay/TrayPanel/Margin/Content/Header/CardTrayCloseButton
@onready var card_tray_prompt: Label = $Interface/CardTrayOverlay/TrayPanel/Margin/Content/Prompt
@onready var card_tray_cards: HBoxContainer = $Interface/CardTrayOverlay/TrayPanel/Margin/Content/CardScroll/CardCenter/CardRow
@onready var card_tray_selection_status: Label = $Interface/CardTrayOverlay/TrayPanel/Margin/Content/Footer/SelectionStatus
@onready var card_tray_skip_button: Button = $Interface/CardTrayOverlay/TrayPanel/Margin/Content/Footer/CardTraySkipButton
@onready var card_tray_confirm_button: Button = $Interface/CardTrayOverlay/TrayPanel/Margin/Content/Footer/CardTrayConfirmButton
@onready var player_life: Label = $Interface/TopBar/Margin/TopRow/PlayerLife
@onready var opponent_life: Label = $Interface/TopBar/Margin/TopRow/OpponentLife
@onready var turn_label: Label = $Interface/TopBar/Margin/TopRow/TurnLabel
@onready var end_turn_button: Button = $Interface/EndTurnButton
@onready var reset_button: Button = $Interface/TopBar/Margin/TopRow/ResetButton
@onready var exit_button: Button = $Interface/TopBar/Margin/TopRow/ExitButton
@onready var battle_log_button: Button = $Interface/BattleLogButton
@onready var battle_log_panel: PanelContainer = $Interface/BattleLogPanel
@onready var battle_log_close_button: Button = $Interface/BattleLogPanel/Margin/Content/Header/CloseButton
@onready var battle_log_text: RichTextLabel = $Interface/BattleLogPanel/Margin/Content/LogText

var service = COMBAT_SERVICE_SCRIPT.new()
var state: Dictionary = {}
var face_materials: Dictionary = {}
var interactive_cards: Array[Node3D] = []
var floating_arts: Array[MeshInstance3D] = []
var highlighted_bodies: Array[MeshInstance3D] = []
var animation_ghost_nodes: Dictionary = {}
var zone_materials: Dictionary = {}
var art_frames: Array[Texture2D] = []
var selected_ref: Dictionary = {}
var pressed_card: Node3D
var hovered_card: Node3D
var press_screen_position := Vector2.ZERO
var dragging := false
var drag_offset := Vector3.ZERO
var drag_original_position := Vector3.ZERO
var drag_original_rotation := Vector3.ZERO
var current_zone := "hand"
var highlighted_zone := ""
var highlighted_slot := -1
var opponent_running := false
var animation_busy := false
var match_seed := 37
var production_match := false
var configured_player_deck: Dictionary = {}
var configured_opponent_deck: Dictionary = {}
var configured_player_name := "Your Kitchen"
var configured_opponent_name := "Opponent Kitchen"
var configured_seed := 1
var configured_first_side := "player"
var configured_exit_label := "Return"
var configured_ai_difficulty := "easy"
var configured_card_border_id := "white"
var configured_match_context: Dictionary = {}
var result_emitted := false
var manual_discard_tray_side := ""
var camera_home_transform := Transform3D.IDENTITY
var camera_home_fov := 43.0
var camera_pacing_tween: Tween
var turn_banner_panel: PanelContainer
var turn_banner_title: Label
var turn_banner_subtitle: Label
var outcome_overlay: ColorRect
var outcome_title: Label
var outcome_subtitle: Label
var outcome_sequence_running := false
var outcome_sequence_played := false
var card_face_redraw_requests := 0
var reaction_countdown_active := false
var reaction_countdown_remaining := 0.0
var reaction_countdown_label: Label
var tutorial_mode := false
var tutorial_step_index := 0
var tutorial_panel: PanelContainer
var tutorial_title_label: Label
var tutorial_body_label: Label
var tutorial_prompt_label: Label
var tutorial_progress_label: Label
var tutorial_action_button: Button


func configure_match(
	player_deck: Dictionary,
	opponent_deck: Dictionary,
	player_name: String,
	opponent_name: String,
	seed: int,
	first_side: String = "player",
	exit_label: String = "Return",
	ai_difficulty: String = "easy",
	card_border_id: String = "white",
	match_context: Dictionary = {}
) -> void:
	production_match = true
	configured_player_deck = player_deck.duplicate(true)
	configured_opponent_deck = opponent_deck.duplicate(true)
	configured_player_name = player_name
	configured_opponent_name = opponent_name
	configured_seed = seed
	configured_first_side = first_side
	configured_exit_label = exit_label
	configured_ai_difficulty = ai_difficulty
	configured_card_border_id = card_border_id
	configured_match_context = match_context.duplicate(true)


func configure_tutorial() -> void:
	tutorial_mode = true
	configured_player_name = "Teaching Kitchen"
	configured_opponent_name = "Practice Rival"
	configured_exit_label = "Exit to Title"
	configured_card_border_id = "white"


func _ready() -> void:
	camera.look_at(Vector3(0.0, 0.25, -1.15), Vector3.UP)
	camera_home_transform = camera.global_transform
	camera_home_fov = camera.fov
	_build_pacing_interface()
	viewport_container.gui_input.connect(_on_table_gui_input)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	reset_button.pressed.connect(_start_match)
	exit_button.pressed.connect(func() -> void: exit_requested.emit())
	battle_log_button.pressed.connect(_toggle_battle_log)
	battle_log_close_button.pressed.connect(func() -> void: _set_battle_log_visible(false))
	card_tray_close_button.pressed.connect(_close_card_tray)
	card_tray_skip_button.pressed.connect(_skip_card_tray_choice)
	card_tray_confirm_button.pressed.connect(_confirm_discard_choice)
	confirm_choice_button.pressed.connect(_confirm_bottom_choice)
	cancel_choice_button.pressed.connect(_cancel_bottom_choice)
	_apply_rounded_button_style(confirm_choice_button)
	_apply_rounded_button_style(cancel_choice_button)
	_apply_rounded_button_style(end_turn_button)
	_apply_rounded_button_style(battle_log_button)
	_apply_rounded_button_style(battle_log_close_button)
	_apply_rounded_button_style(card_tray_close_button)
	_apply_rounded_button_style(card_tray_skip_button)
	_apply_rounded_button_style(card_tray_confirm_button)
	_apply_card_tray_panel_style()
	service.load_content()
	if production_match:
		service.decks["configured_player"] = {"name": configured_player_name, "archetype": "", "cards": configured_player_deck}
		service.decks["configured_opponent"] = {"name": configured_opponent_name, "archetype": "", "cards": configured_opponent_deck}
		reset_button.visible = false
		exit_button.text = configured_exit_label
	if tutorial_mode:
		reset_button.visible = false
		exit_button.text = configured_exit_label
		battle_log_button.visible = false
		_build_tutorial_interface()
	_load_reference_art()
	_prepare_zone_materials()
	_start_match()
	set_process(true)


func _start_match() -> void:
	result_emitted = false
	outcome_sequence_running = false
	outcome_sequence_played = false
	animation_busy = false
	_reset_camera_pacing()
	if outcome_overlay != null:
		outcome_overlay.visible = false
		outcome_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	if turn_banner_panel != null:
		turn_banner_panel.visible = false
	_clear_animation_ghosts()
	manual_discard_tray_side = ""
	if tutorial_mode:
		tutorial_step_index = 0
		state = service.start_game("spicy_test_kitchen", "hearty_test_kitchen", 7107, "player", true, "easy")
		_load_tutorial_scenario("opening")
	elif production_match:
		state = service.start_game("configured_player", "configured_opponent", configured_seed, configured_first_side, true, configured_ai_difficulty)
	else:
		match_seed += 1
		state = service.start_game("spicy_test_kitchen", "hearty_test_kitchen", match_seed, "player", true, "easy")
	selected_ref = {}
	dragging = false
	pressed_card = null
	opponent_running = false
	_render_match()
	if tutorial_mode:
		_refresh_tutorial_panel()
	else:
		call_deferred("_begin_match_pacing")


func _begin_match_pacing() -> void:
	if state.is_empty() or bool(state.get("game_over", false)):
		return
	if String(state.get("phase", "")) == "player_main":
		# The opening banner is presentation-only so the player can immediately inspect or drag a card.
		_show_turn_banner("player_main")
		return
	animation_busy = true
	await _show_turn_banner(String(state.get("phase", "")))
	animation_busy = false
	_render_match()
	if String(state.get("phase", "")) == "opponent_turn":
		_run_opponent_sequence()


func _build_tutorial_interface() -> void:
	tutorial_panel = PanelContainer.new()
	tutorial_panel.name = "GuidedTutorialPanel"
	tutorial_panel.z_index = 40
	tutorial_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	tutorial_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	tutorial_panel.offset_left = 18.0
	tutorial_panel.offset_top = 84.0
	tutorial_panel.offset_right = 430.0
	tutorial_panel.offset_bottom = 310.0
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.035, 0.12, 0.16, 0.96)
	panel_style.border_color = Color("#f1b84f")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(18)
	panel_style.shadow_color = Color(0, 0, 0, 0.55)
	panel_style.shadow_size = 14
	tutorial_panel.add_theme_stylebox_override("panel", panel_style)
	$Interface.add_child(tutorial_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	tutorial_panel.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 7)
	margin.add_child(content)

	tutorial_progress_label = _label("", 12, Color("#8ed9ff"))
	content.add_child(tutorial_progress_label)
	tutorial_title_label = _label("", 24, Color("#fff1c5"))
	content.add_child(tutorial_title_label)
	tutorial_body_label = _label("", 14, Color("#dce9ed"))
	tutorial_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(tutorial_body_label)
	tutorial_prompt_label = _label("", 15, Color("#ffd36f"))
	tutorial_prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(tutorial_prompt_label)
	tutorial_action_button = _styled_button("Begin")
	tutorial_action_button.pressed.connect(_on_tutorial_action_pressed)
	content.add_child(tutorial_action_button)

	# Keep Card Info visible below the written lesson instead of covering it.
	action_panel.offset_top = 322.0


func _refresh_tutorial_panel() -> void:
	if not tutorial_mode or not is_instance_valid(tutorial_panel):
		return
	var step := _tutorial_step()
	tutorial_progress_label.text = "GUIDED HOW TO PLAY  •  LESSON %d OF 7  •  STEP %d/%d" % [
		int(step.get("lesson", 1)),
		tutorial_step_index + 1,
		TUTORIAL_STEPS.size()
	]
	tutorial_title_label.text = String(step.get("title", "How to Play"))
	tutorial_body_label.text = String(step.get("body", ""))
	tutorial_prompt_label.text = "DO THIS: " + String(step.get("prompt", ""))
	var action := String(step.get("action", ""))
	tutorial_action_button.visible = action in ["continue", "finish"]
	tutorial_action_button.text = "Begin Tutorial" if action == "continue" else "Return to Title"
	title_label.text = "HOW TO PLAY  •  GUIDED PRACTICE"


func _on_tutorial_action_pressed() -> void:
	if String(_tutorial_step().get("action", "")) == "finish":
		exit_requested.emit()
	else:
		_tutorial_complete_action("continue")
		_render_match()


func _tutorial_step() -> Dictionary:
	if tutorial_step_index < 0 or tutorial_step_index >= TUTORIAL_STEPS.size():
		return TUTORIAL_STEPS[TUTORIAL_STEPS.size() - 1]
	return TUTORIAL_STEPS[tutorial_step_index]


func _tutorial_complete_action(action: String, details: Dictionary = {}) -> bool:
	if not tutorial_mode:
		return true
	if not _tutorial_action_matches(action, details):
		_tutorial_reject_action()
		return false
	tutorial_step_index = mini(tutorial_step_index + 1, TUTORIAL_STEPS.size() - 1)
	var next_step := _tutorial_step()
	var scenario := String(next_step.get("scenario", ""))
	if scenario != "":
		_load_tutorial_scenario(scenario)
	_refresh_tutorial_panel()
	return true


func _tutorial_action_matches(action: String, details: Dictionary = {}) -> bool:
	var expected := _tutorial_step()
	if String(expected.get("action", "")) != action:
		return false
	for key in ["card_id", "instance_id", "zone", "slot", "target_instance_id"]:
		if expected.has(key) and expected[key] != details.get(key):
			return false
	return true


func _tutorial_reject_action() -> void:
	var prompt := String(_tutorial_step().get("prompt", "Follow the highlighted action."))
	state.message = "Tutorial locked: " + prompt
	_refresh_bottom_status()
	if is_instance_valid(tutorial_prompt_label):
		tutorial_prompt_label.modulate = Color("#ff8f7a")
		var tween := create_tween()
		tween.tween_property(tutorial_prompt_label, "modulate", Color.WHITE, 0.35)


func _load_tutorial_scenario(scenario: String) -> void:
	_reset_tutorial_state()
	match scenario:
		"recipe":
			state.player.hand = ["environment_blazing_wok", "spicy_sriracharrow", "item_wooden_spoon"]
			state.player.deck = ["spicy_jalapeno_panther", "spicy_firecracker_shrimp", "spicy_sriracharrow"]
			_add_tutorial_unit("player", "spicy_hot_honey_bee", "prep", 1, false, true)
			state.message = "A preplanned turn: Hot Honey Bee is now RECIPE READY."
		"support":
			state.player.hand = ["spice_cayenne_crunch", "item_wooden_spoon", "chef_mary"]
			state.player.deck = [
				"spicy_hot_honey_bee", "spicy_jalapeno_panther", "spicy_firecracker_shrimp",
				"spicy_sriracharrow", "spicy_ghost_pepper_python"
			]
			_add_tutorial_unit("player", "spicy_sriracharrow", "plated", 0, true, true)
			state.message = "Support cards use the real card effects with a fixed deck."
		"combat":
			state.player.hand = []
			state.player.deck = ["spicy_hot_honey_bee"]
			state.opponent.life = 5
			_add_tutorial_unit("player", "spicy_sriracharrow", "plated", 0, true, true)
			_add_tutorial_unit("player", "spicy_sriracharrow", "plated", 1, true, true)
			_add_tutorial_unit("opponent", "hearty_bagver", "plated", 0, true, true)
			state.message = "Two ready Meals face one Plated defender."
		_:
			state.player.hand = ["spicy_hot_honey_bee", "item_wooden_spoon", "spicy_sriracharrow"]
			state.player.deck = ["spicy_jalapeno_panther", "spicy_firecracker_shrimp"]
			state.message = "This practice hand is fixed. Only the glowing tutorial action is available."
	selected_ref = {}
	service.clear_animation_events(state)


func _reset_tutorial_state() -> void:
	state.turn = 2
	state.phase = "player_main"
	state.first_player = "opponent"
	state.game_over = false
	state.winner = ""
	state.next_instance_id = 1
	state.selected_ingredients = []
	state.selected_attacker = -1
	state.selected_spice_target = -1
	state.pending_meal = {}
	state.pending_discard = {}
	state.pending_ability = {}
	state.pending_search = {}
	state.pending_choice = {}
	state.pending_resume = {}
	state.pending_reaction = {}
	state.opponent_sequence = {}
	state.animation_events = []
	state.log = []
	for side in ["player", "opponent"]:
		var who: Dictionary = state[side]
		who.life = 25
		who.deck = []
		who.hand = []
		who.prep = []
		who.plated = []
		who.environment = ""
		who.discard = []
		who.meal_served = false
		who.chef_used = false
		who.zone_move_used = false
		who.chefs_disabled = false
		who.items_disabled = false
		who.hand_trap_used = false
		who.fatigue = 0
		who.turns_started = 2


func _add_tutorial_unit(side: String, card_id: String, zone: String, slot: int, ready: bool, recipe_ready: bool) -> Dictionary:
	var who: Dictionary = state[side]
	var unit: Dictionary = service._make_unit(state, who, service.card(card_id), zone, side)
	unit.table_slot = slot
	unit.ready = ready
	unit.recipe_ready_on_turn = 1 if recipe_ready else int(who.turns_started) + 1
	who[zone].append(unit)
	return unit


func _load_reference_art() -> void:
	art_frames.clear()
	for frame_index in range(6):
		var texture := load("res://assets/cards/art/spicy_hot_honey_bee/frame_%02d.png" % frame_index) as Texture2D
		if texture != null:
			art_frames.append(texture)


func _render_match() -> void:
	_ensure_unit_slot_assignments()
	for child in card_layer.get_children():
		child.free()
	interactive_cards.clear()
	floating_arts.clear()
	highlighted_bodies.clear()
	hovered_card = null
	if state.is_empty():
		return
	_build_auxiliary_presentations()
	_build_hand_cards("player")
	_build_hand_cards("opponent")
	_build_field_cards("player", "prep")
	_build_field_cards("player", "plated")
	_build_field_cards("opponent", "plated")
	_build_field_cards("opponent", "prep")
	_build_environment_card("player")
	_build_environment_card("opponent")
	player_life.text = "YOU  %d" % int(state.player.life)
	opponent_life.text = "RIVAL  %d" % int(state.opponent.life)
	turn_label.text = "TURN %d  •  %s" % [int(state.turn), "YOU" if String(state.phase) == "player_main" else "RIVAL"]
	_update_match_title()
	end_turn_button.disabled = animation_busy or String(state.phase) != "player_main" or _has_blocking_prompt() or bool(state.game_over)
	if tutorial_mode:
		end_turn_button.disabled = String(_tutorial_step().get("action", "")) != "end_turn"
	_update_chef_labels()
	_refresh_action_panel()
	_refresh_prompt()
	_refresh_card_tray()
	_refresh_bottom_status()
	_refresh_battle_log()
	if tutorial_mode:
		_refresh_tutorial_panel()
	if bool(state.get("game_over", false)) and not animation_busy and not tutorial_mode:
		_queue_outcome_sequence()


func _update_match_title() -> void:
	if tutorial_mode:
		title_label.text = "HOW TO PLAY  •  GUIDED PRACTICE"
		return
	if not production_match:
		title_label.text = "LIVING TABLE  •  PLAYABLE MATCH"
		return
	var event_name := String(configured_match_context.get("event_name", ""))
	var round_number := int(configured_match_context.get("round", 0))
	var total_rounds := int(configured_match_context.get("rounds", 0))
	if bool(configured_match_context.get("tournament_round", false)) and round_number > 0:
		title_label.text = "%s  •  ROUND %d/%d  •  %s AI" % [event_name if event_name != "" else "TOURNAMENT", round_number, maxi(round_number, total_rounds), configured_ai_difficulty.to_upper()]
	else:
		title_label.text = "%s  vs  %s  •  %s AI" % [configured_player_name, configured_opponent_name, configured_ai_difficulty.to_upper()]


func _emit_match_finished_once() -> void:
	if not production_match or result_emitted or not outcome_sequence_played or not bool(state.get("game_over", false)):
		return
	result_emitted = true
	match_finished.emit({
		"winner": String(state.get("winner", "")),
		"turn": int(state.get("turn", 0)),
		"player_life": int(state.get("player", {}).get("life", 0)),
		"opponent_life": int(state.get("opponent", {}).get("life", 0)),
		"ai_difficulty": String(state.get("ai_difficulty", configured_ai_difficulty)),
		"match_context": configured_match_context.duplicate(true)
	})


func _build_pacing_interface() -> void:
	turn_banner_panel = PanelContainer.new()
	turn_banner_panel.name = "TurnBanner"
	turn_banner_panel.visible = false
	turn_banner_panel.z_index = 240
	turn_banner_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	turn_banner_panel.set_anchors_preset(Control.PRESET_CENTER)
	turn_banner_panel.position = Vector2(-235.0, -58.0)
	turn_banner_panel.size = Vector2(470.0, 116.0)
	var banner_style := StyleBoxFlat.new()
	banner_style.bg_color = Color(0.025, 0.065, 0.085, 0.94)
	banner_style.border_color = Color("#efb246")
	banner_style.set_border_width_all(3)
	banner_style.set_corner_radius_all(18)
	turn_banner_panel.add_theme_stylebox_override("panel", banner_style)
	effect_layer.add_child(turn_banner_panel)
	var banner_margin := MarginContainer.new()
	banner_margin.add_theme_constant_override("margin_left", 26)
	banner_margin.add_theme_constant_override("margin_top", 13)
	banner_margin.add_theme_constant_override("margin_right", 26)
	banner_margin.add_theme_constant_override("margin_bottom", 13)
	turn_banner_panel.add_child(banner_margin)
	var banner_content := VBoxContainer.new()
	banner_content.alignment = BoxContainer.ALIGNMENT_CENTER
	banner_content.add_theme_constant_override("separation", 1)
	banner_margin.add_child(banner_content)
	turn_banner_title = _label("YOUR TURN", 34, Color("#fff2c7"))
	turn_banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_banner_title.add_theme_color_override("font_outline_color", Color("#07151c"))
	turn_banner_title.add_theme_constant_override("outline_size", 8)
	banner_content.add_child(turn_banner_title)
	turn_banner_subtitle = _label("TURN 1", 16, Color("#8fddf5"))
	turn_banner_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_content.add_child(turn_banner_subtitle)

	outcome_overlay = ColorRect.new()
	outcome_overlay.name = "OutcomeOverlay"
	outcome_overlay.visible = false
	outcome_overlay.z_index = 300
	outcome_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	outcome_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outcome_overlay.color = Color(0.005, 0.012, 0.018, 0.0)
	effect_layer.add_child(outcome_overlay)
	var outcome_center := CenterContainer.new()
	outcome_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outcome_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outcome_overlay.add_child(outcome_center)
	var outcome_content := VBoxContainer.new()
	outcome_content.custom_minimum_size = Vector2(650.0, 190.0)
	outcome_content.alignment = BoxContainer.ALIGNMENT_CENTER
	outcome_content.add_theme_constant_override("separation", 10)
	outcome_center.add_child(outcome_content)
	outcome_title = _label("VICTORY!", 68, Color("#ffe277"))
	outcome_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outcome_title.add_theme_color_override("font_outline_color", Color("#160d05"))
	outcome_title.add_theme_constant_override("outline_size", 14)
	outcome_content.add_child(outcome_title)
	outcome_subtitle = _label("THE COOK-OFF IS YOURS", 21, Color.WHITE)
	outcome_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outcome_content.add_child(outcome_subtitle)


func _show_turn_banner(phase: String) -> void:
	if turn_banner_panel == null or phase not in ["player_main", "opponent_turn"]:
		return
	var is_player := phase == "player_main"
	turn_banner_title.text = "YOUR TURN" if is_player else "RIVAL TURN"
	turn_banner_title.add_theme_color_override("font_color", Color("#fff2c7") if is_player else Color("#ffd0e5"))
	turn_banner_subtitle.text = "TURN %d  •  %s" % [int(state.get("turn", 1)), "READY YOUR KITCHEN" if is_player else "WATCH THEIR MOVE"]
	turn_banner_subtitle.add_theme_color_override("font_color", Color("#8fddf5") if is_player else Color("#f2a0c5"))
	turn_banner_panel.visible = true
	turn_banner_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	turn_banner_panel.scale = Vector2(0.72, 0.72)
	turn_banner_panel.pivot_offset = turn_banner_panel.size * 0.5
	_spawn_screen_particle_burst(effect_layer.size * Vector2(0.5, 0.5), Color("#49cef4") if is_player else Color("#e66da5"), 14, "◆")
	var enter_tween := create_tween().set_parallel(true)
	enter_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	enter_tween.tween_property(turn_banner_panel, "modulate:a", 1.0, 0.2)
	enter_tween.tween_property(turn_banner_panel, "scale", Vector2.ONE, 0.26)
	await enter_tween.finished
	await get_tree().create_timer(0.48).timeout
	var exit_tween := create_tween().set_parallel(true)
	exit_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	exit_tween.tween_property(turn_banner_panel, "modulate:a", 0.0, 0.18)
	exit_tween.tween_property(turn_banner_panel, "scale", Vector2(1.08, 1.08), 0.18)
	await exit_tween.finished
	turn_banner_panel.visible = false


func _queue_outcome_sequence() -> void:
	if outcome_sequence_running or outcome_sequence_played:
		return
	outcome_sequence_running = true
	animation_busy = true
	call_deferred("_play_outcome_sequence")


func _play_outcome_sequence() -> void:
	if state.is_empty() or not bool(state.get("game_over", false)):
		outcome_sequence_running = false
		animation_busy = false
		return
	var player_won := String(state.get("winner", "")) == "player"
	var winner_node := player_chef if player_won else opponent_chef
	var accent := Color("#ffe277") if player_won else Color("#ef6b83")
	outcome_title.text = "VICTORY!" if player_won else "DEFEAT"
	outcome_title.add_theme_color_override("font_color", accent)
	outcome_subtitle.text = "THE COOK-OFF IS YOURS" if player_won else "THE RIVAL TAKES THIS ROUND"
	outcome_overlay.visible = true
	outcome_overlay.color = Color(0.005, 0.012, 0.018, 0.0)
	outcome_title.modulate = Color(1.0, 1.0, 1.0, 0.0)
	outcome_title.scale = Vector2(0.55, 0.55)
	outcome_title.pivot_offset = outcome_title.size * 0.5
	outcome_subtitle.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_reset_camera_pacing()
	_spawn_particle_burst(winner_node.global_position + Vector3(0.0, 0.6, 0.0), accent, 28, "✦")
	var enter_tween := create_tween().set_parallel(true)
	enter_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	enter_tween.tween_property(outcome_overlay, "color:a", 0.72, 0.55)
	enter_tween.tween_property(outcome_title, "modulate:a", 1.0, 0.32).set_delay(0.22)
	enter_tween.tween_property(outcome_title, "scale", Vector2.ONE, 0.48).set_delay(0.16)
	enter_tween.tween_property(outcome_subtitle, "modulate:a", 1.0, 0.32).set_delay(0.5)
	await get_tree().create_timer(1.65).timeout
	outcome_sequence_played = true
	outcome_sequence_running = false
	animation_busy = false
	if production_match:
		# Release the full-screen blocker before the season popup or practice controls take over.
		outcome_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var production_exit_tween := create_tween().set_parallel(true)
		production_exit_tween.tween_property(outcome_overlay, "color:a", 0.0, 0.25)
		production_exit_tween.tween_property(outcome_title, "modulate:a", 0.0, 0.2)
		production_exit_tween.tween_property(outcome_subtitle, "modulate:a", 0.0, 0.2)
		await production_exit_tween.finished
		outcome_overlay.visible = false
		_emit_match_finished_once()
	else:
		var exit_tween := create_tween().set_parallel(true)
		exit_tween.tween_property(outcome_overlay, "color:a", 0.0, 0.25)
		exit_tween.tween_property(outcome_title, "modulate:a", 0.0, 0.2)
		exit_tween.tween_property(outcome_subtitle, "modulate:a", 0.0, 0.2)
		await exit_tween.finished
		outcome_overlay.visible = false
		outcome_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
		_reset_camera_pacing()
		_render_match()


func _build_hand_cards(side: String) -> void:
	var hand: Array = state[side].hand
	var count := hand.size()
	if count == 0:
		return
	var is_player := side == "player"
	var preferred_scale := 1.07 if is_player else 0.82
	var available_width := PLAYER_HAND_MAX_WIDTH if is_player else OPPONENT_HAND_MAX_WIDTH
	var scale_factor := minf(preferred_scale, (available_width - HAND_CARD_GAP * float(count - 1)) / (FIELD_CARD_SIZE.x * float(count)))
	scale_factor = maxf(scale_factor, 0.58)
	var spacing := FIELD_CARD_SIZE.x * scale_factor + HAND_CARD_GAP
	for hand_index in range(count):
		var offset := float(hand_index) - float(count - 1) * 0.5
		var root := _make_card(String(hand[hand_index]), is_player)
		root.name = "%sHandCard_%d" % [side.capitalize(), hand_index]
		root.position = Vector3(offset * spacing, (0.62 + absf(offset) * 0.025) if is_player else (0.72 + absf(offset) * 0.012), PLAYER_HAND_Z + absf(offset) * 0.045 if is_player else OPPONENT_HAND_Z - absf(offset) * 0.025)
		root.rotation_degrees = Vector3(63.0 if is_player else 69.0, 0.0, -offset * (1.8 if is_player else 1.2))
		root.scale = Vector3.ONE * scale_factor
		root.set_meta("kind", "hand")
		root.set_meta("side", side)
		root.set_meta("hand_index", hand_index)
		root.set_meta("card_id", String(hand[hand_index]))
		if is_player:
			_apply_pending_discard_hand_style(root, hand_index)
			_apply_tutorial_card_highlight(root, "hand", side, String(hand[hand_index]), -1)
		_store_card_pose(root, float(hand_index) * 0.47)
		card_layer.add_child(root)
		if is_player:
			interactive_cards.append(root)


func _build_field_cards(side: String, zone: String) -> void:
	var units: Array = state[side][zone]
	var capacity: int = service.PREP_SLOTS if zone == "prep" else service.PLATED_SLOTS
	var spacing := 1.72 if capacity == 3 else 1.8
	var zone_key := "%s_%s" % [side, zone]
	var center: Vector3 = ZONE_CENTERS[zone_key]
	for unit in units:
		var slot_index := int(unit.get("table_slot", 0))
		var offset := float(slot_index) - float(capacity - 1) * 0.5
		var root := _make_card(String(unit.card_id), true, false)
		root.name = "%s%sCard_%d" % [side.capitalize(), zone.capitalize(), int(unit.instance_id)]
		root.position = center + Vector3(offset * spacing, 0.0, 0.0)
		root.set_meta("kind", "field")
		root.set_meta("side", side)
		root.set_meta("zone", zone)
		root.set_meta("instance_id", int(unit.instance_id))
		root.set_meta("card_id", String(unit.card_id))
		root.set_meta("ready", bool(unit.get("ready", false)))
		_store_card_pose(root, float(int(unit.instance_id)) * 0.31)
		card_layer.add_child(root)
		interactive_cards.append(root)
		_apply_card_highlight(root, unit, side)
		_apply_tutorial_card_highlight(root, "field", side, String(unit.card_id), int(unit.instance_id))
		_add_spice_attachments(root, unit, side)
		_add_floating_art(root, service.card(String(unit.card_id)), side)
		_add_stat_badge(root, unit, side)


func _ensure_unit_slot_assignments() -> void:
	if state.is_empty():
		return
	for side in ["player", "opponent"]:
		for zone in ["prep", "plated"]:
			var capacity: int = service.PREP_SLOTS if zone == "prep" else service.PLATED_SLOTS
			var used_slots: Array[int] = []
			for unit in state[side][zone]:
				var slot_index := int(unit.get("table_slot", -1))
				if slot_index < 0 or slot_index >= capacity or used_slots.has(slot_index):
					slot_index = _first_unused_slot(used_slots, capacity)
				unit.table_slot = slot_index
				used_slots.append(slot_index)


func _first_unused_slot(used_slots: Array[int], capacity: int) -> int:
	for slot_index in range(capacity):
		if not used_slots.has(slot_index):
			return slot_index
	return 0


func _build_auxiliary_presentations() -> void:
	for side in ["player", "opponent"]:
		_build_zone_marker(side, "deck", "DECK")
		_build_zone_marker(side, "discard", "DISCARD")
		_build_zone_marker(side, "environment", "ENVIRONMENT")
		_build_card_pile(side, "deck")
		_build_card_pile(side, "discard")


func _build_zone_marker(side: String, zone_kind: String, display_name: String) -> void:
	var zone_key := "%s_%s" % [side, zone_kind]
	var root := Node3D.new()
	root.name = "%s%sZone" % [side.capitalize(), zone_kind.capitalize()]
	root.position = AUX_ZONE_POSITIONS[zone_key]
	var marker := MeshInstance3D.new()
	marker.name = "ZonePad"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.18, 0.025, 1.62)
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var tint := Color("#38b8db") if side == "player" else Color("#a45dc7")
	material.albedo_color = Color(tint.r, tint.g, tint.b, 0.13)
	material.emission_enabled = true
	material.emission = tint
	material.emission_energy_multiplier = 0.18
	mesh.material = material
	marker.mesh = mesh
	root.add_child(marker)
	var label := Label3D.new()
	label.name = "ZoneLabel"
	label.position = Vector3(0.0, 0.08, 0.72)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 24
	label.outline_size = 7
	label.modulate = Color("#9cecff") if side == "player" else Color("#e1b5f5")
	label.text = display_name
	root.add_child(label)
	card_layer.add_child(root)


func _build_card_pile(side: String, pile_kind: String) -> void:
	var cards: Array = state[side][pile_kind]
	var zone_key := "%s_%s" % [side, pile_kind]
	var position: Vector3 = AUX_ZONE_POSITIONS[zone_key]
	if pile_kind == "deck":
		var visible_layers := mini(4, cards.size())
		for layer_index in range(visible_layers):
			var card := _make_card("", false)
			card.name = "%sDeckCard_%d" % [side.capitalize(), layer_index]
			card.position = position + Vector3(0.0, 0.045 + float(layer_index) * 0.035, 0.0)
			card.rotation.y = deg_to_rad(2.0 * float(layer_index))
			card.scale = Vector3.ONE * 0.54
			card_layer.add_child(card)
	elif not cards.is_empty():
		var top_card_id := String(cards[-1])
		var discard_card := _make_card(top_card_id, true)
		discard_card.name = "%sDiscardTop" % side.capitalize()
		discard_card.position = position + Vector3(0.0, 0.07, 0.0)
		discard_card.rotation.y = deg_to_rad(-4.0 if side == "player" else 4.0)
		discard_card.scale = Vector3.ONE * 0.54
		discard_card.set_meta("kind", "discard")
		discard_card.set_meta("side", side)
		discard_card.set_meta("card_id", top_card_id)
		_store_card_pose(discard_card, 0.8)
		card_layer.add_child(discard_card)
		interactive_cards.append(discard_card)
	var count_label := Label3D.new()
	count_label.name = "%s%sCount" % [side.capitalize(), pile_kind.capitalize()]
	var count_offset_x := -0.72 if side == "player" else 0.72
	count_label.position = position + Vector3(count_offset_x, 0.28, 0.0)
	count_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	count_label.font_size = 32
	count_label.outline_size = 9
	count_label.text = str(cards.size())
	card_layer.add_child(count_label)


func _slot_is_open(side: String, zone: String, slot_index: int, ignored_instance_id: int = -1) -> bool:
	var capacity: int = service.PREP_SLOTS if zone == "prep" else service.PLATED_SLOTS
	if slot_index < 0 or slot_index >= capacity:
		return false
	for unit in state[side][zone]:
		if int(unit.instance_id) != ignored_instance_id and int(unit.get("table_slot", -1)) == slot_index:
			return false
	return true


func _slot_can_receive_hand_card(card_data: Dictionary, side: String, zone: String, slot_index: int) -> bool:
	if _slot_is_open(side, zone, slot_index):
		return true
	if String(card_data.get("card_type", "")) != "meal" or side != "player":
		return false
	for unit in state[side][zone]:
		if int(unit.get("table_slot", -1)) != slot_index:
			continue
		if String(unit.get("card_type", "")) != "ingredient" or not service._ingredient_is_recipe_ready(state.player, unit):
			return false
		var ingredient_types: Array = service.card(String(unit.get("card_id", ""))).get("ingredient_types", [])
		for requirement in service._effective_recipe(state, "player", card_data):
			if String(requirement) == "any" or ingredient_types.has(requirement):
				return true
		return false
	return false


func _assign_new_unit_to_slot(side: String, zone: String, previous_ids: Array[int], slot_index: int) -> int:
	for unit in state[side][zone]:
		if not previous_ids.has(int(unit.instance_id)):
			unit.table_slot = slot_index
			return int(unit.instance_id)
	return -1


func _build_environment_card(side: String) -> void:
	var card_id := String(state[side].environment)
	if card_id == "":
		return
	var root := _make_card(card_id, true)
	root.name = "%sEnvironmentCard" % side.capitalize()
	root.position = AUX_ZONE_POSITIONS["%s_environment" % side] + Vector3(0.0, 0.06, 0.0)
	root.rotation.y = deg_to_rad(-8.0 if side == "player" else 8.0)
	root.scale = Vector3.ONE * 0.82
	root.set_meta("kind", "environment")
	root.set_meta("side", side)
	root.set_meta("card_id", card_id)
	_store_card_pose(root, 0.0)
	card_layer.add_child(root)
	interactive_cards.append(root)


func _add_spice_attachments(root: Node3D, unit: Dictionary, side: String) -> void:
	var spices: Array = unit.get("spices", [])
	for spice_index in range(spices.size()):
		var spice_id := String(spices[spice_index])
		var spice_card := _make_card(spice_id, true)
		spice_card.name = "SpiceAttachment_%d" % spice_index
		spice_card.position = Vector3(0.38 + float(spice_index) * 0.12, 0.09 + float(spice_index) * 0.025, 0.4)
		spice_card.rotation.y = deg_to_rad(8.0 if side == "player" else -8.0)
		spice_card.scale = Vector3.ONE * 0.34
		spice_card.set_meta("kind", "spice")
		spice_card.set_meta("side", side)
		spice_card.set_meta("card_id", spice_id)
		root.add_child(spice_card)


func _make_card(card_id: String, face_up: bool, show_art: bool = true) -> Node3D:
	var root := Node3D.new()
	var body := MeshInstance3D.new()
	body.name = "CardBody"
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(FIELD_CARD_SIZE.x + 0.06, 0.06, FIELD_CARD_SIZE.y + 0.06)
	var edge_material := StandardMaterial3D.new()
	edge_material.albedo_color = Color("#090b0f")
	edge_material.roughness = 0.68
	body_mesh.material = edge_material
	body.mesh = body_mesh
	root.add_child(body)
	var face := MeshInstance3D.new()
	face.name = "CardFace"
	face.position = Vector3(0.0, 0.034, 0.0)
	face.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var face_mesh := QuadMesh.new()
	face_mesh.size = FIELD_CARD_SIZE
	face.mesh = face_mesh
	face.material_override = _face_material(card_id, show_art) if face_up else _card_back_material()
	root.add_child(face)
	return root


func _face_material(card_id: String, show_art: bool = true) -> StandardMaterial3D:
	var cache_key := card_id if show_art else "%s__field_no_art" % card_id
	if face_materials.has(cache_key):
		return face_materials[cache_key]
	var viewport := SubViewport.new()
	viewport.name = "PrototypeFullCardFaceViewport_%s%s" % [card_id, "" if show_art else "_NoArt"]
	viewport.disable_3d = true
	viewport.transparent_bg = true
	viewport.size = CARD_FACE_TEXTURE_SIZE
	viewport.gui_disable_input = true
	viewport.use_hdr_2d = false
	viewport.msaa_2d = Viewport.MSAA_DISABLED
	# Static faces render once. Animated faces request another single redraw only
	# when CardFace advances an authored art frame.
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	texture_viewports.add_child(viewport)
	var data: Dictionary = service.card(card_id)
	if CARD_FACE_SCRIPT.supports_card(data):
		var face_control := CARD_FACE_SCRIPT.new()
		face_control.name = "PrototypeFullCardFace_%s%s" % [card_id, "" if show_art else "_NoArt"]
		face_control.visual_changed.connect(func() -> void: _request_card_face_redraw(viewport))
		face_control.configure(data, configured_card_border_id if production_match else "black", show_art, false, show_art)
		face_control.position = Vector2.ZERO
		face_control.size = Vector2(viewport.size)
		viewport.add_child(face_control)
	else:
		viewport.add_child(_make_fallback_card_face(data, viewport.size, show_art))
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_texture = viewport.get_texture()
	face_materials[cache_key] = material
	return material


func _request_card_face_redraw(viewport: SubViewport) -> void:
	if not is_instance_valid(viewport):
		return
	card_face_redraw_requests += 1
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


func _make_fallback_card_face(data: Dictionary, face_size: Vector2i, show_art: bool = true) -> Control:
	var root := PanelContainer.new()
	root.name = "PrototypeFallbackCardFace_%s" % String(data.get("id", "card"))
	root.size = Vector2(face_size)
	var card_type := String(data.get("card_type", "card"))
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#d66c34") if card_type == "spice" else Color("#47748a") if card_type == "environment" else Color("#535d69")
	style.border_color = Color("#090909")
	style.set_border_width_all(10)
	style.set_corner_radius_all(20)
	root.add_theme_stylebox_override("panel", style)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	root.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)
	var title := _label(String(data.get("name", "Card")), 30, Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(title)
	var art := TextureRect.new()
	art.custom_minimum_size = Vector2(0, 235)
	art.texture = ART_PENDING
	art.visible = show_art
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(art)
	var type_label := _label(card_type.capitalize(), 22, Color("#fff0cf"))
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(type_label)
	var rules := _label(String(data.get("text", "No printed ability.")), 18, Color.WHITE)
	rules.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(rules)
	return root


func _card_back_material() -> StandardMaterial3D:
	if face_materials.has("__card_back"):
		return face_materials.__card_back
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_texture = CARD_BACK
	face_materials.__card_back = material
	return material


func _add_floating_art(root: Node3D, data: Dictionary, _side: String) -> void:
	var frames: Array[Texture2D] = []
	for path in data.get("art_frames", []):
		var frame := load(String(path)) as Texture2D
		if frame != null:
			frames.append(frame)
	if frames.is_empty():
		var pending := load("res://assets/cards/art_pending.png") as Texture2D
		if pending != null:
			frames.append(pending)
	if frames.is_empty():
		return
	var art := MeshInstance3D.new()
	art.name = "FloatingArt"
	var mesh := QuadMesh.new()
	mesh.size = Vector2(1.03, 0.86)
	art.mesh = mesh
	art.position = Vector3(0.0, FLOATING_ART_HEIGHT, -0.05)
	art.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.albedo_texture = frames[0]
	art.material_override = material
	art.set_meta("frames", frames)
	art.set_meta("frame_duration", float(data.get("art_frame_duration", 0.12)))
	art.set_meta("elapsed", 0.0)
	art.set_meta("frame_index", 0)
	root.add_child(art)
	floating_arts.append(art)


func _add_stat_badge(root: Node3D, unit: Dictionary, side: String) -> void:
	var label := Label3D.new()
	label.name = "Stats"
	label.position = Vector3(0.0, 0.18, 0.59)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 42
	label.outline_size = 10
	label.modulate = Color("#fff3c4") if bool(unit.get("ready", false)) else Color("#c7c9cf")
	label.text = "%d / %d%s" % [int(unit.attack), int(unit.health), "  READY" if side == "player" and bool(unit.get("ready", false)) else ""]
	root.add_child(label)


func _apply_card_highlight(root: Node3D, unit: Dictionary, side: String) -> void:
	var instance_id := int(unit.instance_id)
	var meal_candidate: bool = side == "player" and service.meal_selectable_ingredient_ids(state).has(instance_id)
	var selected_recipe_ingredient: bool = state.get("selected_ingredients", []).has(instance_id)
	var highlighted := service.choice_target_ids(state).has(instance_id)
	highlighted = highlighted or int(state.get("selected_attacker", -1)) == instance_id
	highlighted = highlighted or int(state.get("selected_spice_target", -1)) == instance_id
	highlighted = highlighted or selected_recipe_ingredient or meal_candidate
	var pending_ability: Dictionary = state.get("pending_ability", {})
	if not pending_ability.is_empty():
		var correct_side := (String(pending_ability.get("target_side", "enemy")) == "friendly" and side == "player") or (String(pending_ability.get("target_side", "enemy")) != "friendly" and side == "opponent")
		if correct_side:
			var source := service._find_unit(state.player, int(pending_ability.get("source_instance_id", -1)))
			highlighted = highlighted or service._ability_target_is_valid(state, "player", source, instance_id, pending_ability.get("target_spec", {}))
	if not highlighted:
		return
	var body := root.get_node("CardBody") as MeshInstance3D
	var material := body.get_active_material(0).duplicate() as StandardMaterial3D
	material.albedo_color = Color("#e9a93b") if not meal_candidate or selected_recipe_ingredient else Color("#2eb7d7")
	material.emission_enabled = true
	material.emission = Color("#ffd45b") if not meal_candidate or selected_recipe_ingredient else Color("#63e6ff")
	material.emission_energy_multiplier = 2.1
	body.material_override = material
	highlighted_bodies.append(body)


func _apply_pending_discard_hand_style(root: Node3D, hand_index: int) -> void:
	var pending_discard: Dictionary = state.get("pending_discard", {})
	if pending_discard.is_empty():
		return
	var source_index := int(pending_discard.get("hand_index", -1))
	var selected: bool = pending_discard.get("selected_indices", []).has(hand_index)
	if hand_index != source_index and not selected:
		return
	var body := root.get_node("CardBody") as MeshInstance3D
	var material := body.get_active_material(0).duplicate() as StandardMaterial3D
	var badge := Label3D.new()
	badge.name = "DiscardSelectionBadge"
	badge.position = Vector3(0.0, 0.12, -0.59)
	badge.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	badge.font_size = 34
	badge.outline_size = 9
	badge.no_depth_test = true
	if hand_index == source_index:
		material.albedo_color = Color("#4f5961")
		material.emission_enabled = true
		material.emission = Color("#81909b")
		material.emission_energy_multiplier = 0.45
		badge.modulate = Color("#e1e8ed")
		badge.text = "PAYING"
	else:
		material.albedo_color = Color("#e9a93b")
		material.emission_enabled = true
		material.emission = Color("#ffd45b")
		material.emission_energy_multiplier = 2.1
		badge.modulate = Color("#fff4bd")
		badge.text = "SELECTED"
		highlighted_bodies.append(body)
	body.material_override = material
	root.add_child(badge)


func _apply_tutorial_card_highlight(root: Node3D, kind: String, side: String, card_id: String, instance_id: int) -> void:
	if not tutorial_mode:
		return
	var step := _tutorial_step()
	var action := String(step.get("action", ""))
	var should_highlight := false
	if kind == "hand" and side == "player" and action == "select_hand":
		should_highlight = String(step.get("card_id", "")) == card_id
	elif kind == "field":
		if action in ["select_field", "select_recipe"]:
			should_highlight = side == "player"
			if step.has("instance_id"):
				should_highlight = should_highlight and int(step.instance_id) == instance_id
			elif step.has("card_id"):
				should_highlight = should_highlight and String(step.card_id) == card_id
		elif action == "attack_unit":
			should_highlight = side == "opponent" and int(step.get("target_instance_id", -1)) == instance_id
	if not should_highlight:
		return
	var body := root.get_node("CardBody") as MeshInstance3D
	var material := body.get_active_material(0).duplicate() as StandardMaterial3D
	material.albedo_color = Color("#e9a93b")
	material.emission_enabled = true
	material.emission = Color("#ffd45b")
	material.emission_energy_multiplier = 2.25
	body.material_override = material
	highlighted_bodies.append(body)


func _store_card_pose(root: Node3D, flair_seed: float) -> void:
	root.set_meta("base_position", root.position)
	root.set_meta("base_rotation_degrees", root.rotation_degrees)
	root.set_meta("base_scale", root.scale)
	root.set_meta("flair_seed", flair_seed)


func _prepare_zone_materials() -> void:
	for zone_id in ZONE_CENTERS:
		var zone_root := get_node("ViewportContainer/WorldViewport/World/Zones/%s" % _zone_node_name(String(zone_id))) as Node3D
		var materials: Array[StandardMaterial3D] = []
		for child in zone_root.get_children():
			if child is MeshInstance3D and String(child.name).begins_with("Slot"):
				var zone_mesh := child as MeshInstance3D
				var material := zone_mesh.get_active_material(0).duplicate() as StandardMaterial3D
				zone_mesh.material_override = material
				materials.append(material)
		zone_materials[zone_id] = materials


func _zone_node_name(zone_id: String) -> String:
	match zone_id:
		"player_prep":
			return "PlayerPrep"
		"player_plated":
			return "PlayerPlated"
		"opponent_prep":
			return "OpponentPrep"
	return "OpponentPlated"


func _process(delta: float) -> void:
	_update_reaction_countdown(delta)
	var time := Time.get_ticks_msec() * 0.001
	for art in floating_arts:
		if not is_instance_valid(art):
			continue
		var elapsed := float(art.get_meta("elapsed", 0.0)) + delta
		var duration := maxf(0.03, float(art.get_meta("frame_duration", 0.12)))
		var frames: Array = art.get_meta("frames", [])
		var frame_index := int(art.get_meta("frame_index", 0))
		if frames.size() > 1 and elapsed >= duration:
			elapsed = fmod(elapsed, duration)
			frame_index = (frame_index + 1) % frames.size()
			(art.material_override as StandardMaterial3D).albedo_texture = frames[frame_index]
		art.set_meta("elapsed", elapsed)
		art.set_meta("frame_index", frame_index)
	_animate_physical_cards(delta, time)
	_update_zone_flair(time)
	for body in highlighted_bodies:
		if is_instance_valid(body) and body.material_override is StandardMaterial3D:
			(body.material_override as StandardMaterial3D).emission_energy_multiplier = 1.75 + sin(time * 4.0) * 0.45


func _animate_physical_cards(delta: float, time: float) -> void:
	if animation_busy:
		return
	for card_node in interactive_cards:
		if not is_instance_valid(card_node) or card_node == pressed_card:
			continue
		var base_position: Vector3 = card_node.get_meta("base_position", card_node.position)
		var base_rotation: Vector3 = card_node.get_meta("base_rotation_degrees", card_node.rotation_degrees)
		var base_scale: Vector3 = card_node.get_meta("base_scale", card_node.scale)
		var is_hovered := card_node == hovered_card
		var is_hand := String(card_node.get_meta("kind", "")) == "hand"
		var target_position := base_position
		if is_hovered:
			target_position += Vector3(0.0, 0.14, 0.08 if is_hand else 0.0)
		var target_scale := base_scale * (1.055 if is_hovered else 1.0)
		var target_rotation := base_rotation
		if is_hovered:
			target_rotation.x -= 2.0
		card_node.position = card_node.position.lerp(target_position, clampf(delta * 12.0, 0.0, 1.0))
		card_node.scale = card_node.scale.lerp(target_scale, clampf(delta * 12.0, 0.0, 1.0))
		card_node.rotation_degrees = card_node.rotation_degrees.lerp(target_rotation, clampf(delta * 10.0, 0.0, 1.0))


func _update_zone_flair(time: float) -> void:
	for zone_id in zone_materials:
		var base_color := _zone_color(String(zone_id))
		var idle_alpha := 0.18 + sin(time * 1.5 + float(String(zone_id).hash() % 13)) * 0.018
		var materials: Array = zone_materials[zone_id]
		for slot_index in range(materials.size()):
			var material_variant = materials[slot_index]
			var material := material_variant as StandardMaterial3D
			var active := String(zone_id) == highlighted_zone and (highlighted_slot < 0 or highlighted_slot == slot_index)
			material.albedo_color = Color(base_color.r, base_color.g, base_color.b, 0.48 if active else idle_alpha)
			material.emission_enabled = active
			material.emission = base_color
			material.emission_energy_multiplier = 1.8 + sin(time * 5.0) * 0.35 if active else 0.0


func _zone_color(zone_id: String) -> Color:
	if zone_id == "player_prep":
		return Color("#28b9e2")
	if zone_id == "player_plated":
		return Color("#f36c2c")
	return Color("#9b4fbd")


func _on_table_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			pressed_card = _pick_card(event.position)
			press_screen_position = event.position
			if pressed_card == null:
				if _screen_hits_auxiliary_zone(event.position, "player_discard"):
					_open_discard_tray("player")
					viewport_container.accept_event()
				elif _screen_hits_auxiliary_zone(event.position, "opponent_discard"):
					_open_discard_tray("opponent")
					viewport_container.accept_event()
				elif _screen_hits_opponent_chef(event.position):
					_on_opponent_chef_clicked()
					viewport_container.accept_event()
		elif pressed_card != null:
			if dragging:
				_finish_drag(_mouse_to_table(event.position))
			else:
				_handle_card_click(pressed_card)
			pressed_card = null
			viewport_container.accept_event()
	elif event is InputEventMouseMotion:
		hovered_card = _pick_card(event.position) if not dragging else pressed_card
		if pressed_card != null:
			if not dragging and event.position.distance_to(press_screen_position) >= 8.0 and _can_drag_card(pressed_card):
				var point = _mouse_to_table(event.position)
				if point != null:
					_begin_drag(point)
			if dragging:
				var table_point = _mouse_to_table(event.position)
				if table_point != null:
					_update_drag(table_point)
					viewport_container.accept_event()


func _pick_card(screen_position: Vector2) -> Node3D:
	var best: Node3D
	var best_distance := 100000.0
	for candidate in interactive_cards:
		if not is_instance_valid(candidate):
			continue
		var projected := _world_to_container(candidate.global_position + Vector3(0.0, 0.22, 0.0))
		var threshold := 78.0 if String(candidate.get_meta("kind", "")) == "hand" else 62.0
		var distance := projected.distance_to(screen_position)
		if distance < threshold and distance < best_distance:
			best = candidate
			best_distance = distance
	return best


func _world_to_container(world_position: Vector3) -> Vector2:
	var viewport_position := camera.unproject_position(world_position)
	return viewport_position * viewport_container.size / Vector2(world_viewport.size)


func _screen_hits_opponent_chef(screen_position: Vector2) -> bool:
	return _world_to_container(opponent_chef.global_position + Vector3(0.0, 0.35, 0.0)).distance_to(screen_position) < 74.0


func _screen_hits_auxiliary_zone(screen_position: Vector2, zone_key: String) -> bool:
	if not AUX_ZONE_POSITIONS.has(zone_key):
		return false
	return _world_to_container(AUX_ZONE_POSITIONS[zone_key] + Vector3(0.0, 0.12, 0.0)).distance_to(screen_position) < 68.0


func _mouse_to_table(container_position: Vector2) -> Variant:
	if viewport_container.size.x <= 0.0 or viewport_container.size.y <= 0.0:
		return null
	var viewport_position := container_position * Vector2(world_viewport.size) / viewport_container.size
	var ray_origin := camera.project_ray_origin(viewport_position)
	var ray_direction := camera.project_ray_normal(viewport_position)
	if absf(ray_direction.y) < 0.0001:
		return null
	var distance := (TABLE_Y - ray_origin.y) / ray_direction.y
	if distance < 0.0:
		return null
	return ray_origin + ray_direction * distance


func _can_drag_card(card_node: Node3D) -> bool:
	if animation_busy or String(state.get("phase", "")) != "player_main" or _has_blocking_prompt():
		return false
	if tutorial_mode:
		# The guided lesson uses explicit click-and-button actions so the selected
		# card and exact legal destination stay unambiguous.
		return false
	return String(card_node.get_meta("side", "")) == "player" and String(card_node.get_meta("kind", "")) in ["hand", "field"]


func _begin_drag(point: Vector3) -> void:
	if pressed_card == null:
		return
	dragging = true
	drag_original_position = pressed_card.position
	drag_original_rotation = pressed_card.rotation
	drag_offset = Vector3(pressed_card.position.x - point.x, 0.0, pressed_card.position.z - point.z)
	pressed_card.rotation = Vector3.ZERO
	pressed_card.scale = Vector3.ONE
	pressed_card.position.y = DRAG_Y
	current_zone = String(pressed_card.get_meta("zone", "hand"))
	status_label.text = "Drag to your Prep or Plated lane. Drag an attacker onto a rival defender or chef."


func _update_drag(point: Vector3) -> void:
	if pressed_card == null:
		return
	var desired := _dragged_card_point(point)
	pressed_card.position = Vector3(desired.x, DRAG_Y, desired.z)
	var hovered_slot := _slot_at_point(desired)
	highlighted_zone = String(hovered_slot.get("zone", ""))
	highlighted_slot = int(hovered_slot.get("slot", -1))


func _finish_drag(point: Variant) -> void:
	if pressed_card == null:
		return
	dragging = false
	var drop_point: Variant = _dragged_card_point(point as Vector3) if point != null else null
	var drop_slot := _slot_at_point(drop_point as Vector3) if drop_point != null else {}
	var destination := String(drop_slot.get("zone", ""))
	var destination_slot := int(drop_slot.get("slot", -1))
	var requested_hand_play := -1
	var requested_hand_destination := ""
	var requested_hand_slot := -1
	var requested_attacker := -1
	var requested_attack_target := -2
	var kind := String(pressed_card.get_meta("kind", ""))
	if kind == "hand":
		var hand_index := int(pressed_card.get_meta("hand_index", -1))
		var card_data := service.card(String(pressed_card.get_meta("card_id", "")))
		var card_type := String(card_data.get("card_type", ""))
		if destination in ["player_prep", "player_plated"]:
			requested_hand_play = hand_index
			requested_hand_destination = destination.trim_prefix("player_")
			requested_hand_slot = destination_slot
		elif card_type in ["tool", "chef", "environment"]:
			requested_hand_play = hand_index
			requested_hand_destination = "prep"
	elif kind == "field":
		var instance_id := int(pressed_card.get_meta("instance_id", -1))
		if destination in ["player_prep", "player_plated"]:
			_move_unit(instance_id, destination.trim_prefix("player_"), destination_slot)
		elif destination == "opponent_plated":
			requested_attacker = instance_id
			requested_attack_target = _field_target_near(drop_point as Vector3, "opponent", "plated")
		elif drop_point != null and _point_near_chef(drop_point as Vector3, opponent_chef.position):
			requested_attacker = instance_id
			requested_attack_target = -1
	highlighted_zone = ""
	highlighted_slot = -1
	if requested_attacker >= 0:
		# Attack animations must begin at the card's board slot, not wherever the
		# pointer released it over a defender or chef.
		pressed_card.position = drag_original_position
		pressed_card.rotation = drag_original_rotation
		pressed_card.scale = pressed_card.get_meta("base_scale", pressed_card.scale)
	pressed_card = null
	selected_ref = {}
	if requested_hand_play >= 0:
		_play_hand_card(requested_hand_play, requested_hand_destination, requested_hand_slot)
		return
	if requested_attacker >= 0:
		_perform_attack(requested_attack_target, requested_attacker)
		return
	_render_match()


func _dragged_card_point(pointer_point: Vector3) -> Vector3:
	var desired := pointer_point + drag_offset
	desired.x = clampf(desired.x, -5.4, 5.4)
	desired.z = clampf(desired.z, -4.8, 4.5)
	return Vector3(desired.x, TABLE_Y, desired.z)


func _zone_at_point(point: Vector3) -> String:
	for zone_id in ZONE_CENTERS:
		var center: Vector3 = ZONE_CENTERS[zone_id]
		var extents: Vector2 = ZONE_EXTENTS[zone_id]
		if absf(point.x - center.x) <= extents.x and absf(point.z - center.z) <= extents.y:
			return String(zone_id)
	return ""


func _slot_at_point(point: Vector3) -> Dictionary:
	var zone_id := _zone_at_point(point)
	if zone_id == "":
		return {}
	var zone_name := zone_id.trim_prefix("player_").trim_prefix("opponent_")
	var capacity: int = service.PREP_SLOTS if zone_name == "prep" else service.PLATED_SLOTS
	var spacing := 1.72 if capacity == 3 else 1.8
	var center: Vector3 = ZONE_CENTERS[zone_id]
	for slot_index in range(capacity):
		var offset := (float(slot_index) - float(capacity - 1) * 0.5) * spacing
		if absf(point.x - (center.x + offset)) <= 0.79 and absf(point.z - center.z) <= 0.76:
			return {"zone": zone_id, "slot": slot_index}
	return {}


func _field_target_near(point: Vector3, side: String, zone: String) -> int:
	var closest := -1
	var distance := 2.2
	for candidate in interactive_cards:
		if String(candidate.get_meta("kind", "")) != "field" or String(candidate.get_meta("side", "")) != side or String(candidate.get_meta("zone", "")) != zone:
			continue
		var next_distance := Vector2(candidate.position.x, candidate.position.z).distance_to(Vector2(point.x, point.z))
		if next_distance < distance:
			distance = next_distance
			closest = int(candidate.get_meta("instance_id", -1))
	return closest


func _point_near_chef(point: Vector3, chef_position: Vector3) -> bool:
	return Vector2(point.x, point.z).distance_to(Vector2(chef_position.x, chef_position.z)) < 1.25


func _handle_card_click(card_node: Node3D) -> void:
	if animation_busy:
		return
	var kind := String(card_node.get_meta("kind", ""))
	var side := String(card_node.get_meta("side", ""))
	var instance_id := int(card_node.get_meta("instance_id", -1))
	var card_id := String(card_node.get_meta("card_id", ""))
	if not state.get("pending_meal", {}).is_empty():
		if kind == "field" and side == "player" and service.meal_selectable_ingredient_ids(state).has(instance_id):
			if tutorial_mode and not _tutorial_action_matches("select_recipe", {"card_id": card_id, "instance_id": instance_id}):
				_tutorial_reject_action()
				return
			service.toggle_ingredient_selection(state, instance_id)
			_tutorial_complete_action("select_recipe", {"card_id": card_id, "instance_id": instance_id})
			_render_match()
		return
	var pending_discard: Dictionary = state.get("pending_discard", {})
	if not pending_discard.is_empty() and kind == "hand" and side == "player":
		var hand_index := int(card_node.get_meta("hand_index", -1))
		if hand_index != int(pending_discard.get("hand_index", -1)):
			_toggle_discard_cost(hand_index)
		return
	if kind == "discard":
		_open_discard_tray(side)
		return
	if not state.get("pending_ability", {}).is_empty() and instance_id >= 0:
		_choose_ability_target_animated(instance_id)
		return
	if service.choice_target_ids(state).has(instance_id):
		_choose_effect_target_animated(instance_id)
		return
	if tutorial_mode and String(_tutorial_step().get("action", "")) in ["select_hand", "select_field"]:
		var selection_action := "select_hand" if kind == "hand" else "select_field"
		var selection_details := {"card_id": card_id, "instance_id": instance_id}
		if side != "player":
			_tutorial_reject_action()
			return
		if not _tutorial_complete_action(selection_action, selection_details):
			return
		selected_ref = {
			"kind": kind,
			"side": side,
			"hand_index": int(card_node.get_meta("hand_index", -1)),
			"instance_id": instance_id,
			"zone": String(card_node.get_meta("zone", "")),
			"card_id": card_id
		}
		_refresh_action_panel()
		_refresh_bottom_status()
		return
	if side == "opponent" and String(card_node.get_meta("zone", "")) == "plated" and int(state.get("selected_attacker", -1)) >= 0:
		selected_ref = {}
		_perform_attack(instance_id)
		return
	if tutorial_mode:
		_tutorial_reject_action()
		return
	selected_ref = {
		"kind": kind,
		"side": side,
		"hand_index": int(card_node.get_meta("hand_index", -1)),
		"instance_id": instance_id,
		"zone": String(card_node.get_meta("zone", "")),
		"card_id": String(card_node.get_meta("card_id", ""))
	}
	_refresh_action_panel()


func _on_opponent_chef_clicked() -> void:
	if animation_busy:
		return
	if int(state.get("selected_attacker", -1)) >= 0:
		if tutorial_mode and not _tutorial_action_matches("attack_chef"):
			_tutorial_reject_action()
			return
		selected_ref = {}
		_perform_attack(-1)


func _refresh_action_panel() -> void:
	_clear_children(action_list)
	action_panel.visible = not selected_ref.is_empty()
	if selected_ref.is_empty():
		return
	var data := service.card(String(selected_ref.card_id))
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	action_list.add_child(header)
	var info_heading := _label("CARD INFO", 13, Color("#8fcce5"))
	info_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(info_heading)
	var close_button := _styled_button("Close")
	close_button.name = "LivingTableInfoClose"
	close_button.custom_minimum_size = Vector2(72, 32)
	close_button.pressed.connect(_close_info_window)
	header.add_child(close_button)
	if CARD_FACE_SCRIPT.supports_card(data):
		var face_center := CenterContainer.new()
		face_center.custom_minimum_size = Vector2(0, 220)
		face_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		action_list.add_child(face_center)
		var info_face := CARD_FACE_SCRIPT.new()
		info_face.name = "LivingTableInfoCardFace"
		info_face.configure(data, "black", true, false)
		info_face.custom_minimum_size = Vector2(150, 213)
		face_center.add_child(info_face)
	var title := _label(String(data.get("name", "Card")), 22, Color("#fff3cf"))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	action_list.add_child(title)
	var location := "%s • %s" % [String(data.get("card_type", "card")).capitalize(), String(selected_ref.zone if String(selected_ref.zone) != "" else selected_ref.kind).capitalize()]
	action_list.add_child(_label(location, 13, Color("#f1c66e")))
	if int(selected_ref.instance_id) >= 0:
		var unit := service._find_unit(state[String(selected_ref.side)], int(selected_ref.instance_id))
		if not unit.is_empty():
			action_list.add_child(_label("%d Attack  •  %d/%d Health%s" % [int(unit.attack), int(unit.health), int(unit.max_health), "  •  Ready" if bool(unit.get("ready", false)) else ""], 14, Color("#fff0c2")))
	var rules := _label(String(data.get("text", "")), 13, Color("#d9e2e8"))
	rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	action_list.add_child(rules)
	if String(selected_ref.side) != "player" or String(state.phase) != "player_main" or _has_blocking_prompt():
		return
	if String(selected_ref.kind) == "hand":
		_build_hand_actions(data, int(selected_ref.hand_index))
	else:
		_build_field_actions(data, int(selected_ref.instance_id), String(selected_ref.zone))


func _close_info_window() -> void:
	selected_ref = {}
	_refresh_action_panel()


func _perform_attack(target_instance_id: int, attacker_override: int = -1) -> void:
	if animation_busy:
		return
	var tutorial_action := "attack_chef" if target_instance_id < 0 else "attack_unit"
	if tutorial_mode and not _tutorial_action_matches(tutorial_action, {"target_instance_id": target_instance_id}):
		_tutorial_reject_action()
		return
	if attacker_override >= 0:
		service.select_attacker(state, attacker_override)
	var attacker_id := int(state.get("selected_attacker", -1))
	if attacker_id < 0:
		_render_match()
		return
	animation_busy = true
	service.attack(state, target_instance_id)
	await _drain_animation_event_queue()
	animation_busy = false
	_tutorial_complete_action(tutorial_action, {"target_instance_id": target_instance_id})
	_render_match()


func _choose_effect_target_animated(target_instance_id: int) -> void:
	if animation_busy:
		return
	animation_busy = true
	service.choose_effect_target(state, target_instance_id)
	await _drain_animation_event_queue()
	animation_busy = false
	_render_match()


func _choose_ability_target_animated(target_instance_id: int) -> void:
	if animation_busy:
		return
	animation_busy = true
	service.choose_ability_target(state, target_instance_id)
	await _drain_animation_event_queue()
	animation_busy = false
	_render_match()


func _card_node_for_instance(instance_id: int) -> Node3D:
	var ghost_node = animation_ghost_nodes.get(instance_id)
	if is_instance_valid(ghost_node):
		return ghost_node as Node3D
	for card_node in interactive_cards:
		if is_instance_valid(card_node) and int(card_node.get_meta("instance_id", -1)) == instance_id:
			return card_node
	return null


func _hand_card_node(side: String, hand_index: int, card_id: String = "") -> Node3D:
	for card_node in card_layer.get_children():
		if not card_node is Node3D or String(card_node.get_meta("kind", "")) != "hand" or String(card_node.get_meta("side", "")) != side:
			continue
		if hand_index >= 0 and int(card_node.get_meta("hand_index", -1)) == hand_index:
			return card_node as Node3D
		if hand_index < 0 and card_id != "" and String(card_node.get_meta("card_id", "")) == card_id:
			return card_node as Node3D
	return null


func _drain_animation_event_queue(play_origin_pose: Dictionary = {}) -> void:
	var events: Array[Dictionary] = service.take_animation_events(state)
	_prepare_animation_ghosts(events)
	var event_index := 0
	while event_index < events.size():
		var first_event: Dictionary = events[event_index]
		var group_id := int(first_event.get("group_id", 0))
		var batch: Array[Dictionary] = [first_event]
		event_index += 1
		if group_id > 0:
			while event_index < events.size() and int(events[event_index].get("group_id", 0)) == group_id:
				batch.append(events[event_index])
				event_index += 1
		await _animate_event_batch(batch, play_origin_pose)
	_clear_animation_ghosts()


func _prepare_animation_ghosts(events: Array[Dictionary]) -> void:
	var removed_ids: Array[int] = []
	for event in events:
		if String(event.get("type", "")) not in ["sacrifice", "destroy"]:
			continue
		var instance_id := int(event.get("instance_id", -1))
		if instance_id >= 0 and not removed_ids.has(instance_id):
			removed_ids.append(instance_id)
	for instance_id in removed_ids:
		var card_node: Node3D
		for candidate in interactive_cards:
			if is_instance_valid(candidate) and int(candidate.get_meta("instance_id", -1)) == instance_id:
				card_node = candidate
				break
		if card_node == null:
			continue
		card_node.reparent(animation_ghost_layer, true)
		animation_ghost_nodes[instance_id] = card_node


func _clear_animation_ghosts() -> void:
	for ghost_node in animation_ghost_nodes.values():
		if is_instance_valid(ghost_node):
			(ghost_node as Node).queue_free()
	animation_ghost_nodes.clear()


func _animate_event_batch(events: Array[Dictionary], play_origin_pose: Dictionary) -> void:
	for event in events:
		if String(event.get("type", "")) == "play" and String(event.get("side", "")) == "opponent":
			await _show_opponent_reveal(event)
		elif String(event.get("type", "")) == "move":
			var moving_node := _card_node_for_instance(int(event.get("instance_id", -1)))
			if moving_node != null:
				event.origin_pose = {
					"position": moving_node.position,
					"rotation_degrees": moving_node.rotation_degrees,
					"scale": moving_node.scale
				}
	var needs_destination_render := false
	for event in events:
		if String(event.get("type", "")) in ["play", "draw", "search", "move"]:
			needs_destination_render = true
			break
	if needs_destination_render:
		_render_match()
	var longest_duration := 0.0
	for event in events:
		var event_type := String(event.get("type", ""))
		if event_type == "attack":
			await _animate_attack_motion(
				int(event.get("source_instance_id", -1)),
				int(event.get("target_instance_id", -1)),
				String(event.get("target_kind", "unit"))
			)
			continue
		longest_duration = maxf(longest_duration, _start_animation_event(event, play_origin_pose))
	if longest_duration > 0.0:
		await get_tree().create_timer(longest_duration).timeout


func _start_animation_event(event: Dictionary, play_origin_pose: Dictionary) -> float:
	match String(event.get("type", "")):
		"play":
			return _start_play_event_animation(event, play_origin_pose)
		"draw", "search":
			return _start_card_transfer_event_animation(event)
		"move":
			return _start_move_event_animation(event)
		"damage":
			return _start_damage_event_animation(event)
		"heal":
			return _start_heal_event_animation(event)
		"buff":
			return _start_buff_event_animation(event)
		"sacrifice", "destroy":
			return _start_removal_event_animation(event)
	return 0.0


func _start_play_event_animation(event: Dictionary, play_origin_pose: Dictionary) -> float:
	var side := String(event.get("side", "player"))
	var instance_id := int(event.get("instance_id", -1))
	var card_node := _card_node_for_instance(instance_id) if instance_id >= 0 else null
	if card_node == null and String(event.get("to", "")) == "environment":
		card_node = find_child("%sEnvironmentCard" % side.capitalize(), true, false) as Node3D
	if card_node == null and String(event.get("to", "")) == "discard":
		card_node = find_child("%sDiscardTop" % side.capitalize(), true, false) as Node3D
	if card_node == null and String(event.get("to", "")) == "attachment":
		var target_node := _card_node_for_instance(int(event.get("target_instance_id", -1)))
		if target_node != null:
			card_node = target_node.find_child("SpiceAttachment_*", true, false) as Node3D
	if card_node == null:
		return 0.0
	var origin_pose := play_origin_pose if side == "player" else {}
	var hand_origin := Vector3(0.0, 0.9, PLAYER_HAND_Z if side == "player" else OPPONENT_HAND_Z)
	_start_node_arrival_animation(card_node, origin_pose, hand_origin)
	_spawn_particle_burst(card_node.global_position + Vector3(0.0, 0.18, 0.0), Color("#42d7ff") if side == "player" else Color("#e66da5"), 10, "◆")
	return 0.44


func _start_card_transfer_event_animation(event: Dictionary) -> float:
	var side := String(event.get("side", "player"))
	var hand_index := int(event.get("hand_index", -1))
	var card_id := String(event.get("card_id", ""))
	var destination := String(event.get("to", "hand"))
	var card_node: Node3D
	if destination == "hand":
		card_node = _hand_card_node(side, hand_index, card_id)
	elif destination == "deck":
		card_node = find_child("%sDeckCard_*" % side.capitalize(), true, false) as Node3D
	if card_node == null:
		return 0.0
	var source_kind := String(event.get("from", "deck"))
	var source_key := "%s_%s" % [side, "discard" if source_kind == "discard" else "deck"]
	var source_position: Vector3 = AUX_ZONE_POSITIONS[source_key] + Vector3(0.0, 0.9, 0.0)
	var destination_position := card_node.global_position
	var accent := Color("#42d7ff") if side == "player" else Color("#c979e8")
	var show_particles := String(event.get("type", "")) != "draw"
	if show_particles:
		_spawn_particle_burst(source_position, accent, 7, "•")
	_start_node_arrival_animation(card_node, {}, source_position)
	if show_particles:
		get_tree().create_timer(0.31).timeout.connect(func() -> void: _spawn_particle_burst(destination_position + Vector3(0.0, 0.2, 0.0), accent, 9, "✦"))
	return 0.48


func _start_move_event_animation(event: Dictionary) -> float:
	var side := String(event.get("side", "opponent"))
	var card_node := _card_node_for_instance(int(event.get("instance_id", -1)))
	if card_node == null:
		return 0.0
	var source_zone := String(event.get("from", "prep"))
	var source_key := "%s_%s" % [side, source_zone]
	var fallback_position: Vector3 = ZONE_CENTERS.get(source_key, card_node.position)
	var destination_position := card_node.global_position
	var accent := Color("#e66da5") if side == "opponent" else Color("#42d7ff")
	_start_node_arrival_animation(card_node, event.get("origin_pose", {}), fallback_position)
	_spawn_particle_burst(fallback_position + Vector3(0.0, 0.22, 0.0), accent, 7, "•")
	get_tree().create_timer(0.34).timeout.connect(func() -> void: _spawn_particle_burst(destination_position + Vector3(0.0, 0.28, 0.0), accent, 10, "◆"))
	return 0.52


func _start_node_arrival_animation(card_node: Node3D, origin_pose: Dictionary, fallback_position: Vector3) -> void:
	var target_position: Vector3 = card_node.position
	var target_rotation: Vector3 = card_node.rotation_degrees
	var target_scale: Vector3 = card_node.scale
	card_node.position = origin_pose.get("position", fallback_position)
	card_node.rotation_degrees = origin_pose.get("rotation_degrees", Vector3(68.0, 0.0, 0.0))
	card_node.scale = origin_pose.get("scale", target_scale * 0.62)
	var midpoint := card_node.position.lerp(target_position, 0.52) + Vector3(0.0, 0.48, 0.0)
	var movement := create_tween()
	movement.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	movement.tween_property(card_node, "position", midpoint, 0.19)
	movement.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	movement.tween_property(card_node, "position", target_position, 0.23)
	var pose_tween := create_tween().set_parallel(true)
	pose_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pose_tween.tween_property(card_node, "rotation_degrees", target_rotation, 0.42)
	pose_tween.tween_property(card_node, "scale", target_scale, 0.36)


func _animate_attack_motion(attacker_instance_id: int, target_instance_id: int, target_kind: String = "unit") -> void:
	var attacker_node := _card_node_for_instance(attacker_instance_id)
	if attacker_node == null:
		return
	var attacker_side := String(attacker_node.get_meta("side", "player"))
	var origin := attacker_node.position
	var attacks_chef := target_kind == "chef"
	var target_position := origin + Vector3(0.0, 0.0, -4.5 if attacker_side == "player" else 4.5)
	var target_node: Node3D
	if not attacks_chef:
		target_node = _card_node_for_instance(target_instance_id)
	if target_node != null:
		target_position = target_node.position
	var origin_scale := attacker_node.scale
	var lunge_position := origin.lerp(target_position, 0.58)
	lunge_position.y = maxf(origin.y + 0.5, 0.82)
	if attacks_chef:
		_start_camera_pulse(attacker_side, 2.2)
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(attacker_node, "position", lunge_position, 0.2)
	tween.tween_property(attacker_node, "scale", origin_scale * 1.13, 0.2)
	await tween.finished
	var impact_position := target_node.global_position if target_node != null else lunge_position
	_spawn_impact_flash(impact_position)
	_spawn_particle_burst(impact_position + Vector3(0.0, 0.35, 0.0), Color("#ff9f43"), 14, "✦")
	var return_tween := create_tween().set_parallel(true)
	return_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return_tween.tween_property(attacker_node, "position", origin, 0.28)
	return_tween.tween_property(attacker_node, "scale", origin_scale, 0.24)
	await return_tween.finished


func _start_damage_event_animation(event: Dictionary) -> float:
	var amount := int(event.get("amount", 0))
	if amount <= 0:
		return 0.0
	if String(event.get("target_kind", "unit")) == "chef":
		var chef_node := player_chef if String(event.get("target_side", "player")) == "player" else opponent_chef
		_spawn_damage_number(chef_node.global_position + Vector3(0.0, 0.65, 0.0), amount)
		_spawn_particle_burst(chef_node.global_position + Vector3(0.0, 0.5, 0.0), Color("#ff654f"), 12, "◆")
		_animate_chef_hit(chef_node)
		return 0.42
	var card_node := _card_node_for_instance(int(event.get("target_instance_id", -1)))
	if card_node == null:
		return 0.0
	_spawn_damage_number(card_node.global_position + Vector3(0.0, 0.55, 0.0), amount)
	_spawn_particle_burst(card_node.global_position + Vector3(0.0, 0.42, 0.0), Color("#ff654f"), 9, "•")
	_animate_hit_reaction(card_node)
	return 0.42


func _start_heal_event_animation(event: Dictionary) -> float:
	var amount := int(event.get("amount", 0))
	if amount <= 0:
		return 0.0
	if String(event.get("target_kind", "unit")) == "chef":
		var chef_node := player_chef if String(event.get("target_side", "player")) == "player" else opponent_chef
		_spawn_floating_number(chef_node.global_position + Vector3(0.0, 0.65, 0.0), "+%d" % amount, Color("#68e39a"))
		_spawn_particle_burst(chef_node.global_position + Vector3(0.0, 0.5, 0.0), Color("#68e39a"), 12, "+")
		_animate_positive_reaction(chef_node)
		return 0.42
	var card_node := _card_node_for_instance(int(event.get("target_instance_id", -1)))
	if card_node == null:
		return 0.0
	_spawn_floating_number(card_node.global_position + Vector3(0.0, 0.55, 0.0), "+%d" % amount, Color("#68e39a"))
	_spawn_particle_burst(card_node.global_position + Vector3(0.0, 0.42, 0.0), Color("#68e39a"), 10, "+")
	_animate_positive_reaction(card_node)
	return 0.42


func _start_buff_event_animation(event: Dictionary) -> float:
	var card_node := _card_node_for_instance(int(event.get("target_instance_id", -1)))
	if card_node == null:
		return 0.0
	var parts: Array[String] = []
	var attack_delta := int(event.get("attack_delta", 0))
	var health_delta := int(event.get("health_delta", 0))
	if attack_delta != 0:
		parts.append("%s%d ATK" % ["+" if attack_delta > 0 else "", attack_delta])
	if health_delta != 0:
		parts.append("%s%d HP" % ["+" if health_delta > 0 else "", health_delta])
	_spawn_floating_number(card_node.global_position + Vector3(0.0, 0.55, 0.0), "  ".join(parts), Color("#ffd166"))
	_spawn_particle_burst(card_node.global_position + Vector3(0.0, 0.42, 0.0), Color("#ffd166"), 11, "✦")
	_animate_positive_reaction(card_node)
	return 0.46


func _start_removal_event_animation(event: Dictionary) -> float:
	var card_node := _card_node_for_instance(int(event.get("instance_id", -1)))
	if card_node == null:
		return 0.0
	var target_position := card_node.position + Vector3(0.0, 0.7, 0.0)
	_spawn_particle_burst(card_node.global_position + Vector3(0.0, 0.3, 0.0), Color("#9aa7b1"), 10, "◆")
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(card_node, "position", target_position, 0.32)
	tween.tween_property(card_node, "scale", Vector3.ZERO, 0.32)
	tween.tween_property(card_node, "rotation_degrees:y", card_node.rotation_degrees.y + 24.0, 0.32)
	return 0.34


func _animate_hit_reaction(card_node: Node3D) -> void:
	var origin := card_node.position
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(card_node, "position", origin + Vector3(0.13, 0.09, 0.0), 0.07)
	tween.tween_property(card_node, "position", origin + Vector3(-0.11, 0.04, 0.0), 0.08)
	tween.tween_property(card_node, "position", origin, 0.1)


func _animate_chef_hit(chef_node: Node3D) -> void:
	var original_scale := chef_node.scale
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(chef_node, "scale", original_scale * Vector3(1.22, 0.72, 1.22), 0.12)
	tween.tween_property(chef_node, "scale", original_scale, 0.22)


func _animate_positive_reaction(target_node: Node3D) -> void:
	var original_scale := target_node.scale
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(target_node, "scale", original_scale * 1.16, 0.13)
	tween.tween_property(target_node, "scale", original_scale, 0.24)


func _spawn_damage_number(world_position: Vector3, amount: int) -> void:
	_spawn_floating_number(world_position, "-%d" % amount, Color("#ff6b4a"))


func _spawn_floating_number(world_position: Vector3, text_value: String, color: Color) -> void:
	var damage_label := _label(text_value, 34, color)
	damage_label.add_theme_color_override("font_outline_color", Color("#260b08"))
	damage_label.add_theme_constant_override("outline_size", 8)
	damage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	damage_label.custom_minimum_size = Vector2(170, 52)
	damage_label.position = _world_to_container(world_position) - Vector2(85, 26)
	damage_label.z_index = 220
	damage_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect_layer.add_child(damage_label)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(damage_label, "position:y", damage_label.position.y - 72.0, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(damage_label, "modulate:a", 0.0, 0.65).set_delay(0.18)
	tween.finished.connect(damage_label.queue_free)


func _spawn_impact_flash(world_position: Vector3) -> void:
	var flash := _label("✦", 46, Color("#ffe36d"))
	flash.add_theme_color_override("font_outline_color", Color("#f05a2a"))
	flash.add_theme_constant_override("outline_size", 9)
	flash.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flash.custom_minimum_size = Vector2(90, 70)
	flash.position = _world_to_container(world_position) - Vector2(45, 35)
	flash.pivot_offset = Vector2(45, 35)
	flash.scale = Vector2(0.25, 0.25)
	flash.z_index = 219
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect_layer.add_child(flash)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(flash, "scale", Vector2(1.35, 1.35), 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(flash, "modulate:a", 0.0, 0.32).set_delay(0.08)
	tween.finished.connect(flash.queue_free)


func _show_opponent_reveal(event: Dictionary) -> void:
	var card_id := String(event.get("card_id", ""))
	if card_id == "":
		return
	var reveal_card := TextureRect.new()
	reveal_card.name = "OpponentRevealCard"
	reveal_card.texture = CARD_BACK
	reveal_card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	reveal_card.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	reveal_card.size = Vector2(182.0, 259.0)
	reveal_card.pivot_offset = reveal_card.size * 0.5
	reveal_card.position = _world_to_container(Vector3(0.0, 0.95, OPPONENT_HAND_Z)) - reveal_card.pivot_offset
	reveal_card.scale = Vector2(0.72, 0.72)
	reveal_card.z_index = 245
	reveal_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect_layer.add_child(reveal_card)
	var reveal_label := _label("RIVAL PLAYS", 18, Color("#ffd0e5"))
	reveal_label.name = "OpponentRevealLabel"
	reveal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reveal_label.add_theme_color_override("font_outline_color", Color("#120711"))
	reveal_label.add_theme_constant_override("outline_size", 7)
	reveal_label.size = Vector2(260.0, 38.0)
	reveal_label.position = Vector2(effect_layer.size.x * 0.5 - 130.0, effect_layer.size.y * 0.5 - 192.0)
	reveal_label.modulate.a = 0.0
	reveal_label.z_index = 246
	reveal_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect_layer.add_child(reveal_label)
	var center_position := effect_layer.size * 0.5 - reveal_card.pivot_offset
	var approach := create_tween().set_parallel(true)
	approach.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	approach.tween_property(reveal_card, "position", center_position, 0.24)
	approach.tween_property(reveal_card, "scale", Vector2.ONE, 0.24)
	approach.tween_property(reveal_label, "modulate:a", 1.0, 0.18)
	await approach.finished
	var close_flip := create_tween()
	close_flip.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	close_flip.tween_property(reveal_card, "scale:x", 0.04, 0.1)
	await close_flip.finished
	reveal_card.texture = _face_material(card_id).albedo_texture
	var open_flip := create_tween()
	open_flip.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	open_flip.tween_property(reveal_card, "scale:x", 1.0, 0.2)
	await open_flip.finished
	_spawn_screen_particle_burst(effect_layer.size * 0.5, Color("#e66da5"), 14, "✦")
	await get_tree().create_timer(0.28).timeout
	var leave := create_tween().set_parallel(true)
	leave.tween_property(reveal_card, "modulate:a", 0.0, 0.16)
	leave.tween_property(reveal_card, "scale", Vector2(1.08, 1.08), 0.16)
	leave.tween_property(reveal_label, "modulate:a", 0.0, 0.12)
	await leave.finished
	reveal_card.queue_free()
	reveal_label.queue_free()


func _spawn_particle_burst(world_position: Vector3, color: Color, count: int = 10, glyph: String = "•") -> void:
	_spawn_screen_particle_burst(_world_to_container(world_position), color, count, glyph)


func _spawn_screen_particle_burst(screen_position: Vector2, color: Color, count: int = 10, glyph: String = "•") -> void:
	if effect_layer == null or count <= 0:
		return
	for particle_index in range(count):
		var particle := Polygon2D.new()
		var radius := 6.0 + float(particle_index % 4) * 1.5
		particle.polygon = _particle_polygon(glyph, radius)
		particle.color = color.lightened(float(particle_index % 3) * 0.09)
		particle.position = screen_position
		particle.scale = Vector2(0.35, 0.35)
		particle.z_index = 235
		effect_layer.add_child(particle)
		var angle := TAU * float(particle_index) / float(count) + float(particle_index % 3) * 0.17
		var distance := 34.0 + float((particle_index * 17) % 54)
		var destination := particle.position + Vector2(cos(angle), sin(angle)) * distance
		var duration := 0.42 + float(particle_index % 4) * 0.035
		var tween := create_tween().set_parallel(true)
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(particle, "position", destination, duration)
		tween.tween_property(particle, "scale", Vector2(1.0, 1.0), duration * 0.42)
		tween.tween_property(particle, "rotation", angle * 0.35, duration)
		tween.tween_property(particle, "modulate:a", 0.0, duration * 0.55).set_delay(duration * 0.45)
		tween.finished.connect(particle.queue_free)


func _particle_polygon(style: String, radius: float) -> PackedVector2Array:
	match style:
		"+":
			var arm := radius * 0.34
			return PackedVector2Array([
				Vector2(-arm, -radius), Vector2(arm, -radius),
				Vector2(arm, -arm), Vector2(radius, -arm),
				Vector2(radius, arm), Vector2(arm, arm),
				Vector2(arm, radius), Vector2(-arm, radius),
				Vector2(-arm, arm), Vector2(-radius, arm),
				Vector2(-radius, -arm), Vector2(-arm, -arm)
			])
		"◆":
			return PackedVector2Array([
				Vector2(0.0, -radius), Vector2(radius, 0.0),
				Vector2(0.0, radius), Vector2(-radius, 0.0)
			])
		"✦":
			var inner := radius * 0.22
			return PackedVector2Array([
				Vector2(0.0, -radius), Vector2(inner, -inner),
				Vector2(radius, 0.0), Vector2(inner, inner),
				Vector2(0.0, radius), Vector2(-inner, inner),
				Vector2(-radius, 0.0), Vector2(-inner, -inner)
			])
	var circle := PackedVector2Array()
	for point_index in range(10):
		var angle := TAU * float(point_index) / 10.0
		circle.append(Vector2(cos(angle), sin(angle)) * radius)
	return circle


func _start_camera_pulse(side: String, fov_amount: float = 2.0) -> void:
	if camera == null:
		return
	if camera_pacing_tween != null and camera_pacing_tween.is_valid():
		camera_pacing_tween.kill()
	camera.global_transform = camera_home_transform
	camera.fov = camera_home_fov
	var emphasized := camera_home_transform
	emphasized.origin += Vector3(0.0, -0.12 if side == "player" else 0.1, -0.28 if side == "player" else -0.42)
	camera_pacing_tween = create_tween().set_parallel(true)
	camera_pacing_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	camera_pacing_tween.tween_property(camera, "global_transform", emphasized, 0.16)
	camera_pacing_tween.tween_property(camera, "fov", camera_home_fov - fov_amount, 0.16)
	camera_pacing_tween.chain().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	camera_pacing_tween.tween_property(camera, "global_transform", camera_home_transform, 0.34)
	camera_pacing_tween.tween_property(camera, "fov", camera_home_fov, 0.34)


func _reset_camera_pacing() -> void:
	if camera_pacing_tween != null and camera_pacing_tween.is_valid():
		camera_pacing_tween.kill()
	if camera != null:
		camera.global_transform = camera_home_transform
		camera.fov = camera_home_fov


func _build_hand_actions(data: Dictionary, hand_index: int) -> void:
	var card_type := String(data.get("card_type", ""))
	var card_id := String(data.get("id", ""))
	if card_type in ["ingredient", "meal"]:
		for zone in ["prep", "plated"]:
			var capacity: int = service.PREP_SLOTS if zone == "prep" else service.PLATED_SLOTS
			for slot_index in range(capacity):
				var chosen_zone: String = zone
				var chosen_slot: int = slot_index
				var replacing_ingredient := card_type == "meal" and not _slot_is_open("player", zone, slot_index) and _slot_can_receive_hand_card(data, "player", zone, slot_index)
				var action_text := "%s → %s %d%s" % ["Serve" if card_type == "meal" else "Play", zone.capitalize(), slot_index + 1, " (Sacrifice)" if replacing_ingredient else ""]
				var tutorial_action := "begin_meal" if card_type == "meal" else "play_hand"
				var tutorial_locked := tutorial_mode and not _tutorial_action_matches(tutorial_action, {"card_id": card_id, "zone": zone, "slot": slot_index})
				_add_action_button(action_text, func() -> void: _play_hand_card(hand_index, chosen_zone, chosen_slot), not _slot_can_receive_hand_card(data, "player", zone, slot_index) or tutorial_locked)
	elif card_type == "spice":
		var target_id := int(state.get("selected_spice_target", -1))
		var tutorial_locked := tutorial_mode and not _tutorial_action_matches("play_hand", {"card_id": card_id})
		_add_action_button("Season Selected" if target_id >= 0 else "Select a Field Card First", func() -> void: _play_hand_card(hand_index, "prep"), target_id < 0 or tutorial_locked)
	else:
		var tutorial_locked := tutorial_mode and not _tutorial_action_matches("play_hand", {"card_id": card_id})
		_add_action_button("Use %s" % card_type.capitalize(), func() -> void: _play_hand_card(hand_index, "prep"), tutorial_locked)


func _build_field_actions(data: Dictionary, instance_id: int, zone: String) -> void:
	var unit := service._find_unit(state.player, instance_id)
	if unit.is_empty():
		return
	for ability in data.get("abilities", []):
		if String(ability.get("timing", "")) != "activated":
			continue
		var ability_id := String(ability.get("id", "activated"))
		var used: bool = bool(ability.get("once_per_turn", false)) and unit.get("used_abilities", []).has(ability_id)
		var active_zone := String(ability.get("active_zone", ""))
		var wrong_zone := active_zone != "" and active_zone != zone
		var selected_ability_id := ability_id
		_add_action_button("Activate Ability", func() -> void: _activate_ability(instance_id, selected_ability_id), used or wrong_zone or tutorial_mode)
	if String(data.get("card_type", "")) == "ingredient":
		var recipe_ready := service.ingredient_recipe_status(state.player, unit) == "RECIPE READY"
		_add_action_button("Select for Recipe", func() -> void: _select_recipe_ingredient(instance_id), not recipe_ready or tutorial_mode)
	if zone == "plated" or bool(data.get("can_attack_from_prep", false)):
		var attacker_locked := tutorial_mode and not _tutorial_action_matches("select_attacker", {"card_id": String(data.get("id", "")), "instance_id": instance_id})
		_add_action_button("Choose Attacker", func() -> void: _select_attacker(instance_id), not bool(unit.get("ready", false)) or attacker_locked)
	var spice_locked := tutorial_mode and not _tutorial_action_matches("select_spice_target", {"card_id": String(data.get("id", "")), "instance_id": instance_id})
	_add_action_button("Season This Card", func() -> void: _select_spice_target(instance_id), not unit.get("spices", []).is_empty() or spice_locked)
	var destination := "prep" if zone == "plated" else "plated"
	var destination_capacity: int = service.PREP_SLOTS if destination == "prep" else service.PLATED_SLOTS
	for slot_index in range(destination_capacity):
		var chosen_slot := slot_index
		var move_locked := tutorial_mode and not _tutorial_action_matches("move_unit", {"card_id": String(data.get("id", "")), "instance_id": instance_id, "zone": destination, "slot": slot_index})
		_add_action_button("Move → %s %d" % [destination.capitalize(), slot_index + 1], func() -> void: _move_unit(instance_id, destination, chosen_slot), bool(state.player.zone_move_used) or not _slot_is_open("player", destination, slot_index) or move_locked)


func _play_hand_card(hand_index: int, destination: String, destination_slot: int = -1) -> void:
	if animation_busy:
		return
	if hand_index < 0 or hand_index >= state.player.hand.size():
		return
	var played_card_id := String(state.player.hand[hand_index])
	var card_data: Dictionary = service.card(played_card_id)
	var card_type := String(card_data.get("card_type", ""))
	var tutorial_action := "begin_meal" if card_type == "meal" else "play_hand"
	var tutorial_details := {"card_id": played_card_id, "zone": destination, "slot": destination_slot}
	if tutorial_mode and not _tutorial_action_matches(tutorial_action, tutorial_details):
		_tutorial_reject_action()
		return
	if card_type in ["ingredient", "meal"]:
		if destination_slot < 0:
			state.message = "Choose an exact %s slot." % destination.capitalize()
			_render_match()
			return
		if not _slot_can_receive_hand_card(card_data, "player", destination, destination_slot):
			state.message = "%s slot %d is occupied." % [destination.capitalize(), destination_slot + 1]
			_render_match()
			return
	if card_type == "meal":
		service.begin_meal_play(state, hand_index, destination, destination_slot)
		selected_ref = {}
		_tutorial_complete_action("begin_meal", tutorial_details)
		_render_match()
		return
	var previous_ids: Array[int] = []
	for unit in state.player.get(destination, []):
		previous_ids.append(int(unit.instance_id))
	var hand_pose := _hand_card_pose(hand_index)
	animation_busy = true
	service.play_card(state, hand_index, destination, int(state.get("selected_spice_target", -1)))
	if card_type in ["ingredient", "meal"]:
		_assign_new_unit_to_slot("player", destination, previous_ids, destination_slot)
	selected_ref = {}
	await _drain_animation_event_queue(hand_pose)
	animation_busy = false
	_tutorial_complete_action("play_hand", tutorial_details)
	_render_match()


func _hand_card_pose(hand_index: int) -> Dictionary:
	for card_node in interactive_cards:
		if String(card_node.get_meta("kind", "")) == "hand" and String(card_node.get_meta("side", "")) == "player" and int(card_node.get_meta("hand_index", -1)) == hand_index:
			return {
				"position": card_node.position,
				"rotation_degrees": card_node.rotation_degrees,
				"scale": card_node.scale
			}
	return {}


func _activate_ability(instance_id: int, ability_id: String) -> void:
	if animation_busy:
		return
	animation_busy = true
	service.activate_ability(state, instance_id, ability_id)
	selected_ref = {}
	await _drain_animation_event_queue()
	animation_busy = false
	_render_match()


func _select_recipe_ingredient(instance_id: int) -> void:
	service.toggle_ingredient_selection(state, instance_id)
	selected_ref = {}
	_render_match()


func _select_attacker(instance_id: int) -> void:
	var unit := service._find_unit(state.player, instance_id)
	var details := {"instance_id": instance_id, "card_id": String(unit.get("card_id", ""))}
	if tutorial_mode and not _tutorial_action_matches("select_attacker", details):
		_tutorial_reject_action()
		return
	service.select_attacker(state, instance_id)
	selected_ref = {}
	_tutorial_complete_action("select_attacker", details)
	_render_match()


func _select_spice_target(instance_id: int) -> void:
	var unit := service._find_unit(state.player, instance_id)
	var details := {"instance_id": instance_id, "card_id": String(unit.get("card_id", ""))}
	if tutorial_mode and not _tutorial_action_matches("select_spice_target", details):
		_tutorial_reject_action()
		return
	service.select_spice_target(state, instance_id)
	selected_ref = {}
	_tutorial_complete_action("select_spice_target", details)
	_render_match()


func _move_unit(instance_id: int, destination: String, destination_slot: int = -1) -> void:
	if animation_busy:
		return
	var unit := service._find_unit(state.player, instance_id)
	if unit.is_empty():
		return
	var tutorial_details := {"instance_id": instance_id, "card_id": String(unit.get("card_id", "")), "zone": destination, "slot": destination_slot}
	if tutorial_mode and not _tutorial_action_matches("move_unit", tutorial_details):
		_tutorial_reject_action()
		return
	if destination_slot < 0 or not _slot_is_open("player", destination, destination_slot, instance_id):
		state.message = "%s slot %d is occupied." % [destination.capitalize(), destination_slot + 1]
		_render_match()
		return
	var source_zone := "plated" if not service._find_unit_in_zone(state.player, "plated", instance_id).is_empty() else "prep"
	if source_zone == destination:
		unit.table_slot = destination_slot
		state.message = "%s is repositioned in %s slot %d." % [String(unit.name), destination.capitalize(), destination_slot + 1]
	else:
		animation_busy = true
		service.move_unit(state, instance_id, destination)
		var moved_unit := service._find_unit(state.player, instance_id)
		if not moved_unit.is_empty() and service._unit_zone(state.player, instance_id) == destination:
			moved_unit.table_slot = destination_slot
	selected_ref = {}
	if animation_busy:
		await _drain_animation_event_queue()
		animation_busy = false
	_tutorial_complete_action("move_unit", tutorial_details)
	_render_match()


func _refresh_prompt() -> void:
	_clear_children(prompt_content)
	prompt_panel.visible = (_has_blocking_prompt() and not _uses_bottom_target_prompt() and not _uses_card_tray_prompt()) or (bool(state.game_over) and outcome_sequence_played and not production_match)
	if bool(state.game_over):
		if not outcome_sequence_played or production_match:
			return
		_add_prompt_title("MATCH OVER")
		prompt_content.add_child(_label("%s wins the cook-off." % String(state.winner).capitalize(), 22, Color.WHITE))
		if production_match:
			_add_prompt_button(configured_exit_label, func() -> void: exit_requested.emit())
		else:
			_add_prompt_button("Play Again", _start_match)
		return
	if _uses_card_tray_prompt() or not state.get("pending_discard", {}).is_empty() or not state.get("pending_meal", {}).is_empty():
		return
	var pending_search: Dictionary = state.get("pending_search", {})
	if not pending_search.is_empty():
		_add_prompt_title("CHOOSE A CARD")
		_add_prompt_text(String(pending_search.get("prompt", state.message)))
		for card_id in service.search_display_cards(state):
			var can_take := service.search_candidates(state).has(card_id)
			var selected_card_id := card_id
			_add_prompt_button(String(service.card(card_id).get("name", card_id)), func() -> void: _choose_search(selected_card_id), not can_take)
		_add_prompt_button("Skip", _skip_search)
		return
	var pending_choice: Dictionary = state.get("pending_choice", {})
	if not pending_choice.is_empty():
		if String(pending_choice.get("choice_kind", "")) == "board":
			return
		_add_prompt_title("CARD EFFECT")
		_add_prompt_text(String(pending_choice.get("prompt", state.message)))
		match String(pending_choice.get("choice_kind", "")):
			"board":
				_add_prompt_text("Click one of the highlighted cards on the table.")
			"discard":
				for discard_index in service.discard_choice_indices(state):
					var selected: bool = pending_choice.get("selected_indices", []).has(discard_index)
					var card_id := String(state.player.discard[discard_index])
					var selected_discard_index := discard_index
					_add_prompt_button(("✓ " if selected else "") + String(service.card(card_id).get("name", card_id)), func() -> void: _toggle_discard_choice(selected_discard_index))
				_add_prompt_button("Confirm", _confirm_discard_choice)
			"opponent_hand":
				for hand_index in service.opponent_hand_choice_indices(state):
					var card_id := String(state.opponent.hand[hand_index])
					var selected_opponent_index := hand_index
					_add_prompt_button(String(service.card(card_id).get("name", card_id)), func() -> void: _choose_opponent_hand(selected_opponent_index))
		_add_prompt_button("Skip", _skip_effect_choice)
		return
	var pending_ability: Dictionary = state.get("pending_ability", {})
	if not pending_ability.is_empty():
		return
	var pending_reaction: Dictionary = state.get("pending_reaction", {})
	if not pending_reaction.is_empty():
		_add_prompt_title("REACTION WINDOW")
		_add_prompt_text(String(state.message))
		if String(pending_reaction.get("reaction_kind", "hand_trap")) == "hand_trap":
			if not reaction_countdown_active:
				_start_reaction_countdown()
			reaction_countdown_label = _label("", 17, Color("#ffd36f"))
			reaction_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			prompt_content.add_child(reaction_countdown_label)
			_update_reaction_countdown_label()
		else:
			_cancel_reaction_countdown()
		for hand_index in service.reaction_hand_indices(state):
			var card_id := String(state.player.hand[hand_index])
			var reaction_hand_index := hand_index
			_add_prompt_button("Use %s" % String(service.card(card_id).get("name", card_id)), func() -> void: _resolve_reaction(reaction_hand_index))
		_add_prompt_button("Pass", func() -> void: _resolve_reaction(-1))
		return
	_cancel_reaction_countdown()


func _start_reaction_countdown() -> void:
	reaction_countdown_active = true
	reaction_countdown_remaining = REACTION_WINDOW_SECONDS


func _cancel_reaction_countdown() -> void:
	reaction_countdown_active = false
	reaction_countdown_remaining = 0.0
	reaction_countdown_label = null


func _update_reaction_countdown(delta: float) -> void:
	if not reaction_countdown_active:
		return
	var pending_reaction: Dictionary = state.get("pending_reaction", {})
	if pending_reaction.is_empty() or String(pending_reaction.get("reaction_kind", "hand_trap")) != "hand_trap":
		_cancel_reaction_countdown()
		return
	reaction_countdown_remaining = maxf(0.0, reaction_countdown_remaining - delta)
	_update_reaction_countdown_label()
	if reaction_countdown_remaining <= 0.0 and not animation_busy:
		reaction_countdown_active = false
		_resolve_reaction(-1)


func _update_reaction_countdown_label() -> void:
	if not is_instance_valid(reaction_countdown_label):
		return
	var seconds_left := ceili(reaction_countdown_remaining)
	reaction_countdown_label.text = "Auto-pass in %d second%s" % [seconds_left, "" if seconds_left == 1 else "s"]


func _uses_bottom_target_prompt() -> bool:
	if not state.get("pending_discard", {}).is_empty() or not state.get("pending_meal", {}).is_empty():
		return true
	var pending_choice: Dictionary = state.get("pending_choice", {})
	return String(pending_choice.get("choice_kind", "")) == "board" or not state.get("pending_ability", {}).is_empty()


func _uses_card_tray_prompt() -> bool:
	if not state.get("pending_search", {}).is_empty():
		return true
	return String(state.get("pending_choice", {}).get("choice_kind", "")) == "discard"


func _open_discard_tray(side: String) -> void:
	if side not in ["player", "opponent"] or _has_blocking_prompt() or bool(state.get("game_over", false)):
		return
	manual_discard_tray_side = side
	selected_ref = {}
	_refresh_action_panel()
	_refresh_card_tray()


func _close_card_tray() -> void:
	if _uses_card_tray_prompt():
		return
	manual_discard_tray_side = ""
	_refresh_card_tray()


func _skip_card_tray_choice() -> void:
	if not state.get("pending_search", {}).is_empty():
		_skip_search()
	elif String(state.get("pending_choice", {}).get("choice_kind", "")) == "discard":
		_skip_effect_choice()


func _refresh_card_tray() -> void:
	_clear_children(card_tray_cards)
	card_tray_overlay.visible = false
	if state.is_empty() or bool(state.get("game_over", false)):
		manual_discard_tray_side = ""
		return
	var pending_search: Dictionary = state.get("pending_search", {})
	var pending_choice: Dictionary = state.get("pending_choice", {})
	var choice_kind := String(pending_choice.get("choice_kind", ""))
	var mode := ""
	if not pending_search.is_empty():
		mode = "search"
	elif choice_kind == "discard":
		mode = "discard_choice"
	elif manual_discard_tray_side != "":
		mode = "discard_browse"
	if mode == "":
		return

	card_tray_overlay.visible = true
	action_panel.visible = false
	card_tray_close_button.visible = mode == "discard_browse"
	card_tray_skip_button.visible = mode in ["search", "discard_choice"]
	card_tray_confirm_button.visible = mode == "discard_choice"
	card_tray_selection_status.text = ""
	if mode == "search":
		card_tray_title.text = "CHOOSE FROM YOUR DECK"
		card_tray_prompt.text = String(pending_search.get("prompt", state.message))
		card_tray_selection_status.text = "Click a card to add it to your hand."
		var search_candidates: Array[String] = service.search_candidates(state)
		for card_id in service.search_display_cards(state):
			var selected_card_id := String(card_id)
			_add_card_tray_card(selected_card_id, func() -> void: _choose_search(selected_card_id), search_candidates.has(selected_card_id), false)
	elif mode == "discard_choice":
		card_tray_title.text = "CHOOSE FROM YOUR DISCARD"
		card_tray_prompt.text = String(pending_choice.get("prompt", state.message))
		var valid_indices: Array[int] = service.discard_choice_indices(state)
		var selected_indices: Array = pending_choice.get("selected_indices", [])
		card_tray_selection_status.text = "%d / %d selected" % [selected_indices.size(), int(pending_choice.get("required", 0))]
		for discard_index in valid_indices:
			var selected_discard_index := int(discard_index)
			var card_id := String(state.player.discard[selected_discard_index])
			_add_card_tray_card(card_id, func() -> void: _toggle_discard_choice(selected_discard_index), true, selected_indices.has(selected_discard_index))
	else:
		var side := manual_discard_tray_side
		var cards: Array = state[side].discard
		card_tray_title.text = "YOUR DISCARD" if side == "player" else "RIVAL DISCARD"
		card_tray_prompt.text = "Newest cards appear first."
		card_tray_selection_status.text = "%d card%s" % [cards.size(), "" if cards.size() == 1 else "s"]
		for discard_index in range(cards.size() - 1, -1, -1):
			_add_card_tray_card(String(cards[discard_index]), Callable(), true, false)
	if card_tray_cards.get_child_count() == 0:
		var empty_label := _label("No cards to show.", 22, Color("#b8cbd5"))
		empty_label.custom_minimum_size = Vector2(640, 220)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		card_tray_cards.add_child(empty_label)


func _add_card_tray_card(card_id: String, callback: Callable, enabled: bool, selected: bool) -> void:
	var button := Button.new()
	button.name = "CardTrayCard_%d" % card_tray_cards.get_child_count()
	button.custom_minimum_size = Vector2(170, 241)
	button.tooltip_text = String(service.card(card_id).get("name", card_id))
	button.disabled = not enabled
	button.focus_mode = Control.FOCUS_NONE
	_apply_card_tray_card_style(button, selected)
	if callback.is_valid():
		button.pressed.connect(callback, CONNECT_DEFERRED)
	var face := TextureRect.new()
	face.name = "FullCardFace"
	face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	face.offset_left = 5.0
	face.offset_top = 5.0
	face.offset_right = -5.0
	face.offset_bottom = -5.0
	face.texture = _face_material(card_id).albedo_texture
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_SCALE
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.modulate = Color(1.0, 1.0, 1.0, 1.0 if enabled else 0.38)
	button.add_child(face)
	if selected:
		var badge := _label("✓", 25, Color("#151008"))
		badge.name = "SelectedBadge"
		badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		badge.offset_left = -38.0
		badge.offset_top = 8.0
		badge.offset_right = -8.0
		badge.offset_bottom = 38.0
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var badge_style := StyleBoxFlat.new()
		badge_style.bg_color = Color("#ffd166")
		badge_style.set_corner_radius_all(15)
		badge.add_theme_stylebox_override("normal", badge_style)
		button.add_child(badge)
	card_tray_cards.add_child(button)


func _apply_card_tray_card_style(button: Button, selected: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#0b1117")
	normal.border_color = Color("#ffd166") if selected else Color("#253946")
	normal.set_border_width_all(4 if selected else 2)
	normal.set_corner_radius_all(8)
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#173b4b")
	hover.border_color = Color("#7ee1ff")
	hover.set_border_width_all(3)
	button.add_theme_stylebox_override("hover", hover)
	var pressed := hover.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("#22566a")
	button.add_theme_stylebox_override("pressed", pressed)
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color("#13171b")
	disabled.border_color = Color("#31363b")
	button.add_theme_stylebox_override("disabled", disabled)


func _apply_card_tray_panel_style() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.035, 0.16, 0.21, 0.94)
	panel_style.border_color = Color(0.18, 0.49, 0.62, 0.95)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(28)
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	panel_style.shadow_size = 18
	card_tray_panel.add_theme_stylebox_override("panel", panel_style)


func _refresh_bottom_status() -> void:
	confirm_choice_button.visible = false
	confirm_choice_button.disabled = false
	confirm_choice_button.text = "Confirm"
	cancel_choice_button.visible = false
	cancel_choice_button.text = "Cancel"
	highlighted_zone = ""
	highlighted_slot = -1
	var pending_meal: Dictionary = state.get("pending_meal", {})
	if not pending_meal.is_empty():
		status_label.text = String(state.message)
		confirm_choice_button.visible = true
		confirm_choice_button.text = "Serve Meal"
		confirm_choice_button.disabled = not service.meal_selection_is_ready(state) or (tutorial_mode and String(_tutorial_step().get("action", "")) != "confirm_meal")
		cancel_choice_button.visible = not tutorial_mode
		if tutorial_mode:
			highlighted_zone = "player_prep"
		return
	var pending_discard: Dictionary = state.get("pending_discard", {})
	if not pending_discard.is_empty():
		var selected_count: int = pending_discard.get("selected_indices", []).size()
		var required := int(pending_discard.get("required", 0))
		status_label.text = "Select %d card%s from your hand to discard: %d/%d selected." % [required, "" if required == 1 else "s", selected_count, required]
		confirm_choice_button.visible = true
		confirm_choice_button.disabled = selected_count != required
		cancel_choice_button.visible = true
		return
	var pending_choice: Dictionary = state.get("pending_choice", {})
	if String(pending_choice.get("choice_kind", "")) == "board":
		var effect: Dictionary = pending_choice.get("effect", {})
		var amount := int(effect.get("amount", 0))
		if String(effect.get("type", "")) == "damage_enemy_prep":
			status_label.text = "Choose which prepped card to do %d damage to." % amount
		else:
			status_label.text = String(pending_choice.get("prompt", state.message))
		highlighted_zone = _choice_target_zone(service.choice_target_ids(state))
		cancel_choice_button.visible = true
		cancel_choice_button.text = "Cancel Attack" if String(state.get("pending_resume", {}).get("type", "")) == "player_attack" else "Skip Effect"
		return
	var pending_ability: Dictionary = state.get("pending_ability", {})
	if not pending_ability.is_empty():
		status_label.text = String(state.message)
		highlighted_zone = _pending_ability_zone(pending_ability)
		cancel_choice_button.visible = true
		return
	status_label.text = String(state.message)
	if tutorial_mode:
		var step := _tutorial_step()
		var action := String(step.get("action", ""))
		if action in ["play_hand", "begin_meal", "move_unit"] and step.has("zone"):
			highlighted_zone = "player_%s" % String(step.zone)
			highlighted_slot = int(step.get("slot", -1))


func _toggle_battle_log() -> void:
	_set_battle_log_visible(not battle_log_panel.visible)


func _set_battle_log_visible(visible: bool) -> void:
	battle_log_panel.visible = visible
	if visible:
		_refresh_battle_log()


func _refresh_battle_log() -> void:
	if state.is_empty():
		battle_log_button.text = "BATTLE LOG"
		battle_log_text.text = "The battle log will appear here."
		return
	var entries: Array = state.get("log", [])
	battle_log_button.text = "BATTLE LOG  %d" % entries.size()
	if entries.is_empty():
		battle_log_text.text = "No actions have been recorded yet."
		return
	var lines: Array[String] = []
	for entry_index in range(entries.size()):
		lines.append("[color=#8fcce5]%02d[/color]  %s" % [entry_index + 1, String(entries[entry_index])])
	battle_log_text.text = "\n\n".join(lines)
	if battle_log_panel.visible:
		battle_log_text.scroll_to_line(maxi(0, lines.size() - 1))


func _choice_target_zone(target_ids: Array[int]) -> String:
	for side in ["player", "opponent"]:
		for zone in ["prep", "plated"]:
			for unit in state[side][zone]:
				if target_ids.has(int(unit.instance_id)):
					return "%s_%s" % [side, zone]
	return ""


func _pending_ability_zone(pending: Dictionary) -> String:
	var side := "player" if String(pending.get("target_side", "enemy")) == "friendly" else "opponent"
	var zone := String(pending.get("target_zone", ""))
	return "%s_%s" % [side, zone] if zone in ["prep", "plated"] else ""


func _cancel_bottom_choice() -> void:
	if animation_busy:
		return
	if not state.get("pending_meal", {}).is_empty():
		service.cancel_meal_play(state)
		_render_match()
		return
	if not state.get("pending_discard", {}).is_empty():
		_cancel_discard_cost()
		return
	if not state.get("pending_ability", {}).is_empty():
		service.cancel_ability_target(state)
	elif String(state.get("pending_choice", {}).get("choice_kind", "")) == "board":
		if String(state.get("pending_resume", {}).get("type", "")) == "player_attack":
			service.cancel_pending_attack_choice(state)
		else:
			animation_busy = true
			service.skip_effect_choice(state)
			await _drain_animation_event_queue()
			animation_busy = false
	_render_match()


func _has_blocking_prompt() -> bool:
	return not state.get("pending_meal", {}).is_empty() or not state.get("pending_discard", {}).is_empty() or not state.get("pending_ability", {}).is_empty() or not state.get("pending_search", {}).is_empty() or not state.get("pending_choice", {}).is_empty() or not state.get("pending_reaction", {}).is_empty()


func _confirm_bottom_choice() -> void:
	if not state.get("pending_meal", {}).is_empty():
		_confirm_meal_play()
	elif not state.get("pending_discard", {}).is_empty():
		_confirm_discard_cost()


func _confirm_meal_play() -> void:
	if animation_busy or not service.meal_selection_is_ready(state):
		return
	if tutorial_mode and not _tutorial_action_matches("confirm_meal"):
		_tutorial_reject_action()
		return
	var pending: Dictionary = state.get("pending_meal", {}).duplicate(true)
	var destination := String(pending.get("destination", "plated"))
	var destination_slot := int(pending.get("destination_slot", -1))
	var previous_ids: Array[int] = []
	for unit in state.player.get(destination, []):
		previous_ids.append(int(unit.instance_id))
	var hand_pose := _hand_card_pose(int(pending.get("hand_index", -1)))
	animation_busy = true
	service.confirm_meal_play(state)
	_assign_new_unit_to_slot("player", destination, previous_ids, destination_slot)
	selected_ref = {}
	await _drain_animation_event_queue(hand_pose)
	animation_busy = false
	_tutorial_complete_action("confirm_meal")
	_render_match()


func _toggle_discard_cost(hand_index: int) -> void:
	service.toggle_discard_card(state, hand_index)
	_render_match()


func _confirm_discard_cost() -> void:
	if animation_busy:
		return
	animation_busy = true
	service.confirm_discard_cost(state)
	await _drain_animation_event_queue()
	animation_busy = false
	_render_match()


func _cancel_discard_cost() -> void:
	service.cancel_discard_cost(state)
	_render_match()


func _choose_search(card_id: String) -> void:
	if animation_busy:
		return
	animation_busy = true
	service.select_search_card(state, card_id)
	await _drain_animation_event_queue()
	animation_busy = false
	_render_match()


func _skip_search() -> void:
	service.skip_search(state)
	_render_match()


func _toggle_discard_choice(discard_index: int) -> void:
	service.toggle_discard_choice(state, discard_index)
	_render_match()


func _confirm_discard_choice() -> void:
	if animation_busy:
		return
	animation_busy = true
	service.confirm_discard_choice(state)
	await _drain_animation_event_queue()
	animation_busy = false
	_render_match()


func _choose_opponent_hand(hand_index: int) -> void:
	if animation_busy:
		return
	animation_busy = true
	service.choose_opponent_hand_card(state, hand_index)
	await _drain_animation_event_queue()
	animation_busy = false
	_render_match()


func _skip_effect_choice() -> void:
	if animation_busy:
		return
	animation_busy = true
	service.skip_effect_choice(state)
	await _drain_animation_event_queue()
	animation_busy = false
	_render_match()


func _cancel_ability() -> void:
	service.cancel_ability_target(state)
	_render_match()


func _resolve_reaction(hand_index: int) -> void:
	if animation_busy:
		return
	_cancel_reaction_countdown()
	animation_busy = true
	service.resolve_reaction(state, hand_index, false)
	await _drain_animation_event_queue()
	animation_busy = false
	_render_match()
	if String(state.phase) == "opponent_turn" and state.get("pending_reaction", {}).is_empty():
		_run_opponent_sequence()


func _on_end_turn_pressed() -> void:
	if opponent_running or animation_busy:
		return
	if tutorial_mode:
		if not _tutorial_complete_action("end_turn"):
			return
		selected_ref = {}
		_render_match()
		return
	animation_busy = true
	service.end_player_turn(state, true)
	selected_ref = {}
	await _drain_animation_event_queue()
	animation_busy = false
	_render_match()
	if String(state.phase) == "opponent_turn":
		animation_busy = true
		await _show_turn_banner("opponent_turn")
		animation_busy = false
		_render_match()
		_run_opponent_sequence()


func _run_opponent_sequence() -> void:
	if opponent_running:
		return
	opponent_running = true
	while String(state.phase) == "opponent_turn" and state.get("pending_reaction", {}).is_empty() and not bool(state.game_over):
		await get_tree().create_timer(0.42).timeout
		animation_busy = true
		var phase_before_action := String(state.get("phase", ""))
		service.advance_opponent_turn(state)
		var phase_after_action := String(state.get("phase", ""))
		if phase_before_action != phase_after_action and phase_after_action == "player_main":
			await _show_turn_banner("player_main")
		await _drain_animation_event_queue()
		animation_busy = false
		_render_match()
	opponent_running = false


func _update_chef_labels() -> void:
	(player_chef.get_node("Label") as Label3D).text = "YOU\n%d" % int(state.player.life)
	var rival_text := "RIVAL\n%d" % int(state.opponent.life)
	if tutorial_mode and String(_tutorial_step().get("action", "")) == "attack_chef":
		rival_text += "\nCLICK TO ATTACK"
	(opponent_chef.get_node("Label") as Label3D).text = rival_text


func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		child.free()


func _label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _add_action_button(text_value: String, callback: Callable, disabled := false) -> void:
	var button := _styled_button(text_value)
	button.disabled = disabled
	button.pressed.connect(callback)
	action_list.add_child(button)


func _add_prompt_title(text_value: String) -> void:
	var title := _label(text_value, 23, Color("#fff0c2"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_content.add_child(title)


func _add_prompt_text(text_value: String) -> void:
	var text_label := _label(text_value, 15, Color("#e6edf2"))
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_content.add_child(text_label)


func _add_prompt_button(text_value: String, callback: Callable, disabled := false) -> void:
	var button := _styled_button(text_value)
	button.disabled = disabled
	button.pressed.connect(callback)
	prompt_content.add_child(button)


func _styled_button(text_value: String) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(0, 35)
	button.add_theme_font_size_override("font_size", 14)
	_apply_rounded_button_style(button)
	return button


func _apply_rounded_button_style(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#173e52")
	normal.border_color = Color("#e7a946")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(10)
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#245c73")
	button.add_theme_stylebox_override("hover", hover)
	var pressed := hover.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("#102d3c")
	button.add_theme_stylebox_override("pressed", pressed)
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color("#111b21")
	disabled.border_color = Color("#6f654f")
	button.add_theme_stylebox_override("disabled", disabled)
