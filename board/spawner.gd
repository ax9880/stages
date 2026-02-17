extends Node2D

@export var cards_per_pile: int = 6
@export var piles_count: int = 6

@export var card_packed_scene: PackedScene

@export var pile_wait_time_seconds: float = 0.2
@export var shared_pile_add_time_seconds: float = 0.2

@export var can_randomize: bool = true

@export var submit_button: Button
@export var multiplayer_score_tracker: VBoxContainer
@export var waiting_for_players_container: MarginContainer

@export var peer_disconnected_container: MarginContainer

@export var time_label: Label

@export var go_label: Label

signal all_hands_submitted(score_results: ScoreResults, positions: Array, total_scores: Array)
signal score_updated(total_score: int)

# Dictionary<int, Array<Array<CardData>>>
var games: Dictionary = {}
var all_cards: Dictionary = {}

var piles: Array = []

var _submitted_hands: int = 0

var score_results: ScoreResults

var _is_transferring_pile: bool = false

var _is_waiting_for_results: bool = false
var _is_showing_results: bool = false

var _time_elapsed: float = 0
var _can_update_time_label: bool = true

var _submitted_results: int = 0


func _ready() -> void:
	waiting_for_players_container.visible = false
	
	score_results = ScoreResults.new()
	score_results.peer_id = multiplayer.get_unique_id()
	
	submit_button.disabled = true
	
	$CardDataLoader.load_cards()
	games = $CardDataLoader.games
	
	if GameData.piles > 0:
		piles_count = GameData.piles
	else:
		GameData.piles = piles_count
	
	randomize_piles(GameData.players)
	distribute_piles(GameData.players)
	
	submit_button.pressed.connect(_on_submit_button_pressed)
	
	EventBus.card_dropped_in_shared_pile.connect(_on_card_dropped_in_shared_pile)
	EventBus.card_picked_up_from_shared_pile.connect(_on_card_picked_up_from_shared_pile)
	
	if GameData.is_multiplayer():
		if multiplayer.is_server():
			multiplayer.peer_connected.connect(_on_peer_connected)
			multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		else:
			multiplayer.connected_to_server.connect(_on_connected_to_server)
			multiplayer.server_disconnected.connect(_on_server_disconnected)


func _process(delta: float) -> void:
	_update_time_elapsed(delta)


func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		_quit()


func _update_time_elapsed(delta: float) -> void:
	_time_elapsed += delta
	
	var minutes = int(_time_elapsed / 60)
	var seconds = int(_time_elapsed) % 60
	
	if _can_update_time_label:
		time_label.text = "%02d:%02d" % [minutes, seconds]


func _quit() -> void:
	set_process(false)
	
	Loader.change_scene("res://main_menu/main_menu.tscn")
	
	if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.ConnectionStatus.CONNECTION_CONNECTED:
		if not multiplayer.is_server():
			multiplayer.server_disconnected.disconnect(_on_server_disconnected)
	
	GameData.disconnect_network()


func randomize_piles(players: int = 0) -> void:
	seed(GameData.game_seed)
	
	var available_games: Array = games.keys().duplicate()
	
	if can_randomize:
		available_games.shuffle()
	
	# + shared pile
	var total_piles: int = piles_count * players + 1
	
	assert(total_piles <= games.keys().size())
	
	var chosen_games: Array = available_games.slice(0, total_piles)
	
	var chosen_cards: Array[CardData] = []
	
	for game_index in chosen_games:
		for i in $CardDataLoader.STAGES:
			var cards_per_stage: Array = games[game_index][i]
			cards_per_stage.shuffle()
			
			chosen_cards.push_back(cards_per_stage.front())
	
	if can_randomize:
		chosen_cards.shuffle()
	
	for i in chosen_games.size():
		for j in cards_per_pile:
			var card: Card = card_packed_scene.instantiate()
			
			card.set_data(chosen_cards.pop_front())
			
			$Deck.add_child(card)
			
			all_cards[card._card_data.texture.resource_path] = card


func distribute_piles(players: int) -> void:
	var deck_children: Array[Node] = $Deck.get_children()
	var chosen_piles: Node2D = _pick_piles()
	
	await _add_cards_to_piles(chosen_piles, deck_children, players)
	
	# Shared pile
	$SharedPile.add_cards(deck_children.slice(-6))
	
	await $SharedPile.cards_added
	
	$Deck.hide()
	
	for pile in chosen_piles.get_children():
		pile.enable_area()
	
	go_label.play()


func _pick_piles() -> Node2D:
	if piles_count == 3:
		return $Piles3
	elif piles_count == 4:
		return $Piles4
	elif piles_count == 5:
		return $Piles5
	else:
		return null


func _add_cards_to_piles(chosen_piles: Node2D, deck_children: Array, players: int) -> void:
	chosen_piles.visible = true
	
	var sliced_deck: Array
	
	if players > 1 and not multiplayer.is_server():
		var index: int = GameData.get_player_number()
		
		var start: int = index * chosen_piles.get_child_count() * cards_per_pile
		var end: int = start + chosen_piles.get_child_count() * cards_per_pile
		
		sliced_deck = deck_children.slice(start, end)
	else:
		sliced_deck = deck_children.slice(0, chosen_piles.get_child_count() * cards_per_pile)
	
	assert(sliced_deck.size() == chosen_piles.get_child_count() * cards_per_pile)
	
	for pile in chosen_piles.get_children():
		var cards_to_add := []
		
		for i in cards_per_pile:
			cards_to_add.push_back(sliced_deck.pop_front())
		
		cards_to_add.reverse()
		
		pile.add_cards(cards_to_add)
		
		await pile.cards_added
		
		pile.pile_clicked.connect(_on_pile_clicked.bind(pile))
		
		await get_tree().create_timer(pile_wait_time_seconds).timeout


func _on_pile_clicked(pile: Pile) -> void:
	if _is_transferring_pile:
		return
	
	if $Hand.is_missing_one_card():
		return
	
	_is_transferring_pile = true
	
	if $Hand.has_cards() and $Hand.pile == pile:
		print("Returning cards to pile")
		
		await _return_cards_to_pile(pile)
		
		pile.enable_area()
	elif $Hand.pile != null and $Hand.pile != pile:
		print("Swapping piles")
		
		var original_pile: Pile = $Hand.pile
		
		pile.disable_area()
		
		await _return_cards_to_pile(original_pile)
		await $Hand.transfer_from_pile(pile)
		
		pile.enable_area()
		original_pile.enable_area()
		
		submit_button.disabled = false
	else:
		print("Transferring cards from pile")
		
		await $Hand.transfer_from_pile(pile)
		
		pile.enable_area()
		
		submit_button.disabled = false
	
	_is_transferring_pile = false


func _return_cards_to_pile(pile: Pile, can_flip_cards: bool = true, can_reverse_cards: bool = false) -> void:
	submit_button.disabled = true
	
	var cards: Array = $Hand.take_cards()
	
	if can_reverse_cards:
		cards.reverse()
	
	pile.disable_area()
	pile.add_cards(cards, can_flip_cards)
	
	await pile.cards_added


func _emit_score_signals() -> void:
	score_updated.emit(score_results.get_total_score())
	
	update_score.rpc(score_results.base_score, score_results.perfect_hands, score_results.penalties, _submitted_hands)


func _submit_results_to_server() -> void:
	waiting_for_players_container.visible = true
	_is_waiting_for_results = true
	
	submit_results.rpc(score_results.base_score, score_results.perfect_hands, score_results.penalties, score_results.time_seconds)


func sort_results(first: ScoreResults, second: ScoreResults) -> bool:
	if first.get_total_score() > second.get_total_score():
		return true
	elif first.get_total_score() < second.get_total_score():
		return false
	
	if first.penalties < second.penalties:
		return true
	elif first.penalties > second.penalties:
		return false
	
	if first.perfect_hands > second.perfect_hands:
		return true
	elif first.perfect_hands < second.perfect_hands:
		return false
	
	if first.time_seconds < second.time_seconds:
		return true
	elif first.time_seconds > second.time_seconds:
		return false
	
	return false


func _present_results() -> void:
	if _is_showing_results:
		return
	
	_is_showing_results = true
	
	var scores: Array = GameData.results.values()
	
	for score in scores:
		if score.time_seconds == 0:
			score.time_seconds = floori(_time_elapsed)
	
	scores.sort_custom(sort_results)
	
	var positions: Array = []
	var total_scores: Array = []
	
	for score in scores:
		assert(score.peer_id != 0)
		
		positions.push_back(score.peer_id)
		total_scores.push_back(score.get_total_score())
	
	show_results.rpc(positions, total_scores)


@rpc("call_local", "any_peer")
func submit_results(base_score: int, perfect_hands: int, penalties: int, time_seconds: int) -> void:
	var player_score_results := ScoreResults.new()
	
	var sender_id: int = multiplayer.get_remote_sender_id()
	
	if sender_id == 0:
		player_score_results.peer_id = multiplayer.get_unique_id()
	else:
		player_score_results.peer_id = sender_id
	
	player_score_results.base_score = base_score
	player_score_results.perfect_hands = perfect_hands
	player_score_results.penalties = penalties
	player_score_results.time_seconds = time_seconds
	
	GameData.results[player_score_results.peer_id] = player_score_results
	
	if multiplayer.is_server():
		_submitted_results += 1
		
		_reset_card_peer_ids(sender_id)
		
		if _submitted_results >= GameData.players - 1:
			_present_results()


@rpc("call_local")
func show_results(positions: Array, total_scores: Array) -> void:
	waiting_for_players_container.visible = false
	_can_update_time_label = false
	
	all_hands_submitted.emit(score_results, positions, total_scores)


func _on_submit_button_pressed() -> void:
	var results: HandEvaluationResults = $Hand.is_valid()
	
	submit_button.show_score(results)
	
	submit_button.disabled = true
	
	if results.is_valid:
		_submitted_hands += 1
		
		if results.is_perfect_hand:
			score_results.perfect_hands += 1
		
		score_results.update()
		_emit_score_signals()
		
		EventBus.started_submitting_hand.emit()
		
		await $Hand.show_cards_stages()
		
		var original_pile: Pile = $Hand.pile
		
		_return_cards_to_pile(original_pile, false, true)
		
		await original_pile.cards_added
		
		EventBus.finished_submitting_hand.emit()
		original_pile.submit()
		
		if _submitted_hands == piles_count:
			_can_update_time_label = false
			
			score_results.time_seconds = floori(_time_elapsed)
			
			if GameData.is_multiplayer():
				_submit_results_to_server()
			else:
				all_hands_submitted.emit(score_results, [], [])
	else:
		score_results.add_penalty()
		
		_emit_score_signals()
		
		await $Hand.show_wrong_cards(results)
		
		submit_button.disabled = false


func _on_card_dropped_in_shared_pile(card: Card) -> void:
	print("%d dropped card" % multiplayer.get_unique_id())
	
	drop_card_in_shared_pile.rpc(card._card_data.texture.resource_path, card.position)


func _on_card_picked_up_from_shared_pile(card: Card) -> void:
	print("%d picked up card" % multiplayer.get_unique_id())
	
	pick_up_card_from_shared_pile.rpc(card._card_data.texture.resource_path)


func _on_shared_pile_card_requested(card: Card) -> void:
	print("requesting card")
	
	request_card.rpc(card._card_data.texture.resource_path)


func _on_peer_connected(_id: int) -> void:
	peer_disconnected_container.visible = false
	
	on_peer_connected.rpc()


func _on_peer_disconnected(_id: int) -> void:
	print("Peer disconnected")
	
	if _is_waiting_for_results and multiplayer.get_peers().size() >= GameData.players - 1:
		_present_results()
	else:
		peer_disconnected_container.visible = true
		
		on_peer_disconnected.rpc()


func _on_connected_to_server() -> void:
	on_peer_connected()


func _on_server_disconnected() -> void:
	on_peer_disconnected()


@rpc
func on_peer_connected() -> void:
	peer_disconnected_container.visible = false


@rpc
func on_peer_disconnected() -> void:
	if _is_showing_results:
		return
	
	peer_disconnected_container.visible = true


@rpc("call_local", "any_peer", "reliable")
func request_card(card_path: String) -> void:
	if not multiplayer.is_server():
		return
	
	print("Card requested by ", multiplayer.get_remote_sender_id())
	
	var card: Card = all_cards[card_path]
	
	if card.peer_id == 0 || card.peer_id == multiplayer.get_remote_sender_id():
		card.peer_id = multiplayer.get_remote_sender_id()
		
		for shared_pile_card in $SharedPile.get_cards():
			if shared_pile_card != card and shared_pile_card.peer_id == card.peer_id:
				print("Resetting card peer ID in ", multiplayer.get_unique_id())
				
				shared_pile_card.peer_id = 0
		
		grab_card.rpc_id(multiplayer.get_remote_sender_id(), card_path)
	else:
		print("Card taken by ", card.peer_id)
		
		restore_shared_pile_state.rpc_id(multiplayer.get_remote_sender_id())


func _reset_card_peer_ids(peer_id: int) -> void:
	for shared_pile_card in $SharedPile.get_cards():
		if shared_pile_card.peer_id == peer_id:
			shared_pile_card.peer_id = 0


@rpc("call_local", "reliable")
func grab_card(card_path: String) -> void:
	var card: Card = all_cards[card_path]
	
	$SharedPile.handle_card(card)


@rpc("call_local", "reliable")
func restore_shared_pile_state() -> void:
	$SharedPile.restore_state()


@rpc("any_peer")
func drop_card_in_shared_pile(card_path: String, card_position: Vector2) -> void:
	var card: Card = all_cards[card_path]
	
	card.peer_id = 0
	
	assert(card != null)
	
	$SharedPile.add_card(card)
	
	card.position = card_position
	
	card.flip_up()
	
	print("Adding card at %d" % multiplayer.get_unique_id())


@rpc("any_peer")
func pick_up_card_from_shared_pile(card_path: String) -> void:
	var card: Card = all_cards[card_path]
	
	assert(card != null)
	
	$SharedPile.remove_card(card)
	
	# TODO: Play animation
	
	card.disable()
	card.reparent($Deck)


@rpc("any_peer", "call_local")
func update_score(base_score: int, perfect_hands: int, penalties: int, submitted_hands: int) -> void:
	var peer_id: int = multiplayer.get_remote_sender_id()
	
	var results: ScoreResults = ScoreResults.new()
	results.peer_id = peer_id
	results.base_score = base_score
	results.perfect_hands = perfect_hands
	results.penalties = penalties
	
	multiplayer_score_tracker.update(peer_id, results.get_total_score(), submitted_hands)
	
	GameData.results[peer_id] = results
	print("peer id ", peer_id)


func _on_peer_disconnected_quit_button_pressed() -> void:
	_quit()
