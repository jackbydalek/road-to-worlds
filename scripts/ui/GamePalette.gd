extends RefCounted
class_name GamePalette

## The single source of truth for player-facing UI color.
## New themes and custom controls should reference these constants instead of
## embedding color literals, so a palette change propagates across the game.
## Warm, daylight cafe colors. Lavender is now an accent rather than the room's
## ambient fill, which keeps the lofi character without making every screen
## feel like it is taking place after closing time.
const GHOST := Color("#F5EBD8") # steamed-milk paper
const APRICOT := Color("#E8D1AD") # warm parchment
const SLATE := Color("#846B60") # cocoa-grey secondary copy
const TEAL := Color("#638B83") # muted ceramic teal
const BRICK := Color("#B85F52") # paprika red; warm, not purple

## Derived colors preserve readable states without introducing new color
## identities. They are all lightened/darkened variants of the five swatches.
const INK := Color("#3A241F") # espresso ink, never pure black
const TEAL_DARK := Color("#426B65")
const TEAL_HOVER := Color("#7CA39A")
const BRICK_DARK := Color("#8E4037")
const BRICK_HOVER := Color("#CC7668")
const GHOST_PRESSED := Color("#E8DBC4")
const DISABLED := Color("#D9CCBA")
const DISABLED_INK := Color("#9B8A7C")
const BORDER_SOFT := Color("#A86947")
const TEAL_SOFT := Color("#C9D8C9")
const BRICK_SOFT := Color("#E8C3B9")
const APRICOT_SOFT := Color("#F0DFC2")

## Supporting swatches for screens that need hierarchy beyond the legacy five.
const HONEY := Color("#D8B35F")
const SAGE := Color("#82966F")
const ROSE := Color("#C48691")
const LAVENDER := Color("#A69AB7")

## Brighter glass accents shared by navigation, selection, and primary actions.
## These preserve the game's pastel card-shop identity without requiring
## illustrated UI-kit textures.
const NAVY := Color("#29365F")
const NAVY_MUTED := Color("#53628A")
const CREAM := Color("#FFF7F1")
const CORAL := Color("#EF7E76")
const BLUSH := Color("#F2A4B8")
const PERIWINKLE := Color("#8EA9E6")
const SKY := Color("#68C5E8")
const LAVENDER_GLASS := Color("#E8E3F5")
const FRESH_YELLOW := Color("#D8B35F")
const FUNKY_PLUM := Color("#9A6EAE")
