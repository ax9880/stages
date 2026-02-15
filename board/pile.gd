class_name Pile
extends Node2D

@export var card_add_time_seconds: float = 0.2
@export var spacing: float = -5

@export var disabled_color: Color
@export var hover_color: Color

signal cards_added
signal pile_clicked

var _cards := []

var can_select_pile: bool = true


func _ready() -> void:
	modulate = disabled_color
	
	EventBus.card_picked_up_from_hand.connect(_on_card_picked_up_from_hand)
	EventBus.card_returned_to_hand.connect(_on_card_returned_to_hand)
	
	disable_area()


func add_cards(cards: Array, can_flip_cards: bool = false) -> void:
	_cards = cards
	
	for card in _cards:
		card.disable()
	
	for i in cards.size():
		var card: Card = cards[i]
		card.reparent(self)
		
		# Add to z index so cards appear on top of other piles
		# Reset in reset_position()
		card.z_index += 1
		
		card.reset_position(card_add_time_seconds, Vector2(- i * spacing/2.0, i * spacing))
		
		if can_flip_cards:
			card.flip_down()
		
		card.play_place_audio()
		
		$Timer.start()
		
		await $Timer.timeout
	
	cards_added.emit()


func take_cards() -> Array:
	var cards := _cards.duplicate()
	
	_cards.clear()
	
	return cards


func submit() -> void:
	$MarginContainer.visible = false
	
	_on_margin_container_mouse_entered()


func enable_area() -> void:
	$MarginContainer.mouse_default_cursor_shape = Input.CursorShape.CURSOR_POINTING_HAND
	
	can_select_pile = true


func disable_area() -> void:
	$MarginContainer.mouse_default_cursor_shape = Input.CursorShape.CURSOR_FORBIDDEN
	
	can_select_pile = false


func _on_margin_container_mouse_entered() -> void:
	modulate = hover_color


func _on_margin_container_mouse_exited() -> void:
	modulate = disabled_color


func _on_margin_container_gui_input(event: InputEvent) -> void:
	if not can_select_pile:
		return
	
	if event is InputEventMouseButton and event.is_pressed():
		pile_clicked.emit()


func _on_card_picked_up_from_hand() -> void:
	disable_area()


func _on_card_returned_to_hand() -> void:
	enable_area()
