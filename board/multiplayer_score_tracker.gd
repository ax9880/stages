extends VBoxContainer


@export var multiplayer_score_container_packed_scene: PackedScene


func _ready() -> void:
	if GameData.players == 1:
		visible = false
	
	for i in GameData.players:
		var multiplayer_score_container: Control = multiplayer_score_container_packed_scene.instantiate()
		
		multiplayer_score_container.set_text(i, 0, 0)

		add_child(multiplayer_score_container)


func update(player_id: int, score: int, submitted_hands: int) -> void:
	if player_id == 0:
		return
	
	var player_number: int = GameData.get_player_number(player_id)
	
	assert(player_number <= get_child_count())
	
	var multiplayer_score_container: Control = get_child(player_number)
	
	multiplayer_score_container.set_text(player_number, score, submitted_hands)
