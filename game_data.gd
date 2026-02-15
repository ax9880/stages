extends Node

var connected_peers: int = 0

var players: int = 1
var piles: int = -1

var time_limit_seconds: int = 0

var is_penalties_enabled: bool = true

var player_numbers: Dictionary = {}


func _ready() -> void:
	player_numbers[1] = 0


func get_player_number(id: int = multiplayer.get_unique_id()) -> int:
	return player_numbers[id]
