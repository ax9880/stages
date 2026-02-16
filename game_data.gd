extends Node

var game_seed: int = 0

var connected_peers: int = 0

var players: int = 1
var piles: int = -1

var time_limit_seconds: int = 0

var is_penalties_enabled: bool = true

var player_numbers: Dictionary = {}

var results: Dictionary = {}


func _ready() -> void:
	player_numbers[1] = 0


func is_multiplayer() -> bool:
	return players > 1


func get_player_number(id: int = multiplayer.get_unique_id()) -> int:
	if id == 0:
		return 0
	
	return player_numbers[id]


func start_game() -> void:
	randomize()
	game_seed = randi()
	
	player_numbers.clear()
	
	player_numbers[1] = 0
	
	for i in multiplayer.get_peers().size():
		var peer_id: int = multiplayer.get_peers()[i]
		
		player_numbers[peer_id] = i + 1
	
	_start_game.rpc(game_seed, player_numbers.keys().size(), piles, player_numbers)


@rpc("call_local")
func _start_game(_game_seed: int, _players: int, _piles: int, _player_numbers: Dictionary) -> void:
	seed(_game_seed)
	
	players = _players
	piles = _piles
	player_numbers = _player_numbers
	
	connected_peers = multiplayer.get_peers().size()
	
	_initialize_results()
	
	print("Players: ", players)
	
	Loader.change_scene("res://board/game_tree.tscn")


func _initialize_results() -> void:
	var score_results := ScoreResults.new()
	score_results.peer_id = multiplayer.get_unique_id()
	results[score_results.peer_id] = score_results
	
	for i in multiplayer.get_peers().size():
		var peer_id: int = multiplayer.get_peers()[i]
		
		score_results = ScoreResults.new()
		score_results.peer_id = peer_id
		results[peer_id] = score_results


func disconnect_network() -> void:
	if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.ConnectionStatus.CONNECTION_CONNECTED:
		if multiplayer.is_server():
			for peer in multiplayer.get_peers():
				multiplayer.multiplayer_peer.disconnect_peer(peer)
		
		multiplayer.multiplayer_peer.close()
