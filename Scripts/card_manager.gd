extends Node2D

const COLLISION_MASK_CARD = 1
const COLLISION_MASK_CARD_SLOT = 2

var card_being_dragged
var screen_size
var is_hovering_on_card


# Called when the node enters the scene tree for the first time.
func _ready():
	screen_size = get_viewport_rect().size

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if card_being_dragged:
		var mouse_pos = get_global_mouse_position()
		card_being_dragged.global_position = Vector2(clamp(mouse_pos.x, 0, screen_size.x), clamp(mouse_pos.y, 0, screen_size.y))

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			var card = _check_for_card_raycast()
			if card:
				_start_drag(card)
		else:
			_finish_drag()
		
func _check_for_card_raycast():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		#return result[0].collider.get_parent()
		return _check_for_highest_z_index(result)
	return null
	
func _check_for_card_slot_raycast():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD_SLOT
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		return result[0].collider.get_parent()
	return null

func connect_card_signals(card):
	card.connect("hovered", _on_card_hover)
	card.connect("hovered_off", _off_card_hover)
	
func _on_card_hover(card):
	if !is_hovering_on_card:
		is_hovering_on_card = true
		_highlight_card(card, true)
	
func _off_card_hover(card):
	if !card_being_dragged:
		_highlight_card(card, false)
		var new_card_hovered = _check_for_card_raycast()
		if new_card_hovered and new_card_hovered != card:
			_highlight_card(new_card_hovered, true)
		else:
			is_hovering_on_card = false
	
	
func _highlight_card(card, hovered):
	if hovered:
		card.scale = Vector2(1.05,1.05)
		card.z_index = 2
	else:
		card.scale = Vector2(1,1)
		card.z_index = 1
		
func _check_for_highest_z_index(cards):
	var highest_z_card = cards[0].collider.get_parent()
	var highest_z_index = highest_z_card.z_index
	
	for i in range(1,cards.size()):
		var current_card = cards[i].collider.get_parent()
		if current_card.z_index > highest_z_index:
			highest_z_card = current_card
			highest_z_index = current_card.z_index
	return highest_z_card
	

func _start_drag(card):
	card_being_dragged = card
	card.scale = Vector2(1,1)
	
func _finish_drag():
	if card_being_dragged:
		card_being_dragged.scale = Vector2(1.05,1.05)
		var card_slot_found = _check_for_card_slot_raycast()
		if card_slot_found and not card_slot_found.card_in_slot:
			card_being_dragged.global_position = card_slot_found.global_position
			card_being_dragged.get_node("Area2D/CollisionShape2D").disabled = true
			card_slot_found.card_in_slot = true
		card_being_dragged = null
