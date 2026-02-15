class_name Hand
extends Node2D


@export var max_cards: int = 6
@export var offset: float = 0.5

@export var card_add_time_seconds: float = 0.1

@export var submit_button: Button

signal card_clicked(card: Card)

var _cards := []
var pile: Pile = null

var _card: Card = null

var _is_in_hand_area: bool = false


func _ready() -> void:
	var start: float = 0.5 - offset
	var end: float = 0.5 + offset
	
	for i in max_cards:
		var path_follow2d: PathFollow2D = PathFollow2D.new()
		$Path2D.add_child(path_follow2d)
		
		path_follow2d.progress_ratio = (i + 1) * (start + end) / (max_cards + 1)


func _physics_process(_delta: float) -> void:
	_track_card()


func _track_card() -> void:
	if _card == null:
		return
	
	if not _is_in_hand_area:
		return
	
	var index: int = $Path2D.get_children().find(_card.get_parent())
	
	if index > 0:
		var left_neighbor: PathFollow2D = $Path2D.get_child(index - 1)
		
		if _card.global_position.x < left_neighbor.global_position.x:
			var left_card: Card = left_neighbor.get_child(0)
			
			left_card.reparent(_card.get_parent())
			left_card.play_move_audio()
			
			_reset_card_position(left_card)
			
			_card.reparent(left_neighbor)
		
	if index < $Path2D.get_child_count() - 1:
		var right_neighbor: PathFollow2D = $Path2D.get_child(index + 1)
		
		if _card.global_position.x > right_neighbor.global_position.x:
			var right_card: Card = right_neighbor.get_child(0)
			
			right_card.reparent(_card.get_parent())
			right_card.play_move_audio()
			
			_reset_card_position(right_card)
			
			_card.reparent(right_neighbor)


func get_active_card() -> Card:
	return _card


func has_cards() -> bool:
	return not _cards.is_empty()


func is_missing_one_card() -> bool:
	return _cards.size() == (max_cards - 1)


func take_cards() -> Array:
	_rebuild_cards_list()
	
	var cards := _cards.duplicate()
	
	for card: Card in _cards:
		card.card_clicked.disconnect(_on_card_clicked)
	
	_cards.clear()
	_card = null
	
	pile = null
	
	return cards


func transfer_from_pile(_pile: Pile) -> void:
	pile = _pile
	_cards = pile.take_cards()
	
	pile.disable_area()
	
	for i in _cards.size():
		var card: Card = _cards[_cards.size() - i - 1]
		
		var path_follow2d: PathFollow2D = $Path2D.get_child(i)
		
		card.reparent(path_follow2d)
		card.card_clicked.connect(_on_card_clicked.bind(card))
		
		_reset_card_position(card)
		
		card.flip_up()
		card.play_move_to_hand_audio()
		
		$AddCardTimer.start()
		
		await $AddCardTimer.timeout
		
		card.enable()


func transfer_from_shared_pile(card: Card) -> void:
	for path_follow2d in $Path2D.get_children():
		if path_follow2d.get_child_count() == 0:
			card.reparent(path_follow2d)
			
			break
	
	_rebuild_cards_list()
	
	card.card_clicked.connect(_on_card_clicked.bind(card))
	
	_pick_up_card(card)
	
	EventBus.card_picked_up_from_shared_pile.emit(card)


func swap_with_shared_pile_card(card: Card) -> void:
	assert(_card != null)
	
	# Drop card
	_card.card_clicked.disconnect(_on_card_clicked)
	
	var old_parent = card.get_parent()
	
	card.reparent(_card.get_parent())
	
	_card.reparent(old_parent)
	_card.stop_following_cursor()
	_card.global_position = card.global_position
	
	EventBus.card_dropped_in_shared_pile.emit(_card)
	
	_rebuild_cards_list()
	
	# Pick up card
	card.card_clicked.connect(_on_card_clicked.bind(card))
	
	_pick_up_card(card)
	
	EventBus.card_picked_up_from_shared_pile.emit(card)


func _rebuild_cards_list() -> void:
	_cards.clear()
	
	var nodes = $Path2D.get_children().duplicate()
	nodes.reverse()
	
	for path_follow2d in nodes:
		_cards.push_back(path_follow2d.get_child(0)) 
	
	assert(_cards.size() == max_cards)


func _return_card(card: Card) -> void:
	card.stop_following_cursor()
	
	_reset_card_position(card)


func _swap_cards(new_card: Card) -> void:
	var index: int = _cards.find(new_card)
	
	assert(index != -1)
	
	var old_parent = _card.get_parent()
	
	_card.reparent(new_card.get_parent())
	new_card.reparent(old_parent)
	
	_return_card(_card)


func _reset_card_position(card: Card) -> void:
	card.reset_position(card_add_time_seconds)


func _drop_card() -> void:
	if _card != null:
		_return_card(_card)
		
		_card = null
		
		EventBus.card_returned_to_hand.emit()
		submit_button.disabled = false


func _pick_up_card(card: Card) -> void:
	card.play_pick_up_audio()
	
	_card = card
	_card.follow_cursor()


func _on_card_clicked(card: Card) -> void:
	if _cards.size() < max_cards:
		return
	
	if _card != null:
		_swap_cards(card)
	
	_pick_up_card(card)
	
	card_clicked.emit(card)
	
	EventBus.card_picked_up_from_hand.emit()
	submit_button.disabled = true


func drop_card_in_shared_pile(shared_pile: Node2D) -> void:
	if _card == null:
		return
	
	_card.play_place_audio()
	
	_card.stop_following_cursor()
	_card.reparent(shared_pile)
	_card.card_clicked.disconnect(_on_card_clicked)
	
	_cards.remove_at(_cards.find(_card))
	
	EventBus.card_dropped_in_shared_pile.emit(_card)
	
	_card = null


func is_valid() -> HandEvaluationResults:
	var results := HandEvaluationResults.new()
	
	var stages: Dictionary = {}
	
	results.is_valid = true
	
	for card: Card in _cards:
		var card_data: CardData = card._card_data
		
		if stages.has(card_data.stage):
			stages[card_data.stage].push_back(card)
			
			print("Invalid hand! Stage %d is repeated" % card_data.stage)
			
			results.is_valid = false
		else:
			stages.set(card_data.stage, [card])
	
	for cards_per_stage in stages.values():
		if cards_per_stage.size() > 1:
			for card in cards_per_stage:
				results.wrong_cards.push_back(card)
	
	if results.is_valid:
		results.is_perfect_hand = true
		
		var game: int = _cards.front()._card_data.game
		
		for card: Card in _cards:
			if game != card._card_data.game:
				results.is_perfect_hand = false
				
				break
	
	return results


func show_cards_stages() -> void:
	for path_follow2d in $Path2D.get_children():
		var card = path_follow2d.get_child(0)
		
		await card.reveal_number()
	
	await get_tree().create_timer(0.5).timeout


func show_wrong_cards(results: HandEvaluationResults) -> void:
	for card in results.wrong_cards:
		card.show_wrong_number()
	
	await get_tree().create_timer(0.5).timeout


func _on_hand_area_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		_drop_card()


func _on_hand_area_mouse_entered() -> void:
	_is_in_hand_area = true


func _on_hand_area_mouse_exited() -> void:
	_is_in_hand_area = true
