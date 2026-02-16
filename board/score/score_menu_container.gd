extends MarginContainer

@export var result_label: Label

@export var base_score_label: Label
@export var perfect_hands_label: Label
@export var penalties_label: Label
@export var total_score_label: Label
@export var time_label: Label

@export var multiplayer_results: VBoxContainer

@export var player_score_container_packed_scene: PackedScene

@export var play_again_button: Button

var _peer_ids: Array = []


func _ready() -> void:
	visible = false


func _on_spawner_all_hands_submitted(score_results: ScoreResults, positions: Array = [], total_scores: Array = []) -> void:
	visible = true
	
	# TODO: Animate
	
	$GameFinishedAudio.play()
	
	assert(positions.size() == total_scores.size())
	
	if positions.size() > 1:
		_show_multiplayer_results(positions, total_scores)
		
		if positions.front() == multiplayer.get_unique_id():
			result_label.text = tr("YOU_WIN")
		else:
			result_label.text = tr("YOU_LOSE")
	
	base_score_label.text = str(score_results.base_score)
	
	if score_results.perfect_hands > 0:
		perfect_hands_label.text = "%d (+%d)" % [score_results.perfect_hands, score_results.perfect_hands * ScoreResults.PERFECT_HAND_BONUS]
	else:
		perfect_hands_label.text = "0"
	
	penalties_label.text = str(score_results.penalties)
	
	total_score_label.text = str(score_results.get_total_score())


func _show_multiplayer_results(positions: Array, total_scores: Array) -> void:
	multiplayer_results.visible = true
	
	for i in positions.size():
		var peer_id: int = positions[i]
		var total_score: int = total_scores[i]
		
		var player_score_container = player_score_container_packed_scene.instantiate()
		player_score_container.set_data(i, GameData.get_player_number(peer_id), total_score)
		
		multiplayer_results.add_child(player_score_container)


func _on_play_again_button_pressed() -> void:
	play_again_button.disabled = true
	play_again_button.text = tr("WAITING_FOR_PLAYERS")
	
	if GameData.is_multiplayer():
		play_again.rpc()
	else:
		Loader.change_scene("res://board/game_tree.tscn")


func _on_main_menu_button_pressed() -> void:
	Loader.change_scene("res://main_menu/main_menu.tscn")


@rpc("call_local", "any_peer")
func play_again() -> void:
	_peer_ids.push_back(multiplayer.get_remote_sender_id())
	
	if _peer_ids.size() == GameData.players and multiplayer.is_server():
		GameData.start_game()
