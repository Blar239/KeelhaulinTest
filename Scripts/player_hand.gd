extends Node2D
class_name PlayerHand

signal card_selected(card, player_id)
signal card_deselected(card, player_id)
signal play_requested(cards, player_id)

const CARD_SCENE = preload("res://Scenes/card.tscn")
const CARD_SPACING = 110
const HAND_Y = 0.0

var player_id: int = 0
var hand_cards: Array = []       # Array of CardData
var card_nodes: Array = []       # Array of Card nodes
var selected_cards: Array = []   # Array of selected Card nodes
var is_active: bool = false      # Is it this player's turn?
var types_played_this_round: Array = []  # CardData.CardType values played this round

func _ready():
	pass

func setup(pid: int, start_x: float, start_y: float):
	player_id = pid
	position = Vector2(start_x, start_y)

func deal_cards(card_data_array: Array):
	for data in card_data_array:
		_add_card_node(data)
	_layout_hand()

func add_card(card_data: CardData):
	hand_cards.append(card_data)
	_add_card_node(card_data)
	_layout_hand()

func _add_card_node(card_data: CardData):
	var card_node = CARD_SCENE.instantiate()
	add_child(card_node)
	card_node.setup(card_data)
	card_node.hand_index = hand_cards.size()
	hand_cards.append(card_data)
	card_nodes.append(card_node)
	
	# Connect signals
	card_node.connect("card_clicked", _on_card_clicked)
	card_node.connect("hovered", _on_card_hovered)
	card_node.connect("hovered_off", _on_card_hovered_off)

func _layout_hand():
	var count = card_nodes.size()
	if count == 0:
		return
	var total_width = (count - 1) * CARD_SPACING
	var start_x = -total_width / 2.0
	for i in range(count):
		var card = card_nodes[i]
		card.position = Vector2(start_x + i * CARD_SPACING, 0)
		card.original_y = 0.0
		card.z_index = i
		card.hand_index = i

func _on_card_clicked(card):
	if not is_active:
		return
	
	# Check if card is a ghost and if that type has been played
	if card.card_data.is_ghost:
		var base_type = card.card_data.card_type
		if not base_type in types_played_this_round:
			return  # Ghost not yet unlocked for this type
	
	if card in selected_cards:
		_deselect_card(card)
	else:
		_select_card(card)

func _select_card(card):
	# For normal cards: can select multiple only if same type
	# For special cards: select alone
	if card.card_data.is_special():
		# Deselect all others first
		_clear_selection()
		selected_cards.append(card)
		card.set_selected(true)
		return
	
	# Check if selection is consistent (same type or ghost of same type)
	var sel_type = _get_selection_type()
	var card_base_type = card.card_data.card_type
	
	if sel_type == -1 or sel_type == card_base_type:
		selected_cards.append(card)
		card.set_selected(true)
		emit_signal("card_selected", card, player_id)
	else:
		# Different type - clear and start fresh
		_clear_selection()
		selected_cards.append(card)
		card.set_selected(true)
		emit_signal("card_selected", card, player_id)

func _deselect_card(card):
	selected_cards.erase(card)
	card.set_selected(false)
	emit_signal("card_deselected", card, player_id)

func _clear_selection():
	for card in selected_cards:
		card.set_selected(false)
	selected_cards.clear()

func _get_selection_type() -> int:
	if selected_cards.size() == 0:
		return -1
	return selected_cards[0].card_data.card_type

func can_play_selected() -> bool:
	if selected_cards.size() == 0:
		return false
	
	var card = selected_cards[0]
	
	# Special cards can always be played alone
	if card.card_data.is_special():
		return selected_cards.size() == 1
	
	# Ghost cards: can play alone if type has been played
	if card.card_data.is_ghost:
		return selected_cards.size() == 1
	
	# 3+ of same type: allowed
	if selected_cards.size() >= 3:
		return true
	
	# 1 normal card: always allowed
	if selected_cards.size() == 1:
		return true
	
	# 2 of same type: allowed  
	if selected_cards.size() == 2:
		return true
	
	return false

func play_selected_cards() -> Array:
	if not can_play_selected():
		return []
	
	var played = selected_cards.duplicate()
	
	# Track type played
	if played.size() > 0 and not played[0].card_data.is_ghost:
		var t = played[0].card_data.card_type
		if t not in types_played_this_round and not played[0].card_data.is_special():
			types_played_this_round.append(t)
	
	# Remove from hand
	for card in played:
		_remove_card(card)
	
	selected_cards.clear()
	_layout_hand()
	
	return played

func _remove_card(card_node):
	var idx = card_nodes.find(card_node)
	if idx >= 0:
		card_nodes.remove_at(idx)
		hand_cards.remove_at(idx)
		card_node.queue_free()

func remove_top_card_for_discard() -> CardData:
	# Remove and return last card (for discarding)
	if hand_cards.size() == 0:
		return null
	var idx = hand_cards.size() - 1
	var data = hand_cards[idx]
	var node = card_nodes[idx]
	hand_cards.remove_at(idx)
	card_nodes.remove_at(idx)
	node.queue_free()
	_layout_hand()
	return data

func get_hand_size() -> int:
	return hand_cards.size()

func is_empty() -> bool:
	return hand_cards.size() == 0

func set_active(active: bool):
	is_active = active
	# Visual feedback
	modulate = Color(1, 1, 1, 1) if active else Color(0.6, 0.6, 0.6, 1)

func reset_round():
	types_played_this_round.clear()
	_clear_selection()

func _on_card_hovered(card):
	if is_active:
		card.set_highlighted(true)

func _on_card_hovered_off(card):
	card.set_highlighted(false)

# Required by card.gd - connect_card_signals stub (cards call this on parent)
func connect_card_signals(_card):
	pass  # Signals connected directly in _add_card_node
