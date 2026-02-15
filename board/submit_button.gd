extends Button


@export var floating_label_packed_scene: PackedScene


func show_score(results: HandEvaluationResults) -> void:
	if not results.is_valid:
		$AnimationPlayer.play("shake")
	
	var floating_label: Node2D = floating_label_packed_scene.instantiate()
	$Node2D.add_child(floating_label)
	
	floating_label.show_score(results)
