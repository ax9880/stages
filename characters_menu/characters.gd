extends MarginContainer


@export var game_h_box_container_packed_scene: PackedScene

@onready var _v_box_container: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer


func _ready() -> void:
	$MarginContainer/VBoxContainer/QuitButton.grab_focus()
	
	$CardDataLoader.load_cards()
	
	var games: Dictionary = $CardDataLoader.games
	
	var game_numbers: Array = games.keys()
	game_numbers.sort()
	
	for game_number in game_numbers:
		var game_h_box_container: Control = game_h_box_container_packed_scene.instantiate()
		
		game_h_box_container.set_data(game_number, games[game_number])
		
		_v_box_container.add_child(game_h_box_container)


func _on_quit_button_pressed() -> void:
	Loader.change_scene("res://main_menu/main_menu.tscn")
