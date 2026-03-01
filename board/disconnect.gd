extends Button


func _on_pressed() -> void:
	multiplayer.multiplayer_peer.close()
