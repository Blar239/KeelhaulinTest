extends Node2D

# ─── Keelhaulin Game Manager ───
# Replicates the Keelhaulin minigame from The Sims 2 DS
#
# Rules:
#  - 2 players, each dealt 7 cards from a shared deck
#  - Players take turns: draw or take from discard, then play or discard
#  - Playing 3+ cards of same type = chest (10 pts each chest)
#  - Ghost cards: unlocked after that type played once this round
#    Playing a ghost = 20 pts personal (not chest)
#  - Special Cannon: steals 5-30 pts from opponent
#  - Round ends when a player empties their hand after discarding
#  - Game ends after agreed rounds (default 3)

const PLAYER_HAND_SCENE = preload("res://Scenes/player_hand.tscn")
const CARD_SCENE = preload("res://Scenes/card.tscn")

const CHEST_POINTS = 10
const GHOST_POINTS = 20
const CANNON_MIN = 5
const CANNON_MAX = 30
const TOTAL_ROUNDS = 3

enum GamePhase {
	WAITING,
	DRAW_PHASE,    # Player must draw a card or take from discard
	PLAY_PHASE,    # Player may play cards or must discard
	ROUND_END,
	GAME_OVER
}

enum TurnAction {
	NONE,
	DREW_FROM_DECK,
	DREW_FROM_DISCARD
}

var deck_manager: DeckManager
var current_player: int = 0   # 0 or 1
var current_phase: GamePhase = GamePhase.WAITING
var current_action: TurnAction = TurnAction.NONE
var round_number: int = 1
var has_played_this_turn: bool = false

# Scores
var player_scores: Array = [0, 0]       # Total game scores
var player_chest_scores: Array = [0, 0] # Chest contributions
var player_personal_scores: Array = [0, 0] # Ghost/special contributions

# Round tracking
var cards_played_this_turn: int = 0
var discard_top_node = null  # Visual node for top of discard

@onready var player_hands: Array  # Set in _ready after scene setup
@onready var ui = $UI
@onready var ui_controls = $UIControls
@onready var draw_pile_button = $UIControls/DrawPile
@onready var discard_pile_display = $UIControls/DiscardPile
@onready var play_button = $UIControls/PlayButton
@onready var discard_button = $UIControls/DiscardButton
@onready var status_label = $UIControls/StatusLabel
@onready var score_label = $UIControls/ScoreLabel
@onready var round_label = $UIControls/RoundLabel
@onready var phase_label = $UIControls/PhaseLabel
@onready var player1_hand_node = $CardsLayer/Player1Hand
@onready var player2_hand_node = $CardsLayer/Player2Hand
@onready var discard_card_display = $UIControls/DiscardCardDisplay

func _ready():
	deck_manager = DeckManager.new()
	add_child(deck_manager)
	
	player_hands = [player1_hand_node, player2_hand_node]
	
	# Setup hand positions
	player1_hand_node.setup(0, 0, 0)
	player2_hand_node.setup(1, 0, 0)
	
	# Connect signals
	player1_hand_node.connect("play_requested", _on_play_requested)
	player2_hand_node.connect("play_requested", _on_play_requested)
	
	play_button.connect("pressed", _on_play_button_pressed)
	discard_button.connect("pressed", _on_discard_button_pressed)
	draw_pile_button.connect("pressed", _on_draw_pile_pressed)
	discard_pile_display.connect("pressed", _on_discard_pile_pressed)
	
	start_game()

func start_game():
	player_scores = [0, 0]
	player_chest_scores = [0, 0]
	player_personal_scores = [0, 0]
	round_number = 1
	current_player = 0
	start_round()

func start_round():
	deck_manager.setup_new_game()
	
	# Reset hands
	for hand in player_hands:
		hand.reset_round()
		for node in hand.card_nodes.duplicate():
			node.queue_free()
		hand.hand_cards.clear()
		hand.card_nodes.clear()
	
	# Deal 7 cards each
	var hand1 = deck_manager.deal_hand()
	var hand2 = deck_manager.deal_hand()
	player_hands[0].deal_cards(hand1)
	player_hands[1].deal_cards(hand2)
	
	has_played_this_turn = false
	cards_played_this_turn = 0
	_set_phase(GamePhase.DRAW_PHASE)
	_update_active_player()
	_update_ui()
	_update_discard_display()

func _set_phase(phase: GamePhase):
	current_phase = phase
	_update_ui()

func _update_active_player():
	for i in range(2):
		player_hands[i].set_active(i == current_player)

func _on_draw_pile_pressed():
	if current_phase != GamePhase.DRAW_PHASE:
		return
	var card = deck_manager.draw_card()
	if card:
		player_hands[current_player].add_card(card)
		current_action = TurnAction.DREW_FROM_DECK
		_set_phase(GamePhase.PLAY_PHASE)
		_update_discard_display()

func _on_discard_pile_pressed():
	if current_phase != GamePhase.DRAW_PHASE:
		return
	var card = deck_manager.take_from_discard()
	if card:
		player_hands[current_player].add_card(card)
		current_action = TurnAction.DREW_FROM_DISCARD
		_set_phase(GamePhase.PLAY_PHASE)
		_update_discard_display()

func _on_play_button_pressed():
	if current_phase != GamePhase.PLAY_PHASE:
		return
	var hand = player_hands[current_player]
	if not hand.can_play_selected():
		_show_status("Select valid cards to play!")
		return
	
	var played_nodes = hand.play_selected_cards()
	if played_nodes.size() == 0:
		return
	
	_resolve_played_cards(played_nodes, current_player)
	has_played_this_turn = true
	
	# Check win condition
	if hand.is_empty():
		_end_round(current_player)
		return
	
	_update_ui()

func _on_discard_button_pressed():
	if current_phase != GamePhase.PLAY_PHASE:
		return
	
	# Must discard one card (player picks which - we use selected, or last if none)
	var hand = player_hands[current_player]
	var discard_data: CardData = null
	
	if hand.selected_cards.size() == 1:
		var card_node = hand.selected_cards[0]
		discard_data = card_node.card_data
		hand._remove_card(card_node)
		hand.selected_cards.clear()
		hand._layout_hand()
	else:
		_show_status("Select exactly 1 card to discard.")
		return
	
	deck_manager.discard_card(discard_data)
	_update_discard_display()
	
	# Check if hand empty after discard
	if hand.is_empty():
		_end_round(current_player)
		return
	
	_next_turn()

func _resolve_played_cards(card_nodes: Array, pid: int):
	if card_nodes.size() == 0:
		return
	
	var first_card: CardData = card_nodes[0].card_data
	
	# Special: Cannon Shot
	if first_card.card_type == CardData.CardType.SPECIAL_CANNON:
		var stolen = randi_range(CANNON_MIN, CANNON_MAX)
		var opponent = 1 - pid
		stolen = min(stolen, player_scores[opponent])
		player_scores[opponent] -= stolen
		player_scores[pid] += stolen
		_show_status("CANNON! Stole %d points from Player %d!" % [stolen, opponent + 1])
		return
	
	# Special: Ghost Wild (unlocks ghost for ALL types this round? or just counts)
	if first_card.card_type == CardData.CardType.SPECIAL_GHOST:
		# Unlock all ghost types for the player this round
		for t in CardData.NORMAL_TYPES:
			if t not in player_hands[pid].types_played_this_round:
				player_hands[pid].types_played_this_round.append(t)
		_show_status("Ghost Wild! All ghost cards unlocked!")
		return
	
	# Ghost card played (single ghost = 20 personal pts)
	if first_card.is_ghost:
		player_personal_scores[pid] += GHOST_POINTS
		player_scores[pid] += GHOST_POINTS
		_show_status("Ghost card! +%d personal points!" % GHOST_POINTS)
		return
	
	# Normal cards
	var count = card_nodes.size()
	
	# Track type for ghost unlocking
	var played_type = first_card.card_type
	if played_type not in player_hands[pid].types_played_this_round:
		player_hands[pid].types_played_this_round.append(played_type)
	
	# 3 or more of same type = chest(s)
	if count >= 3:
		# Each group of 3+ cards = one chest = 10 pts
		# The Sims 2 DS: playing exactly 3 = 1 chest, more = proportional
		var chests = count / 3
		var chest_pts = chests * CHEST_POINTS
		player_chest_scores[pid] += chest_pts
		player_scores[pid] += chest_pts
		_show_status("CHEST! %d cards played = +%d points!" % [count, chest_pts])
	else:
		_show_status("Played %d %s card(s)." % [count, first_card.get_type_name()])

func _end_round(winner_pid: int):
	_set_phase(GamePhase.ROUND_END)
	_show_status("Round %d over! Player %d wins the round!" % [round_number, winner_pid + 1])
	_update_ui()
	
	if round_number >= TOTAL_ROUNDS:
		_end_game()
	else:
		round_number += 1
		# Brief delay then start next round
		await get_tree().create_timer(3.0).timeout
		start_round()

func _end_game():
	_set_phase(GamePhase.GAME_OVER)
	var winner = 0 if player_scores[0] > player_scores[1] else 1
	if player_scores[0] == player_scores[1]:
		_show_status("GAME OVER! It's a tie! Both players: %d pts" % player_scores[0])
	else:
		_show_status("GAME OVER! Player %d wins! Score: %d vs %d" % [winner + 1, player_scores[winner], player_scores[1 - winner]])

func _next_turn():
	has_played_this_turn = false
	cards_played_this_turn = 0
	current_player = 1 - current_player
	current_action = TurnAction.NONE
	player_hands[current_player].reset_round()  # Reset round tracking per-turn types? 
	# Note: types_played_this_round persists through the round, not reset on turn change
	_set_phase(GamePhase.DRAW_PHASE)
	_update_active_player()
	_update_ui()

func _update_discard_display():
	var top = deck_manager.peek_discard()
	if top:
		var tex = load(top.get_texture_path())
		if discard_card_display and tex:
			discard_card_display.texture = tex
	else:
		if discard_card_display:
			discard_card_display.texture = null

func _show_status(msg: String):
	if status_label:
		status_label.text = msg

func _update_ui():
	if score_label:
		score_label.text = "P1: %d pts | P2: %d pts" % [player_scores[0], player_scores[1]]
	if round_label:
		round_label.text = "Round %d / %d" % [round_number, TOTAL_ROUNDS]
	if phase_label:
		match current_phase:
			GamePhase.DRAW_PHASE:
				phase_label.text = "Player %d — Draw a card" % (current_player + 1)
			GamePhase.PLAY_PHASE:
				phase_label.text = "Player %d — Play or Discard" % (current_player + 1)
			GamePhase.ROUND_END:
				phase_label.text = "Round Over!"
			GamePhase.GAME_OVER:
				phase_label.text = "Game Over!"
	
	if play_button:
		play_button.disabled = current_phase != GamePhase.PLAY_PHASE
	if discard_button:
		discard_button.disabled = current_phase != GamePhase.PLAY_PHASE
	if draw_pile_button:
		draw_pile_button.disabled = current_phase != GamePhase.DRAW_PHASE
	if discard_pile_display:
		discard_pile_display.disabled = current_phase != GamePhase.DRAW_PHASE or deck_manager.discard_pile_count() == 0

func _on_play_requested(cards, pid):
	pass  # Handled via play button
