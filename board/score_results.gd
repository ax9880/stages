class_name ScoreResults
extends Object


const BASE_HAND_SCORE: int = 30
const PERFECT_HAND_BONUS: int = 15
const PENALTY: int = -5

var base_score: int = 0
var perfect_hands: int = 0
var penalties: int = 0

var total_score: int = 0


func add_perfect_hand() -> void:
	perfect_hands += 1


func add_penalty() -> void:
	penalties += 1


func update() -> void:
	base_score += BASE_HAND_SCORE


func get_total_score() -> int:
	return max(base_score + perfect_hands * PERFECT_HAND_BONUS + penalties * PENALTY, 0)
