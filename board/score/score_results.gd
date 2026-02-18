class_name ScoreResults
extends Object


const BASE_HAND_SCORE: int = 30
const PENALTY: int = -5

var peer_id: int = 0

var base_score: int = 0
var penalties: int = 0

var time_seconds: int = 0


func add_penalty() -> void:
	penalties += 1


func update() -> void:
	base_score += BASE_HAND_SCORE


func get_total_score() -> int:
	return max(base_score + penalties * PENALTY, 0)
