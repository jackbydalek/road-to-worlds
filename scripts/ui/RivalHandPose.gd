extends RefCounted

## Authored source-space masks for the three portraits with painted card fans.
## Only the obscured clothing is repainted natively. The original hands are
## composited over live sleeves by RivalHeldCards; source PNGs remain unchanged.
static func supports_cast(cast_id: String) -> bool:
	return cast_id.to_lower() in ["mina", "pip", "milo", "bea"]


static func for_cast(cast_id: String) -> Dictionary:
	match cast_id.to_lower():
		"pip":
			return {
				"grip": Vector2(710, 850), "card_size": Vector2(140, 210),
				"hand_roi": Rect2i(518, 766, 369, 190),
				"cover": PackedVector2Array([Vector2(571, 686), Vector2(582, 672), Vector2(652, 647), Vector2(667, 641), Vector2(718, 641), Vector2(733, 639), Vector2(846, 671), Vector2(852, 684), Vector2(818, 816), Vector2(760, 844), Vector2(609, 806)]),
				"sample_left": Vector2(559, 722), "sample_right": Vector2(867, 721),
			}
		"milo":
			return {
				"grip": Vector2(778, 853), "card_size": Vector2(140, 210),
				"hand_roi": Rect2i(706, 771, 258, 202),
				"cover": PackedVector2Array([Vector2(636, 694), Vector2(644, 684), Vector2(711, 658), Vector2(722, 648), Vector2(790, 647), Vector2(802, 644), Vector2(909, 681), Vector2(913, 698), Vector2(872, 817), Vector2(821, 851), Vector2(698, 837)]),
				"sample_left": Vector2(626, 714), "sample_right": Vector2(927, 715),
			}
		"bea":
			return {
				"grip": Vector2(710, 868), "card_size": Vector2(134, 196),
				"hand_roi": Rect2i(506, 809, 390, 162),
				"cover": PackedVector2Array([Vector2(640, 826), Vector2(644, 711), Vector2(651, 701), Vector2(765, 703), Vector2(780, 714), Vector2(775, 827), Vector2(742, 868), Vector2(675, 869)]),
				"sample_left": Vector2(626, 761), "sample_right": Vector2(795, 761),
			}
	return {}
