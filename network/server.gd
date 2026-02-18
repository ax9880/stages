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
	
	GameData.port = port


func stop_server() -> void:
	multiplayer.multiplayer_peer.close()


func _on_peer_connected(_id: int) -> void:
	print("Peer connected: ", multiplayer.get_peers().size())
	
	on_peer_connection_status_change.emit(multiplayer.get_peers().size())
	
	if multiplayer.get_peers().size() + 1 >= GameData.players:
		multiplayer.multiplayer_peer.refuse_new_connections = true
		
		GameData.start_game()


func _on_peer_disconnected(_id: int) -> void:
	print("Peer disconnected")
	
	on_peer_connection_status_change.emit(multiplayer.get_peers().size())
