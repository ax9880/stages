class_name Server
extends Node


signal on_peer_connection_status_change(connected_peers: int)

var _network: ENetMultiplayerPeer = null


func start_server(port: int) -> void:
	if _network == null:
		_network = ENetMultiplayerPeer.new()
		
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	multiplayer.multiplayer_peer.refuse_new_connections = false
	
	_network.create_server(port, GameData.players)
	
	multiplayer.multiplayer_peer = _network
	
	print("Starting server on port: ", port)


func stop_server() -> void:
	multiplayer.multiplayer_peer.close()


func _on_peer_connected(_id: int) -> void:
	print("Peer connected: ", multiplayer.get_peers().size())
	on_peer_connection_status_change.emit(multiplayer.get_peers().size())
	
	if multiplayer.get_peers().size() + 1 >= GameData.players:
		multiplayer.multiplayer_peer.refuse_new_connections = true
		
		GameData.player_numbers.clear()
		
		GameData.player_numbers[1] = 0
		
		for i in multiplayer.get_peers().size():
			GameData.player_numbers[multiplayer.get_peers()[i]] = i + 1
		
		_start_game.rpc(GameData.player_numbers.keys().size(), GameData.piles, GameData.player_numbers)


func _on_peer_disconnected(_id: int) -> void:
	print("Peer disconnected")
	
	on_peer_connection_status_change.emit(multiplayer.get_peers().size())


@rpc("call_local")
func _start_game(players: int, piles: int, player_numbers: Dictionary) -> void:
	# TODO: Randomize seed
	seed(1)
	
	GameData.players = players
	GameData.piles = piles
	GameData.player_numbers = player_numbers
	
	GameData.connected_peers = multiplayer.get_peers().size()
	
	print("Players: ", GameData.players)
	
	Loader.change_scene("res://board/game_tree.tscn")
