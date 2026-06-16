extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame

	main._start_new_run("flightless_birds")
	main._run_tournament()
	await process_frame

	if main.run.get("last_result", []).is_empty():
		push_error("Tournament smoke test produced no result log.")
		quit(1)
		return

	var saw_game_summary := false
	for line in main.run.get("last_result", []):
		if String(line).contains("Game 1:"):
			saw_game_summary = true
			break

	if not saw_game_summary:
		push_error("Tournament smoke test did not use combat game summaries.")
		quit(1)
		return

	print("Tournament smoke test ran combat-backed Weekly Locals.")
	quit(0)
