class_name ServerConnector
extends Node


func connect_to_server(host_ip: String, port: int) -> void:
	var network: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	
	network.create_client(host_ip, port)
	
	multiplayer.multiplayer_peer = network
	
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	
	print("Connecting to ", host_ip, ":", port)


func _on_connected_to_server() -> void:
	print("Connected to server!")
