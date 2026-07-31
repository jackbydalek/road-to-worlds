extends SceneTree

const CARD_FACE_SCRIPT := preload("res://scripts/CardFace.gd")
const CONTENT_CATALOG_SCRIPT := preload("res://scripts/ContentCatalog.gd")
const CHEF_SOUP_ART_PATH := "res://assets/cards/art/chefs/soup.png"
const SUPPLIED_ART_CARDS := [
	"spicy_habanero_hare",
	"spicy_jalapeno_jackal",
	"spicy_jalapeno_panther",
	"spicy_wasabi_wasp",
	"hearty_gravy_gazelle",
	"hearty_bison_burrito",
	"spicy_ghost_pepper_python",
	"hearty_macaroni_manatee",
	"hearty_polar_pot_pie_bear"
]

var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog = CONTENT_CATALOG_SCRIPT.new()
	_expect(catalog.load_all(), "Card catalog did not load.")
	var rendered_faces: Dictionary = {}
	for card_id in SUPPLIED_ART_CARDS:
		var card: Dictionary = catalog.cards_by_id.get(card_id, {})
		var art_frames: Array = card.get("art_frames", [])
		_expect(art_frames.size() == 6 and art_frames.all(func(frame_path) -> bool: return String(frame_path).contains(card_id) and ResourceLoader.exists(String(frame_path))), "%s did not reference all six supplied animation frames." % card_id)

		var face := CARD_FACE_SCRIPT.new()
		face.configure(card, "white", true)
		root.add_child(face)
		var artwork := face.find_child("CardArtwork", true, false) as TextureRect
		_expect(artwork != null and artwork.texture != null and artwork.texture.resource_path == String(art_frames[0]) and not bool(artwork.get_meta("art_pending", true)), "%s did not render its supplied animation on the card face." % card_id)
		rendered_faces[card_id] = face

	await process_frame
	await create_timer(0.09).timeout
	for card_id in rendered_faces:
		var face: Control = rendered_faces[card_id]
		var artwork := face.find_child("CardArtwork", true, false) as TextureRect
		_expect(artwork != null and artwork.texture != null and not artwork.texture.resource_path.ends_with("frame_00.png"), "%s supplied artwork did not animate." % card_id)
		face.queue_free()

	var chef_soup: Dictionary = catalog.cards_by_id.get("chef_soup", {})
	_expect(String(chef_soup.get("art_path", "")) == CHEF_SOUP_ART_PATH and ResourceLoader.exists(CHEF_SOUP_ART_PATH), "Chef Soup did not reference the supplied portrait.")
	var chef_soup_face := CARD_FACE_SCRIPT.new()
	chef_soup_face.configure(chef_soup, "white", false)
	root.add_child(chef_soup_face)
	var chef_soup_artwork := chef_soup_face.find_child("CardArtwork", true, false) as TextureRect
	_expect(chef_soup_artwork != null and chef_soup_artwork.texture != null and chef_soup_artwork.texture.resource_path == CHEF_SOUP_ART_PATH and not bool(chef_soup_artwork.get_meta("art_pending", true)), "Chef Soup did not render the supplied portrait.")
	chef_soup_face.queue_free()
	if failed:
		quit(1)
	else:
		print("Supplied card artwork smoke test passed.")
		quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
