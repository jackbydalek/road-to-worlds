extends Control

signal exit_requested
signal match_finished(result: Dictionary)
signal settings_requested
signal battle_preferences_changed(play_speed_id: String, battle_text_scale: float)

const CARD_FACE_SCRIPT := preload("res://scripts/CardFace.gd")
const COMBAT_SERVICE_SCRIPT := preload("res://scripts/cooking/CookingCombatService.gd")
const CARD_BACK := preload("res://assets/cards/card_backs/living_table.png")
const CARD_BACK_FRAME := preload("res://assets/cards/card_backs/card_back_frame.svg")
const ART_PENDING := preload("res://assets/cards/art_pending.png")
const ABILITY_READY_AURA := preload("res://assets/ui/ability_ready_aura.svg")
const ABILITY_READY_SPARKLES := preload("res://assets/ui/ability_ready_sparkles.svg")
const MEAL_CANDIDATE_AURA := preload("res://assets/ui/meal_candidate_aura.svg")
const MEAL_SELECTED_AURA := preload("res://assets/ui/meal_selected_aura.svg")
const TAUNT_AURA := preload("res://assets/ui/taunt_aura.svg")
const STAT_BADGE_BACKING := preload("res://assets/ui/field_stat_badge.svg")
const READABLE_FONT := preload("res://assets/fonts/AtkinsonHyperlegibleNext.ttf")
const UI_THEME_SCRIPT := preload("res://scripts/ui/KitchenGlassTheme.gd")
const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const LOFI_OUTLINE := preload("res://scripts/ui/LofiOutline.gd")
const PICK_CARD_SOUNDS := [
	preload("res://assets/audio/cards/817546__silverdubloons__pickupcard00.wav"),
	preload("res://assets/audio/cards/817547__silverdubloons__pickupcard01.wav"),
	preload("res://assets/audio/cards/817548__silverdubloons__pickupcard02.wav"),
	preload("res://assets/audio/cards/817549__silverdubloons__pickupcard03.wav"),
	preload("res://assets/audio/cards/817550__silverdubloons__pickupcard04.wav"),
	preload("res://assets/audio/cards/817551__silverdubloons__pickupcard05.wav")
]
const DROP_CARD_SOUNDS := [
	preload("res://assets/audio/cards/817540__silverdubloons__dropcard01.wav"),
	preload("res://assets/audio/cards/817541__silverdubloons__dropcard02.wav"),
	preload("res://assets/audio/cards/817542__silverdubloons__dropcard03.wav"),
	preload("res://assets/audio/cards/817543__silverdubloons__dropcard04.wav"),
	preload("res://assets/audio/cards/817544__silverdubloons__dropcard05.wav")
]
const SLIDE_CARD_SOUNDS := [
	preload("res://assets/audio/cards/817576__silverdubloons__slidecard01.wav"),
	preload("res://assets/audio/cards/817577__silverdubloons__slidecard02.wav"),
	preload("res://assets/audio/cards/817579__silverdubloons__slidecard04.wav"),
	preload("res://assets/audio/cards/817580__silverdubloons__slidecard05.wav")
]
const SHUFFLE_SOUNDS := [
	preload("res://assets/audio/cards/817569__silverdubloons__shuffle00.wav"),
	preload("res://assets/audio/cards/817570__silverdubloons__shuffle01.wav"),
	preload("res://assets/audio/cards/817571__silverdubloons__shuffle02.wav"),
	preload("res://assets/audio/cards/817573__silverdubloons__shuffle04.wav"),
	preload("res://assets/audio/cards/817574__silverdubloons__shuffle05.wav")
]
const CARD_IMPACT_SOUNDS := [
	preload("res://assets/audio/combat_hit_thud.mp3")
]
const INGREDIENT_CHEF_IMPACT_SOUNDS := [
	preload("res://assets/audio/combat_hit_thud.mp3")
]
const MEAL_CHEF_IMPACT_SOUNDS := [
	preload("res://assets/audio/combat_hit_ground.mp3")
]
const EFFECT_DAMAGE_SOUNDS := [
	preload("res://assets/audio/kenney_impacts/impactGlass_light_000.ogg"),
	preload("res://assets/audio/kenney_impacts/impactGlass_light_001.ogg"),
	preload("res://assets/audio/kenney_impacts/impactGlass_light_002.ogg"),
	preload("res://assets/audio/kenney_impacts/impactGlass_light_003.ogg"),
	preload("res://assets/audio/kenney_impacts/impactGlass_light_004.ogg")
]
const MEAL_SUMMON_SOUND := preload("res://assets/audio/meal_summon_epic_spell_impact.mp3")
const ABILITY_ACTIVATION_SOUND := preload("res://assets/audio/ability_activation_healing_magic.mp3")
const POSITIVE_EFFECT_SOUND := preload("res://assets/audio/531087__ryusa__magic-spell-buff-bell-sparkle-reverb.wav")
const MEAL_SUMMON_VOLUME_DB := -10.0
const MEAL_SUMMON_SOUND_DELAY_SECONDS := 0.44
const ABILITY_ACTIVATION_VOLUME_DB := 0.0
const POSITIVE_EFFECT_VOLUME_DB := -7.0
const POSITIVE_EFFECT_SOUND_COOLDOWN_MSEC := 160
const CARD_IMPACT_VOLUME_DB := -5.0
const INGREDIENT_CHEF_IMPACT_VOLUME_DB := -3.0
const MEAL_CHEF_IMPACT_VOLUME_DB := -4.0
const MEAL_CHEF_IMPACT_START_OFFSET_SECONDS := 0.28
const EFFECT_DAMAGE_VOLUME_DB := -3.0
const IMPACT_PITCH_VARIATION := 0.03
const VFX_OUTLINE_WIDTH := 2.5

const TABLE_Y := 0.235
const DRAG_Y := 0.82
const FIELD_CARD_SIZE := Vector2(1.14, 1.62)
const FIELD_BADGE_MAX_WIDTH := FIELD_CARD_SIZE.x - 0.12
const ARENA_OUTLINE_COLOR := Color("#29365F")
const TABLE_OUTLINE_WIDTH := 0.032
const ZONE_OUTLINE_WIDTH := 0.018
const CHEF_OUTLINE_WIDTH := 0.026
const PLATED_CARD_SCALE := 1.20
const PLATED_FLOATING_ART_SCALE := 1.18
const INSPECTOR_CARD_SIZE := Vector2(272, 386)
const ACTION_REVEAL_CARD_SIZE := Vector2(350, 498)
# Anchor the player's cards against the near table edge so the center stays open.
const PLAYER_HAND_Z := 4.45
const OPPONENT_HAND_Z := -5.5
const PLAYER_HAND_MAX_WIDTH := 8.8
const OPPONENT_HAND_MAX_WIDTH := 6.6
const HAND_CARD_GAP := 0.14
const CARD_FACE_TEXTURE_SIZE := Vector2i(320, 455)
const FLOATING_ART_HEIGHT := 0.62
const REACTION_WINDOW_SECONDS := 5.0
const READABILITY_SETTINGS_PATH := "user://road_to_worlds_readability.cfg"
const RIVAL_PACING_OPTIONS := [
	{"id": "fast", "label": "FAST", "base_seconds": 0.7, "seconds_per_word": 0.08, "max_seconds": 1.8, "action_gap": 0.22},
	{"id": "normal", "label": "NORMAL", "base_seconds": 1.2, "seconds_per_word": 0.16, "max_seconds": 3.5, "action_gap": 0.42},
	{"id": "slow", "label": "SLOW", "base_seconds": 1.8, "seconds_per_word": 0.22, "max_seconds": 5.0, "action_gap": 0.7}
]
const DEFAULT_TEXT_SCALE := 1.0
const DEFAULT_TEXT_SCALE_INDEX := 0
const TEXT_SCALE_OPTIONS := [DEFAULT_TEXT_SCALE, 1.25, 1.5]
const BASE_TEXT_READABILITY_SCALE := 1.15
const KEYWORD_TOOLTIPS := {
	"stalwart": {"title": "Stalwart", "body": "This card can attack the opposing Chef even while they control Plated cards."},
	"piercing": {"title": "Piercing", "body": "When this card overpowers a Defending unit, excess combat damage reaches the opposing Chef."},
	"defending": {"title": "Defending", "body": "This unit did not attack last turn. It stops excess combat damage unless struck by Piercing; units that attacked remain exposed to normal overflow."},
	"taunt": {"title": "Taunt", "body": "While any Taunt unit is Plated, attackers must target a Taunt before other cards or the Chef. If there are multiple Taunt units, the attacker chooses among them."},
	"hand_trap": {"title": "Handtrap", "body": "Discard this card from your hand to perform its action in response to an opponent's action."}
}
const TUTORIAL_STEPS := [
	{"lesson": 1, "title": "Welcome to the Table", "body": "Both Chefs normally begin at 20 life. The first player skips their opening draw; the second player draws normally. On later turns, draw one card, then draw up to two if your hand is still smaller. Ingredients and Meals occupy Prep or Plated.", "prompt": "Press Begin to learn by playing a fixed practice hand.", "action": "continue", "scenario": "opening"},
	{"lesson": 2, "title": "Play an Ingredient", "body": "Ingredients build recipes. New Ingredients are PREPARING until the start of your next turn.", "prompt": "Click the glowing Hot Honey Bee in your hand.", "action": "select_hand", "card_id": "spicy_hot_honey_bee"},
	{"lesson": 2, "title": "Choose a Safe Zone", "body": "Prep protects a card from normal attacks while it matures. Plated cards can fight, but can also be attacked.", "prompt": "In Card Info, choose Play → Prep 2.", "action": "play_hand", "card_id": "spicy_hot_honey_bee", "zone": "prep", "slot": 1},
	{"lesson": 2, "title": "Let It Mature", "body": "At the start of your next turn, the Ingredient becomes RECIPE READY. Normal matches give the rival a full turn in between.", "prompt": "Press END TURN. The lesson will fast-forward the scripted rival turn.", "action": "end_turn"},
	{"lesson": 3, "title": "Set an Environment", "body": "Environments stay in their own slot and change the rules of your kitchen. Playing another replaces the old one.", "prompt": "Click the glowing spicy taquería.", "action": "select_hand", "card_id": "environment_spicy_taqueria", "scenario": "recipe"},
	{"lesson": 3, "title": "Use the Environment", "body": "spicy taquería gives each Spicy food you serve +2 Attack.", "prompt": "Choose Use Environment in Card Info.", "action": "play_hand", "card_id": "environment_spicy_taqueria"},
	{"lesson": 4, "title": "Serve a Meal", "body": "Meals are stronger units, but they require RECIPE READY Ingredients that match every symbol in their recipe.", "prompt": "Click the glowing Sriracharrow in your hand.", "action": "select_hand", "card_id": "spicy_sriracharrow"},
	{"lesson": 4, "title": "Choose Its Zone", "body": "You may serve one Meal each turn. This one will enter Prep, using the slot its Ingredient is about to vacate.", "prompt": "Choose Serve → Prep 2 (Sacrifice).", "action": "begin_meal", "card_id": "spicy_sriracharrow", "zone": "prep", "slot": 1},
	{"lesson": 4, "title": "Pay the Recipe", "body": "The cyan glow marks legal recipe Ingredients. The selected Ingredient will be sacrificed to your discard pile.", "prompt": "Click the glowing Hot Honey Bee on your table.", "action": "select_recipe", "card_id": "spicy_hot_honey_bee"},
	{"lesson": 4, "title": "Confirm the Meal", "body": "Sriracharrow needs one Spicy Ingredient. The selected Bee satisfies the full recipe.", "prompt": "Press Serve Meal in the message strip.", "action": "confirm_meal"},
	{"lesson": 5, "title": "Prep Versus Plated", "body": "A unit in Prep is safe but normally cannot attack. You may move one unit between Prep and Plated each turn.", "prompt": "Click your glowing Sriracharrow.", "action": "select_field", "card_id": "spicy_sriracharrow"},
	{"lesson": 5, "title": "Move Into Combat", "body": "Moving into Plated makes a unit available for combat immediately, unless another rule says otherwise.", "prompt": "Click the glowing Plated 1 slot.", "action": "move_unit", "card_id": "spicy_sriracharrow", "zone": "plated", "slot": 0},
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
	{"lesson": 7, "title": "Clear Their Plated Zone", "body": "If the rival has a Plated unit, you must attack a legal defender before attacking their Chef. A unit that skips attacking ends the turn Defending and stops overflow unless hit by Piercing. A unit that attacked is exposed to normal overflow. Stalwart can attack the Chef through Plated cards.", "prompt": "Click the glowing opposing Bagver.", "action": "attack_unit", "target_instance_id": 3},
	{"lesson": 7, "title": "Choose Your Second Attacker", "body": "Your first Meal is spent, but the second is still ready.", "prompt": "Click the glowing right Sriracharrow.", "action": "select_field", "instance_id": 2},
	{"lesson": 7, "title": "Declare the Final Attack", "body": "The rival Plated zone is empty, so a direct Chef attack is now legal.", "prompt": "Choose Choose Attacker.", "action": "select_attacker", "instance_id": 2},
	{"lesson": 7, "title": "Attack the Rival Chef", "body": "Reducing the opposing Chef to 0 life wins the match.", "prompt": "Click the glowing rival Chef.", "action": "attack_chef"},
	{"lesson": 7, "title": "Tutorial Complete", "body": "You played an Ingredient, matured and sacrificed it, served and moved a Meal, used support cards, cleared a defender, and won with a direct attack.", "prompt": "Return to the title screen when you are ready.", "action": "finish"}
]
const ZONE_CENTERS := {
	"player_prep": Vector3(0.0, TABLE_Y, 2.25),
	"player_plated": Vector3(0.0, TABLE_Y, 0.15),
	"opponent_plated": Vector3(0.0, TABLE_Y, -2.25),
	"opponent_prep": Vector3(0.0, TABLE_Y, -4.45)
}
const ZONE_EXTENTS := {
	"player_prep": Vector2(2.8, 0.82),
	"player_plated": Vector2(2.0, 0.82),
	"opponent_plated": Vector2(2.0, 0.82),
	"opponent_prep": Vector2(2.8, 0.82)
}
const AUX_ZONE_POSITIONS := {
	"player_deck": Vector3(5.05, TABLE_Y, 4.05),
	"player_discard": Vector3(5.05, TABLE_Y, 2.15),
	"player_environment": Vector3(-5.05, TABLE_Y, 0.7),
	"opponent_deck": Vector3(-5.05, TABLE_Y, -4.9),
	"opponent_discard": Vector3(-5.05, TABLE_Y, -3.0),
	"opponent_environment": Vector3(5.05, TABLE_Y, -2.7)
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
@onready var status_context_label: Label = $Interface/StatusPanel/Margin/StatusRow/StatusContext
@onready var status_panel: PanelContainer = $Interface/StatusPanel
@onready var title_label: Label = $Interface/TopBar/Margin/TopRow/Title
@onready var confirm_choice_button: Button = $Interface/StatusPanel/Margin/StatusRow/ConfirmChoiceButton
@onready var cancel_choice_button: Button = $Interface/StatusPanel/Margin/StatusRow/CancelChoiceButton
@onready var effect_layer: Control = $Interface/EffectLayer
@onready var action_panel: PanelContainer = $Interface/ActionPanel
@onready var action_scroll: ScrollContainer = $Interface/ActionPanel/Margin/InspectorScroll
@onready var action_list: VBoxContainer = $Interface/ActionPanel/Margin/InspectorScroll/Actions
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
@onready var settings_button: Button = $Interface/TopBar/Margin/TopRow/SettingsButton
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
var pulsing_field_auras: Array[MeshInstance3D] = []
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
var ability_activation_sound_player: AudioStreamPlayer
var last_positive_effect_sound_msec := -POSITIVE_EFFECT_SOUND_COOLDOWN_MSEC
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
var configured_resume_snapshot: Dictionary = {}
var result_emitted := false
var manual_discard_tray_side := ""
var camera_home_transform := Transform3D.IDENTITY
var camera_home_fov := 43.0
var camera_pacing_tween: Tween
@export var reduced_motion := false
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
var rival_action_panel: PanelContainer
var rival_action_face: TextureRect
var rival_action_name_label: Label
var rival_action_meta_label: Label
var rival_action_rules_label: Label
var rival_action_outcome_label: Label
var rival_recent_actions_label: RichTextLabel
var game_breakdown_button: Button
var rival_pacing_button: Button
var text_scale_button: Button
var match_options_button: Button
var readability_controls_panel: PanelContainer
var board_info_button: Button
var board_info_visible := false
var invalid_action_visible := false
var invalid_action_timer: Timer
var rival_recent_actions: Array[String] = []
var latest_rival_card_id := ""
var latest_rival_card_data: Dictionary = {}
var latest_rival_summary: Dictionary = {}
var game_breakdown_active := false
var rival_pacing_index := 1
var text_scale_index := DEFAULT_TEXT_SCALE_INDEX
var reveal_active := false
var reveal_skip_requested := false
var fullscreen_action_reveal_count := 0
var last_fullscreen_action_reveal_card_id := ""
var last_fullscreen_action_reveal_type := ""
var last_fullscreen_action_reveal_hold_seconds := 0.0
var field_activation_indicator_count := 0
var last_field_activation_card_id := ""
var last_field_activation_kind := ""
var swap_move_animation_count := 0
var token_evaporation_animation_count := 0
var action_highlight_zone := ""
var action_highlight_slot := -1
var action_highlight_slots: Array[Dictionary] = []
var pending_hand_play_index := -1
var pending_move_instance_id := -1
var keyword_popout: PanelContainer


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


func configure_resume_snapshot(snapshot: Dictionary) -> void:
	configured_resume_snapshot = snapshot.duplicate(true)


func capture_match_snapshot() -> Dictionary:
	if state.is_empty() or service == null:
		return {}
	var saved_state := state.duplicate(true)
	# Presentation events are transient. Restoring their completed rules state is
	# safer than replaying half-finished movement or impact animations.
	saved_state["animation_events"] = []
	return {
		"version": 1,
		"state": saved_state,
		"rng_state": service.rng.state
	}


func configure_tutorial() -> void:
	tutorial_mode = true
	configured_player_name = "Teaching Kitchen"
	configured_opponent_name = "Practice Rival"
	configured_exit_label = "Exit to Title"
	configured_card_border_id = "white"


func configure_battle_preferences(play_speed_id: String, battle_text_scale: float) -> void:
	for option_index in range(RIVAL_PACING_OPTIONS.size()):
		if String(RIVAL_PACING_OPTIONS[option_index].id) == play_speed_id:
			rival_pacing_index = option_index
			break
	var closest_distance := INF
	for option_index in range(TEXT_SCALE_OPTIONS.size()):
		var distance := absf(float(TEXT_SCALE_OPTIONS[option_index]) - battle_text_scale)
		if distance < closest_distance:
			closest_distance = distance
			text_scale_index = option_index
	if is_node_ready():
		_apply_text_scale()
		_refresh_readability_control_labels()


func _ready() -> void:
	theme = UI_THEME_SCRIPT.build(READABLE_FONT)
	_apply_glass_surface_styles()
	camera.look_at(Vector3(0.0, 0.25, -0.75), Vector3.UP)
	camera_home_transform = camera.global_transform
	camera_home_fov = camera.fov
	_build_pacing_interface()
	_build_readability_interface()
	viewport_container.gui_input.connect(_on_table_gui_input)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	reset_button.pressed.connect(_start_match)
	settings_button.pressed.connect(func() -> void: settings_requested.emit())
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
	_apply_high_contrast_button_text(end_turn_button)
	_apply_current_ui_button_style(end_turn_button, true)
	_apply_rounded_button_style(reset_button)
	_apply_high_contrast_button_text(reset_button)
	_apply_current_ui_button_style(reset_button, false)
	_apply_rounded_button_style(settings_button)
	_apply_high_contrast_button_text(settings_button)
	_apply_current_ui_button_style(settings_button, false)
	_apply_rounded_button_style(exit_button)
	_apply_high_contrast_button_text(exit_button)
	_apply_current_ui_button_style(exit_button, false)
	_apply_rounded_button_style(battle_log_button)
	_apply_high_contrast_button_text(battle_log_button)
	_apply_current_ui_button_style(battle_log_button, false)
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
		exit_button.text = "LEAVE MATCH"
		exit_button.custom_minimum_size.x = 126
	if tutorial_mode:
		reset_button.visible = false
		exit_button.text = "EXIT TUTORIAL"
		exit_button.custom_minimum_size.x = 132
		battle_log_button.visible = false
		_build_tutorial_interface()
	_load_reference_art()
	_apply_lofi_arena_outlines()
	_prepare_zone_materials()
	_start_match()
	for button_node in $Interface.find_children("*", "Button", true, false):
		_bind_illustrated_button_feedback(button_node as Button)
	set_process(true)


func _apply_glass_surface_styles() -> void:
	($Interface/TopBar as PanelContainer).add_theme_stylebox_override(
		"panel",
		UI_THEME_SCRIPT.light_glass_style(PALETTE.PERIWINKLE, 2)
	)
	($Interface/StatusPanel as PanelContainer).add_theme_stylebox_override(
		"panel",
		UI_THEME_SCRIPT.light_glass_style(PALETTE.SKY, 2)
	)
	prompt_panel.add_theme_stylebox_override("panel", UI_THEME_SCRIPT.light_glass_style(PALETTE.BLUSH, 2))
	battle_log_panel.add_theme_stylebox_override("panel", UI_THEME_SCRIPT.light_glass_style(PALETTE.PERIWINKLE, 2))
	battle_log_text.add_theme_color_override("default_color", PALETTE.NAVY)
	var battle_log_title := battle_log_panel.find_child("Title", true, false) as Label
	if battle_log_title != null:
		battle_log_title.add_theme_color_override("font_color", PALETTE.NAVY)
	for label in [title_label, turn_label, status_label, status_context_label]:
		label.add_theme_color_override("font_color", PALETTE.NAVY)
	_apply_match_hud_styles()


func _apply_lofi_arena_outlines() -> void:
	var world := $ViewportContainer/WorldViewport/World
	var table_surface := world.get_node_or_null("Table")
	if table_surface != null:
		LOFI_OUTLINE.apply_to_mesh_tree(table_surface, TABLE_OUTLINE_WIDTH, ARENA_OUTLINE_COLOR)
		table_surface.set_meta("lofi_arena_outline", true)
	var zones := world.get_node_or_null("Zones")
	if zones != null:
		LOFI_OUTLINE.apply_to_mesh_tree(zones, ZONE_OUTLINE_WIDTH, ARENA_OUTLINE_COLOR)
		zones.set_meta("lofi_arena_outline", true)
	for chef_path in ["PlayerChef", "OpponentChef"]:
		var chef := world.get_node_or_null(chef_path)
		if chef != null:
			LOFI_OUTLINE.apply_to_mesh_tree(chef, CHEF_OUTLINE_WIDTH, ARENA_OUTLINE_COLOR)
			chef.set_meta("lofi_arena_outline", true)


func _apply_match_hud_styles() -> void:
	var player_style := UI_THEME_SCRIPT.tinted_paper_style(PALETTE.SKY, 2)
	player_style.content_margin_left = 10
	player_style.content_margin_right = 10
	player_life.add_theme_stylebox_override("normal", player_style)
	player_life.add_theme_color_override("font_color", PALETTE.NAVY)
	var rival_style := UI_THEME_SCRIPT.tinted_paper_style(PALETTE.CORAL, 2)
	rival_style.content_margin_left = 10
	rival_style.content_margin_right = 10
	opponent_life.add_theme_stylebox_override("normal", rival_style)
	opponent_life.add_theme_color_override("font_color", PALETTE.NAVY)
	_refresh_turn_badge_style()


func _refresh_turn_badge_style() -> void:
	if state.is_empty() or turn_label == null:
		return
	var player_turn := String(state.get("phase", "")) == "player_main"
	var accent := PALETTE.SKY if player_turn else PALETTE.CORAL
	var turn_style := UI_THEME_SCRIPT.tinted_paper_style(accent, 2)
	turn_style.content_margin_left = 12
	turn_style.content_margin_right = 12
	turn_label.add_theme_stylebox_override("normal", turn_style)
	turn_label.add_theme_color_override("font_color", PALETTE.NAVY)


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
	if rival_action_panel != null:
		rival_action_panel.visible = false
	if battle_log_panel != null:
		_set_battle_log_visible(false)
	rival_recent_actions.clear()
	latest_rival_card_id = ""
	latest_rival_card_data = {}
	latest_rival_summary = {}
	game_breakdown_active = false
	if is_instance_valid(game_breakdown_button):
		game_breakdown_button.disabled = true
	action_highlight_zone = ""
	action_highlight_slot = -1
	action_highlight_slots.clear()
	pending_hand_play_index = -1
	pending_move_instance_id = -1
	_clear_keyword_popout()
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
	if production_match and not configured_resume_snapshot.is_empty():
		var resumed_state: Variant = configured_resume_snapshot.get("state", {})
		if resumed_state is Dictionary and not (resumed_state as Dictionary).is_empty():
			state = (resumed_state as Dictionary).duplicate(true)
			service.clear_animation_events(state)
			service.rng.state = int(configured_resume_snapshot.get("rng_state", service.rng.state))
	selected_ref = {}
	dragging = false
	pressed_card = null
	opponent_running = false
	_render_match()
	if tutorial_mode:
		_refresh_tutorial_panel()
	else:
		call_deferred("_begin_match_pacing")


func _exit_tree() -> void:
	_reset_camera_pacing()
	camera_pacing_tween = null
	for player_node in find_children("*", "AudioStreamPlayer", true, false):
		var player := player_node as AudioStreamPlayer
		player.stop()
		player.stream = null


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
	panel_style.bg_color = Color("#24213F", 0.96)
	panel_style.border_color = Color("#8299D0")
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

	tutorial_progress_label = _label("", 12, Color("#8299D0"))
	content.add_child(tutorial_progress_label)
	tutorial_title_label = _label("", 24, Color("#E9DFEE"))
	content.add_child(tutorial_title_label)
	tutorial_body_label = _label("", 14, Color("#D7CBE0"))
	tutorial_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(tutorial_body_label)
	tutorial_prompt_label = _label("", 15, Color("#D5C16D"))
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
			state.player.hand = ["environment_spicy_taqueria", "spicy_sriracharrow", "item_wooden_spoon"]
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
		who.life = service.STARTING_LIFE
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
	pulsing_field_auras.clear()
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
	player_life.text = "YOU  •  %d LIFE" % int(state.player.life)
	opponent_life.text = "RIVAL  •  %d LIFE" % int(state.opponent.life)
	var player_turn := String(state.phase) == "player_main"
	turn_label.text = "%s  •  TURN %d" % ["YOUR TURN" if player_turn else "RIVAL TURN", int(state.turn)]
	_refresh_turn_badge_style()
	_update_match_title()
	end_turn_button.disabled = animation_busy or String(state.phase) != "player_main" or _has_blocking_prompt() or bool(state.game_over)
	if tutorial_mode:
		end_turn_button.disabled = String(_tutorial_step().get("action", "")) != "end_turn"
	_refresh_end_turn_button()
	_update_chef_labels()
	_refresh_action_panel()
	_refresh_prompt()
	_refresh_card_tray()
	_refresh_bottom_status()
	_refresh_status_context()
	_refresh_status_panel_visibility()
	_refresh_battle_log()
	if tutorial_mode:
		_refresh_tutorial_panel()
	if bool(state.get("game_over", false)) and not animation_busy and not tutorial_mode:
		_queue_outcome_sequence()


func _update_match_title() -> void:
	if tutorial_mode:
		title_label.text = "GUIDED PRACTICE"
		return
	if not production_match:
		title_label.text = "PRACTICE MATCH"
		return
	var event_name := String(configured_match_context.get("event_name", ""))
	var round_number := int(configured_match_context.get("round", 0))
	var total_rounds := int(configured_match_context.get("rounds", 0))
	if bool(configured_match_context.get("tournament_round", false)) and round_number > 0:
		title_label.text = "%s  •  ROUND %d OF %d" % [event_name if event_name != "" else "TOURNAMENT", round_number, maxi(round_number, total_rounds)]
	else:
		title_label.text = "%s  vs  %s" % [configured_player_name, configured_opponent_name]


func _refresh_end_turn_button() -> void:
	if bool(state.get("game_over", false)):
		end_turn_button.text = "MATCH COMPLETE"
	elif _has_blocking_prompt():
		end_turn_button.text = "FINISH CHOICE"
	elif String(state.get("phase", "")) != "player_main":
		end_turn_button.text = "RIVAL THINKING…"
	else:
		end_turn_button.text = "END TURN  →"


func _refresh_status_context() -> void:
	if status_context_label == null or state.is_empty():
		return
	if invalid_action_visible:
		status_context_label.text = "NOT ALLOWED"
		status_context_label.add_theme_color_override("font_color", UI_THEME_SCRIPT.ORANGE)
	elif bool(state.get("game_over", false)):
		status_context_label.text = "MATCH END"
		status_context_label.add_theme_color_override("font_color", UI_THEME_SCRIPT.OAK)
	elif _has_blocking_prompt():
		status_context_label.text = "CHOOSE"
		status_context_label.add_theme_color_override("font_color", UI_THEME_SCRIPT.ORANGE)
	elif String(state.get("phase", "")) == "player_main":
		status_context_label.text = "YOUR MOVE"
		status_context_label.add_theme_color_override("font_color", UI_THEME_SCRIPT.TEAL_LIGHT)
	else:
		status_context_label.text = "RIVAL MOVE"
		status_context_label.add_theme_color_override("font_color", UI_THEME_SCRIPT.ORANGE)


func _refresh_status_panel_visibility() -> void:
	if status_panel == null or state.is_empty():
		return
	status_panel.visible = invalid_action_visible or confirm_choice_button.visible or cancel_choice_button.visible


func _show_invalid_action(message: String) -> void:
	if message.strip_edges() == "":
		message = "That action is not available right now."
	var ui_sounds := get_tree().get_first_node_in_group("ui_sound_controller")
	if ui_sounds != null and ui_sounds.has_method("play_error"):
		ui_sounds.call("play_error")
	invalid_action_visible = true
	status_label.text = message
	_refresh_status_context()
	_refresh_status_panel_visibility()
	if not is_instance_valid(invalid_action_timer):
		invalid_action_timer = Timer.new()
		invalid_action_timer.name = "InvalidActionTimer"
		invalid_action_timer.one_shot = true
		invalid_action_timer.wait_time = 2.6
		invalid_action_timer.timeout.connect(_dismiss_invalid_action)
		add_child(invalid_action_timer)
	invalid_action_timer.start()


func _dismiss_invalid_action() -> void:
	if is_instance_valid(invalid_action_timer):
		invalid_action_timer.stop()
	invalid_action_visible = false
	if not state.is_empty():
		_refresh_bottom_status()
		_refresh_status_context()
	_refresh_status_panel_visibility()


func _action_attempt_marker() -> Dictionary:
	return {
		"hand_size": state.get("player", {}).get("hand", []).size(),
		"log_size": state.get("log", []).size(),
		"animation_size": state.get("animation_events", []).size(),
		"pending_meal": not state.get("pending_meal", {}).is_empty(),
		"pending_discard": not state.get("pending_discard", {}).is_empty(),
		"pending_ability": not state.get("pending_ability", {}).is_empty(),
		"pending_search": not state.get("pending_search", {}).is_empty(),
		"pending_choice": not state.get("pending_choice", {}).is_empty(),
		"pending_reaction": not state.get("pending_reaction", {}).is_empty(),
	}


func _action_attempt_progressed(marker: Dictionary) -> bool:
	return (
		state.get("player", {}).get("hand", []).size() != int(marker.get("hand_size", 0))
		or state.get("log", []).size() != int(marker.get("log_size", 0))
		or state.get("animation_events", []).size() != int(marker.get("animation_size", 0))
		or (not state.get("pending_meal", {}).is_empty()) != bool(marker.get("pending_meal", false))
		or (not state.get("pending_discard", {}).is_empty()) != bool(marker.get("pending_discard", false))
		or (not state.get("pending_ability", {}).is_empty()) != bool(marker.get("pending_ability", false))
		or (not state.get("pending_search", {}).is_empty()) != bool(marker.get("pending_search", false))
		or (not state.get("pending_choice", {}).is_empty()) != bool(marker.get("pending_choice", false))
		or (not state.get("pending_reaction", {}).is_empty()) != bool(marker.get("pending_reaction", false))
	)


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
	var banner_style := UI_THEME_SCRIPT.tinted_paper_style(PALETTE.PERIWINKLE, 3)
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
	turn_banner_title = _label("YOUR TURN", 34, PALETTE.NAVY)
	turn_banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_banner_title.add_theme_color_override("font_outline_color", Color(PALETTE.GHOST, 0.9))
	turn_banner_title.add_theme_constant_override("outline_size", 4)
	banner_content.add_child(turn_banner_title)
	turn_banner_subtitle = _label("TURN 1", 16, PALETTE.SLATE)
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


func _build_readability_interface() -> void:
	rival_action_panel = PanelContainer.new()
	rival_action_panel.name = "RivalActionPanel"
	rival_action_panel.visible = false
	rival_action_panel.z_index = 18
	rival_action_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	rival_action_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	rival_action_panel.offset_left = -508.0
	rival_action_panel.offset_top = 84.0
	rival_action_panel.offset_right = -18.0
	rival_action_panel.offset_bottom = 404.0
	var action_style := StyleBoxFlat.new()
	action_style.bg_color = Color("#24213F", 0.97)
	action_style.border_color = Color("#C477A8")
	action_style.set_border_width_all(2)
	action_style.set_corner_radius_all(16)
	action_style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	action_style.shadow_size = 12
	rival_action_panel.add_theme_stylebox_override("panel", action_style)
	$Interface.add_child(rival_action_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	rival_action_panel.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 7)
	margin.add_child(content)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	content.add_child(header)
	var heading := _label("RIVAL ACTION", 17, Color("#D38BBC"))
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(heading)
	game_breakdown_button = _styled_button("Game Breakdown")
	game_breakdown_button.name = "GameBreakdownButton"
	game_breakdown_button.custom_minimum_size = Vector2(148, 30)
	game_breakdown_button.disabled = true
	game_breakdown_button.pressed.connect(_open_game_breakdown)
	header.add_child(game_breakdown_button)
	var close_button := _styled_button("Hide")
	close_button.name = "RivalActionCloseButton"
	close_button.custom_minimum_size = Vector2(68, 30)
	close_button.pressed.connect(func() -> void: rival_action_panel.visible = false)
	header.add_child(close_button)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(body)
	rival_action_face = TextureRect.new()
	rival_action_face.name = "RivalActionCard"
	rival_action_face.custom_minimum_size = Vector2(110, 156)
	rival_action_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rival_action_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rival_action_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(rival_action_face)
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 4)
	body.add_child(details)
	rival_action_name_label = _label("Card name", 23, Color("#fff3cf"))
	rival_action_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(rival_action_name_label)
	rival_action_meta_label = _label("Card type", 14, Color("#f1c66e"))
	details.add_child(rival_action_meta_label)
	rival_action_rules_label = _label("Printed rules", 16, Color("#edf4f6"))
	rival_action_rules_label.custom_minimum_size = Vector2(0, 60)
	rival_action_rules_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rival_action_rules_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	rival_action_rules_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	rival_action_rules_label.add_theme_constant_override("line_spacing", 3)
	details.add_child(rival_action_rules_label)
	rival_action_outcome_label = _label("What resolved", 15, Color("#8fddf5"))
	rival_action_outcome_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rival_action_outcome_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	rival_action_outcome_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	details.add_child(rival_action_outcome_label)

	var recent_heading := _label("RECENT RIVAL MOVES", 12, Color("#f2a0c5"))
	content.add_child(recent_heading)
	rival_recent_actions_label = RichTextLabel.new()
	rival_recent_actions_label.name = "RivalRecentActions"
	rival_recent_actions_label.custom_minimum_size = Vector2(0, 48)
	rival_recent_actions_label.bbcode_enabled = true
	rival_recent_actions_label.fit_content = false
	rival_recent_actions_label.scroll_active = false
	rival_recent_actions_label.add_theme_font_override("normal_font", READABLE_FONT)
	rival_recent_actions_label.add_theme_font_size_override("normal_font_size", _scaled_font_size(13))
	rival_recent_actions_label.set_meta("readability_base_font_normal_font_size", 13)
	content.add_child(rival_recent_actions_label)

	readability_controls_panel = PanelContainer.new()
	readability_controls_panel.name = "ReadabilityControls"
	readability_controls_panel.visible = false
	readability_controls_panel.z_index = 21
	readability_controls_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	readability_controls_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	readability_controls_panel.offset_left = -372.0
	readability_controls_panel.offset_top = 82.0
	readability_controls_panel.offset_right = -18.0
	readability_controls_panel.offset_bottom = 136.0
	readability_controls_panel.add_theme_stylebox_override("panel", UI_THEME_SCRIPT.dark_glass_style(UI_THEME_SCRIPT.TEAL_LIGHT, 1))
	$Interface.add_child(readability_controls_panel)
	var controls_margin := MarginContainer.new()
	controls_margin.add_theme_constant_override("margin_left", 7)
	controls_margin.add_theme_constant_override("margin_top", 6)
	controls_margin.add_theme_constant_override("margin_right", 7)
	controls_margin.add_theme_constant_override("margin_bottom", 6)
	readability_controls_panel.add_child(controls_margin)
	var controls_row := HBoxContainer.new()
	controls_row.add_theme_constant_override("separation", 7)
	controls_margin.add_child(controls_row)
	rival_pacing_button = _styled_button("")
	rival_pacing_button.name = "RivalPacingButton"
	rival_pacing_button.custom_minimum_size = Vector2(170, 36)
	_apply_high_contrast_button_text(rival_pacing_button)
	rival_pacing_button.pressed.connect(_cycle_rival_pacing)
	controls_row.add_child(rival_pacing_button)
	text_scale_button = _styled_button("")
	text_scale_button.name = "TextScaleButton"
	text_scale_button.custom_minimum_size = Vector2(146, 36)
	_apply_high_contrast_button_text(text_scale_button)
	text_scale_button.pressed.connect(_cycle_text_scale)
	controls_row.add_child(text_scale_button)

	var top_row := $Interface/TopBar/Margin/TopRow as HBoxContainer
	top_row.add_theme_constant_override("separation", 18)
	battle_log_button.reparent(top_row)
	battle_log_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	battle_log_button.custom_minimum_size = Vector2(118, 42)
	battle_log_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	match_options_button = _styled_button("OPTIONS")
	match_options_button.name = "MatchOptionsButton"
	match_options_button.custom_minimum_size = Vector2(106, 42)
	_apply_high_contrast_button_text(match_options_button)
	match_options_button.pressed.connect(_toggle_readability_options)
	top_row.add_child(match_options_button)
	top_row.move_child(battle_log_button, maxi(0, top_row.get_child_count() - 4))
	top_row.move_child(match_options_button, maxi(0, top_row.get_child_count() - 3))
	board_info_button = _styled_button("i")
	board_info_button.name = "BoardInfoButton"
	board_info_button.custom_minimum_size = Vector2(42, 42)
	board_info_button.toggle_mode = true
	board_info_button.tooltip_text = "Show or hide board zone labels"
	board_info_button.add_theme_font_size_override("font_size", _scaled_font_size(18))
	board_info_button.set_meta("readability_base_font_font_size", 18)
	_apply_high_contrast_button_text(board_info_button)
	board_info_button.pressed.connect(_toggle_board_info)
	top_row.add_child(board_info_button)
	top_row.move_child(board_info_button, mini(4, top_row.get_child_count() - 1))

	_refresh_readability_control_labels()
	_apply_text_scale()
	_refresh_board_info_visibility()


func _toggle_readability_options() -> void:
	if not is_instance_valid(readability_controls_panel):
		return
	readability_controls_panel.visible = not readability_controls_panel.visible
	match_options_button.text = "CLOSE" if readability_controls_panel.visible else "OPTIONS"
	if readability_controls_panel.visible:
		_set_battle_log_visible(false)


func _toggle_board_info() -> void:
	board_info_visible = not board_info_visible
	if is_instance_valid(board_info_button):
		board_info_button.set_pressed_no_signal(board_info_visible)
	_refresh_board_info_visibility()


func _refresh_board_info_visibility() -> void:
	var zones := $ViewportContainer/WorldViewport/World/Zones
	for zone in zones.get_children():
		var zone_label := zone.get_node_or_null("Label3D") as Label3D
		if zone_label != null:
			_style_board_info_label(zone_label, 50)
			zone_label.visible = board_info_visible
	for node in card_layer.find_children("*", "Label3D", true, false):
		if bool(node.get_meta("board_info_label", false)):
			var info_label := node as Label3D
			_style_board_info_label(info_label, 56 if info_label.name.ends_with("Count") else 50)
			info_label.visible = board_info_visible


func _style_board_info_label(label: Label3D, minimum_font_size: int) -> void:
	label.font_size = maxi(label.font_size, minimum_font_size)
	label.outline_size = maxi(label.outline_size, 16)
	label.modulate = PALETTE.CREAM
	label.outline_modulate = PALETTE.NAVY


func _load_readability_settings() -> void:
	var config := ConfigFile.new()
	if config.load(READABILITY_SETTINGS_PATH) != OK:
		return
	var pacing_id := String(config.get_value("readability", "rival_pacing", "normal"))
	for option_index in range(RIVAL_PACING_OPTIONS.size()):
		if String(RIVAL_PACING_OPTIONS[option_index].id) == pacing_id:
			rival_pacing_index = option_index
			break
	var saved_scale := float(config.get_value("readability", "text_scale", DEFAULT_TEXT_SCALE))
	var closest_distance := INF
	for option_index in range(TEXT_SCALE_OPTIONS.size()):
		var distance := absf(float(TEXT_SCALE_OPTIONS[option_index]) - saved_scale)
		if distance < closest_distance:
			closest_distance = distance
			text_scale_index = option_index


func _save_readability_settings() -> void:
	battle_preferences_changed.emit(
		String(RIVAL_PACING_OPTIONS[rival_pacing_index].id),
		float(TEXT_SCALE_OPTIONS[text_scale_index])
	)


func _cycle_rival_pacing() -> void:
	rival_pacing_index = (rival_pacing_index + 1) % RIVAL_PACING_OPTIONS.size()
	_refresh_readability_control_labels()
	_save_readability_settings()


func _cycle_text_scale() -> void:
	text_scale_index = (text_scale_index + 1) % TEXT_SCALE_OPTIONS.size()
	_apply_text_scale()
	_refresh_readability_control_labels()
	_save_readability_settings()


func _refresh_readability_control_labels() -> void:
	if is_instance_valid(rival_pacing_button):
		rival_pacing_button.text = "PLAY SPEED  •  %s" % String(RIVAL_PACING_OPTIONS[rival_pacing_index].label)
	if is_instance_valid(text_scale_button):
		text_scale_button.text = "TEXT SIZE  •  %d%%" % int(round(float(TEXT_SCALE_OPTIONS[text_scale_index]) * 100.0))


func _scaled_font_size(base_size: int) -> int:
	return maxi(1, int(round(float(base_size) * BASE_TEXT_READABILITY_SCALE * float(TEXT_SCALE_OPTIONS[text_scale_index]))))


func _apply_text_scale() -> void:
	_apply_text_scale_to_control($Interface)


func _apply_text_scale_to_control(control: Control) -> void:
	var font_size_names: Array[String] = ["font_size"]
	if control is RichTextLabel:
		font_size_names = ["normal_font_size", "bold_font_size", "italics_font_size", "bold_italics_font_size", "mono_font_size"]
	for font_size_name in font_size_names:
		var meta_name := "readability_base_font_%s" % font_size_name
		if control.has_meta(meta_name):
			control.add_theme_font_size_override(font_size_name, _scaled_font_size(int(control.get_meta(meta_name))))
		elif control.has_theme_font_size_override(font_size_name):
			var base_size := control.get_theme_font_size(font_size_name)
			control.set_meta(meta_name, base_size)
			control.add_theme_font_size_override(font_size_name, _scaled_font_size(base_size))
	for child in control.get_children():
		if child is Control:
			_apply_text_scale_to_control(child)


func _show_turn_banner(phase: String) -> void:
	if turn_banner_panel == null or phase not in ["player_main", "opponent_turn"]:
		return
	var is_player := phase == "player_main"
	turn_banner_title.text = "YOUR TURN" if is_player else "RIVAL TURN"
	turn_banner_title.add_theme_color_override("font_color", PALETTE.NAVY)
	turn_banner_subtitle.text = "TURN %d  •  %s" % [int(state.get("turn", 1)), "READY YOUR KITCHEN" if is_player else "WATCH THEIR MOVE"]
	turn_banner_subtitle.add_theme_color_override("font_color", PALETTE.NAVY_MUTED)
	turn_banner_panel.visible = true
	turn_banner_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	turn_banner_panel.scale = Vector2(0.72, 0.72)
	turn_banner_panel.pivot_offset = turn_banner_panel.size * 0.5
	var banner_accent := PALETTE.SKY if is_player else PALETTE.BLUSH
	_spawn_celestial_orbit_screen(effect_layer.size * Vector2(0.5, 0.5), banner_accent, Vector2(178.0, 52.0), 0.8)
	_spawn_screen_particle_burst(effect_layer.size * Vector2(0.5, 0.5), banner_accent, 10, "✦")
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
	var accent := PALETTE.FRESH_YELLOW if player_won else PALETTE.CORAL
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
	_spawn_celestial_orbit_screen(_world_to_container(winner_node.global_position + Vector3(0.0, 0.6, 0.0)), accent, Vector2(118.0, 72.0), 1.25)
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
	var preferred_scale := 1.12 if is_player else 0.84
	var available_width := PLAYER_HAND_MAX_WIDTH if is_player else OPPONENT_HAND_MAX_WIDTH
	var scale_factor := minf(preferred_scale, (available_width - HAND_CARD_GAP * float(count - 1)) / (FIELD_CARD_SIZE.x * float(count)))
	scale_factor = maxf(scale_factor, 0.58)
	var spacing := FIELD_CARD_SIZE.x * scale_factor + HAND_CARD_GAP
	for hand_index in range(count):
		var offset := float(hand_index) - float(count - 1) * 0.5
		var root := _make_card(String(hand[hand_index]), is_player)
		root.name = "%sHandCard_%d" % [side.capitalize(), hand_index]
		root.position = Vector3(offset * spacing, (0.62 + absf(offset) * 0.025) if is_player else (0.72 + absf(offset) * 0.012), PLAYER_HAND_Z + absf(offset) * 0.045 if is_player else OPPONENT_HAND_Z - absf(offset) * 0.025)
		root.rotation_degrees = Vector3(20.0 if is_player else 69.0, 0.0, -offset * (1.8 if is_player else 1.2))
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
		if zone == "plated":
			root.scale = Vector3.ONE * PLATED_CARD_SCALE
		root.set_meta("kind", "field")
		root.set_meta("side", side)
		root.set_meta("zone", zone)
		root.set_meta("instance_id", int(unit.instance_id))
		root.set_meta("card_id", String(unit.card_id))
		root.set_meta("ready", bool(unit.get("ready", false)))
		root.set_meta("upright_rotation_degrees", root.rotation_degrees)
		if zone == "plated" and bool(unit.get("defending", false)):
			root.rotation_degrees.y += 90.0
		_store_card_pose(root, float(int(unit.instance_id)) * 0.31)
		card_layer.add_child(root)
		interactive_cards.append(root)
		_add_taunt_aura(root, unit, zone)
		_add_meal_selection_aura(root, unit, side)
		_add_ability_ready_aura(root, unit, side, zone)
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
	var tint := PALETTE.SKY if side == "player" else PALETTE.BLUSH
	material.albedo_color = Color(tint.r, tint.g, tint.b, 0.24)
	material.emission_enabled = true
	material.emission = tint
	material.emission_energy_multiplier = 0.08
	mesh.material = material
	marker.mesh = mesh
	LOFI_OUTLINE.apply_to_mesh_tree(marker, ZONE_OUTLINE_WIDTH, ARENA_OUTLINE_COLOR)
	marker.set_meta("lofi_arena_outline", true)
	root.add_child(marker)
	var label := Label3D.new()
	label.name = "ZoneLabel"
	label.position = Vector3(0.0, 0.08, 0.72)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 34
	label.outline_size = 10
	label.modulate = PALETTE.NAVY
	label.text = display_name
	label.visible = board_info_visible
	label.set_meta("board_info_label", true)
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
	count_label.font_size = 44
	count_label.outline_size = 12
	count_label.modulate = PALETTE.NAVY
	count_label.text = str(cards.size())
	count_label.visible = board_info_visible
	count_label.set_meta("board_info_label", true)
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
		for requirement in service._effective_recipe(state, "player", card_data):
			if service._ingredient_matches_requirement(service.card(String(unit.get("card_id", ""))), String(requirement)):
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
	if _environment_has_ready_activated_ability(side):
		_add_pulsing_card_aura(root, "AbilityReadyAura", 9000 if side == "player" else 9001, PALETTE.FRESH_YELLOW, PALETTE.CREAM, Vector2(1.42, 1.94), 1.36, 1.08, 1.72)


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


func _add_taunt_aura(root: Node3D, unit: Dictionary, zone: String) -> void:
	if zone != "plated":
		return
	var data: Dictionary = service.card(String(unit.get("card_id", "")))
	if not data.get("keywords", []).has("taunt"):
		return
	_add_pulsing_card_aura(
		root,
		"TauntAura",
		int(unit.get("instance_id", 0)),
		PALETTE.BRICK_DARK,
		Color.WHITE,
		Vector2(1.68, 2.26),
		1.52,
		1.22,
		1.98,
		TAUNT_AURA
	)


func _add_ability_ready_aura(root: Node3D, unit: Dictionary, side: String, zone: String) -> void:
	if not _unit_has_ready_activated_ability(unit, side, zone):
		return
	_add_pulsing_card_aura(
		root,
		"AbilityReadyAura",
		int(unit.get("instance_id", 0)),
		PALETTE.FRESH_YELLOW,
		PALETTE.CREAM,
		Vector2(1.60, 2.18),
		1.42,
		1.12,
		1.82
	)


func _add_meal_selection_aura(root: Node3D, unit: Dictionary, side: String) -> void:
	if side != "player":
		return
	var instance_id := int(unit.get("instance_id", -1))
	var selectable: bool = service.meal_selectable_ingredient_ids(state).has(instance_id)
	var selected: bool = state.get("selected_ingredients", []).has(instance_id)
	if not selectable and not selected:
		return
	var aura_color := PALETTE.FRESH_YELLOW if selected else PALETTE.SKY
	var albedo_tint := Color.WHITE
	root.set_meta("meal_selection_state", "selected" if selected else "candidate")
	_add_pulsing_card_aura(
		root,
		"MealIngredientSelectedAura" if selected else "MealIngredientCandidateAura",
		instance_id,
		aura_color,
		albedo_tint,
		Vector2(1.40, 1.96),
		1.28 if selected else 0.96,
		1.02 if selected else 0.72,
		1.54 if selected else 1.18,
		MEAL_SELECTED_AURA if selected else MEAL_CANDIDATE_AURA
	)


func _add_pulsing_card_aura(
	root: Node3D,
	aura_name: String,
	instance_id: int,
	emission_color: Color,
	albedo_tint: Color,
	mesh_size: Vector2,
	initial_energy: float,
	energy_min: float,
	energy_max: float,
	aura_texture: Texture2D = ABILITY_READY_AURA
) -> void:
	var aura := MeshInstance3D.new()
	aura.name = aura_name
	aura.position = Vector3(0.0, 0.032, 0.0)
	aura.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	aura.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mesh := QuadMesh.new()
	mesh.size = mesh_size
	aura.mesh = mesh
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_texture = aura_texture
	material.albedo_color = albedo_tint
	material.emission_enabled = true
	material.emission = emission_color
	material.emission_texture = aura_texture
	material.emission_energy_multiplier = initial_energy
	aura.material_override = material
	aura.set_meta("pulse_seed", float(instance_id) * 0.37)
	aura.set_meta("pulse_energy_min", energy_min)
	aura.set_meta("pulse_energy_max", energy_max)
	root.add_child(aura)
	if aura_name == "AbilityReadyAura":
		var sparkle_overlay := MeshInstance3D.new()
		sparkle_overlay.name = "AbilityReadySparkles"
		sparkle_overlay.position = Vector3(0.0, 0.037, 0.0)
		sparkle_overlay.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
		sparkle_overlay.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var sparkle_mesh := QuadMesh.new()
		sparkle_mesh.size = mesh_size
		sparkle_overlay.mesh = sparkle_mesh
		var sparkle_material := StandardMaterial3D.new()
		sparkle_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sparkle_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sparkle_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		sparkle_material.albedo_texture = ABILITY_READY_SPARKLES
		sparkle_material.albedo_color = Color(PALETTE.CREAM, 0.08)
		sparkle_material.emission_enabled = true
		sparkle_material.emission = emission_color
		sparkle_material.emission_texture = ABILITY_READY_SPARKLES
		sparkle_material.emission_energy_multiplier = 0.4
		sparkle_overlay.material_override = sparkle_material
		root.add_child(sparkle_overlay)
		aura.set_meta("sparkle_overlay", sparkle_overlay)
	pulsing_field_auras.append(aura)


func _unit_has_ready_activated_ability(unit: Dictionary, side: String, zone: String) -> bool:
	if side != "player" or tutorial_mode or not service._can_player_act(state) or _has_blocking_prompt():
		return false
	var data: Dictionary = service.card(String(unit.get("card_id", "")))
	for ability in data.get("abilities", []):
		if String(ability.get("timing", "")) != "activated":
			continue
		var active_zone := String(ability.get("active_zone", ""))
		if active_zone != "" and active_zone != zone:
			continue
		var ability_id := String(ability.get("id", "activated"))
		if bool(ability.get("once_per_turn", false)) and unit.get("used_abilities", []).has(ability_id):
			continue
		if service._ability_needs_target(ability):
			var target_spec: Dictionary = ability.get("target", {})
			if service._first_ability_target_id(state, "player", unit, target_spec) < 0:
				continue
		return true
	return false


func _environment_has_ready_activated_ability(side: String) -> bool:
	if side != "player" or tutorial_mode or not service._can_player_act(state) or _has_blocking_prompt():
		return false
	var data := service.card(String(state[side].get("environment", "")))
	var used: Array = state[side].get("environment_used_abilities", [])
	for ability in data.get("abilities", []):
		if String(ability.get("timing", "")) == "activated" and String(ability.get("active_zone", "")) == "environment":
			if not bool(ability.get("once_per_turn", false)) or not used.has(String(ability.get("id", "activated"))):
				return true
	return false


func _make_card(card_id: String, face_up: bool, show_art: bool = true) -> Node3D:
	var root := Node3D.new()
	var body := MeshInstance3D.new()
	body.name = "CardBody"
	var body_mesh := _rounded_card_body_mesh(
		Vector3(FIELD_CARD_SIZE.x + 0.06, 0.06, FIELD_CARD_SIZE.y + 0.06),
		0.12,
		6
	)
	var edge_material := StandardMaterial3D.new()
	edge_material.albedo_color = PALETTE.NAVY
	edge_material.roughness = 0.68
	edge_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	body.mesh = body_mesh
	body.material_override = edge_material
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
	if not face_up:
		var back_frame := MeshInstance3D.new()
		back_frame.name = "CardBackFrame"
		back_frame.position = Vector3(0.0, 0.038, 0.0)
		back_frame.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
		back_frame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var back_frame_mesh := QuadMesh.new()
		back_frame_mesh.size = FIELD_CARD_SIZE
		back_frame.mesh = back_frame_mesh
		back_frame.material_override = _card_back_frame_material()
		root.add_child(back_frame)
	return root


func _rounded_card_body_mesh(size: Vector3, corner_radius: float, corner_segments: int) -> ArrayMesh:
	var half_width := size.x * 0.5
	var half_depth := size.z * 0.5
	var radius := minf(corner_radius, minf(half_width, half_depth) - 0.001)
	var boundary := PackedVector2Array()
	var corner_centers := [
		Vector2(half_width - radius, half_depth - radius),
		Vector2(-half_width + radius, half_depth - radius),
		Vector2(-half_width + radius, -half_depth + radius),
		Vector2(half_width - radius, -half_depth + radius),
	]
	for corner_index in range(4):
		var start_angle := float(corner_index) * PI * 0.5
		for segment_index in range(corner_segments + 1):
			var angle := start_angle + PI * 0.5 * float(segment_index) / float(corner_segments)
			boundary.append(corner_centers[corner_index] + Vector2(cos(angle), sin(angle)) * radius)

	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var top_y := size.y * 0.5
	var bottom_y := -top_y
	for point_index in range(boundary.size()):
		var next_index := (point_index + 1) % boundary.size()
		var point := boundary[point_index]
		var next_point := boundary[next_index]
		_add_card_mesh_vertex(surface, Vector3.ZERO + Vector3(0.0, top_y, 0.0), Vector3.UP)
		_add_card_mesh_vertex(surface, Vector3(point.x, top_y, point.y), Vector3.UP)
		_add_card_mesh_vertex(surface, Vector3(next_point.x, top_y, next_point.y), Vector3.UP)
		_add_card_mesh_vertex(surface, Vector3(0.0, bottom_y, 0.0), Vector3.DOWN)
		_add_card_mesh_vertex(surface, Vector3(next_point.x, bottom_y, next_point.y), Vector3.DOWN)
		_add_card_mesh_vertex(surface, Vector3(point.x, bottom_y, point.y), Vector3.DOWN)
		var side_normal := Vector3(point.x + next_point.x, 0.0, point.y + next_point.y).normalized()
		_add_card_mesh_vertex(surface, Vector3(point.x, top_y, point.y), side_normal)
		_add_card_mesh_vertex(surface, Vector3(point.x, bottom_y, point.y), side_normal)
		_add_card_mesh_vertex(surface, Vector3(next_point.x, bottom_y, next_point.y), side_normal)
		_add_card_mesh_vertex(surface, Vector3(point.x, top_y, point.y), side_normal)
		_add_card_mesh_vertex(surface, Vector3(next_point.x, bottom_y, next_point.y), side_normal)
		_add_card_mesh_vertex(surface, Vector3(next_point.x, top_y, next_point.y), side_normal)
	return surface.commit()


func _add_card_mesh_vertex(surface: SurfaceTool, position: Vector3, normal: Vector3) -> void:
	surface.set_normal(normal)
	surface.add_vertex(position)


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
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
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
	var rules := _label(String(data.get("text", "")), 18, Color.WHITE)
	rules.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(rules)
	return root


func _card_back_material() -> StandardMaterial3D:
	if face_materials.has("__card_back"):
		return face_materials.__card_back
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_texture = CARD_BACK
	face_materials.__card_back = material
	return material


func _card_back_frame_material() -> StandardMaterial3D:
	if face_materials.has("__card_back_frame"):
		return face_materials.__card_back_frame
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_texture = CARD_BACK_FRAME
	face_materials.__card_back_frame = material
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
	var art_scale: float = PLATED_FLOATING_ART_SCALE if String(root.get_meta("zone", "")) == "plated" else 1.0
	mesh.size = Vector2(1.03, 0.86) * art_scale
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
	var is_defending := bool(unit.get("defending", false))
	var is_ready := bool(unit.get("ready", false))
	var instance_id := int(unit.get("instance_id", -1))
	var meal_candidate: bool = side == "player" and service.meal_selectable_ingredient_ids(state).has(instance_id)
	var meal_selected: bool = state.get("selected_ingredients", []).has(instance_id)
	var ability_ready: bool = _unit_has_ready_activated_ability(unit, side, String(root.get_meta("zone", "prep")))
	var data: Dictionary = service.card(String(unit.get("card_id", "")))
	var taunt_active: bool = String(root.get_meta("zone", "")) == "plated" and data.get("keywords", []).has("taunt")
	var stat_text := "%d/%d" % [int(unit.attack), int(unit.health)]
	_add_fitted_field_badge(
		root,
		"Stats",
		stat_text,
		Vector3(0.0, 0.18, 0.59),
		Color("#fff3c4") if is_ready else Color("#c7c9cf")
	)
	if not is_defending and side == "player" and is_ready and not meal_candidate and not meal_selected and not ability_ready and not taunt_active:
		_add_fitted_field_badge(
			root,
			"ReadyStatus",
			"READY",
			Vector3(0.0, 0.19, 0.04),
			Color("#fff3c4")
		)
	if not is_defending and meal_selected:
		_add_fitted_field_badge(
			root,
			"MealSelectionBadge",
			"SELECTED",
			Vector3(0.0, 0.20, 0.04),
			PALETTE.FRESH_YELLOW
		)
	elif not is_defending and meal_candidate:
		_add_fitted_field_badge(
			root,
			"MealCandidateBadge",
			"CHOOSE",
			Vector3(0.0, 0.20, 0.04),
			PALETTE.SKY
		)
	if not is_defending:
		return
	_add_fitted_field_badge(
		root,
		"Status",
		"DEFENDING",
		_player_facing_badge_position(root, 0.67),
		Color("#9edcff")
	)


func _add_fitted_field_badge(root: Node3D, badge_name: String, text: String, position: Vector3, text_color: Color) -> void:
	var backing := Sprite3D.new()
	backing.name = badge_name + "Backing"
	backing.position = position + Vector3(0.0, -0.02, 0.0)
	backing.texture = STAT_BADGE_BACKING
	backing.pixel_size = 0.003
	backing.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	var font_size := 54
	var label_pixel_size := 0.006
	var text_size := READABLE_FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var available_text_width := FIELD_BADGE_MAX_WIDTH - 0.18
	if text_size.x * label_pixel_size > available_text_width:
		label_pixel_size = available_text_width / maxf(1.0, text_size.x)
	var desired_width := minf(FIELD_BADGE_MAX_WIDTH, text_size.x * label_pixel_size + 0.18)
	var desired_height := text_size.y * label_pixel_size + 0.08
	var natural_width := float(STAT_BADGE_BACKING.get_width()) * backing.pixel_size
	var natural_height := float(STAT_BADGE_BACKING.get_height()) * backing.pixel_size
	backing.scale = Vector3(
		desired_width / maxf(0.001, natural_width),
		desired_height / maxf(0.001, natural_height),
		1.0
	)
	backing.set_meta("fitted_width", desired_width)
	backing.set_meta("fitted_height", desired_height)
	backing.set_meta("maximum_width", FIELD_BADGE_MAX_WIDTH)
	root.add_child(backing)
	var label := Label3D.new()
	label.name = badge_name
	label.position = position
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font = READABLE_FONT
	label.font_size = font_size
	label.pixel_size = label_pixel_size
	label.outline_size = 13
	label.modulate = text_color
	label.text = text
	root.add_child(label)


func _player_facing_badge_position(root: Node3D, distance: float) -> Vector3:
	var toward_player_world := Vector3(0.0, 0.0, 1.0)
	var toward_player_local := root.global_transform.basis.inverse() * toward_player_world
	toward_player_local.y = 0.0
	toward_player_local = toward_player_local.normalized()
	return Vector3(toward_player_local.x * distance, 0.20, toward_player_local.z * distance)


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
	if meal_candidate or selected_recipe_ingredient:
		return
	var body := root.get_node("CardBody") as MeshInstance3D
	var material := body.get_active_material(0).duplicate() as StandardMaterial3D
	material.albedo_color = Color("#e9a93b")
	material.emission_enabled = true
	material.emission = Color("#ffd45b")
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
	for aura in pulsing_field_auras:
		if not is_instance_valid(aura):
			continue
		var pulse := (sin(time * 4.2 + float(aura.get_meta("pulse_seed", 0.0))) + 1.0) * 0.5
		aura.scale = Vector3.ONE * lerpf(0.985, 1.025, pulse)
		var aura_material := aura.material_override as StandardMaterial3D
		if aura_material != null:
			aura_material.emission_energy_multiplier = lerpf(
				float(aura.get_meta("pulse_energy_min", 1.05)),
				float(aura.get_meta("pulse_energy_max", 1.8)),
				pulse
			)
		var sparkle_overlay := aura.get_meta("sparkle_overlay") as MeshInstance3D if aura.has_meta("sparkle_overlay") else null
		if is_instance_valid(sparkle_overlay):
			var twinkle := 0.78 if reduced_motion else pow((sin(time * 5.0 + float(aura.get_meta("pulse_seed", 0.0)) + 0.9) + 1.0) * 0.5, 1.8)
			sparkle_overlay.scale = Vector3.ONE if reduced_motion else Vector3.ONE * lerpf(0.82, 1.08, twinkle)
			var sparkle_material := sparkle_overlay.material_override as StandardMaterial3D
			if sparkle_material != null:
				sparkle_material.albedo_color.a = lerpf(0.08, 1.0, twinkle)
				sparkle_material.emission_energy_multiplier = lerpf(0.35, 2.15, twinkle)
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
		var idle_alpha := 0.44 + sin(time * 1.5 + float(String(zone_id).hash() % 13)) * 0.012
		var materials: Array = zone_materials[zone_id]
		for slot_index in range(materials.size()):
			var material_variant = materials[slot_index]
			var material := material_variant as StandardMaterial3D
			var drag_active := String(zone_id) == highlighted_zone and (highlighted_slot < 0 or highlighted_slot == slot_index)
			var action_active := (String(zone_id) == action_highlight_zone and (action_highlight_slot < 0 or action_highlight_slot == slot_index)) or _is_action_slot_highlighted(String(zone_id), slot_index)
			var active := drag_active or action_active
			material.albedo_color = Color(base_color.r, base_color.g, base_color.b, 0.48 if active else idle_alpha)
			material.emission_enabled = active
			material.emission = base_color
			material.emission_energy_multiplier = 1.8 + sin(time * 5.0) * 0.35 if active else 0.0


func _is_action_slot_highlighted(zone_id: String, slot_index: int) -> bool:
	for choice in action_highlight_slots:
		if String(choice.get("zone", "")) == zone_id and int(choice.get("slot", -1)) == slot_index:
			return true
	return false


func _zone_color(zone_id: String) -> Color:
	if zone_id == "player_prep":
		return PALETTE.SKY
	if zone_id == "player_plated":
		return PALETTE.CORAL
	if zone_id == "opponent_plated":
		return PALETTE.BLUSH
	return PALETTE.PERIWINKLE


func _on_table_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and String(state.get("phase", "")) == "player_main" and is_instance_valid(rival_action_panel):
		rival_action_panel.visible = false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if pending_hand_play_index >= 0 or pending_move_instance_id >= 0:
				var choice_point: Variant = _mouse_to_table(event.position)
				if choice_point != null:
					var choice_slot: Dictionary = _slot_at_point(choice_point as Vector3)
					if String(choice_slot.get("zone", "")) in ["player_prep", "player_plated"]:
						if pending_hand_play_index >= 0:
							_choose_pending_hand_destination(String(choice_slot.zone).trim_prefix("player_"), int(choice_slot.slot))
						else:
							_choose_pending_move_destination(String(choice_slot.zone).trim_prefix("player_"), int(choice_slot.slot))
						pressed_card = null
						viewport_container.accept_event()
						return
				pressed_card = null
				viewport_container.accept_event()
				return
			# The visible opponent hand is intentionally a large direct-attack target.
			# Its card backs are also interactive for inspection, so resolve an already
			# selected attacker before the generic card picker claims the click.
			if int(state.get("selected_attacker", -1)) >= 0 and _screen_hits_opponent_hand(event.position):
				_on_opponent_chef_clicked()
				pressed_card = null
				viewport_container.accept_event()
				return
			pressed_card = _pick_card(event.position)
			press_screen_position = event.position
			if pressed_card != null and String(state.get("phase", "")) == "opponent_turn":
				_inspect_card(pressed_card)
				pressed_card = null
				viewport_container.accept_event()
				return
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
				elif _screen_hits_opponent_hand(event.position):
					_on_opponent_chef_clicked()
					viewport_container.accept_event()
		elif pressed_card != null:
			if dragging:
				_finish_drag(_mouse_to_table(event.position), event.position)
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
	var best_depth := INF
	var padded_best: Node3D
	var padded_best_distance := 100000.0
	for candidate in interactive_cards:
		if not is_instance_valid(candidate):
			continue
		var polygon := _card_screen_polygon(candidate)
		var card_rect := _card_screen_rect_from_polygon(polygon)
		var visible_rect := card_rect.intersection(Rect2(Vector2.ZERO, viewport_container.size))
		var target_center := visible_rect.get_center() if visible_rect.has_area() else card_rect.get_center()
		var rect_distance := target_center.distance_to(screen_position)
		if polygon.size() == 4 and Geometry2D.is_point_in_polygon(screen_position, polygon):
			var camera_depth := candidate.global_position.distance_squared_to(camera.global_position)
			if camera_depth < best_depth:
				best = candidate
				best_depth = camera_depth
			continue
		if card_rect.grow(10.0).has_point(screen_position) and rect_distance < padded_best_distance:
			padded_best = candidate
			padded_best_distance = rect_distance
	if best != null:
		return best
	if padded_best != null:
		return padded_best
	for candidate in interactive_cards:
		if not is_instance_valid(candidate):
			continue
		var projected := _world_to_container(candidate.global_position + Vector3(0.0, 0.22, 0.0))
		var threshold := 78.0 if String(candidate.get_meta("kind", "")) == "hand" else 62.0
		var distance := projected.distance_to(screen_position)
		if distance < threshold and distance < padded_best_distance:
			best = candidate
			padded_best_distance = distance
	return best


func _card_screen_polygon(card_node: Node3D) -> PackedVector2Array:
	var half_size := FIELD_CARD_SIZE * 0.5
	var local_corners := [
		Vector3(-half_size.x, 0.05, -half_size.y),
		Vector3(half_size.x, 0.05, -half_size.y),
		Vector3(half_size.x, 0.05, half_size.y),
		Vector3(-half_size.x, 0.05, half_size.y),
	]
	var polygon := PackedVector2Array()
	for local_corner in local_corners:
		polygon.append(_world_to_container(card_node.global_transform * local_corner))
	return polygon


func _card_screen_rect(card_node: Node3D) -> Rect2:
	return _card_screen_rect_from_polygon(_card_screen_polygon(card_node))


func _card_screen_rect_from_polygon(polygon: PackedVector2Array) -> Rect2:
	if polygon.is_empty():
		return Rect2()
	var minimum := polygon[0]
	var maximum := polygon[0]
	for point in polygon:
		minimum = minimum.min(point)
		maximum = maximum.max(point)
	return Rect2(minimum, maximum - minimum)


func _world_to_container(world_position: Vector3) -> Vector2:
	var viewport_position := camera.unproject_position(world_position)
	return viewport_position * viewport_container.size / Vector2(world_viewport.size)


func _screen_hits_opponent_chef(screen_position: Vector2) -> bool:
	return _world_to_container(opponent_chef.global_position + Vector3(0.0, 0.35, 0.0)).distance_to(screen_position) < 74.0


func _screen_hits_opponent_hand(screen_position: Vector2) -> bool:
	var found_hand_card := false
	var hand_rect := Rect2()
	for child in card_layer.get_children():
		var card_node := child as Node3D
		if (
			card_node == null
			or card_node.is_queued_for_deletion()
			or String(card_node.get_meta("kind", "")) != "hand"
			or String(card_node.get_meta("side", "")) != "opponent"
		):
			continue
		var card_rect := _card_screen_rect(card_node)
		if not card_rect.has_area():
			continue
		hand_rect = card_rect if not found_hand_card else hand_rect.merge(card_rect)
		found_hand_card = true
	return found_hand_card and hand_rect.grow(10.0).has_point(screen_position)


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
	_play_random_card_sound(PICK_CARD_SOUNDS)
	dragging = true
	drag_original_position = pressed_card.position
	drag_original_rotation = pressed_card.rotation
	drag_offset = Vector3(pressed_card.position.x - point.x, 0.0, pressed_card.position.z - point.z)
	pressed_card.rotation = Vector3.ZERO
	pressed_card.scale = Vector3.ONE
	pressed_card.position.y = DRAG_Y
	current_zone = String(pressed_card.get_meta("zone", "hand"))
	status_label.text = "Drag to your Prep or Plated lane. Drag an attacker onto a rival defender or chef."
	_refresh_status_context()
	_refresh_status_panel_visibility()


func _update_drag(point: Vector3) -> void:
	if pressed_card == null:
		return
	var desired := _dragged_card_point(point)
	pressed_card.position = Vector3(desired.x, DRAG_Y, desired.z)
	var hovered_slot := _slot_at_point(desired)
	highlighted_zone = String(hovered_slot.get("zone", ""))
	highlighted_slot = int(hovered_slot.get("slot", -1))


func _finish_drag(point: Variant, screen_position: Vector2 = Vector2(-10000.0, -10000.0)) -> void:
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
		elif (
			drop_point != null
			and (
				_point_near_chef(drop_point as Vector3, opponent_chef.position)
				or _screen_hits_opponent_hand(screen_position)
			)
		):
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
		# Keep exact-slot hit testing as tall as the visible lane highlight. A card
		# near the illustrated lane edge must resolve to the slot it visibly lights,
		# even when the player grabbed the card away from its center.
		if absf(point.x - (center.x + offset)) <= 0.79 and absf(point.z - center.z) <= float(ZONE_EXTENTS[zone_id].y):
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
	if String(state.get("phase", "")) == "opponent_turn":
		_inspect_card(card_node)
		return
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
		_continue_tutorial_after_physical_selection()
		return
	if side == "opponent" and String(card_node.get_meta("zone", "")) == "plated" and int(state.get("selected_attacker", -1)) >= 0:
		selected_ref = {}
		_perform_attack(instance_id)
		return
	if tutorial_mode:
		_tutorial_reject_action()
		return
	_inspect_card(card_node)


func _continue_tutorial_after_physical_selection() -> void:
	if not tutorial_mode or selected_ref.is_empty():
		return
	var next_action := String(_tutorial_step().get("action", ""))
	var instance_id := int(selected_ref.get("instance_id", -1))
	if String(selected_ref.get("kind", "")) == "field":
		match next_action:
			"move_unit":
				_begin_move_selection(instance_id)
			"select_spice_target":
				_select_spice_target(instance_id)
			"select_attacker":
				_select_attacker(instance_id)


func _inspect_card(card_node: Node3D) -> void:
	if not is_instance_valid(card_node):
		return
	selected_ref = {
		"kind": String(card_node.get_meta("kind", "")),
		"side": String(card_node.get_meta("side", "")),
		"hand_index": int(card_node.get_meta("hand_index", -1)),
		"instance_id": int(card_node.get_meta("instance_id", -1)),
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
	_clear_keyword_popout()
	action_scroll.scroll_vertical = 0
	action_panel.visible = not selected_ref.is_empty()
	if selected_ref.is_empty():
		return
	var inspector_accent := UI_THEME_SCRIPT.TEAL if String(selected_ref.side) == "player" else UI_THEME_SCRIPT.ORANGE
	var inspector_style := UI_THEME_SCRIPT.light_glass_style(inspector_accent, 2)
	# Field-card details should stay visually distinct from the table beneath them.
	inspector_style.border_color = Color.BLACK
	inspector_style.set_border_width_all(6)
	action_panel.add_theme_stylebox_override("panel", inspector_style)
	var data := service.card(String(selected_ref.card_id))
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	action_list.add_child(header)
	var info_heading := _label("CARD INSPECTOR", 13, UI_THEME_SCRIPT.TEAL_DEEP)
	info_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(info_heading)
	var close_button := _styled_button("Close")
	close_button.name = "LivingTableInfoClose"
	close_button.custom_minimum_size = Vector2(72, 32)
	_apply_current_ui_button_style(close_button, false)
	close_button.pressed.connect(_close_info_window)
	header.add_child(close_button)
	var title := _label(String(data.get("name", "Card")), 22, UI_THEME_SCRIPT.INK)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	action_list.add_child(title)
	var location := "%s • %s" % [String(data.get("card_type", "card")).capitalize(), String(selected_ref.zone if String(selected_ref.zone) != "" else selected_ref.kind).capitalize()]
	action_list.add_child(_label(location, 13, UI_THEME_SCRIPT.INK_MUTED))
	if int(selected_ref.instance_id) >= 0:
		var unit := service._find_unit(state[String(selected_ref.side)], int(selected_ref.instance_id))
		if not unit.is_empty():
			action_list.add_child(_label("%d Attack  •  %d/%d Health%s" % [int(unit.attack), int(unit.health), int(unit.max_health), "  •  Ready" if bool(unit.get("ready", false)) else ""], 14, UI_THEME_SCRIPT.TEAL_DEEP))
	var complete_rules := String(data.get("text", "")).strip_edges()
	if complete_rules != "":
		action_list.add_child(_label("CARD TEXT", 12, UI_THEME_SCRIPT.TEAL_DEEP))
		var complete_rules_label := _label(complete_rules, 15, UI_THEME_SCRIPT.INK)
		complete_rules_label.name = "LivingTableCompleteCardText"
		complete_rules_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		complete_rules_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		action_list.add_child(complete_rules_label)
	# Keep the selected card's usable controls above the large visual preview.
	# This makes Play/Move/Attack reachable without scrolling at 1280x720 and
	# with the enlarged readability settings, including the guided tutorial.
	var can_offer_player_actions := String(selected_ref.side) == "player" and String(state.phase) == "player_main"
	if can_offer_player_actions:
		var blocked_by_other_prompt := _has_blocking_prompt() and pending_hand_play_index != int(selected_ref.get("hand_index", -1)) and pending_move_instance_id != int(selected_ref.get("instance_id", -1))
		if not blocked_by_other_prompt:
			if String(selected_ref.kind) == "hand":
				if pending_hand_play_index == int(selected_ref.hand_index):
					action_list.add_child(_label("CHOOSE A DESTINATION ON THE TABLE", 13, UI_THEME_SCRIPT.ORANGE))
					_add_action_button("Cancel", _cancel_pending_hand_play)
				else:
					_build_hand_actions(data, int(selected_ref.hand_index))
			else:
				if pending_move_instance_id == int(selected_ref.instance_id):
					action_list.add_child(_label("CHOOSE A GLOWING DESTINATION SLOT", 13, UI_THEME_SCRIPT.ORANGE))
					_add_action_button("Cancel", _cancel_pending_move)
				else:
					_build_field_actions(data, int(selected_ref.instance_id), String(selected_ref.zone))
	if CARD_FACE_SCRIPT.supports_card(data):
		var face_center := CenterContainer.new()
		face_center.custom_minimum_size = Vector2(0, INSPECTOR_CARD_SIZE.y + 2.0)
		face_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		action_list.add_child(face_center)
		var info_face := CARD_FACE_SCRIPT.new()
		info_face.name = "LivingTableInfoCardFace"
		info_face.configure(data, "black", true, false)
		info_face.custom_minimum_size = INSPECTOR_CARD_SIZE
		face_center.add_child(info_face)
	var keywords: Array = data.get("keywords", [])
	if not keywords.is_empty():
		action_list.add_child(_label("KEYWORDS", 12, UI_THEME_SCRIPT.TEAL_DEEP))
		var keyword_row := HFlowContainer.new()
		keyword_row.add_theme_constant_override("h_separation", 5)
		keyword_row.add_theme_constant_override("v_separation", 5)
		action_list.add_child(keyword_row)
		for keyword_value in keywords:
			var keyword_id := String(keyword_value)
			var keyword_button := _styled_button(_keyword_title(keyword_id))
			keyword_button.custom_minimum_size = Vector2(0, 30)
			_apply_current_ui_button_style(keyword_button, false)
			keyword_button.mouse_entered.connect(func() -> void: _show_keyword_popout(keyword_id))
			keyword_button.focus_entered.connect(func() -> void: _show_keyword_popout(keyword_id))
			keyword_button.pressed.connect(func() -> void: _show_keyword_popout(keyword_id))
			keyword_row.add_child(keyword_button)
		_show_keyword_popout(String(keywords[0]))
func _close_info_window() -> void:
	_cancel_pending_hand_play(false)
	_cancel_pending_move(false)
	selected_ref = {}
	_refresh_action_panel()


func _keyword_title(keyword_id: String) -> String:
	var tooltip: Dictionary = KEYWORD_TOOLTIPS.get(keyword_id, {})
	return String(tooltip.get("title", keyword_id.replace("_", " ").capitalize()))


func _clear_keyword_popout() -> void:
	if is_instance_valid(keyword_popout):
		keyword_popout.queue_free()
	keyword_popout = null


func _show_keyword_popout(keyword_id: String) -> void:
	var tooltip: Dictionary = KEYWORD_TOOLTIPS.get(keyword_id, {})
	if tooltip.is_empty() or selected_ref.is_empty():
		return
	_clear_keyword_popout()
	keyword_popout = PanelContainer.new()
	keyword_popout.name = "KeywordPopout"
	keyword_popout.z_index = 19
	keyword_popout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	keyword_popout.position = Vector2(350.0, clampf(action_panel.position.y + 120.0, 92.0, maxf(92.0, size.y - 180.0)))
	keyword_popout.size = Vector2(310.0, 138.0)
	keyword_popout.clip_contents = true
	var popout_style := UI_THEME_SCRIPT.light_glass_style(UI_THEME_SCRIPT.PALETTE.NAVY, 2)
	popout_style.bg_color = UI_THEME_SCRIPT.PALETTE.CREAM
	popout_style.border_color = UI_THEME_SCRIPT.PALETTE.NAVY
	popout_style.set_border_width_all(2)
	popout_style.set_corner_radius_all(14)
	popout_style.content_margin_left = 0
	popout_style.content_margin_right = 0
	popout_style.content_margin_top = 0
	popout_style.content_margin_bottom = 0
	keyword_popout.add_theme_stylebox_override("panel", popout_style)
	$Interface.add_child(keyword_popout)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	keyword_popout.add_child(row)
	var accent_bar := ColorRect.new()
	accent_bar.name = "KeywordPopoutAccent"
	accent_bar.color = _keyword_popout_accent(keyword_id)
	accent_bar.custom_minimum_size = Vector2(8, 0)
	accent_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(accent_bar)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	row.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)
	var title := _label(String(tooltip.title).to_upper(), 14, UI_THEME_SCRIPT.PALETTE.NAVY)
	content.add_child(title)
	var body := _label(String(tooltip.body), 13, UI_THEME_SCRIPT.PALETTE.NAVY_MUTED)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(body)


func _keyword_popout_accent(keyword_id: String) -> Color:
	match keyword_id:
		"piercing":
			return UI_THEME_SCRIPT.PALETTE.CORAL
		"stalwart":
			return UI_THEME_SCRIPT.PALETTE.PERIWINKLE
		"taunt":
			return UI_THEME_SCRIPT.PALETTE.FRESH_YELLOW
		"hand_trap":
			return UI_THEME_SCRIPT.PALETTE.FUNKY_PLUM
		_:
			return UI_THEME_SCRIPT.PALETTE.SKY


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
		var selection_feedback := String(state.message)
		_render_match()
		_show_invalid_action(selection_feedback)
		return
	var attempt_marker := _action_attempt_marker()
	animation_busy = true
	service.attack(state, target_instance_id)
	var attack_succeeded: bool = _action_attempt_progressed(attempt_marker)
	var attack_feedback := String(state.message)
	await _drain_animation_event_queue()
	animation_busy = false
	if attack_succeeded:
		_tutorial_complete_action(tutorial_action, {"target_instance_id": target_instance_id})
	_render_match()
	if not attack_succeeded:
		_show_invalid_action(attack_feedback)


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
		elif String(first_event.get("type", "")) == "draw":
			# Turn-start draws do not belong to a formal action group. Keep a
			# consecutive run together so we can animate them one at a time instead
			# of rebuilding the hand between card flights.
			while (
				event_index < events.size()
				and int(events[event_index].get("group_id", 0)) == 0
				and String(events[event_index].get("type", "")) == "draw"
				and String(events[event_index].get("side", "")) == String(first_event.get("side", ""))
			):
				batch.append(events[event_index])
				event_index += 1
		await _animate_event_batch(batch, play_origin_pose)
	_clear_animation_ghosts()


func _prepare_animation_ghosts(events: Array[Dictionary]) -> void:
	var removed_ids: Array[int] = []
	for event in events:
		if String(event.get("type", "")) not in ["sacrifice", "destroy", "evaporate"]:
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
		if String(event.get("type", "")) == "search":
			_play_random_card_sound(SHUFFLE_SOUNDS)
			break
	if _is_serial_draw_batch(events):
		_render_match()
		var staged_cards := _stage_activation_result_transfers(events)
		for event in events:
			_release_staged_transfer_card(event, staged_cards)
			var duration := _start_card_transfer_event_animation(event)
			if duration > 0.0:
				await get_tree().create_timer(duration).timeout
		for staged_card in staged_cards:
			if is_instance_valid(staged_card):
				staged_card.visible = true
		return
	for event in events:
		if String(event.get("type", "")) == "play":
			if String(event.get("side", "")) == "opponent":
				await _show_opponent_reveal(event, events)
			var played_card_type := String(event.get("card_type", service.card(String(event.get("card_id", ""))).get("card_type", "")))
			if played_card_type in ["tool", "chef"]:
				await _show_action_card_fullscreen_reveal(event)
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
	var activation_events: Array[Dictionary] = []
	for event in events:
		if _uses_field_activation_indicator(event):
			activation_events.append(event)
	if not activation_events.is_empty():
		var staged_transfer_cards := _stage_activation_result_transfers(events)
		var draw_event_count := 0
		for event in events:
			if String(event.get("type", "")) == "draw" and String(event.get("to", "hand")) == "hand":
				draw_event_count += 1
		var animate_draws_serially := draw_event_count > 1
		var arrival_duration := 0.0
		for event in events:
			if String(event.get("type", "")) in ["play", "move"]:
				arrival_duration = maxf(arrival_duration, _start_animation_event(event, play_origin_pose))
		if arrival_duration > 0.0:
			await get_tree().create_timer(arrival_duration).timeout
		for activation_event in activation_events:
			await _show_field_activation_indicator(activation_event)
		var result_duration := 0.0
		for event in events:
			var event_type := String(event.get("type", ""))
			if event_type in ["play", "move", "ability_activation", "card_text_activation"]:
				continue
			if event_type == "attack":
				await _animate_attack_motion(
					int(event.get("source_instance_id", -1)),
					int(event.get("target_instance_id", -1)),
					String(event.get("target_kind", "unit"))
				)
				continue
			if event_type in ["draw", "search"]:
				_release_staged_transfer_card(event, staged_transfer_cards)
			var event_duration := _start_animation_event(event, play_origin_pose)
			if animate_draws_serially and event_type == "draw":
				# A multi-draw effect is a sequence, not a stack of cards leaving the
				# deck together. Wait for this flight to land before starting the next.
				if event_duration > 0.0:
					await get_tree().create_timer(event_duration).timeout
			else:
				result_duration = maxf(result_duration, event_duration)
		if result_duration > 0.0:
			await get_tree().create_timer(result_duration).timeout
		for staged_card in staged_transfer_cards:
			if is_instance_valid(staged_card):
				staged_card.visible = true
		action_highlight_zone = ""
		action_highlight_slot = -1
		return
	var longest_duration := 0.0
	var swap_move_events := _paired_swap_move_events(events)
	if not swap_move_events.is_empty():
		longest_duration = _start_swap_move_animation(swap_move_events[0], swap_move_events[1])
	for event in events:
		var event_type := String(event.get("type", ""))
		if event_type == "move" and not swap_move_events.is_empty():
			continue
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
	action_highlight_zone = ""
	action_highlight_slot = -1


func _is_serial_draw_batch(events: Array[Dictionary]) -> bool:
	return events.size() > 1 and events.all(func(event: Dictionary) -> bool: return String(event.get("type", "")) == "draw" and String(event.get("to", "hand")) == "hand")


func _uses_field_activation_indicator(event: Dictionary) -> bool:
	if String(event.get("type", "")) == "ability_activation":
		return true
	if String(event.get("type", "")) != "card_text_activation":
		return false
	# Action cards have already received a full-screen spin reveal before they
	# resolve. Since they go straight to discard, a second field pulse only
	# highlights the discard pile and adds a redundant pause.
	return String(event.get("card_type", "")) not in ["tool", "chef", "reaction"]


func _paired_swap_move_events(events: Array[Dictionary]) -> Array[Dictionary]:
	var move_events: Array[Dictionary] = []
	for event in events:
		if String(event.get("type", "")) == "move":
			move_events.append(event)
	if move_events.size() != 2:
		return []
	var first: Dictionary = move_events[0]
	var second: Dictionary = move_events[1]
	if String(first.get("side", "")) != String(second.get("side", "")):
		return []
	if String(first.get("from", "")) != String(second.get("to", "")) or String(first.get("to", "")) != String(second.get("from", "")):
		return []
	return move_events


func _stage_activation_result_transfers(events: Array[Dictionary]) -> Array[Node3D]:
	var staged_cards: Array[Node3D] = []
	for event in events:
		if String(event.get("type", "")) not in ["draw", "search"] or String(event.get("to", "hand")) != "hand":
			continue
		var destination_card := _hand_card_node(
			String(event.get("side", "player")),
			int(event.get("hand_index", -1)),
			String(event.get("card_id", ""))
		)
		if destination_card == null or staged_cards.has(destination_card):
			continue
		destination_card.visible = false
		staged_cards.append(destination_card)
	return staged_cards


func _release_staged_transfer_card(event: Dictionary, staged_cards: Array[Node3D]) -> void:
	var destination_card := _hand_card_node(
		String(event.get("side", "player")),
		int(event.get("hand_index", -1)),
		String(event.get("card_id", ""))
	)
	if destination_card == null:
		return
	destination_card.visible = true
	staged_cards.erase(destination_card)


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
		"defense_position":
			return _start_defense_position_animation(event)
		"sacrifice", "destroy":
			return _start_removal_event_animation(event)
		"discard":
			return _start_opponent_discard_animation(event)
		"evaporate":
			return _start_token_evaporation_animation(event)
	return 0.0


func _start_defense_position_animation(event: Dictionary) -> float:
	var card_node := _card_node_for_instance(int(event.get("instance_id", -1)))
	if card_node == null:
		return 0.0
	var landing_position: Vector3 = card_node.get_meta("base_position", card_node.position)
	var landing_scale: Vector3 = card_node.get_meta("base_scale", card_node.scale)
	var lifted_position := landing_position + Vector3(0.0, 0.72, 0.0)
	var upright_rotation: Vector3 = card_node.get_meta("upright_rotation_degrees", card_node.rotation_degrees)
	var target_rotation := upright_rotation
	if bool(event.get("defending", false)):
		target_rotation.y += 90.0
	card_node.set_meta("base_position", landing_position)
	card_node.set_meta("base_rotation_degrees", target_rotation)
	card_node.set_meta("base_scale", landing_scale)
	var lift_tween := create_tween()
	lift_tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	lift_tween.tween_property(card_node, "position", lifted_position, 0.18)
	lift_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	lift_tween.tween_property(card_node, "position", landing_position, 0.32)
	var turn_tween := create_tween()
	turn_tween.tween_interval(0.08)
	turn_tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT)
	turn_tween.tween_property(card_node, "rotation_degrees", target_rotation, 0.30)
	var scale_tween := create_tween()
	scale_tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	scale_tween.tween_property(card_node, "scale", landing_scale * 1.08, 0.18)
	scale_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	scale_tween.tween_property(card_node, "scale", landing_scale, 0.32)
	return 0.52


func _start_play_event_animation(event: Dictionary, play_origin_pose: Dictionary) -> float:
	var side := String(event.get("side", "player"))
	var card_type := String(event.get("card_type", service.card(String(event.get("card_id", ""))).get("card_type", "")))
	if card_type != "meal":
		_play_random_card_sound(DROP_CARD_SOUNDS)
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
	if card_type == "meal":
		card_node.set_meta("play_animation_style", "meal_power")
		return _start_meal_power_arrival_animation(card_node, side, origin_pose, hand_origin)
	if card_type in ["tool", "chef"]:
		card_node.set_meta("play_animation_style", "action_fullscreen")
		return _start_action_card_discard_landing(card_node, side, card_type)
	card_node.set_meta("play_animation_style", "standard")
	_start_node_arrival_animation(card_node, origin_pose, hand_origin)
	_spawn_particle_burst(card_node.global_position + Vector3(0.0, 0.18, 0.0), PALETTE.SKY if side == "player" else PALETTE.BLUSH, 8, "◆")
	return 0.44


func _start_meal_power_arrival_animation(
	card_node: Node3D,
	side: String,
	origin_pose: Dictionary,
	hand_origin: Vector3
) -> float:
	var target_position: Vector3 = card_node.position
	var target_rotation: Vector3 = card_node.rotation_degrees
	var target_scale: Vector3 = card_node.scale
	var reveal_position := target_position + Vector3(0.0, 2.25, 0.0)
	get_tree().create_timer(MEAL_SUMMON_SOUND_DELAY_SECONDS).timeout.connect(func() -> void:
		if is_inside_tree():
			_play_card_sound(MEAL_SUMMON_SOUND, MEAL_SUMMON_VOLUME_DB)
	)
	card_node.position = origin_pose.get("position", hand_origin)
	card_node.rotation_degrees = origin_pose.get("rotation_degrees", Vector3(64.0, 0.0, 0.0))
	card_node.scale = origin_pose.get("scale", target_scale * 0.72)
	var movement := create_tween()
	movement.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	movement.tween_property(card_node, "position", reveal_position, 0.24)
	movement.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	movement.tween_property(card_node, "position", target_position, 0.34)
	var pose := create_tween()
	pose.set_parallel(true)
	pose.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pose.tween_property(card_node, "scale", target_scale * 1.72, 0.24)
	pose.tween_property(card_node, "rotation_degrees", target_rotation + Vector3(-18.0, -10.0 if side == "player" else 10.0, 0.0), 0.24)
	pose.chain().set_parallel(true)
	pose.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pose.tween_property(card_node, "scale", target_scale, 0.48)
	pose.tween_property(card_node, "rotation_degrees", target_rotation, 0.36)
	var landing_position := target_position
	var landing_accent := PALETTE.FRESH_YELLOW if side == "player" else PALETTE.BLUSH
	get_tree().create_timer(0.56).timeout.connect(func() -> void:
		_spawn_impact_flash(landing_position + Vector3(0.0, 0.22, 0.0))
		_spawn_particle_burst(landing_position + Vector3(0.0, 0.3, 0.0), landing_accent, 24, "✦")
		_spawn_cloud_puff_world(landing_position + Vector3(0.0, 0.2, 0.0), PALETTE.CREAM, landing_accent, 0.54)
	)
	return 0.74


func _start_action_card_discard_landing(
	card_node: Node3D,
	side: String,
	card_type: String
) -> float:
	var target_position: Vector3 = card_node.position
	var target_rotation: Vector3 = card_node.rotation_degrees
	var target_scale: Vector3 = card_node.scale
	card_node.position = target_position + Vector3(0.0, 0.18, 0.0)
	card_node.rotation_degrees = target_rotation
	card_node.scale = target_scale * 0.68
	var landing := create_tween().set_parallel(true)
	landing.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	landing.tween_property(card_node, "position", target_position, 0.24)
	landing.tween_property(card_node, "scale", target_scale, 0.24)
	var landing_accent := PALETTE.SKY if card_type == "tool" else PALETTE.FRESH_YELLOW
	if side == "opponent":
		landing_accent = PALETTE.BLUSH
	var landing_position := target_position
	get_tree().create_timer(0.2).timeout.connect(func() -> void:
		_spawn_particle_burst(landing_position + Vector3(0.0, 0.18, 0.0), landing_accent, 9, "◆")
	)
	return 0.28


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
	card_node.visible = true
	var source_kind := String(event.get("from", "deck"))
	var source_key := "%s_%s" % [side, "discard" if source_kind == "discard" else "deck"]
	var source_position: Vector3 = AUX_ZONE_POSITIONS[source_key] + Vector3(0.0, 0.9, 0.0)
	var destination_position := card_node.global_position
	var accent := PALETTE.SKY if side == "player" else PALETTE.BLUSH
	var show_particles := String(event.get("type", "")) != "draw"
	if show_particles:
		_spawn_particle_burst(source_position, accent, 7, "•")
	_start_node_arrival_animation(card_node, {}, source_position)
	if show_particles:
		get_tree().create_timer(0.31).timeout.connect(func() -> void: _spawn_particle_burst(destination_position + Vector3(0.0, 0.2, 0.0), accent, 9, "✦"))
	return 0.48


func _start_move_event_animation(event: Dictionary) -> float:
	_play_random_card_sound(SLIDE_CARD_SOUNDS)
	var side := String(event.get("side", "opponent"))
	var card_node := _card_node_for_instance(int(event.get("instance_id", -1)))
	if card_node == null:
		return 0.0
	var source_zone := String(event.get("from", "prep"))
	var source_key := "%s_%s" % [side, source_zone]
	var fallback_position: Vector3 = ZONE_CENTERS.get(source_key, card_node.position)
	var destination_position := card_node.global_position
	var accent := PALETTE.BLUSH if side == "opponent" else PALETTE.SKY
	_start_node_arrival_animation(card_node, event.get("origin_pose", {}), fallback_position)
	_spawn_particle_burst(fallback_position + Vector3(0.0, 0.22, 0.0), accent, 7, "•")
	get_tree().create_timer(0.34).timeout.connect(func() -> void: _spawn_particle_burst(destination_position + Vector3(0.0, 0.28, 0.0), accent, 10, "◆"))
	return 0.52


func _start_swap_move_animation(first_event: Dictionary, second_event: Dictionary) -> float:
	var first_card := _card_node_for_instance(int(first_event.get("instance_id", -1)))
	var second_card := _card_node_for_instance(int(second_event.get("instance_id", -1)))
	if first_card == null or second_card == null:
		return 0.0
	swap_move_animation_count += 1
	var first_target_position := first_card.position
	var second_target_position := second_card.position
	var first_target_rotation := first_card.rotation_degrees
	var second_target_rotation := second_card.rotation_degrees
	var first_target_scale := first_card.scale
	var second_target_scale := second_card.scale
	var first_origin_pose: Dictionary = first_event.get("origin_pose", {})
	var second_origin_pose: Dictionary = second_event.get("origin_pose", {})
	var first_source_position: Vector3 = first_origin_pose.get("position", ZONE_CENTERS.get("%s_%s" % [String(first_event.get("side", "player")), String(first_event.get("from", "prep"))], first_target_position))
	var second_source_position: Vector3 = second_origin_pose.get("position", ZONE_CENTERS.get("%s_%s" % [String(second_event.get("side", "player")), String(second_event.get("from", "prep"))], second_target_position))
	first_card.position = first_source_position
	second_card.position = second_source_position
	first_card.rotation_degrees = first_origin_pose.get("rotation_degrees", first_target_rotation)
	second_card.rotation_degrees = second_origin_pose.get("rotation_degrees", second_target_rotation)
	first_card.scale = first_origin_pose.get("scale", first_target_scale)
	second_card.scale = second_origin_pose.get("scale", second_target_scale)
	var crossing_center := (first_source_position + second_source_position) * 0.5
	var travel := second_target_position - first_source_position
	var lateral := Vector3(-travel.z, 0.0, travel.x).normalized() * 0.52
	if lateral.length_squared() < 0.01:
		lateral = Vector3(0.52, 0.0, 0.0)
	var first_midpoint := crossing_center + lateral + Vector3(0.0, 0.62, 0.0)
	var second_midpoint := crossing_center - lateral + Vector3(0.0, 0.62, 0.0)
	_spawn_particle_burst(first_source_position + Vector3(0.0, 0.18, 0.0), PALETTE.SKY, 6, "•")
	_spawn_particle_burst(second_source_position + Vector3(0.0, 0.18, 0.0), PALETTE.SKY, 6, "•")
	var first_motion := create_tween()
	first_motion.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	first_motion.tween_property(first_card, "position", first_midpoint, 0.22)
	first_motion.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	first_motion.tween_property(first_card, "position", first_target_position, 0.26)
	var second_motion := create_tween()
	second_motion.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	second_motion.tween_property(second_card, "position", second_midpoint, 0.22)
	second_motion.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	second_motion.tween_property(second_card, "position", second_target_position, 0.26)
	var first_pose := create_tween().set_parallel(true)
	first_pose.tween_property(first_card, "scale", first_target_scale * 1.12, 0.2)
	first_pose.tween_property(first_card, "rotation_degrees:y", first_target_rotation.y + 16.0, 0.2)
	first_pose.chain().set_parallel(true)
	first_pose.tween_property(first_card, "scale", first_target_scale, 0.28)
	first_pose.tween_property(first_card, "rotation_degrees", first_target_rotation, 0.28)
	var second_pose := create_tween().set_parallel(true)
	second_pose.tween_property(second_card, "scale", second_target_scale * 1.12, 0.2)
	second_pose.tween_property(second_card, "rotation_degrees:y", second_target_rotation.y - 16.0, 0.2)
	second_pose.chain().set_parallel(true)
	second_pose.tween_property(second_card, "scale", second_target_scale, 0.28)
	second_pose.tween_property(second_card, "rotation_degrees", second_target_rotation, 0.28)
	get_tree().create_timer(0.25).timeout.connect(func() -> void:
		_spawn_particle_burst(crossing_center + Vector3(0.0, 0.5, 0.0), PALETTE.FRESH_YELLOW, 12, "✦")
	)
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
	_play_attack_impact_sound(attacker_node, target_kind)
	if attacks_chef:
		_start_camera_pulse(attacker_side, 2.2)
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(attacker_node, "position", lunge_position, 0.2)
	tween.tween_property(attacker_node, "scale", origin_scale * 1.13, 0.2)
	await tween.finished
	var impact_position := target_node.global_position if target_node != null else lunge_position
	_spawn_impact_flash(impact_position)
	_spawn_particle_burst(impact_position + Vector3(0.0, 0.35, 0.0), PALETTE.CORAL, 12, "✦")
	var return_tween := create_tween().set_parallel(true)
	return_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return_tween.tween_property(attacker_node, "position", origin, 0.28)
	return_tween.tween_property(attacker_node, "scale", origin_scale, 0.24)
	await return_tween.finished


func _play_attack_impact_sound(attacker_node: Node3D, target_kind: String) -> void:
	var source_card_id := String(attacker_node.get_meta("card_id", ""))
	var source_card_type := String(service.card(source_card_id).get("card_type", "ingredient"))
	var impact_profile := _damage_impact_profile({
		"combat": true,
		"target_kind": target_kind,
		"source_card_type": source_card_type
	})
	var start_offset := MEAL_CHEF_IMPACT_START_OFFSET_SECONDS if String(impact_profile.kind) == "meal_to_chef" else 0.0
	_play_random_card_sound(
		impact_profile.sounds,
		float(impact_profile.volume_db),
		IMPACT_PITCH_VARIATION,
		start_offset
	)


func _start_damage_event_animation(event: Dictionary) -> float:
	var amount := int(event.get("amount", 0))
	if amount <= 0:
		return 0.0
	if not bool(event.get("combat", false)):
		var impact_profile := _damage_impact_profile(event)
		_play_random_card_sound(
			impact_profile.sounds,
			float(impact_profile.volume_db),
			IMPACT_PITCH_VARIATION
		)
	if String(event.get("target_kind", "unit")) == "chef":
		var chef_node := player_chef if String(event.get("target_side", "player")) == "player" else opponent_chef
		_spawn_damage_number(chef_node.global_position + Vector3(0.0, 0.65, 0.0), amount)
		_spawn_particle_burst(chef_node.global_position + Vector3(0.0, 0.5, 0.0), PALETTE.CORAL, 12, "◆")
		_animate_chef_hit(chef_node)
		return 0.42
	var card_node := _card_node_for_instance(int(event.get("target_instance_id", -1)))
	if card_node == null:
		return 0.0
	_spawn_damage_number(card_node.global_position + Vector3(0.0, 0.55, 0.0), amount)
	_spawn_particle_burst(card_node.global_position + Vector3(0.0, 0.42, 0.0), PALETTE.CORAL, 9, "•")
	_animate_hit_reaction(card_node)
	return 0.42


func _damage_impact_profile(event: Dictionary) -> Dictionary:
	if not bool(event.get("combat", false)):
		return {"sounds": EFFECT_DAMAGE_SOUNDS, "volume_db": EFFECT_DAMAGE_VOLUME_DB, "kind": "effect"}
	if String(event.get("target_kind", "unit")) != "chef":
		return {"sounds": CARD_IMPACT_SOUNDS, "volume_db": CARD_IMPACT_VOLUME_DB, "kind": "card"}
	if String(event.get("source_card_type", "ingredient")) == "meal":
		return {"sounds": MEAL_CHEF_IMPACT_SOUNDS, "volume_db": MEAL_CHEF_IMPACT_VOLUME_DB, "kind": "meal_to_chef"}
	return {"sounds": INGREDIENT_CHEF_IMPACT_SOUNDS, "volume_db": INGREDIENT_CHEF_IMPACT_VOLUME_DB, "kind": "ingredient_to_chef"}


func _play_random_card_sound(sounds: Array, volume_db: float = 0.0, pitch_variation: float = 0.0, from_position: float = 0.0) -> void:
	if sounds.is_empty():
		return
	var pitch_scale := randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
	_play_card_sound(sounds[randi_range(0, sounds.size() - 1)] as AudioStream, volume_db, pitch_scale, from_position)


func _play_card_sound(stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0, from_position: float = 0.0) -> void:
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = &"SFX"
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play(from_position)


func _play_positive_effect_sound() -> void:
	var now := Time.get_ticks_msec()
	if now - last_positive_effect_sound_msec < POSITIVE_EFFECT_SOUND_COOLDOWN_MSEC:
		return
	last_positive_effect_sound_msec = now
	_play_card_sound(POSITIVE_EFFECT_SOUND, POSITIVE_EFFECT_VOLUME_DB, randf_range(0.98, 1.02))


func _start_heal_event_animation(event: Dictionary) -> float:
	var amount := int(event.get("amount", 0))
	if amount <= 0:
		return 0.0
	_play_positive_effect_sound()
	if String(event.get("target_kind", "unit")) == "chef":
		var chef_node := player_chef if String(event.get("target_side", "player")) == "player" else opponent_chef
		_spawn_floating_number(chef_node.global_position + Vector3(0.0, 0.65, 0.0), "+%d" % amount, PALETTE.TEAL)
		_spawn_cloud_puff_world(chef_node.global_position + Vector3(0.0, 0.5, 0.0), PALETTE.CREAM, PALETTE.TEAL, 0.62)
		_spawn_particle_burst(chef_node.global_position + Vector3(0.0, 0.5, 0.0), PALETTE.SKY, 8, "+")
		_animate_positive_reaction(chef_node)
		return 0.42
	var card_node := _card_node_for_instance(int(event.get("target_instance_id", -1)))
	if card_node == null:
		return 0.0
	_spawn_floating_number(card_node.global_position + Vector3(0.0, 0.55, 0.0), "+%d" % amount, PALETTE.TEAL)
	_spawn_cloud_puff_world(card_node.global_position + Vector3(0.0, 0.42, 0.0), PALETTE.CREAM, PALETTE.TEAL, 0.56)
	_spawn_particle_burst(card_node.global_position + Vector3(0.0, 0.42, 0.0), PALETTE.SKY, 7, "+")
	_animate_positive_reaction(card_node)
	return 0.42


func _start_buff_event_animation(event: Dictionary) -> float:
	var card_node := _card_node_for_instance(int(event.get("target_instance_id", -1)))
	if card_node == null:
		return 0.0
	var parts: Array[String] = []
	var attack_delta := int(event.get("attack_delta", 0))
	var health_delta := int(event.get("health_delta", 0))
	if attack_delta > 0 or health_delta > 0:
		_play_positive_effect_sound()
	if attack_delta != 0:
		parts.append("%s%d ATK" % ["+" if attack_delta > 0 else "", attack_delta])
	if health_delta != 0:
		parts.append("%s%d HP" % ["+" if health_delta > 0 else "", health_delta])
	_spawn_floating_number(card_node.global_position + Vector3(0.0, 0.55, 0.0), "  ".join(parts), PALETTE.FRESH_YELLOW)
	_spawn_celestial_orbit_screen(_world_to_container(card_node.global_position + Vector3(0.0, 0.42, 0.0)), PALETTE.FRESH_YELLOW, Vector2(58.0, 34.0), 0.68)
	_spawn_particle_burst(card_node.global_position + Vector3(0.0, 0.42, 0.0), PALETTE.FRESH_YELLOW, 9, "✦")
	_animate_positive_reaction(card_node)
	return 0.46


func _start_removal_event_animation(event: Dictionary) -> float:
	var card_node := _card_node_for_instance(int(event.get("instance_id", -1)))
	if card_node == null:
		return 0.0
	var side := String(event.get("side", "player"))
	var origin_position := card_node.position
	var discard_position: Vector3 = AUX_ZONE_POSITIONS["%s_discard" % side] + Vector3(0.0, 0.24, 0.0)
	var travel_midpoint := origin_position.lerp(discard_position, 0.42) + Vector3(0.0, 0.76, 0.0)
	var discard_scale := Vector3.ONE * 0.54
	_spawn_cloud_puff_world(card_node.global_position + Vector3(0.0, 0.3, 0.0), PALETTE.LAVENDER_GLASS, PALETTE.LAVENDER, 0.58)
	_spawn_particle_burst(card_node.global_position + Vector3(0.0, 0.3, 0.0), PALETTE.LAVENDER, 7, "◆")
	var travel := create_tween()
	travel.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	travel.tween_property(card_node, "position", travel_midpoint, 0.2)
	travel.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	travel.tween_property(card_node, "position", discard_position, 0.38)
	var pose := create_tween().set_parallel(true)
	pose.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	pose.tween_property(card_node, "scale", discard_scale * 1.12, 0.2)
	pose.tween_property(card_node, "rotation_degrees:y", card_node.rotation_degrees.y + 130.0, 0.2)
	pose.chain().set_parallel(true)
	pose.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	pose.tween_property(card_node, "scale", discard_scale, 0.38)
	pose.tween_property(card_node, "rotation_degrees:y", card_node.rotation_degrees.y + 220.0, 0.38)
	get_tree().create_timer(0.54).timeout.connect(func() -> void:
		_spawn_cloud_puff_world(discard_position + Vector3(0.0, 0.14, 0.0), PALETTE.LAVENDER_GLASS, PALETTE.LAVENDER, 0.52)
		_spawn_particle_burst(discard_position + Vector3(0.0, 0.14, 0.0), PALETTE.LAVENDER, 8, "✦")
	)
	var floating_art := card_node.find_child("FloatingArt", true, false) as MeshInstance3D
	if floating_art != null:
		pose.tween_property(floating_art, "scale", Vector3.ZERO, 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		var art_material := floating_art.material_override as StandardMaterial3D
		if art_material != null:
			pose.tween_property(art_material, "albedo_color:a", 0.0, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	for badge_name in ["Stats", "Status"]:
		var badge := card_node.find_child(badge_name, true, false) as Label3D
		if badge != null:
			pose.tween_property(badge, "scale", Vector3.ZERO, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			pose.tween_property(badge, "modulate:a", 0.0, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		var backing := card_node.find_child(badge_name + "Backing", true, false) as Sprite3D
		if backing != null:
			pose.tween_property(backing, "scale", Vector3.ZERO, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			pose.tween_property(backing, "modulate:a", 0.0, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	return 0.6


func _start_opponent_discard_animation(event: Dictionary) -> float:
	if String(event.get("side", "")) != "opponent":
		return 0.0
	var card_id := String(event.get("card_id", ""))
	if card_id == "":
		return 0.0
	var discard_card := _make_card(card_id, true)
	discard_card.name = "OpponentDiscardAnimation_%s" % card_id
	var discard_order := int(event.get("discard_order", 0))
	var discard_count: int = max(1, int(event.get("discard_count", 1)))
	var spread := (float(discard_order) - float(discard_count - 1) * 0.5) * 0.42
	var origin := Vector3(spread, 0.86, OPPONENT_HAND_Z + 0.25)
	if String(event.get("from", "hand")) == "deck":
		origin = AUX_ZONE_POSITIONS["opponent_deck"] + Vector3(0.0, 0.74, 0.0)
	var destination := AUX_ZONE_POSITIONS["opponent_discard"] + Vector3(0.0, 0.25 + float(discard_order) * 0.025, 0.0)
	discard_card.position = origin
	discard_card.rotation_degrees = Vector3(62.0, -8.0 + spread * 18.0, 0.0)
	discard_card.scale = Vector3.ONE * 0.58
	animation_ghost_layer.add_child(discard_card)
	_spawn_particle_burst(origin + Vector3(0.0, 0.18, 0.0), PALETTE.BLUSH, 6, "•")
	var midpoint := origin.lerp(destination, 0.48) + Vector3(0.0, 0.72, 0.0)
	var travel := create_tween()
	travel.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	travel.tween_property(discard_card, "position", midpoint, 0.20)
	travel.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	travel.tween_property(discard_card, "position", destination, 0.32)
	var pose := create_tween().set_parallel(true)
	pose.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	pose.tween_property(discard_card, "scale", Vector3.ONE * 0.68, 0.20)
	pose.tween_property(discard_card, "rotation_degrees:y", 110.0, 0.20)
	pose.chain().set_parallel(true)
	pose.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	pose.tween_property(discard_card, "scale", Vector3.ONE * 0.54, 0.32)
	pose.tween_property(discard_card, "rotation_degrees:y", 182.0, 0.32)
	get_tree().create_timer(0.48).timeout.connect(func() -> void:
		_spawn_cloud_puff_world(destination + Vector3(0.0, 0.14, 0.0), PALETTE.LAVENDER_GLASS, PALETTE.BLUSH, 0.5)
		_spawn_particle_burst(destination + Vector3(0.0, 0.14, 0.0), PALETTE.BLUSH, 8, "✦")
	)
	get_tree().create_timer(0.66).timeout.connect(func() -> void:
		if is_instance_valid(discard_card):
			discard_card.queue_free()
	)
	return 0.62


func _start_token_evaporation_animation(event: Dictionary) -> float:
	var card_node := _card_node_for_instance(int(event.get("instance_id", -1)))
	if card_node == null:
		return 0.0
	token_evaporation_animation_count += 1
	var origin_position := card_node.position
	var origin_global_position := card_node.global_position
	var origin_scale := card_node.scale
	var origin_rotation_y := card_node.rotation_degrees.y
	var vapor_color := PALETTE.TEAL
	_spawn_cloud_puff_world(origin_global_position + Vector3(0.0, 0.32, 0.0), PALETTE.CREAM, PALETTE.TEAL, 0.68)
	_spawn_particle_burst(origin_global_position + Vector3(0.0, 0.28, 0.0), vapor_color, 14, "•")
	_spawn_floating_number(origin_global_position + Vector3(0.0, 0.58, 0.0), "EVAPORATES", vapor_color)

	var rise := create_tween()
	rise.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	rise.tween_property(card_node, "position", origin_position + Vector3(0.0, 0.32, 0.0), 0.18)
	rise.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	rise.tween_property(card_node, "position", origin_position + Vector3(0.0, 1.12, 0.0), 0.46)

	var dissolve := create_tween().set_parallel(true)
	dissolve.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	dissolve.tween_property(card_node, "scale", origin_scale * 1.08, 0.16)
	dissolve.tween_property(card_node, "rotation_degrees:y", origin_rotation_y + 32.0, 0.16)
	dissolve.chain().set_parallel(true)
	dissolve.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	dissolve.tween_property(
		card_node,
		"scale",
		Vector3(origin_scale.x * 0.06, origin_scale.y * 1.2, origin_scale.z * 0.06),
		0.48
	)
	dissolve.tween_property(card_node, "rotation_degrees:y", origin_rotation_y + 210.0, 0.48)

	var floating_art := card_node.find_child("FloatingArt", true, false) as MeshInstance3D
	if floating_art != null:
		var art_fade := create_tween()
		art_fade.tween_interval(0.16)
		art_fade.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		art_fade.tween_property(floating_art, "scale", Vector3.ZERO, 0.36)
	for badge_name in ["Stats", "Status"]:
		var badge := card_node.find_child(badge_name, true, false) as Label3D
		if badge != null:
			var badge_fade := create_tween()
			badge_fade.tween_interval(0.14)
			badge_fade.tween_property(badge, "modulate:a", 0.0, 0.3)
		var backing := card_node.find_child(badge_name + "Backing", true, false) as Sprite3D
		if backing != null:
			var backing_fade := create_tween()
			backing_fade.tween_interval(0.14)
			backing_fade.tween_property(backing, "modulate:a", 0.0, 0.3)

	get_tree().create_timer(0.3).timeout.connect(func() -> void:
		_spawn_particle_burst(origin_global_position + Vector3(0.0, 0.72, 0.0), vapor_color.lightened(0.12), 20, "✦")
	)
	return 0.66


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
	_spawn_floating_number(world_position, "-%d" % amount, PALETTE.CORAL)


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
	var screen_position := _world_to_container(world_position)
	_spawn_impact_rays_screen(screen_position, PALETTE.CORAL, 9, 0.42)
	_spawn_screen_particle_burst(screen_position, PALETTE.FRESH_YELLOW, 5, "✦")


func _show_field_activation_indicator(event: Dictionary) -> void:
	var card_id := String(event.get("card_id", ""))
	if card_id == "":
		return
	var activation_kind := String(event.get("type", "card_text_activation"))
	if activation_kind in ["ability_activation", "card_text_activation"]:
		_play_ability_activation_sound()
	field_activation_indicator_count += 1
	last_field_activation_card_id = card_id
	last_field_activation_kind = activation_kind
	var source_instance_id := int(event.get("source_instance_id", event.get("instance_id", -1)))
	var card_node := _card_node_for_instance(source_instance_id) if source_instance_id >= 0 else null
	var side := String(event.get("side", "player"))
	if card_node == null and String(event.get("card_type", "")) in ["tool", "chef", "reaction"]:
		card_node = find_child("%sDiscardTop" % side.capitalize(), true, false) as Node3D
	if card_node == null and String(event.get("card_type", "")) == "environment":
		card_node = find_child("%sEnvironmentCard" % side.capitalize(), true, false) as Node3D
	var accent := PALETTE.FRESH_YELLOW if side == "player" else PALETTE.BLUSH
	var source_screen := effect_layer.size * 0.5
	if card_node != null:
		source_screen = _world_to_container(card_node.global_position + Vector3(0.0, 0.34, 0.0))
		_spawn_particle_burst(card_node.global_position + Vector3(0.0, 0.22, 0.0), accent, 10, "✦")
	var indicator := PanelContainer.new()
	indicator.name = "FieldActivationIndicator"
	indicator.custom_minimum_size = Vector2(410.0, 78.0)
	indicator.size = indicator.custom_minimum_size
	indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	indicator.z_index = 238
	var indicator_style := StyleBoxFlat.new()
	indicator_style.bg_color = Color(PALETTE.CREAM, 0.97)
	indicator_style.border_color = Color(accent.r, accent.g, accent.b, 0.96)
	indicator_style.set_border_width_all(3)
	indicator_style.set_corner_radius_all(20)
	indicator_style.shadow_color = Color(PALETTE.NAVY, 0.18)
	indicator_style.shadow_size = 8
	indicator.add_theme_stylebox_override("panel", indicator_style)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	var copy := VBoxContainer.new()
	copy.add_theme_constant_override("separation", 0)
	var header := _label(String(event.get("activation_label", "ABILITY")), 14, PALETTE.NAVY_MUTED)
	header.text = "✦  %s" % header.text
	var card_name := _label(String(service.card(card_id).get("name", card_id)), 22, PALETTE.NAVY)
	card_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	copy.add_child(header)
	copy.add_child(card_name)
	margin.add_child(copy)
	indicator.add_child(margin)
	var panel_size := indicator.custom_minimum_size
	indicator.position = Vector2(
		clampf(source_screen.x - panel_size.x * 0.5, 18.0, maxf(18.0, effect_layer.size.x - panel_size.x - 18.0)),
		clampf(source_screen.y - panel_size.y - 72.0, 92.0, maxf(92.0, effect_layer.size.y - panel_size.y - 120.0))
	)
	indicator.pivot_offset = panel_size * 0.5
	indicator.scale = Vector2(0.78, 0.78)
	indicator.modulate.a = 0.0
	effect_layer.add_child(indicator)
	var card_origin_position := card_node.position if card_node != null else Vector3.ZERO
	var card_origin_scale := card_node.scale if card_node != null else Vector3.ONE
	var aura: MeshInstance3D
	var aura_material: StandardMaterial3D
	if card_node != null:
		aura = MeshInstance3D.new()
		aura.name = "ActivationPulseAura"
		aura.position = Vector3(0.0, 0.025, 0.0)
		aura.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
		aura.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var aura_mesh := QuadMesh.new()
		aura_mesh.size = Vector2(1.48, 2.04)
		aura.mesh = aura_mesh
		aura_material = StandardMaterial3D.new()
		aura_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		aura_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		aura_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		aura_material.albedo_texture = ABILITY_READY_AURA
		aura_material.albedo_color = Color(accent.r, accent.g, accent.b, 0.0)
		aura_material.emission_enabled = true
		aura_material.emission = accent
		aura_material.emission_texture = ABILITY_READY_AURA
		aura_material.emission_energy_multiplier = 1.8
		aura.material_override = aura_material
		aura.scale = Vector3(0.72, 0.72, 0.72)
		card_node.add_child(aura)
	var entrance := create_tween().set_parallel(true)
	entrance.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	entrance.tween_property(indicator, "scale", Vector2.ONE, 0.18)
	entrance.tween_property(indicator, "modulate:a", 1.0, 0.12)
	if card_node != null:
		entrance.tween_property(card_node, "position", card_origin_position + Vector3(0.0, 0.3, 0.0), 0.18)
		entrance.tween_property(card_node, "scale", card_origin_scale * 1.12, 0.18)
		entrance.tween_property(aura, "scale", Vector3.ONE * 1.18, 0.22)
		entrance.tween_property(aura_material, "albedo_color:a", 0.9, 0.12)
	await entrance.finished
	await get_tree().create_timer(0.36).timeout
	var leave := create_tween().set_parallel(true)
	leave.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	leave.tween_property(indicator, "scale", Vector2(1.04, 1.04), 0.18)
	leave.tween_property(indicator, "modulate:a", 0.0, 0.16)
	if card_node != null and is_instance_valid(card_node):
		leave.tween_property(card_node, "position", card_origin_position, 0.2)
		leave.tween_property(card_node, "scale", card_origin_scale, 0.2)
	if aura != null and is_instance_valid(aura):
		leave.tween_property(aura, "scale", Vector3.ONE * 1.42, 0.18)
		leave.tween_property(aura_material, "albedo_color:a", 0.0, 0.16)
	await leave.finished
	indicator.queue_free()
	if aura != null and is_instance_valid(aura):
		aura.queue_free()


func _play_ability_activation_sound() -> void:
	if ability_activation_sound_player == null:
		ability_activation_sound_player = AudioStreamPlayer.new()
		ability_activation_sound_player.name = "AbilityActivationSound"
		ability_activation_sound_player.stream = ABILITY_ACTIVATION_SOUND
		ability_activation_sound_player.bus = &"SFX"
		ability_activation_sound_player.volume_db = ABILITY_ACTIVATION_VOLUME_DB
		add_child(ability_activation_sound_player)
	else:
		ability_activation_sound_player.stop()
	ability_activation_sound_player.play()


func _show_action_card_fullscreen_reveal(event: Dictionary) -> void:
	var card_id := String(event.get("card_id", ""))
	if card_id == "":
		return
	var card_type := String(event.get("card_type", service.card(card_id).get("card_type", "")))
	if card_type not in ["tool", "chef"]:
		return
	fullscreen_action_reveal_count += 1
	last_fullscreen_action_reveal_card_id = card_id
	last_fullscreen_action_reveal_type = card_type
	var side := String(event.get("side", "player"))
	var hold_seconds := _action_card_reveal_hold_seconds(side, service.card(card_id))
	last_fullscreen_action_reveal_hold_seconds = hold_seconds
	var accent := PALETTE.SKY if card_type == "tool" else PALETTE.FRESH_YELLOW
	if side == "opponent":
		accent = PALETTE.BLUSH
	var dimmer := ColorRect.new()
	dimmer.name = "ActionCardRevealDimmer"
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.005, 0.012, 0.018, 0.0)
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dimmer.z_index = 242
	effect_layer.add_child(dimmer)
	var reveal_card := TextureRect.new()
	reveal_card.name = "ActionCardFullscreenReveal"
	reveal_card.texture = CARD_BACK
	reveal_card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	reveal_card.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	reveal_card.size = ACTION_REVEAL_CARD_SIZE
	reveal_card.pivot_offset = reveal_card.size * 0.5
	var source_world := Vector3(0.0, 0.9, PLAYER_HAND_Z if side == "player" else OPPONENT_HAND_Z)
	reveal_card.position = _world_to_container(source_world) - reveal_card.pivot_offset
	reveal_card.scale = Vector2(0.42, 0.42)
	reveal_card.rotation = -TAU if side == "player" else TAU
	reveal_card.modulate.a = 0.0
	reveal_card.z_index = 244
	reveal_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect_layer.add_child(reveal_card)
	var reveal_border := Panel.new()
	reveal_border.name = "ActionCardRevealBorder"
	reveal_card.add_child(reveal_border)
	reveal_border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	reveal_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var reveal_border_style := StyleBoxFlat.new()
	reveal_border_style.bg_color = Color.TRANSPARENT
	reveal_border_style.draw_center = false
	reveal_border_style.border_color = _action_reveal_border_color()
	reveal_border_style.set_border_width_all(8)
	reveal_border_style.set_corner_radius_all(20)
	reveal_border.add_theme_stylebox_override("panel", reveal_border_style)
	var type_name := "ITEM" if card_type == "tool" else "CHEF"
	var type_label := _label("%s • %s" % ["RIVAL PLAYS" if side == "opponent" else "YOU PLAY", type_name], 18, accent)
	type_label.name = "ActionCardRevealType"
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.add_theme_color_override("font_outline_color", Color("#080d12"))
	type_label.add_theme_constant_override("outline_size", 8)
	type_label.size = Vector2(360.0, 40.0)
	type_label.position = Vector2(effect_layer.size.x * 0.5 - 180.0, effect_layer.size.y * 0.5 - reveal_card.size.y * 0.5 - 48.0)
	type_label.modulate.a = 0.0
	type_label.z_index = 245
	type_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect_layer.add_child(type_label)
	var center_position := effect_layer.size * 0.5 - reveal_card.pivot_offset
	var approach := create_tween().set_parallel(true)
	approach.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	approach.tween_property(dimmer, "color:a", 0.42, 0.24)
	approach.tween_property(reveal_card, "position", center_position, 0.3)
	approach.tween_property(reveal_card, "scale", Vector2.ONE, 0.3)
	approach.tween_property(reveal_card, "rotation", 0.0, 0.3)
	approach.tween_property(reveal_card, "modulate:a", 1.0, 0.16)
	approach.tween_property(type_label, "modulate:a", 1.0, 0.18)
	await approach.finished
	var close_flip := create_tween()
	close_flip.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	close_flip.tween_property(reveal_card, "scale:x", 0.04, 0.09)
	await close_flip.finished
	reveal_card.texture = _face_material(card_id).albedo_texture
	var open_flip := create_tween()
	open_flip.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	open_flip.tween_property(reveal_card, "scale:x", 1.0, 0.18)
	await open_flip.finished
	_spawn_screen_particle_burst(effect_layer.size * 0.5, accent, 18, "✦")
	await get_tree().create_timer(hold_seconds).timeout
	var leave := create_tween().set_parallel(true)
	leave.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	leave.tween_property(dimmer, "color:a", 0.0, 0.16)
	leave.tween_property(reveal_card, "modulate:a", 0.0, 0.16)
	leave.tween_property(reveal_card, "scale", Vector2(1.08, 1.08), 0.16)
	leave.tween_property(type_label, "modulate:a", 0.0, 0.12)
	await leave.finished
	reveal_card.queue_free()
	type_label.queue_free()
	dimmer.queue_free()


func _action_reveal_border_color() -> Color:
	var border_id := configured_card_border_id if production_match else "black"
	match border_id:
		"blue":
			return PALETTE.PERIWINKLE
		"yellow", "gold":
			return PALETTE.HONEY
		"silver":
			return Color("#B8BBD0")
		_:
			return PALETTE.NAVY


func _action_card_reveal_hold_seconds(side: String, _data: Dictionary) -> float:
	if side != "opponent":
		return 0.35
	match String(RIVAL_PACING_OPTIONS[rival_pacing_index].id):
		"fast":
			return 0.55
		"slow":
			return 1.1
	return 0.8


func _show_opponent_reveal(event: Dictionary, event_batch: Array[Dictionary] = []) -> void:
	var card_id := String(event.get("card_id", ""))
	if card_id == "":
		return
	var data: Dictionary = service.card(card_id)
	var summary := _rival_action_summary(event, event_batch)
	latest_rival_card_id = card_id
	latest_rival_card_data = data.duplicate(true)
	latest_rival_summary = summary.duplicate(true)
	_present_rival_action(card_id, data, summary)
	_set_action_highlight(event)


func _open_game_breakdown() -> void:
	if game_breakdown_active or latest_rival_card_id == "":
		return
	game_breakdown_active = true
	if is_instance_valid(game_breakdown_button):
		game_breakdown_button.disabled = true
	await _show_game_breakdown(latest_rival_card_id, latest_rival_card_data, latest_rival_summary)
	game_breakdown_active = false
	if is_instance_valid(game_breakdown_button):
		game_breakdown_button.disabled = false


func _show_game_breakdown(card_id: String, data: Dictionary, summary: Dictionary) -> void:
	var dimmer := ColorRect.new()
	dimmer.name = "OpponentRevealDimmer"
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.005, 0.012, 0.018, 0.0)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	dimmer.z_index = 244
	effect_layer.add_child(dimmer)

	var reveal_panel := PanelContainer.new()
	reveal_panel.name = "OpponentRevealPanel"
	reveal_panel.size = Vector2(720.0, 478.0)
	reveal_panel.position = effect_layer.size * 0.5 - reveal_panel.size * 0.5
	reveal_panel.pivot_offset = reveal_panel.size * 0.5
	reveal_panel.scale = Vector2(0.86, 0.86)
	reveal_panel.modulate.a = 0.0
	reveal_panel.z_index = 245
	reveal_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.025, 0.065, 0.085, 0.985)
	panel_style.border_color = Color("#e66da5")
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(20)
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.65)
	panel_style.shadow_size = 20
	reveal_panel.add_theme_stylebox_override("panel", panel_style)
	effect_layer.add_child(reveal_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 20)
	reveal_panel.add_child(margin)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 24)
	margin.add_child(body)
	var card_center := CenterContainer.new()
	card_center.custom_minimum_size = Vector2(308, 438)
	body.add_child(card_center)
	var reveal_card := TextureRect.new()
	reveal_card.name = "OpponentRevealCard"
	reveal_card.texture = CARD_BACK
	reveal_card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	reveal_card.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	reveal_card.custom_minimum_size = Vector2(300.0, 426.0)
	reveal_card.pivot_offset = Vector2(150.0, 213.0)
	reveal_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_center.add_child(reveal_card)

	var explanation := VBoxContainer.new()
	explanation.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	explanation.add_theme_constant_override("separation", 8)
	body.add_child(explanation)
	var reveal_label := _label("RIVAL PLAYS", 17, Color("#ffd0e5"))
	explanation.add_child(reveal_label)
	var name_label := _label(String(data.get("name", card_id)), 30, Color("#fff3cf"))
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation.add_child(name_label)
	var meta_label := _label(String(summary.meta), 16, Color("#f1c66e"))
	meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation.add_child(meta_label)
	var rules_heading := _label("PRINTED EFFECT", 12, Color("#8fcce5"))
	explanation.add_child(rules_heading)
	var rules_label := _label(String(data.get("text", "")), 18, Color("#edf4f6"))
	rules_label.custom_minimum_size = Vector2(0, 122)
	rules_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	rules_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	rules_label.add_theme_constant_override("line_spacing", 4)
	explanation.add_child(rules_label)
	var outcome_heading := _label("WHAT HAPPENED", 12, Color("#f2a0c5"))
	explanation.add_child(outcome_heading)
	var outcome_label := _label(String(summary.outcome), 17, Color("#8fddf5"))
	outcome_label.custom_minimum_size = Vector2(0, 78)
	outcome_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outcome_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	outcome_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	explanation.add_child(outcome_label)
	var continue_button := _styled_button("Resume Game  •  Space")
	continue_button.name = "OpponentRevealContinueButton"
	continue_button.custom_minimum_size = Vector2(0, 42)
	continue_button.pressed.connect(func() -> void: reveal_skip_requested = true)
	explanation.add_child(continue_button)

	reveal_active = true
	reveal_skip_requested = false
	var approach := create_tween().set_parallel(true)
	approach.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	approach.tween_property(dimmer, "color:a", 0.56, 0.2)
	approach.tween_property(reveal_panel, "modulate:a", 1.0, 0.2)
	approach.tween_property(reveal_panel, "scale", Vector2.ONE, 0.26)
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
	_spawn_celestial_orbit_screen(effect_layer.size * 0.5, PALETTE.BLUSH, Vector2(210.0, 132.0), 0.9)
	_spawn_screen_particle_burst(effect_layer.size * 0.5, PALETTE.BLUSH, 10, "✦")
	while not reveal_skip_requested:
		await get_tree().process_frame
	reveal_active = false
	var leave := create_tween().set_parallel(true)
	leave.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	leave.tween_property(dimmer, "color:a", 0.0, 0.16)
	leave.tween_property(reveal_panel, "modulate:a", 0.0, 0.16)
	leave.tween_property(reveal_panel, "scale", Vector2(1.04, 1.04), 0.16)
	await leave.finished
	reveal_panel.queue_free()
	dimmer.queue_free()


func _unhandled_key_input(event: InputEvent) -> void:
	if not reveal_active or not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
		reveal_skip_requested = true
		get_viewport().set_input_as_handled()


func _present_rival_action(card_id: String, data: Dictionary, summary: Dictionary) -> void:
	if not is_instance_valid(rival_action_panel):
		return
	game_breakdown_button.disabled = false
	rival_action_face.texture = _face_material(card_id).albedo_texture
	rival_action_name_label.text = String(data.get("name", card_id))
	rival_action_meta_label.text = String(summary.meta)
	rival_action_rules_label.text = String(data.get("text", ""))
	rival_action_outcome_label.text = String(summary.outcome)
	var recent_line := "%s — %s" % [String(data.get("name", card_id)), String(summary.outcome)]
	rival_recent_actions.push_front(recent_line)
	if rival_recent_actions.size() > 3:
		rival_recent_actions.resize(3)
	var recent_lines: Array[String] = []
	for action_index in range(rival_recent_actions.size()):
		recent_lines.append("[color=#f2a0c5]%d[/color]  %s" % [action_index + 1, rival_recent_actions[action_index]])
	rival_recent_actions_label.text = "\n".join(recent_lines)
	rival_action_panel.visible = false


func _rival_action_summary(event: Dictionary, event_batch: Array[Dictionary]) -> Dictionary:
	var card_type := String(event.get("card_type", service.card(String(event.get("card_id", ""))).get("card_type", "card")))
	var destination := String(event.get("zone", ""))
	if destination == "":
		destination = String(event.get("to", ""))
	var destination_label := ""
	match destination:
		"prep", "plated":
			destination_label = destination.capitalize()
		"attachment":
			destination_label = "Attached to a unit"
		"environment":
			destination_label = "Environment slot"
		"discard":
			destination_label = "Resolved, then discarded"
		_:
			destination_label = destination.capitalize()
	var outcome_parts: Array[String] = []
	var opponent_draws := 0
	for effect_event in event_batch:
		var effect_type := String(effect_event.get("type", ""))
		if effect_type == "play":
			continue
		if effect_type == "draw" and String(effect_event.get("side", "")) == "opponent":
			opponent_draws += 1
			continue
		var phrase := _readable_event_phrase(effect_event)
		if phrase != "" and not outcome_parts.has(phrase):
			outcome_parts.append(phrase)
	if opponent_draws > 0:
		outcome_parts.push_front("Drew %d card%s." % [opponent_draws, "" if opponent_draws == 1 else "s"])
	if outcome_parts.is_empty():
		outcome_parts.append("The card resolved with no additional visible change.")
	return {
		"meta": "%s  •  %s" % [card_type.capitalize(), destination_label],
		"outcome": " ".join(outcome_parts)
	}


func _readable_event_phrase(event: Dictionary) -> String:
	var event_type := String(event.get("type", ""))
	match event_type:
		"damage":
			return "Dealt %d damage to %s." % [int(event.get("amount", 0)), _readable_event_target(event)]
		"heal":
			return "Healed %s for %d." % [_readable_event_target(event), int(event.get("amount", 0))]
		"buff":
			var changes: Array[String] = []
			var attack_delta := int(event.get("attack_delta", 0))
			var health_delta := int(event.get("health_delta", 0))
			if attack_delta != 0:
				changes.append("%+d Attack" % attack_delta)
			if health_delta != 0:
				changes.append("%+d Health" % health_delta)
			return "Changed %s by %s." % [_readable_event_target(event), " and ".join(changes)]
		"destroy":
			return "Destroyed %s." % _event_card_name(event)
		"sacrifice":
			return "Sacrificed %s." % _event_card_name(event)
		"evaporate":
			return "%s evaporated instead of entering %s." % [
				_event_card_name(event),
				String(event.get("attempted_destination", "another zone")).capitalize()
			]
		"move":
			return "Moved %s to %s." % [_event_card_name(event), String(event.get("to", "a new zone")).capitalize()]
		"defense_position":
			return "%s entered Defense." % _event_card_name(event) if bool(event.get("defending", false)) else "%s returned upright." % _event_card_name(event)
		"search":
			return "Searched their deck."
	return ""


func _readable_event_target(event: Dictionary) -> String:
	var target_side := String(event.get("target_side", event.get("side", "opponent")))
	var target_kind := String(event.get("target_kind", "unit"))
	if target_kind in ["player", "chef"]:
		return "your Chef" if target_side == "player" else "their Chef"
	var target_instance_id := int(event.get("target_instance_id", event.get("instance_id", -1)))
	for side in ["player", "opponent"]:
		var unit: Dictionary = service._find_unit(state[side], target_instance_id)
		if not unit.is_empty():
			return String(unit.get("name", "a unit"))
	return "a unit"


func _event_card_name(event: Dictionary) -> String:
	var card_id := String(event.get("card_id", ""))
	if card_id != "":
		return String(service.card(card_id).get("name", card_id))
	var instance_id := int(event.get("instance_id", event.get("target_instance_id", -1)))
	for side in ["player", "opponent"]:
		var unit: Dictionary = service._find_unit(state[side], instance_id)
		if not unit.is_empty():
			return String(unit.get("name", "a card"))
	return "a card"


func _set_action_highlight(event: Dictionary) -> void:
	var zone := String(event.get("zone", ""))
	if zone not in ["prep", "plated"]:
		action_highlight_zone = ""
		action_highlight_slot = -1
		return
	action_highlight_zone = "opponent_%s" % zone
	action_highlight_slot = -1
	var instance_id := int(event.get("instance_id", -1))
	var unit: Dictionary = service._find_unit(state.opponent, instance_id)
	if not unit.is_empty():
		action_highlight_slot = int(unit.get("table_slot", -1))


func _spawn_particle_burst(world_position: Vector3, color: Color, count: int = 10, glyph: String = "•") -> void:
	_spawn_screen_particle_burst(_world_to_container(world_position), color, count, glyph)


func _spawn_screen_particle_burst(screen_position: Vector2, color: Color, count: int = 10, glyph: String = "•") -> void:
	if effect_layer == null or count <= 0:
		return
	var actual_count := mini(count, 7) if reduced_motion else count
	var supporting_colors: Array[Color] = [color, PALETTE.CREAM, PALETTE.FRESH_YELLOW]
	for particle_index in range(actual_count):
		var particle_style := glyph
		if glyph == "✦" and particle_index % 3 == 2:
			particle_style = "•"
		elif glyph == "◆" and particle_index % 3 == 1:
			particle_style = "✦"
		var radius := 5.0 + float(particle_index % 4) * 1.55
		var fill := supporting_colors[particle_index % supporting_colors.size()]
		var particle := _outlined_particle(particle_style, radius, fill)
		particle.position = screen_position
		particle.scale = Vector2(0.22, 0.22)
		particle.z_index = 235
		effect_layer.add_child(particle)
		var angle := TAU * float(particle_index) / float(actual_count) + float(particle_index % 3) * 0.17
		var distance := 34.0 + float((particle_index * 17) % 54)
		var destination := particle.position + Vector2(cos(angle), sin(angle)) * distance
		var duration := (0.34 if reduced_motion else 0.46) + float(particle_index % 4) * 0.035
		var tween := create_tween().set_parallel(true)
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(particle, "position", destination, duration)
		tween.tween_property(particle, "scale", Vector2.ONE * (0.82 + float(particle_index % 3) * 0.12), duration * 0.42)
		if not reduced_motion:
			tween.tween_property(particle, "rotation", angle * 0.28, duration)
		tween.tween_property(particle, "modulate:a", 0.0, duration * 0.55).set_delay(duration * 0.45)
		tween.finished.connect(particle.queue_free)


func _outlined_particle(style: String, radius: float, fill: Color, outline: Color = PALETTE.NAVY) -> Polygon2D:
	var particle := Polygon2D.new()
	particle.polygon = _particle_polygon(style, radius + VFX_OUTLINE_WIDTH)
	particle.color = Color(outline.r, outline.g, outline.b, 0.88)
	var center := Polygon2D.new()
	center.polygon = _particle_polygon(style, radius)
	center.color = fill
	particle.add_child(center)
	return particle


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


func _effect_line(points: PackedVector2Array, color: Color, width: float) -> Line2D:
	var line := Line2D.new()
	line.points = points
	line.default_color = color
	line.width = width
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.antialiased = true
	return line


func _ellipse_arc_points(radius: Vector2, from_angle: float, to_angle: float, segments: int = 20) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point_index in range(segments + 1):
		var amount := float(point_index) / float(segments)
		var angle := lerpf(from_angle, to_angle, amount)
		points.append(Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	return points


func _spawn_celestial_orbit_screen(
	screen_position: Vector2,
	accent: Color,
	radius: Vector2 = Vector2(82.0, 48.0),
	duration: float = 0.82
) -> void:
	if effect_layer == null:
		return
	var orbit := Node2D.new()
	orbit.name = "CelestialActivationOrbit"
	orbit.position = screen_position
	orbit.scale = Vector2(0.72, 0.72)
	orbit.z_index = 234
	effect_layer.add_child(orbit)
	var arcs := [
		_ellipse_arc_points(radius, -2.78, -0.18, 18),
		_ellipse_arc_points(radius * Vector2(0.86, 1.18), 0.34, 2.5, 15)
	]
	for arc_index in range(arcs.size()):
		orbit.add_child(_effect_line(arcs[arc_index], Color(PALETTE.NAVY, 0.72), 6.0))
		orbit.add_child(_effect_line(arcs[arc_index], Color(PALETTE.CREAM, 0.96), 3.8))
		orbit.add_child(_effect_line(arcs[arc_index], Color(accent, 0.96), 2.0))
	var star_angles := [-2.5, -1.05, 0.42, 2.12]
	for star_index in range(star_angles.size()):
		var angle: float = star_angles[star_index]
		var star := _outlined_particle("✦", 5.5 + float(star_index % 2) * 2.0, PALETTE.FRESH_YELLOW if star_index == 1 else accent)
		star.position = Vector2(cos(angle) * radius.x, sin(angle) * radius.y)
		orbit.add_child(star)
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(orbit, "scale", Vector2.ONE, duration * 0.34)
	if not reduced_motion:
		tween.tween_property(orbit, "rotation", 0.16, duration)
	tween.tween_property(orbit, "modulate:a", 0.0, duration * 0.42).set_delay(duration * 0.58)
	tween.finished.connect(orbit.queue_free)


func _spawn_cloud_puff_world(
	world_position: Vector3,
	fill: Color = PALETTE.CREAM,
	accent: Color = PALETTE.SKY,
	duration: float = 0.58
) -> void:
	_spawn_cloud_puff_screen(_world_to_container(world_position), fill, accent, duration)


func _spawn_cloud_puff_screen(
	screen_position: Vector2,
	fill: Color = PALETTE.CREAM,
	accent: Color = PALETTE.SKY,
	duration: float = 0.58
) -> void:
	if effect_layer == null:
		return
	var cloud := Node2D.new()
	cloud.name = "IllustratedCloudPuff"
	cloud.position = screen_position
	cloud.scale = Vector2(0.55, 0.55)
	cloud.z_index = 231
	effect_layer.add_child(cloud)
	var lobes := [
		{"offset": Vector2(-18.0, 4.0), "radius": 12.0},
		{"offset": Vector2(-7.0, -6.0), "radius": 16.0},
		{"offset": Vector2(10.0, -4.0), "radius": 14.0},
		{"offset": Vector2(20.0, 5.0), "radius": 10.0},
		{"offset": Vector2(2.0, 8.0), "radius": 16.0}
	]
	for lobe_index in range(lobes.size()):
		var lobe: Dictionary = lobes[lobe_index]
		var outer := Polygon2D.new()
		outer.polygon = _particle_polygon("•", float(lobe.radius) + VFX_OUTLINE_WIDTH)
		outer.color = Color(PALETTE.NAVY, 0.78)
		outer.position = lobe.offset
		var inner := Polygon2D.new()
		inner.polygon = _particle_polygon("•", float(lobe.radius))
		inner.color = fill if lobe_index % 2 == 0 else fill.lerp(accent, 0.22)
		outer.add_child(inner)
		cloud.add_child(outer)
	var twinkle := _outlined_particle("✦", 5.5, accent)
	twinkle.position = Vector2(32.0, -16.0)
	cloud.add_child(twinkle)
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(cloud, "scale", Vector2.ONE, duration * 0.42)
	tween.tween_property(cloud, "position:y", cloud.position.y - 26.0, duration)
	tween.tween_property(cloud, "modulate:a", 0.0, duration * 0.42).set_delay(duration * 0.58)
	tween.finished.connect(cloud.queue_free)


func _spawn_impact_rays_screen(screen_position: Vector2, accent: Color, ray_count: int = 8, duration: float = 0.42) -> void:
	if effect_layer == null:
		return
	var burst := Node2D.new()
	burst.name = "IllustratedImpactRays"
	burst.position = screen_position
	burst.scale = Vector2(0.42, 0.42)
	burst.z_index = 233
	effect_layer.add_child(burst)
	for ray_index in range(ray_count):
		var angle := TAU * float(ray_index) / float(ray_count) + float(ray_index % 2) * 0.12
		var inner_distance := 22.0 + float(ray_index % 3) * 3.0
		var outer_distance := inner_distance + 19.0 + float((ray_index * 7) % 15)
		var points := PackedVector2Array([
			Vector2(cos(angle), sin(angle)) * inner_distance,
			Vector2(cos(angle), sin(angle)) * outer_distance
		])
		burst.add_child(_effect_line(points, Color(PALETTE.NAVY, 0.82), 6.0))
		burst.add_child(_effect_line(points, Color(accent, 0.98), 2.7))
	var center_star := _outlined_particle("✦", 15.0, PALETTE.FRESH_YELLOW)
	burst.add_child(center_star)
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(burst, "scale", Vector2.ONE, duration * 0.5)
	tween.tween_property(burst, "modulate:a", 0.0, duration * 0.45).set_delay(duration * 0.55)
	tween.finished.connect(burst.queue_free)


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
	camera_pacing_tween = null
	if camera != null:
		camera.global_transform = camera_home_transform
		camera.fov = camera_home_fov


func _build_hand_actions(data: Dictionary, hand_index: int) -> void:
	var card_type := String(data.get("card_type", ""))
	var card_id := String(data.get("id", ""))
	if card_type in ["ingredient", "meal"]:
		var tutorial_action := "begin_meal" if card_type == "meal" else "play_hand"
		var tutorial_locked := tutorial_mode and (String(_tutorial_step().get("action", "")) != tutorial_action or String(_tutorial_step().get("card_id", "")) != card_id)
		_add_action_button("Play Card", func() -> void: _begin_hand_play_selection(hand_index), tutorial_locked)
	elif card_type == "spice":
		var target_id := int(state.get("selected_spice_target", -1))
		var tutorial_locked := tutorial_mode and (String(_tutorial_step().get("action", "")) != "play_hand" or String(_tutorial_step().get("card_id", "")) != card_id)
		_add_action_button("Play Card" if target_id >= 0 else "Choose a Card to Season", func() -> void: _play_hand_card(hand_index, "prep"), target_id < 0 or tutorial_locked)
	else:
		var tutorial_locked := tutorial_mode and (String(_tutorial_step().get("action", "")) != "play_hand" or String(_tutorial_step().get("card_id", "")) != card_id)
		_add_action_button("Play Card", func() -> void: _play_hand_card(hand_index, "prep"), tutorial_locked)


func _begin_hand_play_selection(hand_index: int) -> void:
	if animation_busy or hand_index < 0 or hand_index >= state.player.hand.size():
		return
	var card_data: Dictionary = service.card(String(state.player.hand[hand_index]))
	if String(card_data.get("card_type", "")) not in ["ingredient", "meal"]:
		_play_hand_card(hand_index, "prep")
		return
	pending_hand_play_index = hand_index
	action_highlight_slots.clear()
	for zone in ["prep", "plated"]:
		var capacity: int = service.PREP_SLOTS if zone == "prep" else service.PLATED_SLOTS
		for slot_index in range(capacity):
			if _slot_can_receive_hand_card(card_data, "player", zone, slot_index):
				action_highlight_slots.append({"zone": "player_%s" % zone, "slot": slot_index})
	state.message = "Choose a glowing Prep or Plated slot for %s, or Cancel." % String(card_data.get("name", "this card"))
	_refresh_action_panel()
	_refresh_bottom_status()


func _choose_pending_hand_destination(destination: String, destination_slot: int) -> void:
	if pending_hand_play_index < 0:
		return
	var hand_index := pending_hand_play_index
	var card_data: Dictionary = service.card(String(state.player.hand[hand_index])) if hand_index < state.player.hand.size() else {}
	if card_data.is_empty() or not _slot_can_receive_hand_card(card_data, "player", destination, destination_slot):
		return
	pending_hand_play_index = -1
	action_highlight_slots.clear()
	_play_hand_card(hand_index, destination, destination_slot)


func _cancel_pending_hand_play(refresh_ui := true) -> void:
	pending_hand_play_index = -1
	action_highlight_slots.clear()
	action_highlight_zone = ""
	action_highlight_slot = -1
	if refresh_ui and not state.is_empty():
		_refresh_bottom_status()
		_refresh_action_panel()


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
	var move_locked := tutorial_mode and (String(_tutorial_step().get("action", "")) != "move_unit" or int(_tutorial_step().get("instance_id", -1)) != instance_id)
	_add_action_button("Move", func() -> void: _begin_move_selection(instance_id), bool(state.player.zone_move_used) or move_locked)


func _play_hand_card(hand_index: int, destination: String, destination_slot: int = -1) -> void:
	if animation_busy:
		return
	if hand_index < 0 or hand_index >= state.player.hand.size():
		return
	var played_card_id := String(state.player.hand[hand_index])
	_cancel_pending_hand_play(false)
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
			_show_invalid_action(String(state.message))
			return
		if not _slot_can_receive_hand_card(card_data, "player", destination, destination_slot):
			state.message = "%s slot %d is occupied." % [destination.capitalize(), destination_slot + 1]
			_render_match()
			_show_invalid_action(String(state.message))
			return
	if card_type == "meal":
		service.begin_meal_play(state, hand_index, destination, destination_slot)
		var meal_started: bool = not state.get("pending_meal", {}).is_empty()
		var meal_feedback := String(state.message)
		selected_ref = {}
		if meal_started:
			_tutorial_complete_action("begin_meal", tutorial_details)
		_render_match()
		if not meal_started:
			_show_invalid_action(meal_feedback)
		return
	var previous_ids: Array[int] = []
	for unit in state.player.get(destination, []):
		previous_ids.append(int(unit.instance_id))
	var hand_pose := _hand_card_pose(hand_index)
	var attempt_marker := _action_attempt_marker()
	animation_busy = true
	service.play_card(state, hand_index, destination, int(state.get("selected_spice_target", -1)))
	var action_succeeded: bool = _action_attempt_progressed(attempt_marker)
	var action_feedback := String(state.message)
	if card_type in ["ingredient", "meal"]:
		_assign_new_unit_to_slot("player", destination, previous_ids, destination_slot)
	selected_ref = {}
	await _drain_animation_event_queue(hand_pose)
	animation_busy = false
	if action_succeeded:
		_tutorial_complete_action("play_hand", tutorial_details)
	_render_match()
	if not action_succeeded:
		_show_invalid_action(action_feedback)


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
	var attempt_marker := _action_attempt_marker()
	animation_busy = true
	service.activate_ability(state, instance_id, ability_id)
	var action_succeeded: bool = _action_attempt_progressed(attempt_marker)
	var action_feedback := String(state.message)
	selected_ref = {}
	await _drain_animation_event_queue()
	animation_busy = false
	_render_match()
	if not action_succeeded:
		_show_invalid_action(action_feedback)


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
	var attacker_selected: bool = int(state.get("selected_attacker", -1)) == instance_id
	var action_feedback := String(state.message)
	selected_ref = {}
	if attacker_selected:
		_tutorial_complete_action("select_attacker", details)
	_render_match()
	if not attacker_selected:
		_show_invalid_action(action_feedback)


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


func _begin_move_selection(instance_id: int) -> void:
	if animation_busy or bool(state.player.zone_move_used):
		return
	var unit := service._find_unit(state.player, instance_id)
	if unit.is_empty():
		return
	var source_zone := "plated" if not service._find_unit_in_zone(state.player, "plated", instance_id).is_empty() else "prep"
	var destination := "prep" if source_zone == "plated" else "plated"
	pending_move_instance_id = instance_id
	action_highlight_slots.clear()
	var capacity: int = service.PREP_SLOTS if destination == "prep" else service.PLATED_SLOTS
	for slot_index in range(capacity):
		action_highlight_slots.append({"zone": "player_%s" % destination, "slot": slot_index})
	state.message = "Choose a glowing %s slot. An occupied slot swaps cards and uses your move for the turn." % destination.capitalize()
	_refresh_bottom_status()
	_refresh_action_panel()


func _choose_pending_move_destination(destination: String, destination_slot: int) -> void:
	if pending_move_instance_id < 0:
		return
	var instance_id := pending_move_instance_id
	pending_move_instance_id = -1
	action_highlight_slots.clear()
	_move_unit(instance_id, destination, destination_slot)


func _cancel_pending_move(refresh_ui := true) -> void:
	pending_move_instance_id = -1
	action_highlight_slots.clear()
	if refresh_ui and not state.is_empty():
		_refresh_bottom_status()
		_refresh_action_panel()


func _move_unit(instance_id: int, destination: String, destination_slot: int = -1) -> void:
	if animation_busy:
		return
	_cancel_pending_move(false)
	var unit := service._find_unit(state.player, instance_id)
	if unit.is_empty():
		return
	var tutorial_details := {"instance_id": instance_id, "card_id": String(unit.get("card_id", "")), "zone": destination, "slot": destination_slot}
	if tutorial_mode and not _tutorial_action_matches("move_unit", tutorial_details):
		_tutorial_reject_action()
		return
	if destination_slot < 0:
		state.message = "Choose an exact %s slot." % destination.capitalize()
		_render_match()
		_show_invalid_action(String(state.message))
		return
	var source_zone := "plated" if not service._find_unit_in_zone(state.player, "plated", instance_id).is_empty() else "prep"
	if source_zone == destination:
		unit.table_slot = destination_slot
		state.message = "%s is repositioned in %s slot %d." % [String(unit.name), destination.capitalize(), destination_slot + 1]
	else:
		var attempt_marker := _action_attempt_marker()
		animation_busy = true
		service.move_unit(state, instance_id, destination, destination_slot)
		var move_succeeded: bool = _action_attempt_progressed(attempt_marker)
		var move_feedback := String(state.message)
		var moved_unit := service._find_unit(state.player, instance_id)
		if not moved_unit.is_empty() and service._unit_zone(state.player, instance_id) == destination:
			moved_unit.table_slot = destination_slot
		if not move_succeeded:
			animation_busy = false
			selected_ref = {}
			_render_match()
			_show_invalid_action(move_feedback)
			return
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
		var badge := _label("✓", 25, PALETTE.INK)
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
		badge_style.bg_color = PALETTE.APRICOT
		badge_style.set_corner_radius_all(15)
		badge.add_theme_stylebox_override("normal", badge_style)
		button.add_child(badge)
	card_tray_cards.add_child(button)


func _apply_card_tray_card_style(button: Button, selected: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = PALETTE.INK
	normal.border_color = PALETTE.APRICOT if selected else PALETTE.SLATE
	normal.set_border_width_all(4 if selected else 2)
	normal.set_corner_radius_all(8)
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = PALETTE.TEAL_DARK
	hover.border_color = PALETTE.TEAL_HOVER
	hover.set_border_width_all(3)
	button.add_theme_stylebox_override("hover", hover)
	var pressed := hover.duplicate() as StyleBoxFlat
	pressed.bg_color = PALETTE.TEAL
	button.add_theme_stylebox_override("pressed", pressed)
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = PALETTE.DISABLED
	disabled.border_color = PALETTE.BORDER_SOFT
	button.add_theme_stylebox_override("disabled", disabled)


func _apply_card_tray_panel_style() -> void:
	card_tray_panel.add_theme_stylebox_override("panel", UI_THEME_SCRIPT.dark_glass_style(UI_THEME_SCRIPT.TEAL_LIGHT, 2))


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
		_refresh_status_panel_visibility()
		return
	var pending_discard: Dictionary = state.get("pending_discard", {})
	if not pending_discard.is_empty():
		var selected_count: int = pending_discard.get("selected_indices", []).size()
		var required := int(pending_discard.get("required", 0))
		status_label.text = "Select %d card%s from your hand to discard: %d/%d selected." % [required, "" if required == 1 else "s", selected_count, required]
		confirm_choice_button.visible = true
		confirm_choice_button.disabled = selected_count != required
		cancel_choice_button.visible = true
		_refresh_status_panel_visibility()
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
		_refresh_status_panel_visibility()
		return
	var pending_ability: Dictionary = state.get("pending_ability", {})
	if not pending_ability.is_empty():
		status_label.text = String(state.message)
		highlighted_zone = _pending_ability_zone(pending_ability)
		cancel_choice_button.visible = true
		_refresh_status_panel_visibility()
		return
	status_label.text = String(state.message)
	if tutorial_mode:
		var step := _tutorial_step()
		var action := String(step.get("action", ""))
		if action in ["play_hand", "begin_meal", "move_unit"] and step.has("zone"):
			highlighted_zone = "player_%s" % String(step.zone)
			highlighted_slot = int(step.get("slot", -1))
	_refresh_status_panel_visibility()


func _toggle_battle_log() -> void:
	_set_battle_log_visible(not battle_log_panel.visible)


func _set_battle_log_visible(visible: bool) -> void:
	battle_log_panel.visible = visible
	if visible:
		if is_instance_valid(readability_controls_panel):
			readability_controls_panel.visible = false
		if is_instance_valid(match_options_button):
			match_options_button.text = "OPTIONS"
		_refresh_battle_log()


func _refresh_battle_log() -> void:
	if state.is_empty():
		battle_log_button.text = "MATCH LOG"
		battle_log_text.text = "The battle log will appear here."
		return
	var entries: Array = state.get("log", [])
	battle_log_button.text = "LOG  •  %d" % entries.size()
	var lines: Array[String] = [
		"[color=#9D4B45]CURRENT[/color]  [color=#29365F]%s[/color]" % String(state.get("message", "Choose a card or end your turn."))
	]
	if entries.is_empty():
		lines.append("[color=#53628A]No actions recorded yet.[/color]")
	for entry_index in range(entries.size()):
		lines.append("[color=#3D7794]%02d[/color]  [color=#29365F]%s[/color]" % [entry_index + 1, String(entries[entry_index])])
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
	return pending_hand_play_index >= 0 or pending_move_instance_id >= 0 or not state.get("pending_meal", {}).is_empty() or not state.get("pending_discard", {}).is_empty() or not state.get("pending_ability", {}).is_empty() or not state.get("pending_search", {}).is_empty() or not state.get("pending_choice", {}).is_empty() or not state.get("pending_reaction", {}).is_empty()


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
		await _wait_for_game_breakdown()
		await get_tree().create_timer(float(RIVAL_PACING_OPTIONS[rival_pacing_index].action_gap)).timeout
		await _wait_for_game_breakdown()
		animation_busy = true
		var phase_before_action := String(state.get("phase", ""))
		service.advance_opponent_turn(state)
		var phase_after_action := String(state.get("phase", ""))
		if phase_before_action != phase_after_action and phase_after_action == "player_main":
			await _drain_animation_event_queue()
			await _show_turn_banner("player_main")
		else:
			await _drain_animation_event_queue()
		animation_busy = false
		_render_match()
	opponent_running = false


func _wait_for_game_breakdown() -> void:
	while game_breakdown_active:
		await get_tree().process_frame


func _update_chef_labels() -> void:
	(player_chef.get_node("Label") as Label3D).text = str(int(state.player.life))
	(opponent_chef.get_node("Label") as Label3D).text = str(int(state.opponent.life))


func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		child.free()


func _label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_override("font", READABLE_FONT)
	label.add_theme_font_size_override("font_size", _scaled_font_size(font_size))
	label.set_meta("readability_base_font_font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _add_action_button(text_value: String, callback: Callable, disabled := false) -> void:
	var button := _styled_button(text_value)
	_apply_current_ui_button_style(button, true)
	button.disabled = disabled
	button.pressed.connect(callback)
	action_list.add_child(button)


func _add_prompt_title(text_value: String) -> void:
	var title := _label(text_value, 23, PALETTE.NAVY)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_content.add_child(title)


func _add_prompt_text(text_value: String) -> void:
	var text_label := _label(text_value, 15, PALETTE.INK)
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
	button.add_theme_font_override("font", READABLE_FONT)
	button.add_theme_font_size_override("font_size", _scaled_font_size(14))
	button.set_meta("readability_base_font_font_size", 14)
	_apply_rounded_button_style(button)
	_apply_current_ui_button_style(button, false)
	_bind_illustrated_button_feedback(button)
	return button


func _bind_illustrated_button_feedback(button: Button) -> void:
	if button == null or button.has_meta("illustrated_feedback_bound"):
		return
	button.set_meta("illustrated_feedback_bound", true)
	button.resized.connect(func() -> void:
		if is_instance_valid(button):
			button.pivot_offset = button.size * 0.5
	)
	button.mouse_entered.connect(func() -> void:
		if is_instance_valid(button) and not button.disabled and button.visible:
			_spawn_button_twinkle(button)
			_tween_button_scale(button, Vector2(1.025, 1.025), 0.14)
	)
	button.mouse_exited.connect(func() -> void:
		if is_instance_valid(button):
			_tween_button_scale(button, Vector2.ONE, 0.14)
	)
	button.button_down.connect(func() -> void:
		if is_instance_valid(button) and not button.disabled:
			_tween_button_scale(button, Vector2(0.96, 0.96), 0.08)
	)
	button.button_up.connect(func() -> void:
		if is_instance_valid(button):
			_tween_button_scale(button, Vector2.ONE, 0.18)
	)


func _tween_button_scale(button: Button, target_scale: Vector2, duration: float) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", target_scale, duration)


func _spawn_button_twinkle(button: Button) -> void:
	if effect_layer == null or button.size.x < 24.0:
		return
	var effect_origin := effect_layer.global_position
	var button_origin := button.global_position - effect_origin
	var twinkle_position := button_origin + Vector2(button.size.x - 8.0, 8.0)
	_spawn_screen_particle_burst(twinkle_position, PALETTE.SKY, 3, "✦")


func _apply_rounded_button_style(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = PALETTE.LAVENDER_GLASS
	normal.border_color = PALETTE.TEAL_DARK
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(12)
	normal.content_margin_left = 14
	normal.content_margin_right = 14
	normal.content_margin_top = 6
	normal.content_margin_bottom = 7
	normal.shadow_color = Color(0, 0, 0, 0.24)
	normal.shadow_size = 4
	normal.shadow_offset = Vector2(0, 2)
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = PALETTE.BLUSH
	button.add_theme_stylebox_override("hover", hover)
	var pressed := hover.duplicate() as StyleBoxFlat
	pressed.bg_color = PALETTE.PERIWINKLE
	pressed.content_margin_top = 8
	pressed.content_margin_bottom = 5
	pressed.shadow_size = 1
	pressed.shadow_offset = Vector2(0, 1)
	button.add_theme_stylebox_override("pressed", pressed)
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = PALETTE.DISABLED
	disabled.border_color = PALETTE.BORDER_SOFT
	button.add_theme_stylebox_override("disabled", disabled)
	_apply_high_contrast_button_text(button)


func _apply_high_contrast_button_text(button: Button) -> void:
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		button.add_theme_color_override(color_name, PALETTE.NAVY)


func _apply_current_ui_button_style(button: Button, primary: bool) -> void:
	var variant := "action" if primary else "default"
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.remove_theme_stylebox_override(state)
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		button.remove_theme_color_override(color_name)
	button.theme_type_variation = UI_THEME_SCRIPT.button_variation(variant)
