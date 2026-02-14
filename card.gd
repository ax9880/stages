class_name Card
extends Sprite2D

@export var front_texture: Texture
@export var back_texture: Texture

# Proportional control constant
@export var kp: float = 1.4
@export var velocity_pixels_per_second: float = 15.0

@export var max_velocity_pixels_per_second: float = 2048.0

signal flipped_up

signal card_clicked

var _card_data: CardData

var _position_tween: Tween


func _ready() -> void:
	set_physics_process(false)


func _physics_process(_delta: float) -> void:
	global_position = lerp(global_position, get_global_mouse_position(), 0.25)


func set_data(card_data: CardData) -> void:
	_card_data = card_data
	
	$Card/Character.texture = card_data.texture


func flip_up() -> void:
	$AnimationPlayer.play("flip_up")
	
	await $AnimationPlayer.animation_finished
	
	$MarginContainer.visible = true
	
	flipped_up.emit()


func flip_down() -> void:
	$AnimationPlayer.play("flip_down")
	
	$MarginContainer.visible = false


func follow_cursor() -> void:
	set_physics_process(true)
	
	$MarginContainer.visible = false
	
	z_index += 1


func stop_following_cursor() -> void:
	set_physics_process(false)
	
	$MarginContainer.visible = true
	
	z_index = 0


func reset_position(time_seconds: float, target_position: Vector2 = Vector2.ZERO) -> void:
	if _position_tween != null and _position_tween.is_running():
		_position_tween.kill()

	_position_tween = get_tree().create_tween()
	
	_position_tween.tween_property(self, "position", target_position, time_seconds).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_position_tween.tween_property(self, "rotation", 0, time_seconds)


func _on_margin_container_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		card_clicked.emit()
