extends SceneTree


func _initialize() -> void:
	var packed := load("res://scenes/OverworldStageTest.tscn") as PackedScene
	var stage := packed.instantiate()
	root.call_deferred("add_child", stage)
	await process_frame
	var player := stage.get_node("Player")
	var sprite := stage.get_node("Player/Visual/Artwork/PlayerSprite") as Sprite3D
	if sprite.no_depth_test or sprite.render_priority != 0:
		push_error("Player sprite still bypasses foreground tree occlusion")
		quit(1)
		return
	if sprite.alpha_cut != SpriteBase3D.ALPHA_CUT_DISCARD:
		push_error("Player sprite is missing its transparent cutout depth pass")
		quit(1)
		return
	if sprite.texture == null or not sprite.texture.resource_path.ends_with("player_idle.png"):
		push_error("Player did not begin in the idle pose")
		quit(1)
		return
	player._set_pose("walk")
	if not sprite.texture.resource_path.ends_with("player_walk.png"):
		push_error("Walk pose did not load")
		quit(1)
		return
	player._set_pose("victory")
	if not sprite.texture.resource_path.ends_with("player_victory.png"):
		push_error("Victory pose did not load")
		quit(1)
		return
	player.configure_character("hearty")
	if not sprite.texture.resource_path.ends_with("hearty_player_idle.png"):
		push_error("Hearty player did not begin in the supplied idle pose")
		quit(1)
		return
	player._set_pose("walk")
	if not sprite.texture.resource_path.ends_with("hearty_player_walk.png"):
		push_error("Hearty walk pose did not load")
		quit(1)
		return
	player._set_pose("victory")
	if not sprite.texture.resource_path.ends_with("hearty_player_victory.png"):
		push_error("Hearty victory pose did not load")
		quit(1)
		return
	player.configure_character("sweet")
	for pose in ["idle", "walk", "victory"]:
		player._set_pose(pose)
		if not sprite.texture.resource_path.ends_with("sweet_player_neutral.png"):
			push_error("Sweet neutral art did not load for the %s pose" % pose)
			quit(1)
			return
	if player.walk_cycle_speed > 8.0:
		push_error("The overworld walk cycle is still too fast")
		quit(1)
		return
	if player.route_move_speed > 4.2 or player.route_move_speed >= player.move_speed:
		push_error("Automatic route travel is still too fast to read as walking")
		quit(1)
		return
	if player.walk_bounce_height < 0.08:
		push_error("The overworld walk cycle is missing its readable bounce")
		quit(1)
		return
	print("OVERWORLD_POSE_SMOKE_TEST_OK")
	quit()
