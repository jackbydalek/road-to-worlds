extends RefCounted

## Rival presentation registry. Mina uses the owner's supplied GIF frames;
## the other eight portraits are replaceable generated working art.
## The generated-art switch never hides the separately supplied Mina artwork.
const GENERATED_ART_ENABLED := true
const FALLBACK := preload("res://assets/ui/locals-card-club-mark.svg")
const CHARACTER_IDS: Array[String] = ["pip", "otis", "ines", "sana", "milo", "bea", "kit", "ellis", "mina"]
const GENERATED_IDS: Array[String] = ["pip", "otis", "ines", "sana", "milo", "bea", "kit", "ellis"]
const REGULAR_IDS: Array[String] = ["pip", "otis", "ines", "sana", "milo", "kit"]
const CANVAS := Vector2(1448, 1200)
const RESTING_ARM_Y := 1000.0
const ART_ROOT := "res://assets/generated/peach_soda_opponents/"
const MINA_ROOT := "res://assets/characters/mina/"


static func ids() -> Array[String]:
	return CHARACTER_IDS.duplicate()


static func is_cast_id(id: String) -> bool:
	return id.to_lower() in CHARACTER_IDS


static func resolve_id(portrait_id: String, opponent_name: String = "", seed: int = 0) -> String:
	if is_cast_id(portrait_id):
		return portrait_id.to_lower()
	for id in CHARACTER_IDS:
		if opponent_name.to_lower() == id or opponent_name.to_lower().ends_with(" " + id):
			return id
	# Presentation selection is deterministic and never consumes combat RNG.
	return REGULAR_IDS[posmod(seed, REGULAR_IDS.size())]


static func name_for(id: String) -> String:
	return id.capitalize() if is_cast_id(id) else "Local regular"


static func asset_path(id: String) -> String:
	if id.to_lower() == "mina":
		return MINA_ROOT + "idle-00.png"
	return ART_ROOT + id.to_lower() + ".png" if id.to_lower() in GENERATED_IDS else ""


static func has_generated_art(id: String, enabled: bool = true) -> bool:
	return GENERATED_ART_ENABLED and enabled and id.to_lower() in GENERATED_IDS and ResourceLoader.exists(asset_path(id))


static func has_supplied_art(id: String) -> bool:
	return id.to_lower() == "mina" and ResourceLoader.exists(asset_path(id))


static func has_seated_art(id: String, generated_enabled: bool = true) -> bool:
	return has_supplied_art(id) or has_generated_art(id, generated_enabled)


static func texture_for(id: String, generated_enabled: bool = true) -> Texture2D:
	if has_seated_art(id, generated_enabled):
		return load(asset_path(id)) as Texture2D
	return FALLBACK


static func profile_texture(id: String, generated_enabled: bool = true) -> Texture2D:
	if not has_seated_art(id, generated_enabled):
		return FALLBACK
	var portrait := AtlasTexture.new()
	portrait.atlas = texture_for(id, generated_enabled)
	portrait.region = Rect2(130, 90, 335, 335) if id.to_lower() == "mina" else Rect2(345, 0, 758, 758)
	return portrait


static func frame_textures(id: String, generated_enabled: bool = true) -> Array[Texture2D]:
	var frames: Array[Texture2D] = []
	if has_supplied_art(id):
		for index in range(6):
			var path := MINA_ROOT + "idle-%02d.png" % index
			if not ResourceLoader.exists(path):
				# A partially removed animation remains a usable static portrait.
				return [texture_for(id, generated_enabled)]
			frames.append(load(path) as Texture2D)
	else:
		frames.append(texture_for(id, generated_enabled))
	return frames


static func frame_durations(id: String) -> Array[float]:
	var durations: Array[float] = [1.0]
	if id.to_lower() == "mina":
		durations = [0.07, 0.07, 0.07, 0.07, 0.07, 0.07]
	return durations


static func canvas_for(id: String) -> Vector2:
	return Vector2(701, 628) if id.to_lower() == "mina" else CANVAS


static func resting_arm_y_for(id: String) -> float:
	return 610.0 if id.to_lower() == "mina" else RESTING_ARM_Y


static func height_fraction_for(id: String) -> float:
	# Mina's source is tightly cropped; the generated sheets have large gutters.
	match id.to_lower():
		"mina":
			return 0.28
		"milo":
			# Fit both the hair and low resting fist above the opposing cloth.
			return 0.37
	return 0.435


static func table_anchor_fraction_for(id: String) -> float:
	# Keep Mina's low resting hand above the far mat edge, not hidden behind it.
	match id.to_lower():
		"mina":
			return 0.29
		"milo":
			# The portrait and live finger layer must both clear the mat. Otherwise
			# its edge cuts the body while the higher finger overlay remains visible.
			return 0.286
	return 0.33
