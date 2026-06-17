extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame

	main._start_new_run("flightless_birds")
	main._show_ui_combat()
	main._start_manual_combat_lab_battle()
	await process_frame
	await process_frame

	if main.run.get("manual_combat", {}).is_empty():
		push_error("UI smoke test did not create manual combat.")
		quit(1)
		return
	if main.current_screen != "ui_combat":
		push_error("UI smoke test did not stay on the UI Combat tab.")
		quit(1)
		return
	if _count_named_nodes(main, "ManualInspectPanelOverlay") > 0:
		push_error("UI smoke test rendered the UI Combat inspect overlay before a card was selected.")
		quit(1)
		return

	main.run.manual_combat["player"]["board"].append({
		"instance_id": 777,
		"card_id": "red_spark_runner",
		"name": "Smoke Runner",
		"attack": 2,
		"health": 1,
		"max_health": 1,
		"ready": true,
		"tags": ["fast"]
	})
	main.run.manual_combat["opponent"]["board"].append({
		"instance_id": 778,
		"card_id": "ver_trail_guardian",
		"name": "Smoke Guardian",
		"attack": 1,
		"health": 4,
		"max_health": 4,
		"ready": false,
		"tags": ["guard"]
	})
	main.run.manual_combat["player"]["board"].append({
		"instance_id": 779,
		"card_id": "red_alley_brawler",
		"name": "Smoke Brawler",
		"attack": 3,
		"health": 2,
		"max_health": 2,
		"ready": false,
		"tags": []
	})
	main.run.manual_combat["opponent"]["board"].append({
		"instance_id": 780,
		"card_id": "ver_trail_guardian",
		"name": "Smoke Counter",
		"attack": 2,
		"health": 3,
		"max_health": 3,
		"ready": false,
		"tags": []
	})
	main._manual_select_attacker(777)
	await process_frame
	await process_frame

	if _count_named_nodes(main, "ManualBattlefield") == 0 and _count_named_nodes(main, "UICombatBattlefield") == 0:
		push_error("UI smoke test did not render manual battlefield.")
		quit(1)
		return
	if _count_named_nodes(main, "ManualBoardArcLayer") == 0:
		push_error("UI smoke test did not render the UI Combat board arc layer.")
		quit(1)
		return
	if _count_named_nodes(main, "ManualContextPanel") == 0:
		push_error("UI smoke test did not render floating board controls.")
		quit(1)
		return
	if _count_named_nodes(main, "ManualEndTurnButton") == 0:
		push_error("UI smoke test did not render the middle-right End Turn button.")
		quit(1)
		return
	if _count_named_nodes(main, "ManualBattleLogButton") == 0:
		push_error("UI smoke test did not render the top-left Battle Log button.")
		quit(1)
		return
	if _count_named_nodes(main, "ManualBattleLogPanel") > 0:
		push_error("UI smoke test rendered the battle log before it was opened.")
		quit(1)
		return
	if _count_named_nodes(main, "ManualOpponentFanHand") == 0:
		push_error("UI smoke test did not render the fanned opponent hand.")
		quit(1)
		return
	var opponent_hand_count: int = main.run.manual_combat["opponent"]["hand"].size()
	if _count_named_nodes(main, "ManualCardBackSlot") < opponent_hand_count:
		push_error("UI smoke test did not render enough fanned opponent hand backs.")
		quit(1)
		return
	if _count_named_nodes(main, "ManualPlayerResourceReadout") == 0 or (_count_named_nodes(main, "ManualOpponentResourceReadout") == 0 and _count_named_nodes(main, "ManualFaceTargetAffordance") == 0):
		push_error("UI smoke test did not render player/opponent life-focus readouts.")
		quit(1)
		return
	if _count_named_nodes(main, "ManualBoardPreviewArc") == 0:
		push_error("UI smoke test did not render live selection preview arcs.")
		quit(1)
		return
	if _count_named_nodes(main, "ManualInspectPanel") == 0:
		push_error("UI smoke test did not render the card inspect panel.")
		quit(1)
		return
	if _count_named_nodes(main, "ManualInspectPanelOverlay") == 0:
		push_error("UI smoke test did not render the floating UI Combat inspect overlay.")
		quit(1)
		return
	if _count_named_nodes(main, "ManualZone_PlayerBoard") == 0 or _count_named_nodes(main, "ManualZone_OpponentBoard") == 0:
		push_error("UI smoke test did not render explicit board zones.")
		quit(1)
		return
	if _count_named_nodes(main, "ManualBoardSlot_Player") < 5 or _count_named_nodes(main, "ManualBoardSlot_Opponent") < 5:
		push_error("UI smoke test did not render positioned board slots.")
		quit(1)
		return
	if _count_named_nodes(main, "ManualZone_PlayerEngine") == 0 or _count_named_nodes(main, "ManualZone_OpponentEngine") == 0:
		push_error("UI smoke test did not render explicit engine zones.")
		quit(1)
		return
	if _count_named_nodes(main, "ManualZone_OpponentHand") == 0 or _count_named_nodes(main, "ManualCardBackSlot") == 0:
		push_error("UI smoke test did not render opponent hand zone/card backs.")
		quit(1)
		return
	if _count_named_nodes(main, "CombatCardPanel") == 0:
		push_error("UI smoke test did not render combat card panels.")
		quit(1)
		return
	if _count_named_nodes(main, "CombatCardPanel_PlayerUnit_777") == 0:
		push_error("UI smoke test did not render exact player unit card anchors.")
		quit(1)
		return
	if _count_named_nodes(main, "ManualUnitTargetButton") == 0:
		push_error("UI smoke test did not render a legal unit target button.")
		quit(1)
		return
	if _count_named_nodes(main, "ManualTargetBadge") == 0:
		push_error("UI smoke test did not render a legal target badge.")
		quit(1)
		return

	if not main.run.manual_combat["player"]["hand"].has("red_quick_spark"):
		main.run.manual_combat["player"]["hand"].append("red_quick_spark")
	main.run.manual_combat["player"]["focus"] = max(int(main.run.manual_combat["player"].get("focus", 0)), 1)
	main._manual_select_card("red_quick_spark")
	await process_frame
	await process_frame

	if _count_named_nodes(main, "ManualFaceTargetAffordance") == 0:
		push_error("UI smoke test did not render face target affordance.")
		quit(1)
		return
	if _count_named_nodes(main, "ManualFaceTargetButton") == 0:
		push_error("UI smoke test did not render face target button.")
		quit(1)
		return
	if not _node_center_closer_to(main, "ManualFaceTargetAffordance", "ManualOpponentFanHand", "ManualOpponentResourceReadout"):
		push_error("UI smoke test face target affordance is not anchored to the opponent hand.")
		quit(1)
		return
	if _count_named_nodes(main, "ManualFanHand") == 0:
		push_error("UI smoke test did not render the fanned player hand.")
		quit(1)
		return
	if _count_named_nodes(main, "CombatCardPanel_Hand_red_quick_spark") == 0:
		push_error("UI smoke test did not render exact hand card anchors.")
		quit(1)
		return
	if _count_named_nodes(main, "ManualBoardPreviewArc") > 0:
		push_error("UI smoke test rendered a hand-card preview arrow across the board.")
		quit(1)
		return

	main._manual_target_unit(778)
	await process_frame
	await process_frame

	if int(main.run.manual_combat["opponent"]["board"][0].get("health", 0)) != 4:
		push_error("UI smoke test committed targeted card effects before the action animation finished.")
		quit(1)
		return
	if _count_named_nodes(main, "ManualActionSummaryPanel") > 0 or _count_named_nodes(main, "ManualFeedbackChip") > 0:
		push_error("UI smoke test rendered hidden battle log/action feedback by default.")
		quit(1)
		return
	if _count_named_nodes(main, "ManualBoardTargetArc") == 0 or _count_named_nodes(main, "ManualBoardTargetArrowHead") == 0:
		push_error("UI smoke test did not render committed board-position target arcs.")
		quit(1)
		return
	if _count_named_nodes(main, "ManualBoardMovingCardGhost") == 0:
		push_error("UI smoke test did not render board-layer moving card ghost for a targeted action.")
		quit(1)
		return
	if _count_named_nodes(main, "ManualBoardImpactBadge") == 0:
		push_error("UI smoke test did not render board-layer impact feedback.")
		quit(1)
		return
	await create_timer(1.15).timeout
	await process_frame
	if int(main.run.manual_combat["opponent"]["board"][0].get("health", 0)) >= 4:
		push_error("UI smoke test did not commit targeted card effects after the action animation finished.")
		quit(1)
		return

	main._toggle_manual_battle_log()
	await process_frame
	await process_frame

	if _count_named_nodes(main, "ManualBattleLogPanel") == 0:
		push_error("UI smoke test did not open the Battle Log panel.")
		quit(1)
		return
	if _count_named_nodes(main, "ManualActionSummaryPanel") == 0:
		push_error("UI smoke test did not render action summary inside the opened Battle Log.")
		quit(1)
		return
	if _count_named_nodes(main, "ManualImpactBadge") == 0:
		push_error("UI smoke test did not render impact badges inside the opened Battle Log.")
		quit(1)
		return
	if _count_named_nodes(main, "ManualFeedbackChip") == 0:
		push_error("UI smoke test did not render manual feedback chips inside the opened Battle Log.")
		quit(1)
		return
	if not _has_label_text(main, "DMG"):
		push_error("UI smoke test did not render damage feedback.")
		quit(1)
		return
	main._toggle_manual_battle_log()
	await process_frame
	await process_frame
	await create_timer(1.8).timeout
	if _count_named_nodes(main, "ManualBoardTargetArc") > 0 or _count_named_nodes(main, "ManualBoardTargetArrowHead") > 0:
		push_error("UI smoke test left committed board target arrows on screen after their VFX lifetime.")
		quit(1)
		return
	if _count_named_nodes(main, "ManualBoardMovingCardGhost") > 0 or _count_named_nodes(main, "ManualBoardImpactBadge") > 0:
		push_error("UI smoke test left board card/impact VFX on screen after their lifetime.")
		quit(1)
		return

	main.run.manual_animation = {}
	main.run.manual_animation_queue = []
	main.run.manual_combat["opponent"]["hand"] = ["red_quick_spark"]
	main.run.manual_combat["opponent"]["deck"] = []
	main.run.manual_combat["opponent"]["max_focus"] = 0
	main.run.manual_combat["opponent"]["focus"] = 0
	main.run.manual_combat["opponent"]["board"].append({
		"instance_id": 881,
		"card_id": "red_spark_runner",
		"name": "Smoke Rival",
		"attack": 2,
		"health": 1,
		"max_health": 1,
		"ready": false,
		"tags": ["fast"]
	})
	main._show_active_combat_screen()
	await process_frame
	await process_frame
	main._manual_end_turn()
	await process_frame
	await process_frame
	if main.run.manual_animation.is_empty():
		push_error("UI smoke test did not create an opponent action animation after end turn.")
		quit(1)
		return
	if String(main.run.manual_animation.get("source_anchor", "")) != "ManualOpponentFanHand":
		push_error("UI smoke test opponent action did not originate from the opponent hand.")
		quit(1)
		return
	if not _point_closer_to(main, main.run.manual_animation.get("source_global_point", []), "ManualOpponentFanHand", "ManualFanHand"):
		push_error("UI smoke test opponent action source point was not captured at the opponent hand.")
		quit(1)
		return
	if _count_named_nodes(main, "ManualBoardMovingCardGhost") == 0:
		push_error("UI smoke test did not render opponent action card movement.")
		quit(1)
		return
	if main.run.manual_animation_queue.is_empty():
		push_error("UI smoke test did not queue a follow-up opponent action animation.")
		quit(1)
		return
	main.run.manual_animation = {}
	main.run.manual_animation_queue = []

	main.run.manual_combat["player"]["hand"].append("lan_late_fee_drake")
	main.run.manual_combat["player"]["focus"] = max(int(main.run.manual_combat["player"].get("focus", 0)), 5)
	main._show_active_combat_screen()
	await process_frame
	await process_frame
	if _count_named_nodes(main, "CombatCardPanel_Hand_lan_late_fee_drake") == 0:
		push_error("UI smoke test did not render the injected finisher hand card before play.")
		quit(1)
		return
	main._manual_play_card("lan_late_fee_drake")
	await process_frame
	await process_frame
	if not _player_board_has_card(main, "lan_late_fee_drake"):
		push_error("UI smoke test did not commit a clicked played threat immediately.")
		quit(1)
		return
	if _count_named_nodes(main, "ManualBoardTargetArc") > 0 or _count_named_nodes(main, "ManualBoardTargetArrowHead") > 0:
		push_error("UI smoke test rendered a target arrow for a non-target finisher play.")
		quit(1)
		return
	if _count_named_nodes(main, "ManualBoardMovingCardGhost") > 0:
		push_error("UI smoke test animated a card ghost for an immediate clicked play.")
		quit(1)
		return
	main._manual_set_inspect_card("red_quick_spark", "Hand", "", false)
	await process_frame
	main._show_active_combat_screen()
	await process_frame
	if _count_named_nodes(main, "ManualInspectPanelOverlay") > 0:
		push_error("UI smoke test rendered a UI Combat inspect overlay for hover-only inspect data.")
		quit(1)
		return
	main._manual_clear_hover_inspect("red_quick_spark", "Hand", "")
	await process_frame
	main._show_active_combat_screen()
	await process_frame
	if _count_named_nodes(main, "ManualInspectPanelOverlay") > 0:
		push_error("UI smoke test did not keep hover-only inspect hidden.")
		quit(1)
		return
	main._manual_set_inspect_card("red_quick_spark", "Hand", "")
	main._show_active_combat_screen()
	await process_frame
	if not _has_named_label_text(main, "ManualInspectName", "Quick Peck"):
		push_error("UI smoke test did not update the click-pinned card inspect overlay.")
		quit(1)
		return
	main._manual_clear_inspect_overlay()
	await process_frame
	await process_frame
	if _count_named_nodes(main, "ManualInspectPanelOverlay") > 0:
		push_error("UI smoke test did not dismiss the click-pinned inspect overlay.")
		quit(1)
		return

	main.run.manual_combat["player"]["hand"].append("ver_second_wind")
	main.run.manual_combat["player"]["focus"] = max(int(main.run.manual_combat["player"].get("focus", 0)), 2)
	main.run.manual_combat["player"]["life"] = 10
	main._show_active_combat_screen()
	await process_frame
	await process_frame
	main._manual_play_card("ver_second_wind")
	await process_frame
	await process_frame
	if int(main.run.manual_combat["player"].get("life", 0)) != 10:
		push_error("UI smoke test committed a non-target action before the action animation finished.")
		quit(1)
		return
	if _count_named_nodes(main, "ManualBoardMovingCardGhost") == 0:
		push_error("UI smoke test did not animate a card ghost for a non-target action.")
		quit(1)
		return
	await create_timer(1.15).timeout
	await process_frame
	if int(main.run.manual_combat["player"].get("life", 0)) != 14:
		push_error("UI smoke test did not commit a non-target action after the action animation finished.")
		quit(1)
		return

	main._start_manual_combat_lab_battle()
	await process_frame
	await process_frame
	main.run.manual_combat["player"]["board"] = []
	main.run.manual_combat["player"]["hand"] = ["red_alley_brawler"]
	main.run.manual_combat["player"]["focus"] = 2
	main.run.manual_combat["player"]["max_focus"] = max(int(main.run.manual_combat["player"].get("max_focus", 0)), 2)
	main._show_active_combat_screen()
	await process_frame
	await process_frame
	var drag_card := _find_named_node(main, "CombatCardPanel_Hand_red_alley_brawler")
	var target_slot := _find_named_node(main, "ManualBoardSlot_Player_3")
	if drag_card == null or target_slot == null:
		push_error("UI smoke test could not find drag source card or target board slot.")
		quit(1)
		return
	main._manual_try_begin_hand_card_drag("red_alley_brawler", drag_card)
	var drag_point := _node_global_center(drag_card) + Vector2(18, -18)
	main._manual_update_hand_card_drag(drag_point)
	await process_frame
	if _count_named_nodes(main, "ManualDragCardGhost") == 0:
		push_error("UI smoke test did not create a drag ghost for a playable hand threat.")
		quit(1)
		return
	var drag_ghost := _find_named_node(main, "ManualDragCardGhost")
	if drag_ghost == null or _node_global_center(drag_ghost).distance_to(drag_point) > 32.0:
		push_error("UI smoke test drag ghost frame did not follow the pointer.")
		quit(1)
		return
	main._manual_finish_hand_card_drag(_node_global_center(target_slot))
	await process_frame
	await process_frame
	if not _player_board_has_card(main, "red_alley_brawler"):
		push_error("UI smoke test did not commit a dragged threat immediately.")
		quit(1)
		return
	if _count_named_nodes(main, "ManualBoardMovingCardGhost") > 0:
		push_error("UI smoke test animated a card ghost for an immediate dragged threat.")
		quit(1)
		return
	if _player_card_visual_slot(main, "red_alley_brawler") != 2:
		push_error("UI smoke test did not keep dragged threat in the selected board slot.")
		quit(1)
		return

	main._start_manual_combat_lab_battle()
	await process_frame
	await process_frame
	main.run.manual_combat["player"]["board"] = []
	main.run.manual_combat["player"]["hand"] = ["red_alley_brawler"]
	main.run.manual_combat["player"]["focus"] = 2
	main.run.manual_combat["player"]["max_focus"] = max(int(main.run.manual_combat["player"].get("max_focus", 0)), 2)
	main._show_active_combat_screen()
	await process_frame
	await process_frame
	var orphan_drag_card := _find_named_node(main, "CombatCardPanel_Hand_red_alley_brawler")
	if orphan_drag_card == null:
		push_error("UI smoke test could not find drag source card for orphan cleanup check.")
		quit(1)
		return
	main._manual_try_begin_hand_card_drag("red_alley_brawler", orphan_drag_card)
	var orphan_drag_point := _node_global_center(orphan_drag_card) + Vector2(24, -24)
	main._manual_update_hand_card_drag(orphan_drag_point)
	await process_frame
	if _count_named_nodes(main, "ManualDragCardGhost") == 0:
		push_error("UI smoke test did not create a drag ghost for orphan cleanup check.")
		quit(1)
		return
	var orphan_drag_ghost := _find_named_node(main, "ManualDragCardGhost")
	if orphan_drag_ghost == null or _node_global_center(orphan_drag_ghost).distance_to(orphan_drag_point) > 32.0:
		push_error("UI smoke test orphan-check drag ghost frame did not follow the pointer.")
		quit(1)
		return
	main._manual_play_card("red_alley_brawler")
	await process_frame
	await process_frame
	if _count_named_nodes(main, "ManualDragCardGhost") > 0:
		push_error("UI smoke test left a drag ghost visible after a played card action.")
		quit(1)
		return

	main._start_manual_combat_lab_battle()
	await process_frame
	await process_frame
	main.run.manual_combat["player"]["engines"] = []
	main.run.manual_combat["player"]["hand"] = ["red_reckless_recruiter"]
	main.run.manual_combat["player"]["focus"] = 2
	main.run.manual_combat["player"]["max_focus"] = max(int(main.run.manual_combat["player"].get("max_focus", 0)), 2)
	main._show_active_combat_screen()
	await process_frame
	await process_frame
	var engine_drag_card := _find_named_node(main, "CombatCardPanel_Hand_red_reckless_recruiter")
	var engine_target_slot := _find_named_node(main, "ManualEngineSlot_Player_2")
	if engine_drag_card == null or engine_target_slot == null:
		push_error("UI smoke test could not find engine drag card or target engine slot.")
		quit(1)
		return
	main._manual_try_begin_hand_card_drag("red_reckless_recruiter", engine_drag_card)
	var engine_drag_point := _node_global_center(engine_drag_card) + Vector2(18, -18)
	main._manual_update_hand_card_drag(engine_drag_point)
	await process_frame
	if _count_named_nodes(main, "ManualDragCardGhost") == 0:
		push_error("UI smoke test did not create a drag ghost for a playable engine.")
		quit(1)
		return
	main._manual_finish_hand_card_drag(_node_global_center(engine_target_slot))
	await process_frame
	await process_frame
	if _player_engine_has_card(main, "red_reckless_recruiter"):
		push_error("UI smoke test committed a dragged engine before its play animation finished.")
		quit(1)
		return
	if _count_named_nodes(main, "ManualBoardMovingCardGhost") == 0:
		push_error("UI smoke test did not animate a dragged engine play.")
		quit(1)
		return
	await create_timer(1.2).timeout
	await process_frame
	if not _player_engine_has_card(main, "red_reckless_recruiter"):
		push_error("UI smoke test did not commit dragged engine after the play animation finished.")
		quit(1)
		return
	if _player_engine_visual_slot(main, "red_reckless_recruiter") != 1:
		push_error("UI smoke test did not keep dragged engine in the selected engine slot.")
		quit(1)
		return

	main._start_manual_combat_lab_battle()
	await process_frame
	await process_frame
	main.run.manual_combat["player"]["hand"] = ["red_last_point"]
	main.run.manual_combat["player"]["focus"] = 2
	main.run.manual_combat["player"]["max_focus"] = max(int(main.run.manual_combat["player"].get("max_focus", 0)), 2)
	main.run.manual_combat["opponent"]["life"] = 20
	main._show_active_combat_screen()
	await process_frame
	await process_frame
	var face_action_card := _find_named_node(main, "CombatCardPanel_Hand_red_last_point")
	var opponent_hand := _find_named_node(main, "ManualOpponentFanHand")
	if face_action_card == null or opponent_hand == null:
		push_error("UI smoke test could not find face action card or opponent hand target.")
		quit(1)
		return
	main._manual_try_begin_hand_card_drag("red_last_point", face_action_card)
	main._manual_update_hand_card_drag(_node_global_center(opponent_hand))
	await process_frame
	if _count_named_nodes(main, "ManualDragTargetPreviewArc") == 0:
		push_error("UI smoke test did not render a live drag preview arc for a face action target.")
		quit(1)
		return
	main._manual_finish_hand_card_drag(_node_global_center(opponent_hand))
	await process_frame
	await process_frame
	if int(main.run.manual_combat["opponent"].get("life", 0)) != 20:
		push_error("UI smoke test committed a face action before its play animation finished.")
		quit(1)
		return
	if _count_named_nodes(main, "ManualBoardMovingCardGhost") == 0:
		push_error("UI smoke test did not animate a dragged face action.")
		quit(1)
		return
	await create_timer(1.2).timeout
	await process_frame
	if int(main.run.manual_combat["opponent"].get("life", 0)) != 16:
		push_error("UI smoke test did not resolve dragged face action after the play animation finished.")
		quit(1)
		return

	main._start_manual_combat_lab_battle()
	await process_frame
	await process_frame
	main.run.manual_combat["player"]["hand"] = ["red_cheap_shot"]
	main.run.manual_combat["player"]["focus"] = 1
	main.run.manual_combat["player"]["max_focus"] = max(int(main.run.manual_combat["player"].get("max_focus", 0)), 1)
	main.run.manual_combat["opponent"]["board"] = [{
		"instance_id": 881,
		"card_id": "ver_trail_guardian",
		"name": "Smoke Target",
		"attack": 2,
		"health": 5,
		"max_health": 5,
		"ready": false,
		"tags": []
	}]
	main._show_active_combat_screen()
	await process_frame
	await process_frame
	var unit_action_card := _find_named_node(main, "CombatCardPanel_Hand_red_cheap_shot")
	var opponent_unit_target := _find_named_node(main, "CombatCardPanel_OpponentUnit_881")
	if unit_action_card == null or opponent_unit_target == null:
		push_error("UI smoke test could not find unit action card or opponent unit target.")
		quit(1)
		return
	main._manual_try_begin_hand_card_drag("red_cheap_shot", unit_action_card)
	main._manual_update_hand_card_drag(_node_global_center(opponent_unit_target))
	await process_frame
	if _count_named_nodes(main, "ManualDragTargetPreviewArc") == 0:
		push_error("UI smoke test did not render a live drag preview arc for a unit action target.")
		quit(1)
		return
	main._manual_finish_hand_card_drag(_node_global_center(opponent_unit_target))
	await process_frame
	await process_frame
	if _opponent_unit_health(main, 881) != 5:
		push_error("UI smoke test committed a unit action before its play animation finished.")
		quit(1)
		return
	if _count_named_nodes(main, "ManualBoardMovingCardGhost") == 0:
		push_error("UI smoke test did not animate a dragged unit action.")
		quit(1)
		return
	await create_timer(1.2).timeout
	await process_frame
	if _opponent_unit_health(main, 881) != 2:
		push_error("UI smoke test did not resolve dragged action onto the opponent unit target after the play animation finished.")
		quit(1)
		return

	print("UI smoke test built polished UI Combat board targeting elements.")
	quit(0)


func _count_named_nodes(node: Node, target_name: String) -> int:
	var count := 1 if String(node.name).begins_with(target_name) else 0
	for child in node.get_children():
		count += _count_named_nodes(child, target_name)
	return count


func _has_label_text(node: Node, text: String) -> bool:
	if node is Label and String(node.text).contains(text):
		return true
	for child in node.get_children():
		if _has_label_text(child, text):
			return true
	return false


func _has_named_label_text(node: Node, target_name: String, text: String) -> bool:
	if node is Label and String(node.name) == target_name and String(node.text).contains(text):
		return true
	for child in node.get_children():
		if _has_named_label_text(child, target_name, text):
			return true
	return false


func _node_center_closer_to(root_node: Node, target_name: String, near_name: String, far_name: String) -> bool:
	var target := _find_named_node(root_node, target_name)
	var near := _find_named_node(root_node, near_name)
	var far := _find_named_node(root_node, far_name)
	if target == null or near == null or far == null:
		return false
	var target_center := _node_global_center(target)
	return target_center.distance_to(_node_global_center(near)) < target_center.distance_to(_node_global_center(far))


func _point_closer_to(root_node: Node, point_data: Variant, near_name: String, far_name: String) -> bool:
	if typeof(point_data) != TYPE_ARRAY or point_data.size() < 2:
		return false
	var near := _find_named_node(root_node, near_name)
	var far := _find_named_node(root_node, far_name)
	if near == null or far == null:
		return false
	var point := Vector2(float(point_data[0]), float(point_data[1]))
	return point.distance_to(_node_global_center(near)) < point.distance_to(_node_global_center(far))


func _player_board_has_card(main, card_id: String) -> bool:
	var board: Array = main.run.manual_combat.get("player", {}).get("board", [])
	for unit in board:
		if String(unit.get("card_id", "")) == card_id:
			return true
	return false


func _player_card_visual_slot(main, card_id: String) -> int:
	var board: Array = main.run.manual_combat.get("player", {}).get("board", [])
	for unit in board:
		if String(unit.get("card_id", "")) == card_id:
			return int(unit.get("board_slot", -1))
	return -1


func _player_engine_has_card(main, card_id: String) -> bool:
	var engines: Array = main.run.manual_combat.get("player", {}).get("engines", [])
	for engine in engines:
		if String(engine.get("card_id", "")) == card_id:
			return true
	return false


func _player_engine_visual_slot(main, card_id: String) -> int:
	var engines: Array = main.run.manual_combat.get("player", {}).get("engines", [])
	for engine in engines:
		if String(engine.get("card_id", "")) == card_id:
			return int(engine.get("engine_slot", -1))
	return -1


func _opponent_unit_health(main, instance_id: int) -> int:
	var board: Array = main.run.manual_combat.get("opponent", {}).get("board", [])
	for unit in board:
		if int(unit.get("instance_id", -1)) == instance_id:
			return int(unit.get("health", -999))
	return -999


func _find_named_node(node: Node, target_name: String) -> Node:
	if String(node.name).begins_with(target_name):
		return node
	for child in node.get_children():
		var found := _find_named_node(child, target_name)
		if found != null:
			return found
	return null


func _node_global_center(node: Node) -> Vector2:
	if node is Control:
		return (node as Control).get_global_rect().get_center()
	if node is Node2D:
		return (node as Node2D).global_position
	return Vector2.ZERO
