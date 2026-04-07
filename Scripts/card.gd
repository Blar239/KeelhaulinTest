extends Node2D

signal hovered(card)
signal hovered_off(card)
signal card_clicked(card)

var card_data: CardData = null
var is_selected: bool = false
var is_ghost: bool = false
var original_y: float = 0.0
var hand_index: int = -1

@onready var card_sprite = $CardSprite

func _ready():
	original_y = position.y
	# If setup() was already called before _ready (shouldn't happen, but safe)
	if card_data != null:
		_update_texture()

func setup(data: CardData):
	card_data = data
	is_ghost = data.is_ghost
	# card_sprite may not be ready yet if called before _ready
	# Use call_deferred to ensure node is in tree
	if is_inside_tree():
		_update_texture()
	else:
		# Will be picked up in _ready, but _ready fires after add_child
		# so we set a flag and update after
		pass

func _update_texture():
	if card_data == null:
		return
	var card_sprite_node = get_node_or_null("CardSprite")
	if card_sprite_node == null:
		return
	var tex = load(card_data.get_texture_path())
	if tex:
		card_sprite_node.texture = tex

func set_selected(selected: bool):
	is_selected = selected
	if selected:
		position.y = original_y - 20
		if card_sprite:
			card_sprite.modulate = Color(1.2, 1.2, 0.8, 1.0)
	else:
		position.y = original_y
		if card_sprite:
			card_sprite.modulate = Color(1, 1, 1, 1)

func set_highlighted(highlight: bool):
	if is_selected:
		return
	if highlight:
		scale = Vector2(1.05, 1.05)
		z_index = 2
	else:
		scale = Vector2(1.0, 1.0)
		z_index = 1

func _on_area_2d_mouse_entered():
	emit_signal("hovered", self)

func _on_area_2d_mouse_exited():
	emit_signal("hovered_off", self)

func _on_area_2d_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		emit_signal("card_clicked", self)
