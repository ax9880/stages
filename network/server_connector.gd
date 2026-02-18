class_name ServerConnector
extends Node


var _network: ENetMultiplayerPeer = null


func connect_to_server(host_ip: String, port: int) -> void:
	if _network == null:
		_network = ENetMultiplayerPeer.new()
		
		multiplayer.connected_to_server.connect(_on_connected_to_server)
	
	_network.create_client(host_ip, port)
	
	multiplayer.multiplayer_peer = _network
	
	print("Connecting to ", host_ip, ":", port)
	
	GameData.ip_address = host_ip
	GameData.port = port


func stop() -> void:
	multiplayer.multiplayer_peer.close()


func _on_connected_to_server() -> void:
	print("Connected to server!")
