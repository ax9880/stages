extends Node2D


@export var default_color: Color
@export var penalty_color: Color

@onready var label: Label = $MarginContainer/VBoxContainer/Label
@onready var game_label: Label = $MarginContainer/VBoxContainer/GameLabel


func show_score(results: HandEvaluationResults) -> void:
	game_label.visible = results.is_valid
	
	if results.is_valid:
		# Button 22
		label.modulate = default_color
		
		$ScoreAudio.play()
		
		assert(results.game_number > 0)
		
		label.text = "+%d" % ScoreResults.BASE_HAND_SCORE
		game_label.text = "%s %d" % [tr("TOUHOU"), results.game_number]
	else:
		$PenaltyAudio.play()
		
		label.text = "%d" % ScoreResults.PENALTY
		
		label.modulate = penalty_color
	
	$AnimationPlayer.play("float_up")
