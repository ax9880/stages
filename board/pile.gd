class_name Pile
extends Node2D

@export var card_add_time_seconds: float = 0.2
@export var spacing: float = -5

@export var disabled_color: Color
@export var hover_color: Color

signal cards_added
signal pile_clicked

var _cards := []


func _ready() -> void:
	modulate = disabled_color


func add_cards(cards: Array, can_flip_cards: bool = false) -> void:
	_cards = cards
	
	for i in cards.size():
		var card: Card = cards[i]
		card.reparent(self)
		
		# Add to z index so cards appear on top of other piles
		card.z_index += 1
		
		card.reset_position(card_add_time_seconds, Vector2(- i * spacing/2.0, i * spacing))
		
		if can_flip_cards:
			card.flip_down()
		
		$PlaceAudio.play()
		
		$Timer.start()
		
		await $Timer.timeout
	
	cards_added.emit()


func take_cards() -> Array:
	var cards := _cards.duplicate()
	
	_cards.clear()
	
	return cards


func submit() -> void:
	$MarginContainer.visible = false


func disable_area() -> void:
	$MarginContainer.mouse_default_cursor_shape = Input.CursorShape.CURSOR_FORBIDDEN


func _on_margin_container_mouse_entered() -> void:
	modulate = hover_color


func _on_margin_container_mouse_exited() -> void:
	modulate = disabled_color


func _on_margin_container_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		pile_clicked.emit()
