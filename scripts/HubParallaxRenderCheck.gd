extends SceneTree
## Measures actual rendered subpixel movement, not just spring coordinates.
## --baseline records the old behavior without asserting the smoothness limit.

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main := (load("res://scenes/Main.tscn") as PackedScene).instantiate()
	main.autosave_suspended = true
	root.add_child(main)
	main.autosave_enabled = false
	main.player_settings.reduced_motion = false
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var deck: Dictionary = main._deck_entries_to_dict(main.archetypes_by_id.spicy.starterDeck)
	main.run = main.run_state_service.create_run("spicy", deck, "hearty", "season", "white")
	main.route_run_service.initialize_run(main.run, 20260905)
	main._show_tournament_hub()
	var hub := main.find_child("TournamentHub", true, false)
	hub.set_process(false)
	for unused in range(8):
		await process_frame
	# A bilinear texture makes fractional translation measurable at a real edge.
	# It is mounted on the production layer and never enters the shipped scene.
	var texture_image := Image.create(64, 16, false, Image.FORMAT_RGBA8)
	texture_image.fill(Color.BLACK)
	for x in range(28, 36):
		for y in range(16):
			texture_image.set_pixel(x, y, Color.WHITE)
	var samples: Dictionary = {}
	for layer_name in ["HubBackLayer", "HubMidLayer", "HubFrontLayer", "HubRoomCamera"]:
		var layer: CanvasItem = hub.find_child(layer_name, true, false)
		var original: Vector2 = layer.position
		var marker := Sprite2D.new()
		marker.texture = ImageTexture.create_from_image(texture_image)
		marker.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		marker.centered = false
		marker.position = Vector2(900, 310)
		marker.z_index = 4000
		layer.add_child(marker)
		var centers: Array[float] = []
		for frame in range(49):
			layer.position = original + Vector2(float(frame) / 16.0, 0)
			await process_frame
			await RenderingServer.frame_post_draw
			var rendered := root.get_texture().get_image()
			var total := 0.0
			var weighted := 0.0
			var origin := marker.get_global_transform_with_canvas().origin
			for x in range(floori(origin.x) + 20, floori(origin.x) + 45):
				var value := rendered.get_pixel(x, roundi(origin.y) + 8).r
				total += value
				weighted += value * x
			assert(total > 1.0, "Motion measurement marker is obscured.")
			centers.append(weighted / total)
		var largest_step := 0.0
		var stalled_frames := 0
		for i in range(1, centers.size()):
			var step := absf(centers[i] - centers[i - 1])
			largest_step = maxf(largest_step, step)
			if step < 0.005:
				stalled_frames += 1
		samples[layer_name] = {"node_type": layer.get_class(), "largest_pixel_step": largest_step, "stalled_frames": stalled_frames, "total_pixel_travel": centers.back() - centers.front()}
		layer.position = original
		layer.remove_child(marker)
		marker.queue_free()
	var baseline := "--baseline" in OS.get_cmdline_user_args()
	var result := {"gui_snap_controls_to_pixels": root.gui_snap_controls_to_pixels, "samples": samples}
	var output_dir := ProjectSettings.globalize_path("res://outputs/parallax_motion")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var file := FileAccess.open(output_dir.path_join("before.json" if baseline else "after.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	print(JSON.stringify(result))
	if not baseline:
		for sample in samples.values():
			assert(sample.largest_pixel_step < 0.15 and sample.stalled_frames == 0 and sample.total_pixel_travel > 2.9, "Room movement still stalls or jumps between pixels.")
	print("HUB_PARALLAX_RENDER_CHECK_COMPLETE")
	main._release_audio_streams()
	main.queue_free()
	await process_frame
	quit(0)
