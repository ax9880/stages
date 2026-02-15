extends MarginContainer

@export var base_score_label: Label
@export var perfect_hands_label: Label
@export var penalties_label: Label
@export var total_score_label: Label
@export var time_label: Label


func _ready() -> void:
	visible = false


func _on_spawner_all_hands_submitted(score_results: ScoreResults) -> void:
	visible = true
	
	$GameFinishedAudio.play()
	
	# TODO: Animate
	
	base_score_label.text = str(score_results.base_score)
	
	if score_results.perfect_hands > 0:
		perfect_hands_label.text = "%d (+%d)" % [score_results.perfect_hands, score_results.perfect_hands * ScoreResults.PERFECT_HAND_BONUS]
	else:
		perfect_hands_label.text = "0"
	
	penalties_label.text = str(score_results.penalties)
	
	total_score_label.text = str(score_results.get_total_score())


func _on_play_again_button_pressed() -> void:
	Loader.change_scene("res://board/game_tree.tscn")


func _on_main_menu_button_pressed() -> void:
	Loader.change_scene("res://main_menu/main_menu.tscn")
