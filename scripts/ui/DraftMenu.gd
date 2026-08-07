extends VBoxContainer
class_name DraftMenu

const WORKSPACE_UI := preload("res://scripts/ui/WorkspaceUIComponents.gd")
const PALETTE := preload("res://scripts/ui/GamePalette.gd")

signal abandon_requested


func _ready() -> void:
	_apply_regular_panel_styles()
	WORKSPACE_UI.style_button(%AbandonDraftButton, "secondary")
	%AbandonDraftButton.pressed.connect(abandon_requested.emit)


func _apply_regular_panel_styles() -> void:
	$DraftModePanel.add_theme_stylebox_override(
		"panel",
		WORKSPACE_UI.clean_style(
			PALETTE.CREAM,
			PALETTE.NAVY,
			2,
			16,
			Vector4(22, 10, 18, 10),
			7,
			true
		)
	)
	%DraftProgress.add_theme_color_override("font_color", PALETTE.NAVY)
	%DraftProgress.add_theme_stylebox_override(
		"normal",
		WORKSPACE_UI.clean_style(
			Color(PALETTE.LAVENDER_GLASS, 0.94),
			PALETTE.PERIWINKLE,
			2,
			12,
			Vector4(16, 7, 16, 7)
		)
	)
	%DraftInstruction.add_theme_color_override("font_color", PALETTE.NAVY_MUTED)
	for slot in %DraftOfferRow.get_children():
		(slot as PanelContainer).add_theme_stylebox_override(
			"panel",
			WORKSPACE_UI.clean_style(
				Color(PALETTE.CREAM, 0.96),
				PALETTE.NAVY,
				2,
				16,
				Vector4(12, 10, 12, 12),
				0,
				true
			)
		)
	$DraftWorkspace/DraftDeckRail.add_theme_stylebox_override(
		"panel",
		WORKSPACE_UI.clean_style(
			Color(PALETTE.LAVENDER_GLASS, 0.9),
			PALETTE.NAVY,
			2,
			16,
			Vector4(16, 14, 16, 16),
			6,
			true
		)
	)
	$DraftDistributionCharts/DraftTypeChartPanel.add_theme_stylebox_override(
		"panel",
		WORKSPACE_UI.clean_style(
			Color(PALETTE.CREAM, 0.94),
			PALETTE.PERIWINKLE,
			2,
			14,
			Vector4(16, 10, 16, 12)
		)
	)
	$DraftDistributionCharts/DraftFlavorChartPanel.add_theme_stylebox_override(
		"panel",
		WORKSPACE_UI.clean_style(
			Color(PALETTE.CREAM, 0.94),
			PALETTE.SKY,
			2,
			14,
			Vector4(16, 10, 16, 12)
		)
	)


func configure(instruction: String, progress_text: String) -> void:
	%DraftInstruction.text = instruction
	%DraftProgress.text = progress_text


func get_offer_row() -> HBoxContainer:
	return %DraftOfferRow


func get_workspace() -> HBoxContainer:
	return %DraftWorkspace
