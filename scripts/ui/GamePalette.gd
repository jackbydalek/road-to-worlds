extends RefCounted
class_name GamePalette

## Pokémon Black and White-inspired UI foundation. These are the target tokens
## for new and migrated interface chrome.
const CARBON := Color("#12161C")
const TRUE_BLACK := Color("#000000")
const GRAPHITE := Color("#252B33")
const STEEL := Color("#4A535F")
const COOL_WHITE := Color("#F3F6FA")
const ELECTRIC_CYAN := Color("#26C7ED")
const SELECTION_BLUE := Color("#168AC3")
const SIGNAL_RED := Color("#EF3655")
const EMERALD := Color("#21C77A")
const SIGNAL_YELLOW := Color("#F2D33D")
const INTERFACE_VIOLET := Color("#7258C7")

## Production semantic roles. Player-facing UI should consume these names so
## layout code describes intent instead of choosing a color ad hoc. The aliases
## keep ART_DIRECTION.md's compact target palette as the single source of truth.
const SURFACE_ROOT := CARBON
const SURFACE_RAISED := GRAPHITE
const SURFACE_SECONDARY := STEEL
const SURFACE_PAPER := COOL_WHITE
const SURFACE_PAPER_MUTED := Color("#DDE3EA")
const TEXT_PRIMARY := COOL_WHITE
const TEXT_SECONDARY := Color("#B7C0CB")
const TEXT_DISABLED := Color("#76808C")
const TEXT_ON_LIGHT := CARBON
const TEXT_ON_LIGHT_SECONDARY := Color("#4F5965")
const STRUCTURAL_EDGE := Color("#89929F")
const FOCUS_EDGE := ELECTRIC_CYAN
const ACTION_PRIMARY := SELECTION_BLUE
const ACTION_CONFIRM := EMERALD
const ACTION_DANGER := SIGNAL_RED
const STATE_REWARD := SIGNAL_YELLOW
const ACTION_SPECIAL := INTERFACE_VIOLET
const HEALTH_FILL := Color("#177A4B")
const OVERLAY_DIM := Color("#090C10B8")

## Living Table ownership colors. Plated slots use the full player/rival signal;
## Prep keeps the same hue with lower saturation so zone function remains clear
## without introducing extra pastel categories.
const ZONE_PLAYER_PLATED := SELECTION_BLUE
const ZONE_PLAYER_PREP := Color("#3F8FB6")
const ZONE_OPPONENT_PLATED := SIGNAL_RED
const ZONE_OPPONENT_PREP := Color("#D85B70")

## Starter City environment colors. These keep the illustrated town warmer
## than the UI while sharing its cool neutral hierarchy and restrained accents.
const CITY_ROAD_ASPHALT := Color("#74717F")
const CITY_ROAD_SHADOW := Color("#555360")
const CITY_PAVING := Color("#E7DED1")
const CITY_GRASS := Color("#82CF98")
const CITY_PAVER_SURFACE := Color("#D6DADF")
const CITY_PAVER_JOINT := Color("#A7ACB3")
const CITY_PATH_SURFACE := Color("#CAD8E5")
const CITY_PATH_HIGHLIGHT := Color("#E6EEF4")
const CITY_PATH_EDGE := Color("#8797A6")
const CITY_PATH_FLECK := Color("#AEBCC8")
const CITY_PATH_MOTIF := Color("#B3C2CF")
const CITY_PATH_BRICK_LINE := Color("#85878A")
const CITY_EVENT := Color("#D7A9D5")
const CITY_HEAL_CENTER := Color("#F0CDBB")
const CITY_SHOP := Color("#ADD7E7")
const CITY_CHAMPIONSHIP := Color("#27677F")
const CITY_POND_OUTLINE := Color("#5E7481")
const CITY_POND_BANK := Color("#8BA38A")
const CITY_POND_DEEP := Color("#397EA8")
const CITY_POND_SURFACE := Color("#58A9D2")
const CITY_POND_GLINT := Color("#D6F1FA")
const CITY_WALL := Color("#EFE5D5")
const CITY_ROOF := Color("#8A8297")
const CITY_TRIM := Color("#596478")
const CITY_GLASS := Color("#8FB3C3")
const CITY_SAGE := Color("#78906F")
const CITY_WARM_ACCENT := Color("#C47D67")

## Tournament-table material colors. These are intentionally warmer and more
## natural than the UI chassis while retaining enough value contrast for cards.
const TOURNAMENT_WOOD_BASE := Color("#62503F")
const TOURNAMENT_WOOD_LIGHT := Color("#806A52")
const TOURNAMENT_WOOD_DARK := Color("#362D27")

## Authored card identities from ART_DIRECTION.md. Affinity accents should use
## these tokens rather than borrowing semantic UI-state colors.
const AFFINITY_SPICY := Color("#EF3D56")
const AFFINITY_HEARTY := Color("#45B96B")
const AFFINITY_SWEET := Color("#4E8FE8")
const AFFINITY_FRESH := Color("#F2D33D")
const AFFINITY_FUNKY := Color("#A85ED5")
const AFFINITY_NEUTRAL := Color("#89929F")

## Ingredient cards use quieter versions of the same affinity hues so their
## class is distinguishable from the more saturated Meal cards in a crowded
## hand. These remain identity colors, not disabled-state colors.
const INGREDIENT_SPICY := Color("#D95D70")
const INGREDIENT_HEARTY := Color("#67AA7A")
const INGREDIENT_SWEET := Color("#6F98D1")
const INGREDIENT_FRESH := Color("#D8C65D")
const INGREDIENT_FUNKY := Color("#A77ABD")
const INGREDIENT_NEUTRAL := Color("#9BA2AC")
const TAG_SPICES := Color("#E36B3E")
const TAG_ENVIRONMENTS := Color("#24AFA7")

## Shared implementation tokens for player-facing UI color. ART_DIRECTION.md owns
## the target color logic: a cool, high-contrast system inspired by the confidence
## and state clarity of Pokémon Black and White's UI, without copying its assets.
## New themes and controls should reference shared constants instead of embedding
## color literals. The warm constants below remain temporarily for compatibility
## during migration; they are not the north star for new UI work.
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

## Existing brighter accents shared by navigation, selection, and primary actions.
## Migrate these deliberately toward ART_DIRECTION.md's dark-neutral chassis and
## saturated state colors as each UI surface is updated.
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
