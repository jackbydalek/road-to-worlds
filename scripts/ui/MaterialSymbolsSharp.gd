extends RefCounted
class_name MaterialSymbolsSharp

## Small, explicit subset of Google Material Symbols Sharp used by production
## UI. Keeping a curated local set avoids an icon-font dependency and makes the
## exact shipped glyphs deterministic in Godot exports.

const ICONS := {
	"accessibility": preload("res://assets/ui/material_symbols_sharp/accessibility_new.svg"),
	"add": preload("res://assets/ui/material_symbols_sharp/add.svg"),
	"attach": preload("res://assets/ui/material_symbols_sharp/attach_file.svg"),
	"back": preload("res://assets/ui/material_symbols_sharp/arrow_back.svg"),
	"calendar": preload("res://assets/ui/material_symbols_sharp/calendar_month.svg"),
	"cards": preload("res://assets/ui/material_symbols_sharp/cards.svg"),
	"check": preload("res://assets/ui/material_symbols_sharp/check.svg"),
	"close": preload("res://assets/ui/material_symbols_sharp/close.svg"),
	"delete": preload("res://assets/ui/material_symbols_sharp/delete.svg"),
	"display": preload("res://assets/ui/material_symbols_sharp/display_settings.svg"),
	"folder": preload("res://assets/ui/material_symbols_sharp/folder_open.svg"),
	"forward": preload("res://assets/ui/material_symbols_sharp/arrow_forward.svg"),
	"heart": preload("res://assets/ui/material_symbols_sharp/favorite.svg"),
	"history": preload("res://assets/ui/material_symbols_sharp/history.svg"),
	"info": preload("res://assets/ui/material_symbols_sharp/info.svg"),
	"library": preload("res://assets/ui/material_symbols_sharp/menu_book.svg"),
	"money": preload("res://assets/ui/material_symbols_sharp/paid.svg"),
	"play": preload("res://assets/ui/material_symbols_sharp/play_arrow.svg"),
	"remove": preload("res://assets/ui/material_symbols_sharp/remove.svg"),
	"restart": preload("res://assets/ui/material_symbols_sharp/restart_alt.svg"),
	"save": preload("res://assets/ui/material_symbols_sharp/save.svg"),
	"settings": preload("res://assets/ui/material_symbols_sharp/settings.svg"),
	"sort": preload("res://assets/ui/material_symbols_sharp/sort.svg"),
	"speed": preload("res://assets/ui/material_symbols_sharp/speed.svg"),
	"store": preload("res://assets/ui/material_symbols_sharp/storefront.svg"),
	"swap": preload("res://assets/ui/material_symbols_sharp/swap_horiz.svg"),
	"swords": preload("res://assets/ui/material_symbols_sharp/swords.svg"),
	"upgrade": preload("res://assets/ui/material_symbols_sharp/upgrade.svg"),
	"view_grid": preload("res://assets/ui/material_symbols_sharp/view_module.svg"),
	"volume": preload("res://assets/ui/material_symbols_sharp/volume_up.svg"),
}


static func icon(symbol_id: String) -> Texture2D:
	return ICONS.get(symbol_id) as Texture2D


static func apply_to_button(
	button: Button,
	symbol_id: String,
	max_width: int = 20,
	alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT
) -> Button:
	var symbol := icon(symbol_id)
	if button == null or symbol == null:
		return button
	button.icon = symbol
	button.expand_icon = false
	button.icon_alignment = alignment
	button.add_theme_constant_override("icon_max_width", max_width)
	button.set_meta("material_symbol", symbol_id)
	return button
