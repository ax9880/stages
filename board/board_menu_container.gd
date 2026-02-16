extends MarginContainer

@export var score_label: Label

@export var player_label: Label


func _ready() -> void:
	if GameData.is_multiplayer():
		var player_number: int = GameData.get_player_number()
		
		player_label.text = "%s %d" % [tr("PLAYER"), player_number + 1]
	else:
		player_label.hide()


func _on_spawner_score_updated(total_score: int) -> void:
	score_label.text = str(total_score)
