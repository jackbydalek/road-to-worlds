extends SceneTree

const TABLETOP_SCENE := preload("res://scenes/Tabletop3DPrototype.tscn")

var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var table = TABLETOP_SCENE.instantiate()
	_check_profile(table, {"combat": true, "target_kind": "unit", "source_card_type": "meal"}, "card", "combat_hit_thud", -5.0, 1)
	_check_profile(table, {"combat": true, "target_kind": "chef", "source_card_type": "ingredient"}, "ingredient_to_chef", "combat_hit_thud", -3.0, 1)
	_check_profile(table, {"combat": true, "target_kind": "chef", "source_card_type": "meal"}, "meal_to_chef", "combat_hit_ground", -4.0, 1)
	_check_profile(table, {"combat": false, "target_kind": "chef", "source_card_type": "meal"}, "effect", "impactGlass_light", -3.0, 5)
	_expect("meal_summon_epic_spell_impact.mp3" in String(table.MEAL_SUMMON_SOUND.resource_path), "Meal summons did not reference the DRAGON-STUDIO cue.")
	_expect(is_equal_approx(float(table.MEAL_SUMMON_VOLUME_DB), -10.0), "The Meal summon cue was not mixed below its source level.")
	_expect(is_equal_approx(float(table.MEAL_SUMMON_SOUND_DELAY_SECONDS), 0.44), "The Meal summon cue was not aligned with its landing flash.")
	_expect(is_equal_approx(float(table.MEAL_CHEF_IMPACT_START_OFFSET_SECONDS), 0.28), "The Meal hit cue retained its audible lead-in.")
	_expect("ability_activation_healing_magic.mp3" in String(table.ABILITY_ACTIVATION_SOUND.resource_path), "Activated abilities did not reference Yodguard's cue.")
	table.free()
	if failed:
		quit(1)
		return
	print("Impact sound routing smoke test passed.")
	quit()


func _check_profile(table: Node, event: Dictionary, expected_kind: String, expected_filename: String, expected_volume: float, expected_count: int) -> void:
	var profile: Dictionary = table._damage_impact_profile(event)
	var sounds: Array = profile.get("sounds", [])
	_expect(String(profile.get("kind", "")) == expected_kind, "%s damage selected the wrong impact category." % expected_kind)
	_expect(sounds.size() == expected_count, "%s exposed the wrong number of sound variations." % expected_kind)
	_expect(is_equal_approx(float(profile.get("volume_db", 0.0)), expected_volume), "%s used the wrong mix level." % expected_kind)
	for stream in sounds:
		_expect(expected_filename in String((stream as AudioStream).resource_path), "%s selected an asset from the wrong sound family." % expected_kind)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
