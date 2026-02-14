extends MarginContainer


@export var game_h_box_container_packed_scene: PackedScene


func _ready() -> void:
	$CardDataLoader.load_cards()
	
	var games: Dictionary = $CardDataLoader.games
	
	var game_numbers: Array = games.keys()
	game_numbers.sort()
	
	for game_number in game_numbers:
		var game_h_box_container: Control = game_h_box_container_packed_scene.instantiate()
		
		game_h_box_container.set_data(game_number, games[game_number])
		
		$MarginContainer/ScrollContainer/VBoxContainer.add_child(game_h_box_container)
