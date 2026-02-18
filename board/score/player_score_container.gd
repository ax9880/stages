extends HBoxContainer

@export var position_label: Label
@export var player_label: Label
@export var score_label: Label
@export var time_label: Label


func set_data(player_position: int, player_number: int, total_score: int, time_seconds: int) -> void:
	position_label.text = "#%d" % (player_position + 1)
	
	player_label.text = "%s %d" % [tr("PLAYER"), player_number + 1]
	
	# TODO: Make method
	if time_seconds > 0:
		var minutes = int(float(time_seconds) / 60)
		var seconds = int(time_seconds) % 60
		
		time_label.text = "%02d:%02d" % [minutes, seconds]
	else:
		time_label.text = "--"
	
	score_label.text = str(total_score)
