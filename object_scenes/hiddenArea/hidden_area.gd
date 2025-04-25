extends Area2D

@export var transitionSpeed :float = 0.3

var tween:Tween

func _ready() -> void:
	modulate.a = 1.0

func _on_body_entered(body: Node2D) -> void:
	if is_instance_valid(tween):
		tween.kill()
	tween = get_tree().create_tween().bind_node(self)
	tween.tween_property(self,"modulate:a",0.0,transitionSpeed)


func _on_body_exited(body: Node2D) -> void:
	if is_instance_valid(tween):
		tween.kill()
	tween = get_tree().create_tween().bind_node(self)
	tween.tween_property(self,"modulate:a",1.0,transitionSpeed)
