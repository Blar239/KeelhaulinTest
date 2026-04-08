extends Resource
class_name CardData

enum CardType {
	ANCHOR,    # card1
	WHEEL,     # card2
	COMPASS,   # card3
	ROPE,      # card4
	LANTERN,   # card5
	BARREL,    # card6
	CANNON,    # card7
	TREASURE,  # card8
	SPECIAL_CANNON,  # card9 - special
	SPECIAL_GHOST    # card10 - special (wild/ghost enabler)
}

const CARD_TEXTURES = {
	CardType.ANCHOR:        "res://Assets/NormalCards/card1.png",
	CardType.WHEEL:         "res://Assets/NormalCards/card2.png",
	CardType.COMPASS:       "res://Assets/NormalCards/card3.png",
	CardType.ROPE:          "res://Assets/NormalCards/card4.png",
	CardType.LANTERN:       "res://Assets/NormalCards/card5.png",
	CardType.BARREL:        "res://Assets/NormalCards/card6.png",
	CardType.CANNON:        "res://Assets/NormalCards/card7.png",
	CardType.TREASURE:      "res://Assets/NormalCards/card8.png",
	CardType.SPECIAL_CANNON:"res://Assets/SpecialCards/card9.png",
	CardType.SPECIAL_GHOST: "res://Assets/SpecialCards/card10.png",
}

const GHOST_TEXTURES = {
	CardType.ANCHOR:   "res://Assets/GhostCards/card1_2.png",
	CardType.WHEEL:    "res://Assets/GhostCards/card2_2.png",
	CardType.COMPASS:  "res://Assets/GhostCards/card3_2.png",
	CardType.ROPE:     "res://Assets/GhostCards/card4_2.png",
	CardType.LANTERN:  "res://Assets/GhostCards/card5_2.png",
	CardType.BARREL:   "res://Assets/GhostCards/card6_2.png",
	CardType.CANNON:   "res://Assets/GhostCards/card7_2.png",
	CardType.TREASURE: "res://Assets/GhostCards/card8_2.png",
}

const TYPE_NAMES = {
	CardType.ANCHOR:        "Anchor",
	CardType.WHEEL:         "Wheel",
	CardType.COMPASS:       "Compass",
	CardType.ROPE:          "Rope",
	CardType.LANTERN:       "Lantern",
	CardType.BARREL:        "Barrel",
	CardType.CANNON:        "Cannon",
	CardType.TREASURE:      "Treasure",
	CardType.SPECIAL_CANNON:"Rum",
	CardType.SPECIAL_GHOST: "Cannon Shot",
}

# Normal card types for deck building (excludes specials)
const NORMAL_TYPES = [
	CardType.ANCHOR,
	CardType.WHEEL,
	CardType.COMPASS,
	CardType.ROPE,
	CardType.LANTERN,
	CardType.BARREL,
	CardType.CANNON,
	CardType.TREASURE,
]

var card_type: CardType = CardType.ANCHOR
var is_ghost: bool = false

func get_texture_path() -> String:
	if is_ghost and card_type in GHOST_TEXTURES:
		return GHOST_TEXTURES[card_type]
	return CARD_TEXTURES.get(card_type, CARD_TEXTURES[CardType.ANCHOR])

func is_special() -> bool:
	return card_type == CardType.SPECIAL_CANNON or card_type == CardType.SPECIAL_GHOST

func get_type_name() -> String:
	return TYPE_NAMES.get(card_type, "Unknown")
