extends CanvasLayer


func fade_out() -> void:
	$ColorRect/AnimationPlayer.play("fade_out")
	
	await $ColorRect/AnimationPlayer.animation_finished


func fade_in() -> void:
	$ColorRect/AnimationPlayer.play("fade_in")
	
	await $ColorRect/AnimationPlayer.animation_finished
