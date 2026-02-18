class_name Card
extends Sprite2D


@export var target_scale: Vector2 = Vector2(1.1, 1.1)

signal flipped_up

signal card_clicked

var _card_data: CardData

var _position_tween: Tween
var _appear_tween: Tween
var _scale_tween: Tween

var peer_id: int = 0

@onready var _original_scale: Vector2 = scale


func _ready() -> void:
	set_physics_process(false)
	
	disable()


func _physics_process(_delta: float) -> void:
	global_position = lerp(global_position, get_global_mouse_position(), 0.25)


func set_data(card_data: CardData) -> void:
	_card_data = card_data
	
	$Card/Character.texture = card_data.texture
	
	$GameLabel.text = str(_card_data.game)


func enable() -> void:
	$MarginContainer.visible = true


func disable() -> void:
	$MarginContainer.visible = false


func allow() -> void:
	$MarginContainer.mouse_default_cursor_shape = Input.CursorShape.CURSOR_POINTING_HAND


func forbid() -> void:
	$MarginContainer.mouse_default_cursor_shape = Input.CursorShape.CURSOR_FORBIDDEN


func flip_up() -> void:
	$AnimationPlayer.play("flip_up")
	
	await $AnimationPlayer.animation_finished
	
	flipped_up.emit()


func flip_down() -> void:
	disable()
	
	$AnimationPlayer.play("flip_down")


func _tween_modulate(target_color: Color) -> void:
	if _appear_tween != null and _appear_tween.is_running():
		_appear_tween.kill()
	
	_appear_tween = get_tree().create_tween()
	
	_appear_tween.tween_property(self, "modulate", target_color, 0.2)


func appear() -> void:
	_tween_modulate(Color.WHITE)


func disappear(next_parent: Node) -> void:
	disable()
	
	_tween_modulate(Color.TRANSPARENT)
	
	await _appear_tween.finished
	
	reparent(next_parent)


func play_hide() -> void:
	disable()
	
	$AnimationPlayer.play("hide")
	
	await $AnimationPlayer.animation_finished


func follow_cursor() -> void:
	set_physics_process(true)
	
	disable()
	
	z_index = 1
	
	_tween_scale(target_scale)


func stop_following_cursor() -> void:
	set_physics_process(false)
	
	enable()
	
	z_index = 0
	
	_tween_scale(_original_scale)


func reset_position(time_seconds: float, target_position: Vector2 = Vector2.ZERO) -> void:
	if _position_tween != null and _position_tween.is_running():
		_position_tween.kill()

	_position_tween = get_tree().create_tween()
	
	# .set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_position_tween.tween_property(self, "position", target_position, time_seconds)
	_position_tween.tween_property(self, "rotation", 0, time_seconds)
	
	await _position_tween.finished
	
	z_index = 0


func play_place_audio() -> void:
	$PlaceAudio.play()


func play_peer_place_audio() -> void:
	$PeerPlaceAudio.play()


func play_peer_grab_audio() -> void:
	$PeerGrabAudio.play()


func play_pick_up_audio() -> void:
	$PickUpAudio.play()


func play_move_to_hand_audio() -> void:
	$MoveToHandAudio.play()


func play_move_audio() -> void:
	$MoveAudio.play()


func reveal_number() -> void:
	$GameLabel/AnimationPlayer.play("reveal_number")
	
	await $GameLabel/AnimationPlayer.animation_finished


func show_number(color: Color) -> void:
	$GameLabel.add_theme_color_override("font_color", color)
	
	$GameLabel/AnimationPlayer.play("show_number")


func _tween_scale(_target_scale: Vector2) -> void:
	if _scale_tween != null and _scale_tween.is_running():
		_scale_tween.kill()
	
	_scale_tween = get_tree().create_tween()
	
	_scale_tween.tween_property(self, "scale", _target_scale, 0.1).set_trans(Tween.TRANS_ELASTIC)


func _on_margin_container_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		card_clicked.emit()


func _on_margin_container_mouse_entered() -> void:
	if $MarginContainer.mouse_default_cursor_shape == Input.CursorShape.CURSOR_FORBIDDEN:
		return
	
	_tween_scale(target_scale)


func _on_margin_container_mouse_exited() -> void:
	if is_physics_processing():
		return
	
	_tween_scale(_original_scale)
