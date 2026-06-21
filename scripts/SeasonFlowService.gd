extends RefCounted
class_name SeasonFlowService

const DEFAULT_SEASON_GOAL := "Win Worlds before your season lives run out."

var run_state_service: RefCounted
var tournaments_by_id: Dictionary = {}


func setup(state_service: RefCounted, tournament_database: Dictionary) -> void:
	run_state_service = state_service
	tournaments_by_id = tournament_database


func normalize_calendar_state(run: Dictionary) -> void:
	if run.is_empty():
		return
	var ids: Array = run.get("season_calendar", [])
	if ids.is_empty():
		ids = run_state_service.default_season_calendar()
		run.season_calendar = ids.duplicate()
	if not run.has("calendar_completed") or not (run.calendar_completed is Array):
		run.calendar_completed = []
	run.calendar_unlocked_index = clamp(int(run.get("calendar_unlocked_index", 0)), 0, max(0, ids.size() - 1))
	if not run.has("season_goal"):
		run.season_goal = DEFAULT_SEASON_GOAL
	if not run.has("season_champion"):
		run.season_champion = false
	if not run.has("season_notice"):
		run.season_notice = ""
	var selected_id := String(run.get("selected_event_id", ""))
	if selected_id == "" or not ids.has(selected_id) or event_completed(run, selected_id):
		run.selected_event_id = first_selectable_event_id(run)


func calendar_ids(run: Dictionary) -> Array:
	if run.is_empty():
		return []
	var ids: Array = run.get("season_calendar", [])
	if ids.is_empty():
		ids = run_state_service.default_season_calendar()
		run.season_calendar = ids.duplicate()
	return ids


func event_index(run: Dictionary, event_id: String) -> int:
	var ids := calendar_ids(run)
	for index in range(ids.size()):
		if String(ids[index]) == event_id:
			return index
	return -1


func event_by_id(event_id: String) -> Dictionary:
	if tournaments_by_id.has(event_id):
		return tournaments_by_id[event_id]
	return tournaments_by_id.get("weekly_locals", {})


func first_selectable_event_id(run: Dictionary) -> String:
	var ids := calendar_ids(run)
	if ids.is_empty():
		return "weekly_locals"
	var completed: Array = run.get("calendar_completed", [])
	var unlocked: int = clamp(int(run.get("calendar_unlocked_index", 0)), 0, max(0, ids.size() - 1))
	for index in range(ids.size()):
		var event_id := String(ids[index])
		if index <= unlocked and not completed.has(event_id):
			return event_id
	return String(ids[unlocked])


func selected_event_id(run: Dictionary) -> String:
	normalize_calendar_state(run)
	return String(run.get("selected_event_id", "weekly_locals"))


func selected_event(run: Dictionary) -> Dictionary:
	return event_by_id(selected_event_id(run))


func event_completed(run: Dictionary, event_id: String) -> bool:
	var completed: Array = run.get("calendar_completed", [])
	return completed.has(event_id)


func event_unlocked(run: Dictionary, event_id: String) -> bool:
	var index := event_index(run, event_id)
	return index >= 0 and index <= int(run.get("calendar_unlocked_index", 0))


func event_selectable(run: Dictionary, event_id: String, tournament_active: bool) -> bool:
	return event_unlocked(run, event_id) and not event_completed(run, event_id) and not tournament_active


func completed_count(run: Dictionary) -> int:
	var count := 0
	var completed: Array = run.get("calendar_completed", [])
	for event_id in calendar_ids(run):
		if completed.has(String(event_id)):
			count += 1
	return count


func event_is_final(run: Dictionary, event_id: String) -> bool:
	var ids := calendar_ids(run)
	return not ids.is_empty() and event_id == String(ids[ids.size() - 1])


func mark_event_completed(run: Dictionary, event_id: String) -> void:
	var completed: Array = run.get("calendar_completed", [])
	if not completed.has(event_id):
		completed.append(event_id)
	run.calendar_completed = completed
	var ids := calendar_ids(run)
	var index := event_index(run, event_id)
	if index >= 0:
		run.calendar_unlocked_index = max(int(run.get("calendar_unlocked_index", 0)), min(index + 1, ids.size() - 1))
		if index + 1 < ids.size():
			run.selected_event_id = String(ids[index + 1])
			set_prep_notice(run, String(ids[index + 1]))


func set_prep_notice(run: Dictionary, event_id: String) -> void:
	run.season_notice = prep_notice_text(event_id)


func prep_notice_text(event_id: String) -> String:
	var event := event_by_id(event_id)
	return "%s unlocked. Prepare your deck before registering: visit the shop, open prize packs, and tune for %s." % [
		String(event.get("name", event_id)),
		String(event.get("winConditionText", "the required record"))
	]
