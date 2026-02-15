extends Node2D

@export var shared_pile_add_time_seconds: float = 0.2

signal cards_added

@onready var hand: Node2D = $"../Hand"

var _card: Card = null


func add_cards(cards: Array) -> void:
	for i in cards.size():
		var card: Card = cards[i]
		
		card.reparent(self)
		
		_connect_signals(card)
		
		var tween = get_tree().create_tween()
		tween.tween_property(card, "position", Vector2(i * 120, 0), shared_pile_add_time_seconds)
		
		await tween.finished
		
		card.flip_up()
		
		await card.flipped_up
	
	cards_added.emit()


func _on_card_clicked(card: Card) -> void:
	if hand.is_missing_one_card():
		print("Missing one card")
		_disconnect_signals(card)
		
		hand.transfer_from_shared_pile(card)
	elif hand.get_active_card() != null:
		print("Swapping cards")
		_connect_signals(hand.get_active_card())
		
		_disconnect_signals(card)
		
		hand.swap_with_shared_pile_card(card)
	else:
		pass
		# TODO: Allow moving card but not swapping


func _on_shared_pile_area_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if false:
			_card.stop_following_cursor()
			_card.reparent(self)
			
			_card = null
		else:
			var card: Card = hand.get_active_card()
			
			hand.drop_card_in_shared_pile(self)
			
			if card != null:
				_connect_signals(card)


func _connect_signals(card: Card) -> void:
	card.card_clicked.connect(_on_card_clicked.bind(card))


func _disconnect_signals(card: Card) -> void:
	card.card_clicked.disconnect(_on_card_clicked)
