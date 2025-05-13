extends AnimatableBody2D

@export var movingPosition :Vector2 = Vector2.ZERO
@export var time :float = 1.0

var originalPosition :Vector2
var newPosition :Vector2

func _ready() -> void:
	originalPosition = global_position
	newPosition = global_position + movingPosition
	poop()

func poop():
	var tween1 = get_tree().create_tween().bind_node(self)
	tween1.tween_property(self,"global_position",newPosition,time)
	await tween1.finished
	
	var tween2 = get_tree().create_tween().bind_node(self)
	tween2.tween_property(self,"global_position",originalPosition,time)
	await tween2.finished
	
	poop()
