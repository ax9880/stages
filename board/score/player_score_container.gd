extends HBoxContainer

@export var position_label: Label
@export var player_label: Label
@export var score_label: Label
@export var time_label: Label


func set_data(player_position: int, player_number: int, total_score: int) -> void:
	position_label.text = "#%d" % (player_position + 1)
	
	player_label.text = "%s %d" % [tr("PLAYER"), player_number + 1]
	
	score_label.text = str(total_score)
