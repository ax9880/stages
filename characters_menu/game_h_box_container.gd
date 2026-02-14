extends HBoxContainer


@export var character_vbox_container_packed_scene: PackedScene


func set_data(game_number: int, stages: Array) -> void:
	$Label.text = str(game_number)
	
	for i in stages.size():
		var stage: Array = stages[i]
		
		for card_data in stage:
			var character_vbox_container: Control = character_vbox_container_packed_scene.instantiate()
			
			character_vbox_container.set_data(card_data)
			
			add_child(character_vbox_container)
