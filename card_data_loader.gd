extends Node

const STAGES: int = 6

const _SPRITE_PREFFIX: String = "Charas_"
const _SPRITE_EXTENSION: String = ".png.import"


# Dictionary<int, Array<Array<CardData>>>
var games: Dictionary = {}
var cards_by_stage: Dictionary = {}


func load_cards(path: String = "res://dotpack/Charas") -> void:
	var directory = DirAccess.open(path)
	
	if directory == null:
		printerr("An error occurred when trying to access the path %s" % path)
		
		return
	
	directory.list_dir_begin()
	
	var file_name: String = directory.get_next()
	
	for i in STAGES:
		cards_by_stage[i + 1] = []
	
	while not file_name.is_empty():
		if file_name.begins_with("."):
			file_name = directory.get_next()
			
			continue
		
		if directory.current_is_dir():
			var game_number: int = file_name.replace("Touhou", "").to_int()
			
			var game_card_data := []
			
			for i in STAGES:
				game_card_data.push_back([])
			
			games[game_number] = game_card_data
			
			var game_directory = DirAccess.open(directory.get_current_dir() + "/" + file_name)
			
			if game_directory == null:
				continue
			
			game_directory.list_dir_begin()
			
			var character: String = game_directory.get_next()
			
			while not character.is_empty():
				if character.ends_with(_SPRITE_EXTENSION):
					var card_data: CardData = CardData.new()
					var texture_path = game_directory.get_current_dir() + "/" + character.trim_suffix(".import")
					
					card_data.texture = ResourceLoader.load(texture_path)
					
					assert(card_data.texture != null)
					
					card_data.game = game_number
					card_data.stage = _extract_stage(character)
					
					cards_by_stage[card_data.stage].push_back(card_data)
					game_card_data[card_data.stage - 1].push_back(card_data)
				
				character = game_directory.get_next()
				
			game_directory.list_dir_end()
		
		file_name = directory.get_next()
	
	directory.list_dir_end()


# Extracts an index from a path in the form "path/Charas_***_<index>.png"
func _extract_stage(path: String) -> int:
	var extension_start: int = path.find(_SPRITE_EXTENSION)
	
	assert(extension_start != -1)
	
	return path.substr(extension_start - 1, 1).to_int()
