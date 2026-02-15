extends Node


@onready var fader_packed_scene: PackedScene = preload("res://loader/Fader.tscn")

var current_scene: Node = null

var _is_loading: bool = false


func _ready() -> void:
	var root: Node = get_tree().get_root()
	
	current_scene = root.get_child(root.get_child_count() - 1)


func change_scene(path: String) -> void:
	if _is_loading:
		return
	
	_is_loading = true
	
	var fader = fader_packed_scene.instantiate()
	get_tree().get_root().add_child(fader)
	
	await fader.fade_out()
	
	# Load next scene
	var next_scene = ResourceLoader.load(path).instantiate()
	
	current_scene.queue_free()
	
	current_scene = next_scene
	get_tree().get_root().add_child(current_scene)
	
	# Fade in next scene
	await fader.fade_in()
	
	fader.queue_free()
	
	_is_loading = false
