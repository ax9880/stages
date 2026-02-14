extends VBoxContainer


func set_data(card_data: CardData) -> void:
	$Label.text = str(card_data.stage)
	
	$TextureRect.texture = card_data.texture
