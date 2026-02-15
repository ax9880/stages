extends Node2D

@export var cards_per_pile: int = 6
@export var piles_count: int = 6

@export var card_packed_scene: PackedScene

@export var shared_pile_add_time_seconds: float = 0.2

@export var can_randomize: bool = true

@export var submit_button: Button
@export var multiplayer_score_tracker: VBoxContainer

signal all_hands_submitted(score_results: ScoreResults)
signal score_updated(total_score: int)

# Dictionary<int, Array<Array<CardData>>>
var games: Dictionary = {}
var all_cards: Dictionary = {}

var piles: Array = []

var _submitted_hands: int = 0

var score_results: ScoreResults

var _is_transferring_pile: bool = false


func _ready() -> void:
	score_results = ScoreResults.new()
	
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


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		set_process(false)
		
		Loader.change_scene("res://main_menu/main_menu.tscn")
		
		if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.ConnectionStatus.CONNECTION_CONNECTED:
			if multiplayer.is_server():
				for peer in multiplayer.get_peers():
					multiplayer.multiplayer_peer.disconnect_peer(peer)
			
			multiplayer.multiplayer_peer.close()


func randomize_piles(players: int = 0) -> void:
	var available_games: Array = games.keys().duplicate()
	
	if can_randomize:
		available_games.shuffle()
	
	# + shared pile
	var total_piles: int = piles_count * players + 1
	
	print(total_piles)
	
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
	update_score.rpc(score_results.get_total_score(), _submitted_hands)


func _on_submit_button_pressed() -> void:
	var results: HandEvaluationResults = $Hand.is_valid()
	
	submit_button.show_score(results)
	
	submit_button.disabled = true
	
	if results.is_valid:
		_submitted_hands += 1
		
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
			print("You won!")
			
			all_hands_submitted.emit(score_results)
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
	# Disable card?
	request_card.rpc(card._card_data.texture.resource_path)


@rpc("call_local", "any_peer")
func request_card(card_path: String) -> void:
	if not multiplayer.is_server():
		return
	
	print("Card requested by ", multiplayer.get_remote_sender_id())
	
	var card: Card = all_cards[card_path]
	
	if card.peer_id == 0 || card.peer_id == multiplayer.get_remote_sender_id():
		card.peer_id = multiplayer.get_remote_sender_id()
		
		grab_card.rpc_id(multiplayer.get_remote_sender_id(), card_path)
	else:
		print("Card taken by ", card.peer_id)
		pass


@rpc("call_local")
func grab_card(card_path: String) -> void:
	var card: Card = all_cards[card_path]
	
	$SharedPile.handle_card(card)

# func request_card()
#	get card
#	if card.peer_id == -1:
#		card.peer_id = get_request_peer_id()
#		shared_pile.grab_card.rpc(get_request_peer_id())
#  		enable card
#	else:
#		enable card


@rpc("any_peer")
func drop_card_in_shared_pile(card_path: String, card_position: Vector2) -> void:
	var card: Card = all_cards[card_path]
	
	card.peer_id = 0
	
	assert(card != null)
	
	$SharedPile.add_card(card)
	
	card.position = card_position
	
	card.flip_up()
	
	print("Adding card at %d" % multiplayer.get_unique_id())
	
	if multiplayer.is_server():
		pass


@rpc("any_peer")
func pick_up_card_from_shared_pile(card_path: String) -> void:
	var card: Card = all_cards[card_path]
	
	assert(card != null)
	
	$SharedPile.remove_card(card)
	
	card.disable()
	card.reparent($Deck)


@rpc("any_peer", "call_local")
func update_score(score: int, submitted_hands: int) -> void:
	multiplayer_score_tracker.update(multiplayer.get_remote_sender_id(), score, submitted_hands)
