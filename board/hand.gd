class_name Hand
extends Node2D


@export var max_cards: int = 6
@export var offset: float = 0.5

@export var card_add_time_seconds: float = 0.1

@export var submit_button: Button

@export var wrong_color: Color
@export var wrong_color_2: Color
@export var wrong_color_3: Color

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
	
	for card_in_hand in _cards:
		card_in_hand.allow()
	
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
	_card.peer_id = 0
	
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
	_card.peer_id = 0
	
	_cards.remove_at(_cards.find(_card))
	
	for card in _cards:
		card.forbid()
	
	EventBus.card_dropped_in_shared_pile.emit(_card)
	
	_card = null


func _find_game_and_cards(card: Card, array: Array[GameAndCards]) -> GameAndCards:
	for game_and_card: GameAndCards in array:
		if game_and_card.game_number == card.card_data.game:
			return game_and_card
	
	return null


func _add_wrong_cards(game_and_cards_list: Array[GameAndCards], start_index: int, wrong_cards: Array) -> void:
	for i in range(start_index, game_and_cards_list.size()):
		wrong_cards.append_array(game_and_cards_list[i].cards)


func _assign_cards(game_and_cards_list: Array[GameAndCards], results: HandEvaluationResults) -> void:
	assert(game_and_cards_list.size() >= 1)
	
	var number_of_cards: int = game_and_cards_list.front().cards.size()
	var number_of_ties: int = 0
	
	for i in range(1, game_and_cards_list.size()):
		if number_of_cards > game_and_cards_list[i].cards.size():
			break
		else:
			number_of_ties += 1
	
	results.correct_cards = game_and_cards_list.front().cards
	
	if number_of_ties == 0:
		results.correct_cards = game_and_cards_list.front().cards
		
		_add_wrong_cards(game_and_cards_list, 1, results.wrong_cards)
	elif number_of_ties == 1:
		assert(game_and_cards_list.size() >= 2)
		
		results.correct_cards = game_and_cards_list.front().cards
		results.wrong_cards = game_and_cards_list[1].cards
		
		_add_wrong_cards(game_and_cards_list, 2, results.wrong_cards_2)
	elif number_of_ties == 2:
		assert(game_and_cards_list.size() >= 3)
		
		results.correct_cards = game_and_cards_list.front().cards
		results.wrong_cards = game_and_cards_list[1].cards
		results.wrong_cards_2 = game_and_cards_list[2].cards
		
		_add_wrong_cards(game_and_cards_list, 3, results.wrong_cards_3)
	else:
		_add_wrong_cards(game_and_cards_list, 0, results.wrong_cards)


func is_valid() -> HandEvaluationResults:
	var results := HandEvaluationResults.new()
	
	var game_and_cards_list: Array[GameAndCards] = []
	
	for card in _cards:
		var game_and_cards: GameAndCards = _find_game_and_cards(card, game_and_cards_list)
		
		if game_and_cards != null:
			game_and_cards.cards.push_back(card)
		else:
			game_and_cards = GameAndCards.new()
			
			game_and_cards.game_number = card.card_data.game
			game_and_cards.cards = [card]
			
			game_and_cards_list.push_back(game_and_cards)
	
	game_and_cards_list.sort_custom(GameAndCards.sort_ascending)
	
	_assign_cards(game_and_cards_list, results)
	
	results.is_valid = game_and_cards_list.size() == 1
	results.game_number = game_and_cards_list.front().cards.front().card_data.game
	
	return results


func show_wrong_cards(results: HandEvaluationResults) -> void:
	_show_card_colors(results.correct_cards, Color.BLACK)
	_show_card_colors(results.wrong_cards, wrong_color)
	_show_card_colors(results.wrong_cards_2, wrong_color_2)
	_show_card_colors(results.wrong_cards_3, wrong_color_3)
	
	await get_tree().create_timer(2).timeout


func _show_card_colors(cards: Array, color: Color) -> void:
	for card in cards:
		card.show_number(color)


func _on_hand_area_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		_drop_card()


func _on_hand_area_mouse_entered() -> void:
	_is_in_hand_area = true


func _on_hand_area_mouse_exited() -> void:
	_is_in_hand_area = true
