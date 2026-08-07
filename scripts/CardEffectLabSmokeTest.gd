extends SceneTree

const LAB_SCRIPT := preload("res://scripts/CardEffectLab.gd")


func _init() -> void:
	var lab: RefCounted = LAB_SCRIPT.new()
	var results: Array[Dictionary] = lab.run_all_scenarios()
	var failed_labels: Array[String] = []
	for result in results:
		if not bool(result.get("passed", false)):
			failed_labels.append(String(result.get("label", result.get("id", "unknown"))))
	if results.size() != lab.SCENARIOS.size():
		push_error("Card Effect Lab did not run every registered canonical scenario.")
		quit(1)
		return
	if not failed_labels.is_empty():
		push_error("Canonical Card Effect Lab failures: %s" % ", ".join(failed_labels))
		quit(1)
		return
	print("Canonical Card Effect Lab smoke test passed (%d/%d)." % [results.size(), lab.SCENARIOS.size()])
	quit(0)
