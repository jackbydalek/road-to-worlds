extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")

var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await create_timer(1.0).timeout

	var shop_music := main.find_child("CardShopMusic", true, false) as AudioStreamPlayer
	_expect(shop_music != null and shop_music.playing, "Intro music did not start on the title menu.")
	_expect(shop_music != null and shop_music.stream.resource_name.ends_with("intro.mp3"), "The title menu did not use the intro track.")
	_expect(shop_music != null and shop_music.bus == &"MenuMusic", "Title music did not use the faded menu mix.")
	_expect(shop_music != null and is_equal_approx(shop_music.volume_db, main.MENU_MUSIC_VOLUME_DB), "Title music did not reach its intended mix level.")
	var menu_bus := AudioServer.get_bus_index("MenuMusic")
	_expect(menu_bus >= 0 and AudioServer.get_bus_send(menu_bus) == &"Music", "The menu mix did not feed the Music settings bus.")
	_expect(menu_bus >= 0 and AudioServer.get_bus_effect_count(menu_bus) == 1, "The menu mix was missing its low-pass treatment.")
	main.current_screen = "season"
	main._sync_music_for_current_screen()
	_expect(shop_music.playing and shop_music.bus == &"MenuMusic", "The season calendar did not retain the pre-shop mix.")

	main.current_screen = "shop"
	main._sync_music_for_current_screen()
	await create_timer(1.0).timeout
	_expect(shop_music.playing and shop_music.bus == &"Music", "Entering the shop did not restore the full shop mix.")
	_expect(shop_music.stream.resource_name.ends_with("shop.mp3"), "The card store did not use the shop track.")
	_expect(is_equal_approx(shop_music.volume_db, main.SHOP_MUSIC_VOLUME_DB), "Shop music did not reach its intended mix level.")

	main.current_screen = "kitchen_match"
	main._sync_music_for_current_screen()
	await create_timer(1.0).timeout
	var battle_music := main.find_child("BattleMusic", true, false) as AudioStreamPlayer
	_expect(battle_music != null and battle_music.playing and battle_music.bus == &"Music", "Combat music did not take over for a battle.")
	_expect(battle_music != null and battle_music.stream.resource_name.ends_with("combat.mp3"), "The battle did not use the combat track.")
	_expect(battle_music != null and is_equal_approx(battle_music.volume_db, main.BATTLE_MUSIC_VOLUME_DB), "Battle music did not reach its intended mix level.")
	_expect(not shop_music.playing, "Shop music remained audible under the battle track.")

	main.current_screen = "shop"
	main._sync_music_for_current_screen()
	await create_timer(1.0).timeout
	_expect(shop_music.playing and not battle_music.playing, "Returning to the shop did not restore Sunlit cleanly.")

	main._release_audio_streams()
	await create_timer(0.12).timeout
	main.queue_free()
	await process_frame
	if failed:
		quit(1)
		return
	print("Music mix smoke test passed.")
	quit()


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
