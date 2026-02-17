class_name AudioButton
extends Button


func _on_pressed() -> void:
	$AudioStreamPlayer.play()
