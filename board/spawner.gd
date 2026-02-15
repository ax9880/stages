extends Node2D

@export var cards_per_pile: int = 6
@export var piles_count: int = 6

@export var card_packed_scene: PackedScene

@export var shared_pile_add_time_seconds: float = 0.2

@export var can_randomize: bool = true

@export var submit_button: Button

signal all_hands_submitted(score_results: ScoreResults)
signal score_updated(total_score: int)

# Dictionary<int, Array<Array<CardData>>>
var games: Dictionary = {}

var piles: Array = []

var _submitted_hands: int = 0

var score_results: ScoreResults


func _ready() -> void:
	score_results = ScoreResults.new()
	
	submit_button.disabled = true
	
	$CardDataLoader.load_cards()
	games = $CardDataLoader.games
	
	randomize_piles(piles_count)
	distribute_piles(piles_count)
	
	submit_button.pressed.connect(_on_submit_button_pressed)


func randomize_piles(piles_count: int) -> void:
	assert(piles_count + 1 <= games.keys().size())
	
	var available_games: Array = games.keys().duplicate()
	
	if can_randomize:
		available_games.shuffle()
	
	# + shared pile
	var chosen_games: Array = available_games.slice(0, piles_count + 1)
	
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
			var card: Node2D = card_packed_scene.instantiate()
			
			card.set_data(chosen_cards.pop_front())
			
			$Deck.add_child(card)


func distribute_piles(piles_count: int) -> void:
	var deck_children: Array[Node] = $Deck.get_children()
	
	await _add_cards_to_piles(_pick_piles(piles_count), deck_children)
	
	# Shared pile
	assert(deck_children.size() == 6)
	
	$SharedPile.add_cards(deck_children)
	
	await $SharedPile.cards_added


func _pick_piles(piles_count: int) -> Node2D:
	if piles_count == 3:
		return $Piles3
	elif piles_count == 4:
		return $Piles4
	elif piles_count == 5:
		return $Piles5
	else:
		return null


func _add_cards_to_piles(chosen_piles: Node2D, deck_children: Array) -> void:
	chosen_piles.visible = true
	
	for pile in chosen_piles.get_children():
		var cards_to_add := []
		
		for i in cards_per_pile:
			cards_to_add.push_back(deck_children.pop_front())
		
		cards_to_add.reverse()
		
		pile.add_cards(cards_to_add)
		
		await pile.cards_added
		
		pile.pile_clicked.connect(_on_pile_clicked.bind(pile))


func _on_pile_clicked(pile: Pile) -> void:
	print("clicked ", pile.name)
	
	if $Hand.is_missing_one_card():
		return
	
	if $Hand.has_cards() and $Hand.pile == pile:
		_return_cards_to_pile(pile)
	elif $Hand.pile != null and $Hand.pile != pile:
		var original_pile: Pile = $Hand.pile
		_return_cards_to_pile(original_pile)
		
		await original_pile.cards_added
		
		$Hand.transfer_from_pile(pile)
		
		submit_button.disabled = false
	else:
		$Hand.transfer_from_pile(pile)
		
		submit_button.disabled = false


func _return_cards_to_pile(pile: Pile, can_flip_cards: bool = true, can_reverse_cards: bool = false) -> void:
	submit_button.disabled = true
	
	var cards: Array = $Hand.take_cards()
	
	if can_reverse_cards:
		cards.reverse()
	
	pile.add_cards(cards, can_flip_cards)


func _on_submit_button_pressed() -> void:
	if $Hand.is_valid():
		submit_button.disabled = true
		
		_submitted_hands += 1
		
		score_results.update()
		
		score_updated.emit(score_results.get_total_score())
		
		await $Hand.show_cards_stages()
		
		var original_pile: Pile = $Hand.pile
		_return_cards_to_pile(original_pile, false, true)
		
		await original_pile.cards_added
		
		if _submitted_hands == piles_count:
			print("You won!")
			
			all_hands_submitted.emit(score_results)
	else:
		score_results.add_penalty()
	
	score_updated.emit(score_results.get_total_score())
