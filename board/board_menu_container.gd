extends MarginContainer

@export var score_label: Label

@export var player_label: Label

@export var movements_label: Label


func _ready() -> void:
	if GameData.is_multiplayer():
		var player_number: int = GameData.get_player_number()
		
		player_label.text = "%s %d" % [tr("PLAYER"), player_number + 1]
	else:
		player_label.hide()
	
	_on_spawner_movements_updated(0)


func _on_spawner_score_updated(total_score: int) -> void:
	score_label.text = str(total_score)


func _on_spawner_movements_updated(total_movements: int) -> void:
	movements_label.text = tr("MOVEMENTS") % total_movements
