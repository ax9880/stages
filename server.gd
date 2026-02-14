class_name Server
extends Node

const MAX_PLAYERS: int = 4

func start_server(port: int) -> void:
	var network: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	
	network.create_server(port, MAX_PLAYERS)
	
	multiplayer.multiplayer_peer = network
	
	print("Starting server on port: ", port)
