extends RefCounted
class_name AffinityVisuals

const SYMBOL_FONT := preload("res://assets/fonts/KitchenAffinitySymbols.ttf")

const SYMBOLS := {
	"fresh": "🍋‍🟩",
	"spicy": "🌶️",
	"funky": "🥒",
	"sweet": "🍬",
	"hearty": "🍲",
	"neutral": "🧊",
	"typeless": "🧊",
}

const DISPLAY_NAMES := {
	"fresh": "Fresh",
	"spicy": "Spicy",
	"funky": "Funky",
	"sweet": "Sweet",
	"hearty": "Hearty",
	"neutral": "Typeless",
	"typeless": "Typeless",
	"any": "Any",
}

const CARD_TYPE_SYMBOLS := {
	"chef": "🧑‍🍳",
	"tool": "🥄",
	"spice": "✨",
	"environment": "🌄",
}

const CARD_TYPE_NAMES := {
	"chef": "Chef",
	"tool": "Item",
	"spice": "Spice",
	"environment": "Environment",
}


static func symbol(archetype_id: String) -> String:
	return String(SYMBOLS.get(archetype_id.to_lower(), ""))


static func label(archetype_id: String, fallback_name: String = "") -> String:
	var normalized := archetype_id.to_lower()
	var display_name := String(DISPLAY_NAMES.get(normalized, fallback_name))
	if display_name == "":
		display_name = archetype_id.capitalize()
	var affinity_symbol := symbol(normalized)
	if affinity_symbol == "":
		return display_name
	return "%s %s" % [affinity_symbol, display_name]


static func format_requirements(requirements: Array) -> String:
	if requirements.is_empty():
		return "No ingredients required"
	var formatted: Array[String] = []
	for requirement in requirements:
		var archetype_id := String(requirement)
		if archetype_id == "any":
			formatted.append("*")
			continue
		var options: Array[String] = []
		for option in archetype_id.split("|"):
			options.append(label(String(option)))
		formatted.append(" or ".join(options))
	return " + ".join(formatted)


static func card_type_symbol(card_type: String) -> String:
	return String(CARD_TYPE_SYMBOLS.get(card_type.to_lower(), ""))


static func card_type_label(card_type: String) -> String:
	var normalized := card_type.to_lower()
	var display_name := String(CARD_TYPE_NAMES.get(normalized, card_type.capitalize()))
	if display_name == "":
		display_name = "Card"
	var type_symbol := card_type_symbol(normalized)
	if type_symbol == "":
		return display_name
	return "%s %s" % [type_symbol, display_name]


static func card_display_name(card: Dictionary) -> String:
	var display_name := String(card.get("name", card.get("id", "Card")))
	var type_symbol := card_type_symbol(String(card.get("card_type", "")))
	var display_symbol := type_symbol
	if display_symbol == "":
		display_symbol = symbol(String(card.get("archetype", "neutral")))
	if display_symbol == "":
		return display_name
	return "%s %s" % [display_symbol, display_name]


static func card_classification_symbol(card: Dictionary) -> String:
	var type_symbol := card_type_symbol(String(card.get("card_type", "")))
	if type_symbol != "":
		return type_symbol
	return symbol(String(card.get("archetype", "neutral")))


static func card_classification_label(card: Dictionary) -> String:
	var card_type := String(card.get("card_type", "card"))
	if card_type_symbol(card_type) != "":
		return card_type_label(card_type)
	return label(String(card.get("archetype", "neutral")))


static func card_descriptor(card: Dictionary) -> String:
	var card_type := String(card.get("card_type", "card"))
	if card_type_symbol(card_type) != "":
		return card_type_label(card_type)
	return "%s %s" % [label(String(card.get("archetype", "neutral"))), card_type.capitalize()]


static func monochrome_symbol_font() -> FontFile:
	var monochrome := SYMBOL_FONT.duplicate() as FontFile
	monochrome.allow_system_fallback = false
	return monochrome


static func font_with_symbols(base_font: Font) -> FontVariation:
	var scoped_base := base_font.duplicate() as Font
	if scoped_base is FontFile or scoped_base is SystemFont:
		scoped_base.set("allow_system_fallback", false)
	var scoped_symbols := monochrome_symbol_font()
	var combined := FontVariation.new()
	combined.base_font = scoped_base
	var symbol_fallbacks: Array[Font] = [scoped_symbols]
	combined.fallbacks = symbol_fallbacks
	return combined


static func default_ui_font_with_symbols() -> FontVariation:
	return font_with_symbols(ThemeDB.fallback_font)
