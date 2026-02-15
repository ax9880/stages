extends VBoxContainer


func _ready() -> void:
	if GameData.players == 1:
		visible = false
	
	for i in GameData.players:
		var label: Label = Label.new()
		
		_set_label_text(label, i, 0, 0)
		
		add_child(label)


func update(player_id: int, score: int, submitted_hands: int) -> void:
	if player_id == 0:
		return
	
	var player_number: int = GameData.get_player_number(player_id)
	
	assert(player_number <= get_child_count())
	
	var label: Label = get_child(player_number)
	
	_set_label_text(label, player_number, score, submitted_hands)


func _set_label_text(label: Label, player_number: int, score: int, submitted_hands: int) -> void:
	# PLAYER X
	# Score: 9999
	# 1/6
	label.text = "%s %d\n%s: %d\n%d/%d" % [tr("PLAYER"), player_number + 1, tr("SCORE"), score, submitted_hands, GameData.piles]
