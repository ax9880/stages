extends Node2D


@export var default_color: Color
@export var penalty_color: Color

@onready var label: Label = $MarginContainer/Label


func show_score(results: HandEvaluationResults) -> void:
	if results.is_valid:
		label.modulate = default_color
		
		if results.is_perfect_hand:
			$PerfectAudio.play()
			
			label.text = "%s +%d" % [tr("PERFECT"), (ScoreResults.BASE_HAND_SCORE + ScoreResults.PERFECT_HAND_BONUS)]
		else:
			$ScoreAudio.play()
			
			label.text = "+%d" % ScoreResults.BASE_HAND_SCORE
	else:
		$PenaltyAudio.play()
		
		label.text = "%d" % ScoreResults.PENALTY
		
		label.modulate = penalty_color
	
	$AnimationPlayer.play("float_up")
