extends Node
class_name DeckManager

# Standard Keelhaulin deck composition
# 8 normal types x 4 copies each = 32 normal cards
# 2 special cannon cards
# 2 special ghost/wild cards
# Total: 36 cards per deck

const CARDS_PER_TYPE = 4
const SPECIAL_COUNT = 2
const HAND_SIZE = 7

var draw_pile: Array = []
var discard_pile: Array = []

func build_deck() -> Array:
	var deck = []
	
	# Add normal cards
	for card_type in CardData.NORMAL_TYPES:
		for i in range(CARDS_PER_TYPE):
			var data = CardData.new()
			data.card_type = card_type
			data.is_ghost = false
			deck.append(data)
	
	# Add special cannon cards
	for i in range(SPECIAL_COUNT):
		var data = CardData.new()
		data.card_type = CardData.CardType.SPECIAL_CANNON
		deck.append(data)
	
	# Add special ghost/wild cards
	for i in range(SPECIAL_COUNT):
		var data = CardData.new()
		data.card_type = CardData.CardType.SPECIAL_GHOST
		deck.append(data)
	
	return deck

func shuffle(deck: Array) -> Array:
	var d = deck.duplicate()
	d.shuffle()
	return d

func setup_new_game():
	var full_deck = build_deck()
	draw_pile = shuffle(full_deck)
	discard_pile = []

func deal_hand() -> Array:
	var hand = []
	for i in range(HAND_SIZE):
		if draw_pile.size() > 0:
			hand.append(draw_pile.pop_front())
	return hand

func draw_card() -> CardData:
	if draw_pile.size() == 0:
		_reshuffle_discard()
	if draw_pile.size() > 0:
		return draw_pile.pop_front()
	return null

func discard_card(card_data: CardData):
	discard_pile.append(card_data)

func take_from_discard() -> CardData:
	if discard_pile.size() > 0:
		return discard_pile.pop_back()
	return null

func peek_discard() -> CardData:
	if discard_pile.size() > 0:
		return discard_pile.back()
	return null

func _reshuffle_discard():
	if discard_pile.size() == 0:
		return
	var top = discard_pile.pop_back()
	draw_pile = shuffle(discard_pile)
	discard_pile = [top]

func draw_pile_count() -> int:
	return draw_pile.size()

func discard_pile_count() -> int:
	return discard_pile.size()
