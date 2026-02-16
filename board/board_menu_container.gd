extends MarginContainer

@export var score_label: Label
@export var time_label: Label

@export var player_label: Label

var _time_elapsed: float = 0


func _ready() -> void:
	player_label.text = "%s %d" % [tr("PLAYER"), GameData.get_player_number() + 1]


func _process(delta: float) -> void:
	# TODO: If there is a time limit, count down instead
	_update_time_elapsed(delta)


func _update_time_elapsed(delta: float) -> void:
	_time_elapsed += delta
	
	var minutes = int(_time_elapsed / 60)
	var seconds = int(_time_elapsed) % 60
	
	# Time left: 59:59
	time_label.text = "%02d:%02d" % [minutes, seconds]


func _on_spawner_score_updated(total_score: int) -> void:
	score_label.text = str(total_score)


func _on_play_timer_timeout() -> void:
	pass # Replace with function body.
