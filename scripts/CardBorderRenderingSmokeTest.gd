extends SceneTree
## Checks actual rendered outer pixels as well as the separate physical sleeve.
## Run without --headless for raster checks; headless still checks 3D geometry.

const CARD_FACE := preload("res://scripts/CardFace.gd")
const TABLE_SCENE := preload("res://scenes/Tabletop3DPrototype.tscn")
const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const OUTPUT := "res://outputs/battle_feedback_2026-09-11/borders"
const BORDERS := ["white", "blue", "yellow", "silver", "gold"]

var errors: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var table = TABLE_SCENE.instantiate()
	root.add_child(table)
	await process_frame
	await process_frame
	await create_timer(1.0).timeout
	table.production_match = true
	var card: Dictionary = table.service.card("sweet_pup_tart")
	var viewport := SubViewport.new()
	viewport.disable_3d = true
	viewport.transparent_bg = true
	viewport.size = Vector2i(420, 620)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var raster := DisplayServer.get_name() != "headless"
	if raster:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	for border_value in BORDERS:
		var border_id := String(border_value)
		var expected := PALETTE.card_border_color(border_id)
		table.configured_card_border_id = border_id
		table.face_materials.clear()
		var physical := table._make_card("sweet_pup_tart", true) as Node3D
		var body := physical.get_node("CardBody") as MeshInstance3D
		var material := body.material_override as StandardMaterial3D
		_expect(material.albedo_color.is_equal_approx(expected), "%s physical sleeve retained a different outer color." % border_id)
		var expected_size: Vector3 = Vector3(table.FIELD_CARD_SIZE.x * 404.0 / 420.0, 0.06, table.FIELD_CARD_SIZE.y * 604.0 / 620.0)
		_expect(body.mesh.get_aabb().size.is_equal_approx(expected_size), "%s physical sleeve extends beyond the printed face." % border_id)
		physical.free()
		for compact in [false, true]:
			var face := CARD_FACE.new()
			face.configure(card, border_id, false, compact)
			face.custom_minimum_size = Vector2(420, 620)
			face.size = Vector2(420, 620)
			viewport.add_child(face)
			await process_frame
			await process_frame
			var runtime := face.find_child("RuntimeCardFace", true, false) as RuntimeAngularCard
			_expect(runtime.card_border_color.is_equal_approx(expected), "%s lost its border in the shared face." % border_id)
			if raster:
				await RenderingServer.frame_post_draw
				var rendered := viewport.get_texture().get_image()
				# Sample all four outer bands, clear of interior ribbons and artwork.
				for sample in [Vector2i(10, 500), Vector2i(409, 500), Vector2i(210, 10), Vector2i(210, 609)]:
					var pixel := rendered.get_pixelv(sample)
					_expect(_same_rgb(pixel, expected) and pixel.a > 0.99, "%s %s outer pixel %s is %s instead of the selected rim." % [border_id, "compact" if compact else "full", sample, pixel])
				# Nothing dark may surround that band in the transparent face texture.
				for sample in [Vector2i(4, 500), Vector2i(416, 500), Vector2i(210, 4), Vector2i(210, 617), Vector2i(8, 8)]:
					_expect(rendered.get_pixelv(sample).a < 0.01, "%s outer padding contains an unwanted printed surround at %s." % [border_id, sample])
				if not compact:
					var label := "black" if border_id == "white" else border_id
					_expect(rendered.save_png(ProjectSettings.globalize_path(OUTPUT.path_join(label + ".png"))) == OK, "Could not save %s rim capture." % label)
			face.queue_free()
			await process_frame
			await process_frame
	# Concealed cards keep the supplied card-back presentation.
	var concealed := table._make_card("sweet_pup_tart", false) as Node3D
	var concealed_body := concealed.get_node("CardBody") as MeshInstance3D
	_expect((concealed_body.material_override as StandardMaterial3D).albedo_color.is_equal_approx(PALETTE.PEACH_INK), "Concealed cards changed their supplied-back sleeve.")
	concealed.free()
	viewport.queue_free()
	table.queue_free()
	await process_frame
	await process_frame
	for message in errors:
		push_error(message)
	print("Card border rendering smoke test: five colors, full/compact faces, physical sleeves; %s; %d failures." % ["rendered pixels verified" if raster else "headless (pixel checks skipped)", errors.size()])
	quit(0 if errors.is_empty() else 1)


func _same_rgb(left: Color, right: Color) -> bool:
	return maxf(absf(left.r - right.r), maxf(absf(left.g - right.g), absf(left.b - right.b))) < 0.015


func _expect(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)
