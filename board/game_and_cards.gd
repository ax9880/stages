class_name GameAndCards
extends Object

enum HandResults {
	OK,
	ALL_WRONG,
	TIE,
	THREE_WAY_TIME
}

static func sort_ascending(first, second) -> bool:
	if first.cards.size() == second.cards.size():
		return first.game_number < second.game_number
	
	return first.cards.size() > second.cards.size()


var game_number: int = 0
var cards: Array[Card] = []
