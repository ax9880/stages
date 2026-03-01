extends VBoxContainer

@export var player_label: Label
@export var score_label: Label
@export var hands_label: Label


var _submitted_hands: int = 0


func set_text(player_number: int, score: int, submitted_hands: int) -> void:
	player_label.text = "%s %d" % [tr("PLAYER"), player_number + 1]
	score_label.text = "%s: %d" % [tr("SCORE"), score]
	hands_label.text = "%d/%d" % [submitted_hands, GameData.piles]
	
	if player_number != GameData.get_player_number() and _submitted_hands < submitted_hands:
		_submitted_hands = submitted_hands
		
		$AnimationPlayer.play("plus_one")
