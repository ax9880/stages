extends Node


signal peer_reconnected


func _ready() -> void:
	if GameData.is_multiplayer():
		if multiplayer.is_server():
			multiplayer.peer_connected.connect(_on_peer_connected)
			multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		else:
			multiplayer.connected_to_server.connect(_on_connected_to_server)
			multiplayer.server_disconnected.connect(_on_server_disconnected)


func _on_peer_connected(id: int) -> void:
	print("Peer %d trying to connect" % id)
	
	_request_persistent_peer_id.rpc_id(id)


func _on_peer_disconnected(_id: int) -> void:
	print("Peer disconnected")
	
	multiplayer.multiplayer_peer.refuse_new_connections = false


func _on_connected_to_server() -> void:
	$ReconnectionTimer.stop()


func _on_server_disconnected() -> void:
	$ReconnectionTimer.start()


func _on_reconnection_timer_timeout() -> void:
	if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.ConnectionStatus.CONNECTION_CONNECTED:
		return
	
	if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.ConnectionStatus.CONNECTION_CONNECTING:
		return
	
	$ServerConnector.connect_to_server(GameData.ip_address, GameData.port)


@rpc("reliable")
func _request_persistent_peer_id() -> void:
	_send_peer_id.rpc_id(1, GameData.persistent_peer_id)


@rpc("any_peer", "reliable")
func _send_peer_id(persistent_peer_id: int) -> void:
	var peer_id: int = multiplayer.get_remote_sender_id()
	print("Persistent peer ID: %d. New peer ID: %d" % [persistent_peer_id, peer_id])
	
	var player_number = GameData.player_numbers.get(persistent_peer_id, -1)
	
	if player_number < 0:
		printerr("Unrecognized peer")
		
		multiplayer.multiplayer_peer.disconnect_peer(peer_id)
		
		return
	
	print("Peer recognized")
	
	peer_reconnected.emit()
