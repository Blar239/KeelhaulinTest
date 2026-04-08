extends Node2D

signal hovered(card)
signal hovered_off(card)
signal card_clicked(card)

var card_data: CardData = null
var is_selected: bool = false
var is_ghost: bool = false
var original_y: float = 0.0
var hand_index: int = -1

var card_width: float = 90.0
var card_height: float = 114.0

func _ready():
	z_index = 100
	_update_texture()

func setup(data: CardData):
	card_data = data
	is_ghost = data.is_ghost
	_update_texture()

func _update_texture():
	if card_data == null:
		return
	var sprite = get_node_or_null("CardSprite")
	if sprite:
		var tex = load(card_data.get_texture_path())
		if tex:
			sprite.texture = tex

func set_selected(selected: bool):
	is_selected = selected
	if selected:
		position.y = original_y - 20
		var sprite = get_node_or_null("CardSprite")
		if sprite:
			sprite.modulate = Color(1.2, 1.2, 0.8, 1.0)
	else:
		position.y = original_y
		var sprite = get_node_or_null("CardSprite")
		if sprite:
			sprite.modulate = Color(1, 1, 1, 1)

func set_highlighted(highlight: bool):
	if is_selected:
		return
	if highlight:
		scale = Vector2(1.05, 1.05)
	else:
		scale = Vector2(1.0, 1.0)

func _input(event):
	if event is InputEventMouseMotion:
		var mouse_pos = event.position
		var card_rect = Rect2(global_position - Vector2(card_width/2, card_height/2), Vector2(card_width, card_height))
		if card_rect.has_point(mouse_pos):
			emit_signal("hovered", self)
		else:
			emit_signal("hovered_off", self)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var mouse_pos = event.position
			var card_rect = Rect2(global_position - Vector2(card_width/2, card_height/2), Vector2(card_width, card_height))
			if card_rect.has_point(mouse_pos):
				emit_signal("card_clicked", self)
