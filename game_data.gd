extends Node

var game_seed: int = 0

var ip_address: String = "localhost"
var port: int = 30000


var players: int = 1
var piles: int = 3

# Persistent peer ID, player number
var player_numbers: Dictionary[int, int] = {}

# Current peer ID to handle reconnection requests
var current_peer_id: int = 0

# Original peer ID, to handle scoring and card assignments
var persistent_peer_id: int

var time_limit_seconds: int = 0

var is_full_screen: bool = true

var results: Dictionary[int, ScoreResults] = {}


func _ready() -> void:
	player_numbers[1] = 0


func is_multiplayer() -> bool:
	return players > 1


func get_player_number(id: int = persistent_peer_id) -> int:
	if id == 0:
		return 0
	
	return player_numbers[id]


func start_game() -> void:
	randomize()
	game_seed = randi()
	
	player_numbers.clear()
	player_numbers[1] = 0
	
	results.clear()
	
	for i in multiplayer.get_peers().size():
		var peer_id: int = multiplayer.get_peers()[i]
		
		player_numbers[peer_id] = i + 1
	
	_start_game.rpc(game_seed, player_numbers.keys().size(), piles, player_numbers)


@rpc("call_local", "reliable")
func _start_game(_game_seed: int, _players: int, _piles: int, _player_numbers: Dictionary) -> void:
	game_seed = _game_seed
	
	seed(GameData.game_seed)
	
	players = _players
	piles = _piles
	player_numbers = _player_numbers
	
	persistent_peer_id = multiplayer.get_unique_id()
	
	_initialize_results()
	
	print("Players: ", players)
	
	$GameStartAudio.play()
	
	Loader.change_scene("res://board/game_tree.tscn")


func _initialize_results() -> void:
	var score_results := ScoreResults.new()
	score_results.peer_id = persistent_peer_id
	results[score_results.peer_id] = score_results
	
	for i in multiplayer.get_peers().size():
		var peer_id: int = multiplayer.get_peers()[i]
		
		score_results = ScoreResults.new()
		score_results.peer_id = peer_id
		results[peer_id] = score_results


func disconnect_network(force: bool = false) -> void:
	if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.ConnectionStatus.CONNECTION_CONNECTED:
		if multiplayer.is_server():
			for peer in multiplayer.get_peers():
				multiplayer.multiplayer_peer.disconnect_peer(peer, force)
		
		multiplayer.multiplayer_peer.close()
