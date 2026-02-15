extends HSlider

# https://www.gdquest.com/tutorial/godot/audio/volume-slider/

@export_enum("Sound effects", "Music") var bus_name := "Music"


@onready var bus_index := AudioServer.get_bus_index(bus_name)
@onready var slide_sound_effect := $SlideAudio


func _ready() -> void:
	value = db_to_linear(AudioServer.get_bus_volume_db(bus_index))
	
	value_changed.connect(_on_slider_value_changed)


func _on_slider_value_changed(new_value: float) -> void:
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(new_value))
	
	slide_sound_effect.play()
