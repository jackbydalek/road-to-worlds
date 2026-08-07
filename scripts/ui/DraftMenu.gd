extends VBoxContainer
class_name DraftMenu

const WORKSPACE_UI := preload("res://scripts/ui/WorkspaceUIComponents.gd")

signal abandon_requested


func _ready() -> void:
	_apply_regular_panel_styles()
	WORKSPACE_UI.style_button(%AbandonDraftButton, "danger")
	%AbandonDraftButton.pressed.connect(abandon_requested.emit)


func _apply_regular_panel_styles() -> void:
	$DraftModePanel.add_theme_stylebox_override(
		"panel",
		WORKSPACE_UI.clean_style(
			WORKSPACE_UI.SURFACE,
			WORKSPACE_UI.TEAL,
			2,
			10,
			Vector4(22, 14, 22, 16),
			5,
			true
		)
	)
	for slot in %DraftOfferRow.get_children():
		(slot as PanelContainer).add_theme_stylebox_override(
			"panel",
			WORKSPACE_UI.clean_style(
				WORKSPACE_UI.SURFACE,
				WORKSPACE_UI.BORDER_SOFT,
				2,
				10,
				Vector4(14, 14, 14, 16),
				0,
				true
			)
		)
	$DraftWorkspace/DraftDeckRail.add_theme_stylebox_override(
		"panel",
		WORKSPACE_UI.clean_style(
			WORKSPACE_UI.SURFACE,
			WORKSPACE_UI.TEAL,
			2,
			10,
			Vector4(18, 16, 18, 18),
			4,
			true
		)
	)
	$DraftDistributionCharts/DraftTypeChartPanel.add_theme_stylebox_override(
		"panel",
		WORKSPACE_UI.clean_style(
			WORKSPACE_UI.SURFACE,
			WORKSPACE_UI.PALETTE.SLATE,
			2,
			10,
			Vector4(18, 14, 18, 16)
		)
	)
	$DraftDistributionCharts/DraftFlavorChartPanel.add_theme_stylebox_override(
		"panel",
		WORKSPACE_UI.clean_style(
			WORKSPACE_UI.SURFACE,
			WORKSPACE_UI.TEAL,
			2,
			10,
			Vector4(18, 14, 18, 16)
		)
	)


func configure(instruction: String, progress_text: String) -> void:
	%DraftInstruction.text = instruction
	%DraftProgress.text = progress_text


func get_offer_row() -> HBoxContainer:
	return %DraftOfferRow


func get_workspace() -> HBoxContainer:
	return %DraftWorkspace
