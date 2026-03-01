extends Node2D

@export var shared_pile_add_time_seconds: float = 0.2

signal cards_added
signal card_requested(card: Card)

@onready var hand: Node2D = $"../Hand"

var _is_waiting_for_server: bool = false


func _ready() -> void:
	EventBus.card_picked_up_from_hand.connect(_on_card_picked_up_from_hand)
	EventBus.card_returned_to_hand.connect(_on_card_returned_to_hand)


func add_cards(cards: Array) -> void:
	assert(cards.size() == 6)
	
	for i in cards.size():
		var card: Card = cards[i]
		
		add_card(card)
		card.forbid()
		
		var tween = get_tree().create_tween()
		tween.tween_property(card, "position", Vector2(i * 180, 0), shared_pile_add_time_seconds)
		
		await tween.finished
		
		card.flip_up()
		
		await card.flipped_up
	
	cards_added.emit()


func add_card(card: Card) -> void:
	card.reparent($Cards)
	
	card.enable()
	
	if not hand.is_missing_one_card() and hand.get_active_card() == null:
		card.forbid()
	
	_connect_signals(card)
	
	card.play_peer_place_audio()


func get_cards() -> Array:
	return $Cards.get_children()


func remove_card(card: Card, next_parent: Node, is_silent: bool = false) -> void:
	_disconnect_signals(card)
	
	card.disappear(next_parent, is_silent)
	
	if not is_silent:
		card.play_peer_grab_audio()


func handle_card(card: Card) -> void:
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
	
	_is_waiting_for_server = false


func restore_state() -> void:
	_is_waiting_for_server = false


func _on_card_clicked(card: Card) -> void:
	if _is_waiting_for_server:
		print("Waiting for server")
		
		#return
	
	if not hand.is_missing_one_card() and hand.get_active_card() == null:
		return
	
	if GameData.is_multiplayer():
		_is_waiting_for_server = true
		
		card_requested.emit(card)
	else:
		handle_card(card)


func _on_shared_pile_area_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		var card: Card = hand.get_active_card()
		
		hand.drop_card_in_shared_pile($Cards)
		
		if card != null:
			_connect_signals(card)


func _connect_signals(card: Card) -> void:
	card.card_clicked.connect(_on_card_clicked.bind(card))


func _disconnect_signals(card: Card) -> void:
	card.card_clicked.disconnect(_on_card_clicked)


func _on_card_picked_up_from_hand() -> void:
	for card in $Cards.get_children():
		card.allow()


func _on_card_returned_to_hand() -> void:
	for card in $Cards.get_children():
		card.forbid()
